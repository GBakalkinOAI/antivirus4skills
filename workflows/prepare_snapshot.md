# PREPARE_SNAPSHOT

Purpose: define a reusable, human-auditable workflow for preparing immutable local snapshots of external skills/plugin repositories for later no-network review.

## Scope and guardrails
- Preparation is intake only, not review.
- Static handling only: resolve exact commit, hash the canonical GitHub archive for provenance, create a local hydrated checkout, and derive a push-safe review tree.
- Do not execute untrusted code.
- Do not install dependencies from downloaded external sources.
- Do not inspect downloaded source contents beyond the minimum needed to verify extraction, compute hashes, and record provenance.
- Work only under `snapshots/`.
- The local hydrated source under `snapshots/*/hydrated/` is immutable after preparation.
- If `review.md`, `curated/`, or other review artifacts appear later in a snapshot directory, treat them as downstream evidence from Codex Cloud or manual review and do not overwrite them.

## Accepted source types
1. Plain GitHub repository URL:
   - Example: `https://github.com/openai/skills`
   - Resolve the exact source commit SHA first.
   - Download an archive for that exact SHA.

2. GitHub archive URL:
   - Examples:
     - `https://github.com/OWNER/REPO/archive/refs/tags/TAG.zip`
     - `https://github.com/OWNER/REPO/archive/refs/tags/TAG.tar.gz`
     - `https://github.com/OWNER/REPO/archive/refs/heads/BRANCH.zip`
   - Download that exact archive URL.
   - Resolve the underlying commit SHA when possible and record it in `snapshot.yml`.

## Snapshot naming
- Snapshot directories are append-only and always new.
- Use a natural-sort name with newest snapshots last.
- Naming pattern:
  - Branch snapshot: `<repo>-<ref>-YYYY-MM-DD`
  - Release snapshot: `<repo>-<tag>-YYYY-MM-DD`
- Examples:
  - `openai-skills-main-2026-03-31`
  - `claude-scientific-skills-v2.31.0-2026-03-31`

## Duplicate and conflict policy
- Stop if the target snapshot directory already exists.
- Stop if another snapshot already exists for the same source/version label:
  - same `source_slug`
  - same `requested_ref`
- Stop if provenance for the new snapshot conflicts with an existing snapshot.
- Explain the conflicting path(s) and metadata field(s) before stopping.

## Per-snapshot layout
Each prepared snapshot directory contains:

```text
snapshots/<snapshot-id>/
  snapshot.yml
  omitted-lfs.yml
  review/
  hydrated/
```

Rules:
- `review/` is the tracked, push-safe subset for Codex Cloud review.
- `hydrated/` is local-only and gitignored. It contains the full hydrated checkout, including real bytes for upstream LFS files.
- `.gitattributes` files from upstream must not be kept in either `review/` or `hydrated/`.
- `omitted-lfs.yml` lists files excluded from `review/` because upstream stored them via Git LFS.
- No review artifacts such as `review.md` are created during preparation.

## `snapshot.yml` schema
Required fields:

```yaml
snapshot_id: openai-skills-main-2026-03-31
layout_version: 2
status: unreviewed
source_type: github_repo
source_url: https://github.com/openai/skills
source_slug: openai/skills
requested_ref: main
resolved_commit_sha: <fullsha-or-empty-if-unresolvable>
archive_url: <exact archive url used>
archive_sha256: <sha256>
prepared_at_utc: 2026-03-31T00:00:00Z
prepared_by: ai2
review_root: review
hydrated_root: hydrated
omitted_lfs_manifest: omitted-lfs.yml
notes: ""
```

Field rules:
- `status` starts as `unreviewed`.
- `resolved_commit_sha` must be filled when it can be resolved reliably.
- `archive_url` must be the exact URL used for the downloaded archive.
- `archive_sha256` is the hash of the downloaded archive file before it is deleted.
- `review_root` is the reviewable tracked subset path inside the snapshot directory.
- `hydrated_root` is the local-only full-content path inside the snapshot directory.
- `omitted_lfs_manifest` is the tracked manifest of files excluded from `review/`.

## Extraction rules
- Download the exact archive URL and hash it for provenance.
- Create a temporary git checkout at the resolved commit SHA.
- Hydrate Git LFS objects in the temporary checkout when present.
- If `git lfs` cannot hydrate a path, try the exact GitHub raw URL for that pinned commit.
- Build `hydrated/` from that checkout after stripping `.git/` and all `.gitattributes`.
- Build `review/` from `hydrated/` by excluding every path reported by `git lfs ls-files` for the pinned commit.
- Record excluded paths in `omitted-lfs.yml`.
- If an upstream LFS object is no longer available, leave that path excluded from `review/` and record the unresolved count in `snapshot.yml` notes plus `pointer_only` entries in `omitted-lfs.yml`.
- Remove temporary checkout and downloaded archive after successful verification and recording.

## Helper command
Use:

```bash
tools/prepare_snapshot.sh <source-url>
tools/prepare_snapshot.sh <source-url> <snapshot-id>
```

Expected behavior:
- reject unsupported URLs
- resolve provenance
- enforce duplicate/conflict checks
- create `snapshots/<snapshot-id>/snapshot.yml`
- create `snapshots/<snapshot-id>/review/`
- create local-only `snapshots/<snapshot-id>/hydrated/`
- create `snapshots/<snapshot-id>/omitted-lfs.yml`
- delete temporary clone state and downloaded archive after success

Notes:
- `<snapshot-id>` is optional.
- Use an explicit `<snapshot-id>` if the default name would be too generic.
- By default, obviously generic repository names like `skills` are prefixed with the GitHub owner to keep names readable.

## Intake for later review
- Later no-network review should point at an existing prepared snapshot directory.
- Review artifacts such as `review.md` and `curated/` are maintained separately from `review/`.
