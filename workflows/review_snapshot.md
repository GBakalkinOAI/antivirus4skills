# REVIEW_SNAPSHOT

Purpose: define a reusable, human-auditable, **max paranoia** workflow for reviewing external skill/plugin repositories before local use.

Snapshots are prepared separately before review. For snapshot preparation rules, provenance, and extraction policy, see [`workflows/prepare_snapshot.md`](workflows/prepare_snapshot.md).

## Scope and guardrails
- Review one external repository at a time from a prepared local snapshot, not a live mutable upstream checkout.
- Static-analysis mode only (read/analyze; no execution of untrusted code).
- Do not trust prior pass status without re-checking pinned version metadata.
- Produce human-readable Markdown artifacts only.
- Codex is evidence-only: it must not pre-fill, draft, suggest, or infer final Pass/Maybe/Fail decisions.

## Required review inputs
- Prepared snapshot directory under `snapshots/`.
- Reviewer name/identifier.
- Review date (UTC).

## Workflow steps
1. **Intake and pin target**
   - Read `snapshot.yml` for repo URL, owner/repo slug, intended pin, and resolved SHA.
   - Confirm that the snapshot contains `review/` and use that as the review input tree.
   - Record that this repo is being reviewed.

2. **Baseline context check**
   - Identify repository structure and where skills/plugins live.
   - Identify files that can influence behavior: prompts, scripts, shell snippets, install instructions, hooks, network calls, dynamic loaders.

3. **Suspicious pattern pass (broad)**
   - Use `SUSPICIOUS_PATTERNS.md` as checklist.
   - Flag all potential matches conservatively (false positives are acceptable in this stage).
   - Do **not** flag ordinary, well-curated standard tooling/package usage by itself.
   - Examples usually safe-by-default when used normally: R/Bioconductor packages, standard conda packages from trusted channels, and common tools like `samtools`.
   - Only flag such tooling when usage context is suspicious (for example: untrusted install source, unpinned raw URL/git install, shell injection risk, credential access/exfiltration, unsafe writes outside expected scope, disabled security checks, suspicious post-install/download behavior).

4. **Evidence collection and triage**
   - For each finding, capture exact path and snippet.
   - Assign severity and confidence.
   - Explain why it may be risky and what manual verification is needed.
   - Reuse `SUSPICIOUS_PATTERNS.md` categories

5. **Human-only decision gate**
   - Codex outputs findings/evidence in a single `report.md` file and leaves decision fields as `undecided`.
   - Human reviewer alone assigns final `pass` / `maybe` / `fail` after manual verification.
   - Human reviewer may add final rationale and required follow-up actions.

6. **Manifest creation (only if safe enough to overview)**
   - If decision is `pass`, create a reviewed-repo `safe-manifest.md` from human-curated `report.md`.
   - Group skills by what they do, add keyword tags and show overview.
   - Manifest intend to give human user an overview of all safe skills in the repo, so user can include them in future Codex projects.

7. **Distillation of decisions and catches**
   - Consider only findings where human reviewer assigned `pass` or `fail`
   - Are there newly observed patterns for `SUSPICIOUS_PATTERNS.md`? If eyes, show diffs implementing them, ask user for approval, add if approved.

## Decision policy
- Final decision ownership: **human reviewer only**.
- **Pass**: no high-risk unresolved findings; remaining concerns are low-risk and documented.
- **Maybe**: unresolved or ambiguous findings requiring human/manual validation.
- **Fail**: confirmed high-risk behavior, policy violations, or unacceptable unresolved critical risk.

Notes:
- Keep names lowercase, hyphenated, and stable.
- Do not create repo-specific directories unless later explicitly requested.
- Do not read from `hydrated/` unless the workflow is explicitly being debugged locally; Codex Cloud review should use `review/` only.
