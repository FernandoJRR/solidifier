#!/usr/bin/env bash
#
# install.sh — install the solidifier skill for a specific agent.
# Each agent has its own self-contained copy under this repo; this copies
# the right one into the directory that agent scans.
#
# Usage:
#   ./install.sh <agent> [--global]
#     <agent>   claude | opencode | copilot | codex
#     --global  install into your home/user config instead of the current project
#
# Run it from the project you want the skill active in (omit --global), e.g.:
#   /path/to/solidifier/install.sh opencode

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT="${1:-}"
SCOPE="${2:-}"
global=false
[[ "$SCOPE" == "--global" ]] && global=true

if [[ -z "$AGENT" ]]; then
  echo "Usage: ./install.sh <claude|opencode|copilot|codex> [--global]" >&2
  exit 1
fi

# Source skill folder (per-agent copy) and destination directory the agent scans.
case "$AGENT" in
  claude)
    src="$REPO/claude-code/plugins/solidifier/skills/solidifier"
    $global && base="$HOME/.claude/skills" || base=".claude/skills" ;;
  opencode)
    src="$REPO/opencode/solidifier"
    $global && base="$HOME/.config/opencode/skills" || base=".opencode/skills" ;;
  copilot)
    src="$REPO/copilot/solidifier"
    $global && base="$HOME/.config/github-copilot/skills" || base=".github/skills" ;;
  codex)
    src="$REPO/codex/solidifier"
    $global && base="$HOME/.agents/skills" || base=".agents/skills" ;;  # consensus dir; or register in ~/.codex/config.toml
  *) echo "Unknown agent: $AGENT (use claude|opencode|copilot|codex)" >&2; exit 1 ;;
esac

[[ -d "$src" ]] || { echo "Error: source skill not found at $src" >&2; exit 1; }

dest="$base/solidifier"
mkdir -p "$base"
rm -rf "$dest"
cp -R "$src" "$dest"

echo "Installed solidifier ($AGENT) -> $dest"
[[ "$AGENT" == "codex" ]] && echo "Note: if Codex doesn't auto-discover it, register the path in ~/.codex/config.toml under [[skills.config]]."
echo "Reload the agent if it was already running."
