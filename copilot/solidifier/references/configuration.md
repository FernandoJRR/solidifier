# Configuration — `.solidifier.json`

The skill is tuned by a project config file. This lets a team or user fix the rigor, scope, and emphasis once, so behavior is predictable across sessions. Read this file when applying the skill; honor it for the whole task.

## Where it lives

Look, in order, for:
1. A path the user named explicitly in the request.
2. `.solidifier.json` in the target directory.
3. `.solidifier.json` in the project root.
4. A `"solidifier"` key inside an existing project config (e.g. `package.json`, `pyproject.toml [tool.solidifier]`).

If none exists, use the defaults below and tell the user once that they can create a `.solidifier.json` to tune behavior — optionally offer to scaffold one. Never create or modify this file without the user's go-ahead (it's persistent project configuration).

## Schema

```jsonc
{
  // How invasive the work is + how high the justification bar sits.
  // "advisory" | "conservative" | "standard" | "thorough"
  // Default: "conservative". See SKILL.md "Rigor levels".
  "rigor": "conservative",

  // Glob(s) the skill MAY touch. Nothing outside this is modified.
  // If omitted, scope = exactly what the user named in the request.
  "scope": ["src/services/**", "src/domain/**"],

  // Globs to never touch even if inside scope (generated code, vendored, migrations).
  "exclude": ["**/*.generated.*", "**/migrations/**", "**/node_modules/**"],

  // Per-principle controls. "on" = apply normally, "advisory" = only flag,
  // never auto-change for this principle, "off" = ignore entirely.
  // Omitted principles inherit from rigor.
  "principles": {
    "srp": "on",
    "ocp": "on",
    "lsp": "on",
    "isp": "advisory",
    "dip": "on"
  },

  // Pattern policy. Patterns are opt-in by need at every rigor level;
  // these lists further constrain what may be introduced.
  "patterns": {
    // If non-empty, ONLY these patterns may be introduced. Empty/omitted = any
    // pattern that meets the justification bar is allowed.
    "allow": [],
    // Patterns that must never be introduced (team has decided against them).
    "deny": ["singleton", "abstract_factory"],
    // Hard ceiling on abstraction the skill may add without explicit user OK.
    // "maxNewAbstractionLayers": cap on layers of indirection introduced per unit.
    "maxNewAbstractionLayers": 1
  },

  // Whether refactors may change public/exported signatures.
  // false = keep contracts stable (default); true = allowed within scope.
  "allowContractChanges": false,

  // Language/framework hints so idioms match (optional; usually inferable).
  // e.g. "python/fastapi", "typescript/nestjs", "java/spring", "go".
  "stack": null,

  // If true, every change must be accompanied by its one-line justification
  // in the summary (recommended; default true).
  "requireJustification": true
}
```

All fields are optional. An empty `{}` is valid and means "all defaults."

## How each field changes behavior

- **`rigor`** — The primary dial. Governs how aggressively to refactor and how high the bar for change sits. See SKILL.md. When in doubt between two readings, the lower-rigor (more restrained) interpretation wins.
- **`scope`** — A hard boundary. Files outside `scope` are read-only context at most; never refactor or rename them. If the user's request points outside `scope`, ask before proceeding.
- **`exclude`** — Wins over `scope`. Generated, vendored, and migration code is off-limits by default; respect these even at `thorough`.
- **`principles`** — Lets a team dial individual principles. `"advisory"` is useful for principles a team wants surfaced but not auto-applied (common for ISP/LSP, which are easy to misjudge). `"off"` silences a principle entirely.
- **`patterns.allow`** — A whitelist. Non-empty means *only* these patterns may be introduced; everything else is flagged-but-not-applied. Use to keep a codebase to a known vocabulary.
- **`patterns.deny`** — A blacklist of patterns the team has ruled out (e.g. `singleton`). Never introduce a denied pattern; if one seems warranted, note it as a suggestion only.
- **`patterns.maxNewAbstractionLayers`** — A guard against over-engineering. If a refactor would stack more than this many new layers of indirection over a unit, stop and surface it for explicit approval rather than applying it. Default 1.
- **`allowContractChanges`** — When `false`, preserve public/exported signatures; refactor internals only. When `true`, the skill may change signatures within scope (still summarizing the breakage).
- **`stack`** — Steers idioms (dataclasses vs. Pydantic, NestJS providers vs. plain classes, Go interfaces-at-consumer, etc.) so output matches the ecosystem. Usually inferable from the code; this just makes it explicit.
- **`requireJustification`** — When `true`, the per-change justification (principle/pattern, problem fixed, cost) is mandatory in the summary.

## Precedence

When signals conflict, resolve in this order (highest wins):
1. Explicit instruction in the **user's current message**.
2. **`exclude`** globs (always respected).
3. **`patterns.deny`** (never introduce a denied pattern).
4. **`.solidifier.json`** values.
5. Skill defaults.

A user's in-message instruction can raise or lower rigor for one task without editing the file — honor it for that task only, and don't persist it unless asked.

## Example configs

**Audit an existing service without touching it:**
```json
{ "rigor": "advisory", "scope": ["src/billing/**"] }
```

**Conservative cleanup of one module, no contract changes, no Singletons:**
```json
{
  "rigor": "conservative",
  "scope": ["src/orders/**"],
  "patterns": { "deny": ["singleton"], "maxNewAbstractionLayers": 1 },
  "allowContractChanges": false
}
```

**Thorough refactor of the domain layer in a NestJS app, contracts may change:**
```json
{
  "rigor": "thorough",
  "scope": ["src/domain/**", "src/application/**"],
  "stack": "typescript/nestjs",
  "allowContractChanges": true,
  "patterns": { "maxNewAbstractionLayers": 2 }
}
```

Even at `thorough` with a higher abstraction ceiling, the prime directive holds: every abstraction needs a concrete justification, and "no change needed" remains a valid outcome for code that's already sound.
