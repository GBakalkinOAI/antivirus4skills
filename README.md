# antivirus4skills
I want to inspect skills and plugins for bad things before trusting Codex CLI to use them on my local server.
I instruct Codex Cloud to 
- read through the skills collected in several high profile public repo in "max paranoia" mode
- show me all the suspicious places so I can re-check manually
- remember what I checked "Pass" so next time I do not have to re-check the same or highly similar issue
- for each repo make a single manifest overviewing all skills that "Pass", grouping skills into sections by what they do and tagging them for quick keyword search - one place to preselect safe/good skills for my other Codex projects

# Simplified workflow (see `REVIEW_WORKFLOW.md` for details)
- Fork skills repo so Codex's GitHub connector will use it (and reliably freeze the repo's version, so no silent updates could slip unreviewed).
- Run Codex Cloud in forked repo by pasting the prompt from `templates/prompt-review-repo.md`.
- Codex generates `<SOURCE_REPO>-codex-issues.md`, the single file aggregating all suspicious issues from all skills of that repo plus flags other problems, like installation scripts doing something unexpected.
- Copy generated files to this repo, run Codex Cloud with `templates/prompt-guess-similar.md` to pre-fill decisions for the same or highly similar issues we met before in old versions of this repo or in other repos.
- Manually curate remaining issues and sanity-check Codex's pre-filled decisions.
- Run Codex Cloud on manually curated issues to get three more files: overview of all safe skills in this repo, overview of unresolved issues, clearly malicious/dangerous stuff with human readable explanations to notify the original skill repo's maintainer.

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
