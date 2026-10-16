#!/usr/bin/env bash
set -euo pipefail

DEFAULT_SHARED_ITEMS="CLAUDE.md,skills,agents,commands"

usage() {
  cat <<EOF
Usage: $(basename "$0") <profile> [options]

Create an additional Claude Code profile in ~/.claude-<profile>, with a
'claude-<profile>' launcher, so you can log in with a second Claude account.

Options:
  --share <items>    Comma-separated items symlinked from ~/.claude
                     (default: $DEFAULT_SHARED_ITEMS)
  --no-share         Do not share anything with ~/.claude
  --label <text>     Status line label (default: <profile> in uppercase)
  --bin-dir <dir>    Where to install the launcher (default: ~/.local/bin)
  -h, --help         Show this help
EOF
}

info() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
fail() { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }

profile=""
shared_items="$DEFAULT_SHARED_ITEMS"
label=""
bin_dir="$HOME/.local/bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --share) shared_items="${2:?--share requires a value}"; shift 2 ;;
    --no-share) shared_items=""; shift ;;
    --label) label="${2:?--label requires a value}"; shift 2 ;;
    --bin-dir) bin_dir="${2:?--bin-dir requires a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) fail "unknown option: $1" ;;
    *) [[ -z "$profile" ]] || fail "only one profile name expected"; profile="$1"; shift ;;
  esac
done

[[ -n "$profile" ]] || { usage; exit 1; }
[[ "$profile" =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail "profile name must match [a-z0-9-]+"
label="${label:-$(tr '[:lower:]' '[:upper:]' <<<"$profile")}"

main_dir="$HOME/.claude"
profile_dir="$HOME/.claude-$profile"
launcher="$bin_dir/claude-$profile"

echo "Profile directory: $profile_dir"
mkdir -p "$profile_dir"
info "directory ready"

echo "Launcher: $launcher"
mkdir -p "$bin_dir"
cat >"$launcher" <<EOF
#!/usr/bin/env bash
export CLAUDE_CONFIG_DIR="\$HOME/.claude-$profile"
exec claude "\$@"
EOF
chmod +x "$launcher"
info "launcher written"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) warn "$bin_dir is not in your PATH — add it to your shell profile" ;;
esac

if [[ -n "$shared_items" ]]; then
  echo "Shared with $main_dir:"
  IFS=',' read -ra items <<<"$shared_items"
  for item in "${items[@]}"; do
    source_path="$main_dir/$item"
    target_path="$profile_dir/$item"

    if [[ -L "$target_path" ]]; then
      info "$item (already linked)"
      continue
    fi
    if [[ -e "$target_path" ]]; then
      warn "$item already exists in $profile_dir and is not a symlink — skipped"
      continue
    fi
    if [[ ! -e "$source_path" ]]; then
      if [[ "$item" == *.* ]]; then
        mkdir -p "$main_dir" && touch "$source_path"
      else
        mkdir -p "$source_path"
      fi
    fi
    ln -s "$source_path" "$target_path"
    info "$item"
  done
fi

echo "Status line:"
settings="$profile_dir/settings.json"
statusline_command="echo '$label'"
if [[ ! -e "$settings" ]]; then
  jq -n --arg cmd "$statusline_command" \
    '{statusLine: {type: "command", command: $cmd}}' >"$settings" 2>/dev/null \
    || printf '{\n  "statusLine": { "type": "command", "command": "%s" }\n}\n' "$statusline_command" >"$settings"
  info "settings.json created with a '$label' status line"
elif command -v jq >/dev/null && ! jq -e '.statusLine' "$settings" >/dev/null; then
  tmp="$(mktemp)"
  jq --arg cmd "$statusline_command" '. + {statusLine: {type: "command", command: $cmd}}' "$settings" >"$tmp"
  mv "$tmp" "$settings"
  info "'$label' status line added to settings.json"
else
  info "settings.json already has a status line (or jq is missing) — left untouched"
fi

cat <<EOF

Done. Next steps:
  1. Run 'claude-$profile' and '/login' with your other Claude account
  2. Install the plugins and MCP servers specific to this profile from there
EOF
