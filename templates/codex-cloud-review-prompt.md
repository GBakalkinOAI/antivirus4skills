# Codex Cloud Review Prompt (Template)

Use this template to request a max-paranoia static review of exactly one external repo.

```markdown
You are reviewing one external skills/plugins repository in **max paranoia** mode.

Scope:
- Review only this repository: <REVIEWED_REPO_URL>
- Source/upstream repo (if different): <SOURCE_REPO_URL>
- Version to review: <COMMIT_SHA_OR_TAG>

Hard constraints:
- Static analysis only; do not execute untrusted code.
- Do not propose automated execution pipelines.
- Produce Markdown output only.
- Do not pre-fill or infer Pass/Maybe/Fail; leave final decision as human-only `undecided` placeholder.

Required outputs:
1) Review metadata (reviewed repo, source repo, exact version pin, reviewer/date placeholders).
2) Suspicious findings list with:
   - exact file path
   - short snippet
   - reason
   - severity (Critical/High/Medium/Low)
   - confidence (High/Medium/Low)
   - manual verification notes
3) Human-only decision placeholder section (`undecided` by default; no Codex inference).
4) Follow-up actions required before trust.
5) If safe enough to overview, draft a grouped manifest of skills by function and add keyword tags.

Method guidance:
- Be conservative; include ambiguous items as findings for manual review.
- Reuse historical suspicious patterns and prior decisions when available.
- Treat decision as valid only for the exact pinned version.
- Avoid false positives for ordinary use of well-curated standard tools/packages; flag only suspicious invocation context.
```
