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

solidifier is tuned by an optional project file, **`.solidifier.json`**. It lets you fix *how invasive* the skill is, *which files* it may touch, and *which principles and patterns* it may apply — once, so behavior is predictable across sessions and across your team. Without it, the skill uses sensible defaults (and tells you the file is available).

> The full schema reference also ships inside the skill itself at `*/solidifier/references/configuration.md`. This section is the practical summary.

### Where it goes and how it's found

The skill looks for configuration in this order and uses the first it finds:

1. A path you name explicitly in your request.
2. `.solidifier.json` in the **target directory** you're working on.
3. `.solidifier.json` in the **project root**.
4. A `"solidifier"` key inside an existing project config (e.g. `package.json`, or `[tool.solidifier]` in `pyproject.toml`).

Put it at the **project root** for repo-wide defaults, or in a **subdirectory** to override behavior for just that module. The skill won't create or modify this file without your go-ahead, since it's persistent project config.

### The schema

Every field is optional. An empty `{}` is valid and means "all defaults."

```jsonc
{
  // How invasive the work is + how high the justification bar sits.
  // "advisory" | "conservative" | "standard" | "thorough"   (default: "conservative")
  "rigor": "conservative",

  // Glob(s) the skill MAY modify. Nothing outside this is touched.
  // If omitted, scope = exactly what you named in your request.
  "scope": ["src/services/**", "src/domain/**"],

  // Globs never touched, even if inside scope (generated code, vendored, migrations).
  "exclude": ["**/*.generated.*", "**/migrations/**", "**/node_modules/**"],

  // Per-principle control. "on" = apply normally, "advisory" = only flag (never auto-change),
  // "off" = ignore. Omitted principles inherit from rigor.
  "principles": {
    "srp": "on", "ocp": "on", "lsp": "on", "isp": "advisory", "dip": "on"
  },

  // Pattern policy. Patterns are opt-in by need at every rigor level; these further constrain.
  "patterns": {
    "allow": [],                       // if non-empty, ONLY these patterns may be introduced
    "deny": ["singleton"],             // patterns that must never be introduced
    "maxNewAbstractionLayers": 1       // ceiling on layers of indirection added without asking
  },

  // May refactors change public/exported signatures? false = keep contracts stable (default).
  "allowContractChanges": false,

  // Idiom hint so output matches your ecosystem (optional; usually inferred from the code).
  // e.g. "python/fastapi", "typescript/nestjs", "java/spring", "go"
  "stack": null,

  // Require a one-line justification (principle/pattern, problem fixed, cost) per change. Default true.
  "requireJustification": true
}
```

### What each field does

- **`rigor`** — the primary dial. It controls *how aggressively the skill refactors and how high the bar for change sits* — **not** how many patterns to add. The four levels:

  | `rigor` | Behavior |
  |---|---|
  | `advisory` | Reviews only — a ranked list of findings with tradeoffs. **Never edits code.** Best for audits and learning. |
  | `conservative` *(default)* | Fixes only unambiguous violations where the change clearly reduces complexity. Biases strongly toward leaving working code alone. |
  | `standard` | Applies SOLID where it causes real friction, and introduces a pattern when a clear, named present need exists (e.g. three providers behind a growing `switch` → Strategy). |
  | `thorough` | Comprehensive refactor of the target — but every abstraction still needs a concrete justification. "Thorough" means careful and complete, not maximalist. |

  There is intentionally **no "maximize patterns" level**. Maximizing pattern usage is an anti-goal; when two readings are possible, the more restrained one wins.

- **`scope`** — a hard boundary. Files outside these globs are read-only context at most; the skill won't refactor or rename them. If your request points outside `scope`, the skill asks first. Omit it and the scope is exactly what you named in the request.

- **`exclude`** — wins over `scope`. Generated, vendored, and migration code stays off-limits even at `thorough`.

- **`principles`** — dial individual SOLID principles. `"advisory"` surfaces a principle's violations without auto-applying them (handy for ISP/LSP, which are easy to misjudge); `"off"` silences it entirely. Anything omitted follows `rigor`.

- **`patterns.allow`** — a whitelist. If non-empty, only the listed patterns may be introduced; anything else is flagged but not applied. Use it to hold a codebase to a known vocabulary.

- **`patterns.deny`** — a blacklist of patterns ruled out (e.g. `singleton`). The skill never introduces a denied pattern; if one seems warranted it's noted as a suggestion only.

- **`patterns.maxNewAbstractionLayers`** — the over-engineering guard. If a refactor would stack more than this many new layers of indirection over a unit, the skill stops and asks rather than applying it. Default `1`.

- **`allowContractChanges`** — `false` (default) keeps public/exported signatures stable and refactors internals only; `true` lets the skill change signatures within scope (still reporting the breakage).

- **`stack`** — steers idioms so output matches your ecosystem (dataclasses vs. Pydantic, NestJS providers vs. plain classes, Go interfaces-at-consumer). Usually inferable from the code; this just makes it explicit.

- **`requireJustification`** — when `true`, every change comes with its one-line rationale (which principle/pattern, what it fixed, what it cost). Recommended — it's how you sanity-check that an abstraction earned its place.

### Precedence when signals conflict

Highest wins:

1. An explicit instruction in your **current message** (e.g. "be thorough on this one" overrides the file for that task only — it isn't persisted unless you ask).
2. **`exclude`** globs — always respected.
3. **`patterns.deny`** — a denied pattern is never introduced.
4. **`.solidifier.json`** values.
5. Skill defaults.

### Worked examples

**Audit one service without touching it:**
```json
{ "rigor": "advisory", "scope": ["src/billing/**"] }
```

**Careful cleanup of one module — contracts frozen, no Singletons, at most one new layer of indirection:**
```json
{
  "rigor": "conservative",
  "scope": ["src/orders/**"],
  "exclude": ["**/*.generated.*", "**/migrations/**"],
  "allowContractChanges": false,
  "patterns": { "deny": ["singleton"], "maxNewAbstractionLayers": 1 }
}
```

**Thorough refactor of a NestJS domain layer where signatures may change:**
```json
{
  "rigor": "thorough",
  "scope": ["src/domain/**", "src/application/**"],
  "stack": "typescript/nestjs",
  "allowContractChanges": true,
  "patterns": { "maxNewAbstractionLayers": 2 }
}
```

Even at `thorough` with a higher ceiling, the prime directive holds: every abstraction needs a concrete justification, and "no change needed" stays a valid outcome for code that's already sound.

### A note on per-agent copies

`.solidifier.json` lives in **your project** being worked on, not in this repo — so it's read identically no matter which agent's copy of the skill is installed. The config behavior above is part of the skill content, so it's the same across all four agent copies (and `sync.sh` keeps it that way).

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
