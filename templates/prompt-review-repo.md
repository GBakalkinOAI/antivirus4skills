You are reviewing one external skills/plugins repository in **max paranoia** mode.

Scope:
- This is fork of repo: SOURCE_REPO_URL = 
- Version to review: COMMIT_SHA_OR_TAG = 
- If user forgot to fill is scope, complain and stop.

Hard constraints:
- Static analysis only; do not execute untrusted code.
- Do not propose automated execution pipelines.
- Produce exactly two Markdown output files: `<SOURCE_REPO>-codex-issues.md` and `<SOURCE_REPO>-codex-overview.md`.
- Do not pre-fill or infer Pass/Maybe/Fail; leave final decision as human-only `undecided` placeholder.

Required outputs in `<SOURCE_REPO>-codex-issues.md`:
1) Review metadata, to place once in the beginning of the file
   - <SOURCE_REPO_URL>, version <COMMIT_SHA_OR_TAG>
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

Required outputs in `<SOURCE_REPO>-codex-overview.md`:
1) Review metadata, to place once in the beginning of the file
   - <SOURCE_REPO_URL>, version <COMMIT_SHA_OR_TAG>
   - Reviewed: <Year-Month-Date> Daniil Sarkisyan
2) For each skill output:
   - name
   - overview
   - list of tags/keywords
3) Group skills into sections according to the tasks they solve.

Method guidance:
- Be conservative; include ambiguous items as findings for manual review.
- Avoid false positives for ordinary use of well-curated standard tools/packages; flag only suspicious invocation context.
