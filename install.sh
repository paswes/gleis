#!/usr/bin/env bash
#
# install.sh — symlink bin/gleis into PATH and check dependencies.
# Re-run safely; if gleis is already installed, the symlink is replaced.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$REPO_DIR/bin/gleis"

# Pick the install target based on what's on PATH.
if [[ -d /opt/homebrew/bin ]]; then
  TARGET="/opt/homebrew/bin/gleis"
elif [[ -d /usr/local/bin ]]; then
  TARGET="/usr/local/bin/gleis"
else
  echo "error: neither /opt/homebrew/bin nor /usr/local/bin exists." >&2
  exit 1
fi

c_green=$'\033[1;32m'; c_yellow=$'\033[1;33m'; c_reset=$'\033[0m'
ok()   { printf "%s✓%s %s\n" "$c_green"  "$c_reset" "$*"; }
warn() { printf "%s!%s %s\n" "$c_yellow" "$c_reset" "$*"; }

[[ -f "$SCRIPT" ]] || { echo "error: missing $SCRIPT" >&2; exit 1; }
chmod +x "$SCRIPT"

# Remove existing file or symlink at the target without warning.
if [[ -L "$TARGET" || -e "$TARGET" ]]; then
  rm -f "$TARGET"
fi

ln -s "$SCRIPT" "$TARGET"
ok "linked $TARGET → $SCRIPT"

# Ensure config dir exists. We do NOT seed a default config — having one would
# silently fall through as the config for any repo without its own .gleis.conf,
# which is more confusing than helpful. See $REPO_DIR/config/example.conf for
# the template to copy into projects.
mkdir -p "$HOME/.config/gleis"

# Dependency check (warn only — install.sh doesn't refuse to finish).
missing=()
for cmd in fzf jq xcodebuild xcrun; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
  warn "missing dependencies: ${missing[*]}"
  warn "install with: brew install ${missing[*]}"
fi
command -v xcbeautify     >/dev/null 2>&1 || warn "optional: brew install xcbeautify (prettier build output)"
command -v idevicesyslog  >/dev/null 2>&1 || warn "recommended: brew install libimobiledevice (Xcode-style device logs)"
command -v vercel         >/dev/null 2>&1 || warn "abfahrt only: npm install -g vercel (deploy OTA install page)"

echo
ok "gleis $($SCRIPT --version | awk '{print $2}') installed."
echo
echo "Next step — tell gleis about an iOS project (once per project):"
echo "  cd ~/Code/YourApp     # the main worktree of your iOS project"
echo "  gleis init            # interactive setup; auto-detects most values"
echo
echo "Then 'gleis wartung' to verify, and 'gleis' to build + launch."
echo "For OTA installs, run 'gleis abfahrt init' in the project, then 'gleis abfahrt'."
echo "Detailed setup notes: $REPO_DIR/README.md"
