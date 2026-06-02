# solidifier

A coding-agent **skill** that applies **SOLID principles and design patterns to backend code — with judgment and restraint.**

The goal is not to maximize the number of principles or patterns in the code. It is to make code **easier to understand and cheaper to change**, using SOLID and patterns *only where they pay for themselves*. The most common backend-design failure is over-engineering — interfaces with one implementation, factories wrapping a single constructor, indirection that hides logic. solidifier treats that as a defect, not a goal, and bakes restraint in at every level.

Built on the **[Agent Skills open standard](https://agentskills.io)** (`SKILL.md`). This repo ships a **separate, self-contained copy of the skill per agent** so each one drops straight into the directory that agent scans — no symlinks, no shared-directory assumptions.

## Layout — one folder per agent

```
.
├── claude-code/                     # Claude Code: plugin + marketplace
│   ├── .claude-plugin/marketplace.json
│   └── plugins/solidifier/
│       ├── .claude-plugin/plugin.json
│       └── skills/solidifier/{SKILL.md, references/}
├── opencode/solidifier/{SKILL.md, references/}    # → copy into .opencode/skills/
├── copilot/solidifier/{SKILL.md, references/}     # → copy into .github/skills/
├── codex/solidifier/{SKILL.md, references/}       # → copy into .agents/skills/
├── install.sh                       # install the right copy for an agent
├── sync.sh                          # align the copies from one source (optional)
├── README.md  CHANGELOG.md  LICENSE  .gitignore
```

Each agent folder is independent. That means you can tailor a copy to its agent later (e.g. add Codex's `agents/openai.yaml`, or Copilot-recognized frontmatter) without affecting the others. The tradeoff is duplication — see [Keeping copies in sync](#keeping-copies-in-sync).

## Install per agent

Run from the project you want the skill active in (add `--global` for your user config):

```bash
/path/to/solidifier/install.sh claude      # → .claude/skills/solidifier
/path/to/solidifier/install.sh opencode    # → .opencode/skills/solidifier
/path/to/solidifier/install.sh copilot     # → .github/skills/solidifier
/path/to/solidifier/install.sh codex       # → .agents/skills/solidifier
```

Or copy the folder by hand into the location each agent scans:

| Agent | Source in this repo | Project location | Docs |
|---|---|---|---|
| **Claude Code** | `claude-code/plugins/solidifier/skills/solidifier` | `.claude/skills/` (or marketplace, below) | — |
| **OpenCode** | `opencode/solidifier` | `.opencode/skills/`, `.claude/skills/`, or `.agents/skills/` | [docs](https://opencode.ai/docs/skills/) |
| **GitHub Copilot** | `copilot/solidifier` | `.github/skills/` (recommended) or `.claude/skills/` | [docs](https://code.visualstudio.com/docs/copilot/customization/agent-skills) |
| **OpenAI Codex** | `codex/solidifier` | `.agents/skills/` or register in `~/.codex/config.toml` | [docs](https://developers.openai.com/codex/skills) |

### Claude Code via marketplace (optional, one command)

```shell
/plugin marketplace add <your-github-username>/solidifier
/plugin install solidifier@solidifier-marketplace
```

Note: the marketplace `source` points at `./claude-code/plugins/solidifier`, so adding the repo as a marketplace works directly.

## Usage

You don't invoke it by name — each agent consults it when your request matches refactoring, design review, or testability concerns (by matching the skill's description). Give it a **target** and a **pain**:

- "Review `src/orders/order_service.ts` for SOLID violations."
- "This payment handler has a giant switch that grows every time we add a provider — clean it up."
- "Refactor billing so I can unit-test pricing without a database."
- "Audit `src/domain/`, but don't change anything yet."

Expect "leave it alone" on already-sound code — that's the skill working, not failing.

## Configuration

Drop a `.solidifier.json` at your project root (or target directory). Everything optional; `{}` means defaults. Main dial is `rigor`: `advisory` (review only) · `conservative` (default) · `standard` · `thorough`. There is no "maximize patterns" level — that's deliberately an anti-goal. Full schema lives in each copy's `references/configuration.md`.

## Keeping copies in sync

Because each agent has its own copy, editing the shared SOLID/pattern content means updating all of them. When you want them identical again, run:

```bash
./sync.sh claude        # use the Claude Code copy as the source of truth
./sync.sh opencode      # or any other agent
```

`sync.sh` mirrors `SKILL.md` and `references/` from the chosen source into the other folders, leaving any agent-specific extras alone. If you intend the copies to diverge, just don't run it.

## License

MIT — see [LICENSE](LICENSE).

---

> Status: **0.1.0 — initial draft.** Validated structurally, not yet exercised against real codebases at multiple rigor levels.

