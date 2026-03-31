#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tools/migrate_snapshot_layout.sh [snapshot-dir ...]
EOF
}

if [[ $# -eq 0 ]]; then
  mapfile -t SNAPSHOT_DIRS < <(find "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/snapshots" -mindepth 1 -maxdepth 1 -type d | sort)
else
  SNAPSHOT_DIRS=("$@")
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for snapshot_dir in "${SNAPSHOT_DIRS[@]}"; do
  if [[ ! -d "$snapshot_dir" ]]; then
    echo "Snapshot directory not found: $snapshot_dir" >&2
    exit 1
  fi

  snapshot_yml="$snapshot_dir/snapshot.yml"
  if [[ ! -f "$snapshot_yml" ]]; then
    echo "Missing snapshot.yml in $snapshot_dir" >&2
    exit 1
  fi

  layout_version="$(sed -n 's/^layout_version:[[:space:]]*//p' "$snapshot_yml" | head -n1)"
  if [[ "$layout_version" == "2" ]]; then
    echo "Already migrated: $snapshot_dir"
    continue
  fi

  source_url="$(sed -n 's/^source_url:[[:space:]]*//p' "$snapshot_yml" | head -n1)"
  snapshot_id="$(sed -n 's/^snapshot_id:[[:space:]]*//p' "$snapshot_yml" | head -n1)"
  if [[ -z "$source_url" || -z "$snapshot_id" ]]; then
    echo "Missing source_url or snapshot_id in $snapshot_yml" >&2
    exit 1
  fi

  "$ROOT_DIR/tools/prepare_snapshot.sh" --rebuild-layout "$snapshot_dir" "$source_url"
done
