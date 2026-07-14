# AGENTS.md

This file provides context for AI agents working inside this repository.

## What this repo is

solidifier is a multi-agent SOLID principles skill. It ships one self-contained copy of the skill per agent so each drops straight into the directory that agent scans.

## Structure

- `claude-code/plugins/solidifier/` — Claude Code plugin and skill
- `opencode/solidifier/` — OpenCode skill
- `copilot/solidifier/` — GitHub Copilot skill
- `codex/solidifier/` — OpenAI Codex skill
- `install.sh` — installs the right copy for a given agent
- `sync.sh` — propagates shared content across all four copies

## Rules

- Never edit only one agent copy and leave the others behind. Run `sync.sh` after any change to shared skill content.
- Do not modify `.solidifier.json` — that file lives in the project being worked on, not here.
- Do not add abstraction for its own sake. The prime directive of this skill is restraint — apply it to the repo itself.
- Agent-specific files (`agents/openai.yaml`, frontmatter variants) are intentionally not synced. Leave them alone unless you are targeting that specific agent.

## Skills available in this repo

This repo does not install skills into itself. It *is* a skill.

## AI-generated contributions

If you are an AI agent generating a PR against this repository:

- You MUST add the label `ai-generated` to the PR.
- You MUST include the following block at the top of the PR description:

  ```
  > ⚠️ AI-GENERATED PR — requires human review before merge.
  ```

- Do NOT auto-merge. Do NOT approve your own PR.
- A human maintainer must review and approve all AI-generated changes before they are merged.

Failure to follow these rules does not block the PR from being submitted, but it will be closed without review if the label and notice are missing.
