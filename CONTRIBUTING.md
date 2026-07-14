# Contributing to solidifier

## Reporting issues
Open a GitHub issue describing the problem, the agent you're using, and the rigor level that triggered it.

## Suggesting changes
Fork the repo, make your changes on a branch, and open a PR. If you're editing skill content, run `sync.sh` from your agent of choice to propagate the change to all four copies before submitting.

## Editing skill content
All four agent copies (`claude-code/`, `opencode/`, `copilot/`, `codex/`) should stay in sync on shared SOLID/pattern content. Use `sync.sh` to align them. Agent-specific extras (e.g. `agents/openai.yaml` for Codex) are intentionally separate and should not be synced.

## Adding a new agent
1. Create a new folder `<agent>/solidifier/` with `SKILL.md` and `references/`.
2. Add an entry to the install table in `README.md`.
3. Update `install.sh` to handle the new agent target.
4. Update `sync.sh` to include the new folder.

## License
By contributing you agree your changes are licensed under MIT.
