#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/prepare_snapshot.sh <github-repo-or-archive-url> [snapshot-id]
  tools/prepare_snapshot.sh --rebuild-layout <snapshot-dir> <github-repo-or-archive-url>
EOF
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

MODE="prepare"
TARGET_DIR=""
SOURCE_URL=""
SNAPSHOT_ID_OVERRIDE=""
if [[ "$1" == "--rebuild-layout" ]]; then
  if [[ $# -ne 3 ]]; then
    usage >&2
    exit 1
  fi
  MODE="rebuild"
  TARGET_DIR="$2"
  SOURCE_URL="$3"
else
  SOURCE_URL="$1"
  SNAPSHOT_ID_OVERRIDE="${2:-}"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOTS_DIR="$ROOT_DIR/snapshots"
TODAY_UTC="$(date -u +%F)"
PREPARED_AT_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PREPARED_BY="${USER:-ai2}"
SNAPSHOT_NOTES=""

mkdir -p "$SNAPSHOTS_DIR"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

for cmd in awk cat cp curl find git grep mktemp rm sed sha256sum sort tar tr; do
  require_cmd "$cmd"
done

json_get_string() {
  local key="$1"
  local file="$2"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | head -n1
}

normalize_name() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g'
}

urlencode_path() {
  local input="$1"
  local output=""
  local i char hex

  for ((i = 0; i < ${#input}; i++)); do
    char="${input:$i:1}"
    case "$char" in
      [a-zA-Z0-9._~/-])
        output+="$char"
        ;;
      *)
        printf -v hex '%%%02X' "'$char"
        output+="$hex"
        ;;
    esac
  done

  printf '%s' "$output"
}

cleanup() {
  if [[ -n "${TMP_ROOT:-}" && -d "${TMP_ROOT:-}" ]]; then
    rm -rf "$TMP_ROOT"
  fi
}
trap cleanup EXIT

TMP_ROOT="$(mktemp -d "$ROOT_DIR/.tmp.prepare_snapshot.XXXXXX")"
META_JSON="$TMP_ROOT/meta.json"

SOURCE_TYPE=""
SOURCE_SLUG=""
REQUESTED_REF=""
RESOLVED_COMMIT_SHA=""
ARCHIVE_URL=""
REPO_NAME=""
ARCHIVE_FORMAT=""
OWNER=""

resolve_source() {
  if [[ "$SOURCE_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    SOURCE_SLUG="$OWNER/$REPO_NAME"
    SOURCE_TYPE="github_repo"

    curl -fsSL "https://api.github.com/repos/$SOURCE_SLUG" -o "$META_JSON"
    DEFAULT_BRANCH="$(json_get_string default_branch "$META_JSON")"
    if [[ -z "$DEFAULT_BRANCH" ]]; then
      echo "Failed to resolve default branch for $SOURCE_SLUG" >&2
      exit 1
    fi
    REQUESTED_REF="$DEFAULT_BRANCH"
    ARCHIVE_FORMAT="tar.gz"

    curl -fsSL "https://api.github.com/repos/$SOURCE_SLUG/commits/$REQUESTED_REF" -o "$META_JSON"
    RESOLVED_COMMIT_SHA="$(json_get_string sha "$META_JSON")"
    if [[ -z "$RESOLVED_COMMIT_SHA" ]]; then
      echo "Failed to resolve commit SHA for $SOURCE_SLUG at $REQUESTED_REF" >&2
      exit 1
    fi

    ARCHIVE_URL="https://github.com/$SOURCE_SLUG/archive/$RESOLVED_COMMIT_SHA.tar.gz"
  elif [[ "$SOURCE_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/archive/refs/tags/([^/]+)\.(zip|tar\.gz)$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    TAG="${BASH_REMATCH[3]}"
    EXT="${BASH_REMATCH[4]}"
    SOURCE_SLUG="$OWNER/$REPO_NAME"
    SOURCE_TYPE="github_archive_url"
    REQUESTED_REF="$TAG"
    ARCHIVE_URL="$SOURCE_URL"
    ARCHIVE_FORMAT="$EXT"

    curl -fsSL "https://api.github.com/repos/$SOURCE_SLUG/git/ref/tags/$TAG" -o "$META_JSON" || true
    REF_OBJECT_TYPE="$(json_get_string type "$META_JSON")"
    REF_OBJECT_SHA="$(json_get_string sha "$META_JSON")"
    if [[ "$REF_OBJECT_TYPE" == "commit" ]]; then
      RESOLVED_COMMIT_SHA="$REF_OBJECT_SHA"
    elif [[ "$REF_OBJECT_TYPE" == "tag" && -n "$REF_OBJECT_SHA" ]]; then
      curl -fsSL "https://api.github.com/repos/$SOURCE_SLUG/git/tags/$REF_OBJECT_SHA" -o "$META_JSON" || true
      RESOLVED_COMMIT_SHA="$(awk '
        /"object"[[:space:]]*:/ {in_object=1}
        in_object && /"type"[[:space:]]*:[[:space:]]*"commit"/ {commit_type=1}
        in_object && commit_type && /"sha"[[:space:]]*:/ {
          gsub(/^.*"sha"[[:space:]]*:[[:space:]]*"/,"")
          gsub(/".*$/,"")
          print
          exit
        }
      ' "$META_JSON")"
    fi
  elif [[ "$SOURCE_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/archive/refs/heads/([^/]+)\.(zip|tar\.gz)$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    BRANCH="${BASH_REMATCH[3]}"
    SOURCE_SLUG="$OWNER/$REPO_NAME"
    SOURCE_TYPE="github_archive_url"
    REQUESTED_REF="$BRANCH"
    ARCHIVE_URL="$SOURCE_URL"
    ARCHIVE_FORMAT="${BASH_REMATCH[4]}"

    curl -fsSL "https://api.github.com/repos/$SOURCE_SLUG/commits/$BRANCH" -o "$META_JSON" || true
    RESOLVED_COMMIT_SHA="$(json_get_string sha "$META_JSON")"
  else
    echo "Unsupported source URL: $SOURCE_URL" >&2
    exit 1
  fi

  if [[ -z "$RESOLVED_COMMIT_SHA" ]]; then
    echo "Failed to resolve exact commit SHA for $SOURCE_URL" >&2
    exit 1
  fi
}

check_existing_snapshot() {
  local snapshot_yml="$1"
  local existing_id existing_slug existing_ref existing_source_url existing_sha

  existing_id="$(sed -n 's/^snapshot_id:[[:space:]]*//p' "$snapshot_yml" | head -n1)"
  existing_slug="$(sed -n 's/^source_slug:[[:space:]]*//p' "$snapshot_yml" | head -n1)"
  existing_ref="$(sed -n 's/^requested_ref:[[:space:]]*//p' "$snapshot_yml" | head -n1)"
  existing_source_url="$(sed -n 's/^source_url:[[:space:]]*//p' "$snapshot_yml" | head -n1)"
  existing_sha="$(sed -n 's/^resolved_commit_sha:[[:space:]]*//p' "$snapshot_yml" | head -n1)"

  if [[ "$existing_slug" == "$SOURCE_SLUG" && "$existing_ref" == "$REQUESTED_REF" ]]; then
    echo "Duplicate source/version label already exists: $snapshot_yml" >&2
    echo "Existing snapshot_id: $existing_id" >&2
    exit 1
  fi

  if [[ "$existing_slug" == "$SOURCE_SLUG" && "$existing_sha" == "$RESOLVED_COMMIT_SHA" ]]; then
    echo "Conflicting preparation target: commit already captured in $snapshot_yml" >&2
    echo "Existing requested_ref: $existing_ref" >&2
    exit 1
  fi

  if [[ "$existing_id" == "$SNAPSHOT_ID" && "$existing_source_url" != "$SOURCE_URL" ]]; then
    echo "Snapshot id conflict for $SNAPSHOT_ID with different source URL in $snapshot_yml" >&2
    exit 1
  fi
}

download_archive_hash() {
  ARCHIVE_FILE="$TMP_ROOT/archive"
  ARCHIVE_SHA256_FILE="$TMP_ROOT/archive.sha256"

  curl -fL "$ARCHIVE_URL" -o "$ARCHIVE_FILE"
  sha256sum "$ARCHIVE_FILE" | awk '{print $1}' > "$ARCHIVE_SHA256_FILE"
  ARCHIVE_SHA256="$(cat "$ARCHIVE_SHA256_FILE")"
  rm -f "$ARCHIVE_FILE" "$ARCHIVE_SHA256_FILE"
}

hydrate_git_checkout() {
  CLONE_DIR="$TMP_ROOT/clone"
  mkdir -p "$CLONE_DIR"

  GIT_LFS_SKIP_SMUDGE=1 git clone --quiet "https://github.com/$SOURCE_SLUG.git" "$CLONE_DIR"
  git -C "$CLONE_DIR" checkout --quiet --detach "$RESOLVED_COMMIT_SHA"

  : > "$TMP_ROOT/excluded-paths.txt"
  while IFS= read -r rel_path; do
    attr_value="$(git -C "$CLONE_DIR" check-attr filter -- "$rel_path" | sed 's/.*: filter: //')"
    if [[ "$attr_value" == "lfs" ]]; then
      printf '%s\n' "$rel_path" >> "$TMP_ROOT/excluded-paths.txt"
    fi
  done < <(git -C "$CLONE_DIR" ls-files)

  if git -C "$CLONE_DIR" lfs ls-files -n >/dev/null 2>&1; then
    git -C "$CLONE_DIR" lfs fetch origin "$RESOLVED_COMMIT_SHA" >/dev/null 2>&1 || true
    git -C "$CLONE_DIR" lfs checkout >/dev/null 2>&1 || true
    git -C "$CLONE_DIR" lfs ls-files -l > "$TMP_ROOT/lfs-long.txt" || true
  else
    : > "$TMP_ROOT/lfs-long.txt"
  fi

  : > "$TMP_ROOT/unresolved-lfs.txt"
  while IFS= read -r rel_path; do
    raw_url="https://github.com/$SOURCE_SLUG/raw/$RESOLVED_COMMIT_SHA/$(urlencode_path "$rel_path")"
    file_path="$CLONE_DIR/$rel_path"
    tmp_download="$TMP_ROOT/raw-lfs-download"

    if [[ ! -f "$file_path" ]]; then
      printf '%s\n' "$rel_path" >> "$TMP_ROOT/unresolved-lfs.txt"
      continue
    fi

    if ! head -n 1 "$file_path" | grep -Fqx 'version https://git-lfs.github.com/spec/v1'; then
      continue
    fi

    rm -f "$tmp_download"
    if curl -fsSL "$raw_url" -o "$tmp_download"; then
      if [[ -s "$tmp_download" ]] && ! head -n 1 "$tmp_download" | grep -Fqx 'version https://git-lfs.github.com/spec/v1'; then
        mv "$tmp_download" "$file_path"
        continue
      fi
    fi

    rm -f "$tmp_download"
    printf '%s\n' "$rel_path" >> "$TMP_ROOT/unresolved-lfs.txt"
  done < "$TMP_ROOT/excluded-paths.txt"

  unresolved_count="$(wc -l < "$TMP_ROOT/unresolved-lfs.txt" | awk '{print $1}')"
  if [[ "$unresolved_count" -gt 0 ]]; then
    SNAPSHOT_NOTES="unresolved_lfs_paths=$unresolved_count"
    printf 'Warning: %s unresolved LFS paths remain as pointers for %s\n' "$unresolved_count" "$SOURCE_SLUG" >&2
  fi
}

copy_tree_without_metadata() {
  local source_dir="$1"
  local dest_dir="$2"

  mkdir -p "$dest_dir"
  cp -R "$source_dir/." "$dest_dir/"
  rm -rf "$dest_dir/.git"
  while IFS= read -r attr_file; do
    rm -f "$attr_file"
  done < <(find "$dest_dir" -name .gitattributes -type f | sort)
}

is_lfs_pointer_file() {
  local file_path="$1"

  [[ -f "$file_path" ]] || return 1
  head -n 1 "$file_path" | grep -Fqx 'version https://git-lfs.github.com/spec/v1'
}

lookup_pointer_oid() {
  local rel_path="$1"
  local oid=""

  oid="$(awk -v path="$rel_path" '$0 ~ (" " path "$") {print $1; exit}' "$TMP_ROOT/lfs-long.txt")"
  if [[ -n "$oid" ]]; then
    printf 'sha256:%s' "$oid"
    return 0
  fi

  if is_lfs_pointer_file "$HYDRATED_DIR/$rel_path"; then
    sed -n 's/^oid //p' "$HYDRATED_DIR/$rel_path" | head -n1
    return 0
  fi

  printf ''
}

build_omitted_manifest() {
  local manifest_path="$1"
  local count

  sort -u "$TMP_ROOT/excluded-paths.txt" "$TMP_ROOT/pointer-detected-paths.txt" > "$TMP_ROOT/all-omitted-paths.txt"
  count="$(wc -l < "$TMP_ROOT/all-omitted-paths.txt" | awk '{print $1}')"
  {
    printf 'count: %s\n' "$count"
    if [[ "$count" -eq 0 ]]; then
      printf 'paths: []\n'
    else
      printf 'paths:\n'
      while IFS= read -r rel_path; do
        oid="$(lookup_pointer_oid "$rel_path")"
        size_bytes=""
        hydration_status="hydrated"
        exclusion_source="upstream_filter_lfs"
        if [[ -f "$HYDRATED_DIR/$rel_path" ]]; then
          size_bytes="$(wc -c < "$HYDRATED_DIR/$rel_path" | awk '{print $1}')"
        fi
        if grep -Fqx "$rel_path" "$TMP_ROOT/pointer-detected-paths.txt"; then
          exclusion_source="detected_pointer_blob"
        fi
        if grep -Fqx "$rel_path" "$TMP_ROOT/unresolved-lfs.txt" || is_lfs_pointer_file "$HYDRATED_DIR/$rel_path"; then
          hydration_status="pointer_only"
        fi
        printf '  - path: %s\n' "$rel_path"
        printf '    oid: %s\n' "${oid:-}"
        printf '    size_bytes: %s\n' "${size_bytes:-unknown}"
        printf '    hydration_status: %s\n' "$hydration_status"
        printf '    exclusion_source: %s\n' "$exclusion_source"
        printf '    reason: excluded_from_review_push\n'
      done < "$TMP_ROOT/all-omitted-paths.txt"
    fi
  } > "$manifest_path"
}

prepare_layout() {
  HYDRATED_DIR="$TARGET_DIR/hydrated"
  REVIEW_DIR="$TARGET_DIR/review"
  OMITTED_MANIFEST="$TARGET_DIR/omitted-lfs.yml"

  rm -rf "$HYDRATED_DIR" "$REVIEW_DIR" "$OMITTED_MANIFEST"

  copy_tree_without_metadata "$CLONE_DIR" "$HYDRATED_DIR"
  copy_tree_without_metadata "$HYDRATED_DIR" "$REVIEW_DIR"

  : > "$TMP_ROOT/pointer-detected-paths.txt"
  while IFS= read -r rel_path; do
    rm -f "$REVIEW_DIR/$rel_path"
  done < "$TMP_ROOT/excluded-paths.txt"

  while IFS= read -r review_file; do
    rel_path="${review_file#$REVIEW_DIR/}"
    if is_lfs_pointer_file "$review_file"; then
      printf '%s\n' "$rel_path" >> "$TMP_ROOT/pointer-detected-paths.txt"
      rm -f "$review_file"
    fi
  done < <(find "$REVIEW_DIR" -type f | sort)

  build_omitted_manifest "$OMITTED_MANIFEST"
}

write_snapshot_yml() {
  cat > "$TARGET_DIR/snapshot.yml" <<EOF
snapshot_id: $SNAPSHOT_ID
layout_version: 2
status: unreviewed
source_type: $SOURCE_TYPE
source_url: $SOURCE_URL
source_slug: $SOURCE_SLUG
requested_ref: $REQUESTED_REF
resolved_commit_sha: $RESOLVED_COMMIT_SHA
archive_url: $ARCHIVE_URL
archive_sha256: $ARCHIVE_SHA256
prepared_at_utc: $PREPARED_AT_UTC
prepared_by: $PREPARED_BY
review_root: review
hydrated_root: hydrated
omitted_lfs_manifest: omitted-lfs.yml
notes: $SNAPSHOT_NOTES
EOF
}

resolve_source

DEFAULT_STEM="$(normalize_name "$REPO_NAME")"
if [[ "$DEFAULT_STEM" == "skills" || "$DEFAULT_STEM" == "plugins" ]]; then
  DEFAULT_STEM="$(normalize_name "$OWNER")-$DEFAULT_STEM"
fi

if [[ "$MODE" == "prepare" ]]; then
  if [[ -n "$SNAPSHOT_ID_OVERRIDE" ]]; then
    SNAPSHOT_ID="$(normalize_name "$SNAPSHOT_ID_OVERRIDE")"
  else
    SNAPSHOT_ID="$DEFAULT_STEM-$(normalize_name "$REQUESTED_REF")-$TODAY_UTC"
  fi
  TARGET_DIR="$SNAPSHOTS_DIR/$SNAPSHOT_ID"

  if [[ -e "$TARGET_DIR" ]]; then
    echo "Target snapshot directory already exists: $TARGET_DIR" >&2
    exit 1
  fi

  while IFS= read -r snapshot_yml; do
    check_existing_snapshot "$snapshot_yml"
  done < <(find "$SNAPSHOTS_DIR" -mindepth 2 -maxdepth 2 -name snapshot.yml | sort)

  mkdir -p "$TARGET_DIR"
else
  if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Snapshot directory does not exist: $TARGET_DIR" >&2
    exit 1
  fi
  SNAPSHOT_ID="$(basename "$TARGET_DIR")"
fi

download_archive_hash
hydrate_git_checkout
prepare_layout
write_snapshot_yml

if [[ "$MODE" == "rebuild" ]]; then
  rm -rf "$TARGET_DIR/original"
  printf 'Rebuilt snapshot layout: %s\n' "$TARGET_DIR"
else
  printf 'Prepared snapshot: %s\n' "$TARGET_DIR"
fi
