#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
failures=0

assert() {
  local description="$1"; shift
  if "$@"; then
    printf '  \033[32m✓\033[0m %s\n' "$description"
  else
    printf '  \033[31m✗\033[0m %s\n' "$description"
    failures=$((failures + 1))
  fi
}

run_install() {
  HOME="$fake_home" PATH="$fake_home/.local/bin:$PATH" "$script_dir/install.sh" "$@" >/dev/null
}

fake_homes=()
trap 'rm -rf "${fake_homes[@]}"' EXIT

new_fake_home() {
  fake_home="$(mktemp -d)"
  fake_homes+=("$fake_home")
}

echo "Default install"
new_fake_home
mkdir -p "$fake_home/.claude/skills"
echo "# shared" >"$fake_home/.claude/CLAUDE.md"
run_install work
assert "profile dir created" test -d "$fake_home/.claude-work"
assert "launcher is executable" test -x "$fake_home/.local/bin/claude-work"
assert "launcher sets CLAUDE_CONFIG_DIR" grep -q 'CLAUDE_CONFIG_DIR="$HOME/.claude-work"' "$fake_home/.local/bin/claude-work"
assert "CLAUDE.md is a symlink" test -L "$fake_home/.claude-work/CLAUDE.md"
assert "CLAUDE.md content is shared" grep -q "# shared" "$fake_home/.claude-work/CLAUDE.md"
assert "missing shared dir is created in ~/.claude" test -d "$fake_home/.claude/agents"
assert "status line label defaults to uppercase profile" grep -q "echo 'WORK'" "$fake_home/.claude-work/settings.json"

echo "Idempotency"
run_install work
assert "second run keeps the symlink" test -L "$fake_home/.claude-work/skills"

echo "Existing settings and files are preserved"
new_fake_home
mkdir -p "$fake_home/.claude-work/skills"
echo '{"model":"opus"}' >"$fake_home/.claude-work/settings.json"
run_install work --label "🏢 ACME"
assert "existing real dir is not replaced" test ! -L "$fake_home/.claude-work/skills"
assert "existing settings keys are kept" grep -q '"model"' "$fake_home/.claude-work/settings.json"
assert "custom label is added" grep -q "ACME" "$fake_home/.claude-work/settings.json"

echo "--no-share"
new_fake_home
run_install work --no-share
assert "nothing is linked" test ! -e "$fake_home/.claude-work/CLAUDE.md"

echo "Invalid profile name"
new_fake_home
assert "uppercase name is rejected" bash -c "! HOME='$fake_home' '$script_dir/install.sh' Work 2>/dev/null"

[[ $failures -eq 0 ]] || { echo "$failures failure(s)"; exit 1; }
echo "All tests passed"
