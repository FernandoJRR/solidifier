#!/usr/bin/env bash
#
# sync.sh — mirror one agent's skill copy into the others.
#
# The per-agent folders are independent by design, so you CAN let them diverge
# (e.g. add Codex's openai.yaml or Copilot-specific frontmatter). But when you
# edit the shared SOLID/pattern content and want every copy identical again,
# run this to push one folder's content to the rest.
#
# Usage:
#   ./sync.sh <source-agent>
#     <source-agent>  claude | opencode | copilot | codex   (default: claude)

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${1:-claude}"

skilldir() {
  case "$1" in
    claude)   echo "$REPO/claude-code/plugins/solidifier/skills/solidifier" ;;
    opencode) echo "$REPO/opencode/solidifier" ;;
    copilot)  echo "$REPO/copilot/solidifier" ;;
    codex)    echo "$REPO/codex/solidifier" ;;
    *) echo ""; ;;
  esac
}

SRC="$(skilldir "$SOURCE")"
[[ -n "$SRC" && -d "$SRC" ]] || { echo "Unknown or missing source agent: $SOURCE" >&2; exit 1; }

echo "Source of truth: $SOURCE ($SRC)"
for a in claude opencode copilot codex; do
  [[ "$a" == "$SOURCE" ]] && continue
  dst="$(skilldir "$a")"
  mkdir -p "$dst"
  # Sync only the portable skill content; leave any agent-specific extras in place.
  cp -f "$SRC/SKILL.md" "$dst/SKILL.md"
  rm -rf "$dst/references"
  cp -R "$SRC/references" "$dst/references"
  echo "  synced -> $a"
done
echo "Done. Per-agent skill content is now aligned with '$SOURCE'."
