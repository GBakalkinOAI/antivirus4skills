# SUSPICIOUS_PATTERNS

Purpose: a conservative, growing checklist for identifying potentially dangerous behavior in external skill/plugin repositories.

## How to use this file
- Use this checklist in every review.
- Flag liberally during first pass; reduce false positives during manual triage.
- When a new suspicious case is manually confirmed, add it here with context.

## Pattern categories

### 1) Command execution and shell risk
- Hidden or indirect shell execution (`sh`, `bash`, `powershell`, dynamic command composition).
- Use of `eval`/equivalents or command strings built from untrusted input.
- Instructions encouraging elevated privileges (`sudo`, policy bypass, security disabling).

### 2) Network and data exfiltration
- Silent outbound requests to unknown endpoints.
- Uploading local files, environment variables, tokens, or workspace metadata.
- Dynamic remote content fetch/execute behavior.

### 3) Credential and secret handling
- Reading secret files or keychains without explicit user intent.
- Prompting users to paste secrets in insecure ways.
- Hardcoded credentials, tokens, or suspicious placeholders.

### 4) Persistence and environment modification
- Auto-editing shell profiles/startup files.
- Installing background services/agents/tasks.
- Modifying system configuration beyond declared scope.

### 5) Obfuscation and anti-audit behavior
- Encoded/obfuscated payloads without clear reason.
- Minified blobs in otherwise human-readable repositories.
- Instructions that discourage inspection or hide side effects.

### 6) Supply-chain and execution indirection
- Unpinned dependencies or remote scripts executed directly.
- Download-and-run patterns.
- Tooling that mutates behavior at runtime from external sources.

### 7) Destructive or irreversible actions
- File deletion/wiping patterns.
- Bulk overwrite operations without safeguards.
- Risky data migration steps lacking backup/confirmation guidance.

### 8) Misrepresentation and trust signals
- Claimed behavior not matching files/instructions.
- Security claims with no evidence.
- Mismatched ownership/provenance metadata.

## Severity guidance (initial)
- **Critical**: clear compromise risk (credential theft, remote execution, destructive actions).
- **High**: likely harmful without mitigation.
- **Medium**: suspicious and potentially risky; needs confirmation.
- **Low**: weak signal but worth tracking.

## Confidence guidance
- **High confidence**: direct evidence in file/snippet.
- **Medium confidence**: plausible but context incomplete.
- **Low confidence**: weak indicator; monitor for recurrence.

## Growth log template (append over time)
Use this block for newly confirmed catches:

```markdown
### Catch: <short title>
- Date:
- Repo/version:
- Pattern category:
- Evidence path(s):
- Why it mattered:
- Decision impact:
- Rule added/updated:
```
