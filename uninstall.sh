#!/usr/bin/env bash
#
# uninstall.sh — remove the gleis symlink from PATH.
# Leaves the repo, configs (~/.config/gleis/), and cache (~/Library/Caches/gleis/) intact.

set -euo pipefail

for target in /opt/homebrew/bin/gleis /usr/local/bin/gleis; do
  if [[ -L "$target" ]]; then
    rm -f "$target"
    echo "✓ removed symlink $target"
  elif [[ -e "$target" ]]; then
    echo "! $target exists but is not a symlink — leaving it alone"
  fi
done

echo
echo "Note: configs in ~/.config/gleis/ and cache in ~/Library/Caches/gleis/ were not touched."
echo "To remove them: rm -rf ~/.config/gleis ~/Library/Caches/gleis"
