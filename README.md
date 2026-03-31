# antivirus4skills
I want to inspect skills and plugins for bad things before trusting Codex CLI to use them on my local server.
I instruct Codex Cloud to 
- read through the skills collected in several high profile public repo in "max paranoia" mode
- show me all the suspicious places so I can re-check manually
- remember what I checked "Pass" so next time I do not have to re-check the same or highly similar issue
- for each repo make a single manifest overviewing all skills that "Pass", grouping skills into sections by what they do and tagging them for quick keyword search - one place to preselect safe/good skills for my other Codex projects

# Simplified workflow
1. Prepare an immutable local snapshot from a GitHub repo URL or release archive URL. See [`workflows/prepare_snapshot.md`](workflows/prepare_snapshot.md).
  - The helper records provenance in `snapshots/<snapshot-id>/snapshot.yml`, stores the full local hydrated tree in `snapshots/<snapshot-id>/hydrated/`, and creates a push-safe review subset in `snapshots/<snapshot-id>/review/`.
2. Run no-network Codex Cloud review against that prepared snapshot (see [`workflows/review_snapshot.md`](workflows/review_snapshot.md)).
  - Keep review artifacts separate from `review/`, prepared snapshot is immutable.
  - Codex generates a single human-readable review `report.md` file of suspicious issues without executing untrusted code, then stops to let human curate `report.md`.
  - Curate safe issues as `pass` and Codex will generate manifest briefly describing all safe skills and learn to treat similar issues as safe.
  - Curate dangerous/malicious issues as `fail` and Codex will generate human-readable bug report for each issue for the repo's maintaniter attention.

# Repos to be reviewed...

## openai/skills
This is the safest place to start. I do not expect any bad stuff there, so I will just debug manifest creation

## GPTomics/bioSkills
This is what I will likely need for my work ... but lets sanity-check them first and make an "onboarding manifest" to know what each of these skills is for

## K-Dense-AI/claude-scientific-skills
Next one to check

## FreedomIntelligence/OpenClaw-Medical-Skills
OpenClaw ... gives me mixed excitement/greed and fear. I am not ready to let these skills roam unchecked on my Ubuntu server where I do improtant stuff, and I can not afford a "throw away" spare Mac Silicon just for experiments.

## ClawBio/ClawBio
same greed and fear

# Disclaimer
I am just learning Codex, so do not expect much yet.
