# Changelog

This project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-06-02
### Added
- Portable SOLID + design-patterns skill for backend code, applied with restraint.
- Separate, self-contained skill copy per agent: Claude Code, OpenCode, GitHub Copilot, OpenAI Codex.
- `SKILL.md` (Agent Skills open-standard format) + `references/{solid,patterns,configuration}.md`.
- Claude Code plugin + marketplace packaging.
- `install.sh` (per-agent installer) and `sync.sh` (align copies from one source).

### Notes
- Per-agent copies are independent by design; run sync.sh to keep them identical.
- Not yet exercised against real codebases at multiple rigor levels.
