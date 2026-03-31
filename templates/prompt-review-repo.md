You are reviewing one prepared local snapshot of an external skills/plugins repository in **max paranoia** mode.

Read these workflow docs first:
- `workflows/prepare_snapshot.md`
- `workflows/review_snapshot.md`

Snapshot to review:
- `PASTE_SNAPSHOT_PATH_HERE`

Required preflight:
- Read `snapshot.yml` in that snapshot directory first.
- Use the recorded provenance as the review metadata source of truth.
- Review only the prepared source under `review/`.
- Do not modify `review/`.
- If `PASTE_SNAPSHOT_PATH_HERE` is missing, invalid, or does not contain both `snapshot.yml` and `review/`, complain and stop.

Hard constraints:
- Static analysis only; do not execute untrusted code.
- Do not propose automated execution pipelines.
- Produce exactly one Markdown output file inside the snapshot directory: `review.md`.
- Do not pre-fill or infer Pass/Maybe/Fail; leave final decision as human-only `undecided` placeholder.
- Do not edit `snapshot.yml`.
- Do not create or modify `curated/` in this step.

Required outputs in `review.md`:
1) Review metadata, to place once in the beginning of the file
   - snapshot path
   - source URL
   - source slug
   - requested ref
   - exact commit SHA reviewed
   - Reviewed: <Year-Month-Date> Daniil Sarkisyan
2) For each suspicious finding output:
   - exact file path
   - short snippet
   - reason
   - follow-up actions required before trust
   - severity (Critical/High/Medium/Low)
   - confidence (High/Medium/Low)
   - decision: undecided (Human-only placeholder, no Codex inference)
   - verification notes (empty placeholder, no Codex inference)

Method guidance:
- Be conservative; include ambiguous items as findings for manual review.
- Avoid false positives for ordinary use of well-curated standard tools/packages; flag only suspicious invocation context.
- Keep `review.md` separate from `review/`.
