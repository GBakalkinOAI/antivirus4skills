You are helping extend this local snapshot-preparation workspace.

Read these workflow docs first:
- `workflows/prepare_snapshot.md`
- `workflows/review_snapshot.md`

Task:
- Add prepared snapshots for the GitHub sources pasted below.
- Use the existing local workflow and helper script.
- Keep changes minimal and reviewable.

Hard constraints:
- Work only inside this repository.
- Do not run code from downloaded external sources.
- Do not install dependencies from downloaded external sources.
- Do not inspect downloaded source contents beyond the minimum needed to verify extraction, compute hashes, and record provenance.
- Treat `snapshots/*/review/` and local `snapshots/*/hydrated/` as immutable after preparation.
- Stop and explain if any requested snapshot conflicts with existing provenance or duplicates an existing source/version label.

URLs to add:
PASTE_URLS_HERE

Expected outcome:
- one new snapshot directory per accepted source under `snapshots/`
- each new snapshot contains `snapshot.yml`, `review/`, `hydrated/`, and `omitted-lfs.yml`
- downloaded archives and temporary clone state removed after preparation
- no edits to existing downstream review artifacts

At the end, report:
- which snapshots were added
- each snapshot path
- each resolved commit SHA
- any conflicts, duplicates, or unresolved metadata
