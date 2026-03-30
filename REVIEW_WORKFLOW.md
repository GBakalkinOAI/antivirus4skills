# REVIEW_WORKFLOW

Purpose: define a reusable, human-auditable, **max paranoia** workflow for reviewing external skill/plugin repositories before local use.

## Scope and guardrails
- Review one external repository at a time.
- Static-analysis mode only (read/analyze; no execution of untrusted code).
- Do not trust prior pass status without re-checking pinned version metadata.
- Produce human-readable Markdown artifacts only.
- Codex is evidence-only: it must not pre-fill, draft, suggest, or infer final Pass/Maybe/Fail decisions.

## Required review inputs
- Reviewed repo (fork or source under review).
- Source repo (upstream/original if different).
- Version pin target (commit SHA preferred, tag allowed if resolved to SHA).
- Reviewer name/identifier.
- Review date (UTC).

## Workflow steps
1. **Intake and pin target**
   - Record repo URL and owner/repo slug.
   - Record intended pin (commit SHA or tag+resolved SHA).
   - Record why this repo is being reviewed.

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

5. **Human-only decision gate**
   - Codex outputs findings/evidence and leaves decision fields blank or `undecided`.
   - Human reviewer alone assigns final Pass / Maybe / Fail after manual verification.
   - Human reviewer may add final rationale and required follow-up actions.

6. **Manifest creation (only if safe enough to overview)**
   - If decision is Pass (or explicitly approved Maybe), create a reviewed-repo manifest from template.
   - Group skills by what they do and add keyword tags.

7. **Index update**
   - Add the reviewed repo/version to one top-level index:
     - `skill-index.md` for Pass
     - `skill-index-maybe.md` for Maybe
     - `skill-index-failed.md` for Fail
   - Include links to findings report and manifest (if any).
   - Do not add Pass/Maybe/Fail entries until a human decision exists.

## Version pinning requirements (mandatory)
Every review artifact must include:
- Reviewed repo URL and owner/repo.
- Source repo URL and owner/repo (if applicable).
- Pin type: commit SHA (preferred) or tag.
- Exact commit SHA reviewed.
- Reviewed date (UTC).
- Reviewer.

Rules:
- Treat branch names as unpinned/mutable (insufficient).
- If only a tag is available, resolve and store the commit SHA that tag pointed to during review.
- A decision applies **only** to that pinned version.

## Reuse of prior decisions and catches
Before finalizing any new review:
- Check prior findings reports for same repo and related repos/authors.
- Reuse `SUSPICIOUS_PATTERNS.md` categories and add newly observed patterns.
- Note whether each suspicious pattern is recurring, new, or regressed.
- If a previously failed pattern reappears, bias toward Maybe/Fail until resolved.

## Decision policy
- Final decision ownership: **human reviewer only**.
- **Pass**: no high-risk unresolved findings; remaining concerns are low-risk and documented.
- **Maybe**: unresolved or ambiguous findings requiring human/manual validation.
- **Fail**: confirmed high-risk behavior, policy violations, or unacceptable unresolved critical risk.

## Naming conventions for reviewed artifacts
For future per-review artifacts, use sortable names:
- Findings report:
  - `reports/YYYY-MM-DD__owner-repo__pin-<shortsha-or-tag>__findings.md`
- Reviewed manifest:
  - `manifests/YYYY-MM-DD__owner-repo__pin-<shortsha-or-tag>__manifest.md`

Notes:
- Keep names lowercase, hyphenated, and stable.
- Do not create repo-specific directories unless later explicitly requested.
