#!/usr/bin/env bash
#
# uninstall.sh — remove the gleis symlink from PATH.
# By default, asks before removing configs/cache.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--all|--purge]

Removes the gleis symlink from PATH.

Options:
  --all, --purge   also remove ~/.config/gleis and ~/Library/Caches/gleis
  -h, --help       show this help
EOF
}

purge=0
for arg in "$@"; do
  case "$arg" in
    --all|--purge) purge=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option: $arg" >&2; usage >&2; exit 1 ;;
  esac
done

confirm_purge() {
  local reply
  printf "Remove gleis configs and cache too? [y/N]: "
  IFS= read -r reply </dev/tty 2>/dev/null || reply=""
  [[ "$reply" =~ ^[Yy] ]]
}

for target in /opt/homebrew/bin/gleis /usr/local/bin/gleis; do
  if [[ -L "$target" ]]; then
    rm -f "$target"
    echo "✓ removed symlink $target"
  elif [[ -e "$target" ]]; then
    echo "! $target exists but is not a symlink — leaving it alone"
  fi
done

echo
if (( purge )) || confirm_purge; then
  rm -rf "$HOME/.config/gleis" "$HOME/Library/Caches/gleis"
  echo "✓ removed ~/.config/gleis and ~/Library/Caches/gleis"
else
  echo "Note: configs in ~/.config/gleis/ and cache in ~/Library/Caches/gleis/ were not touched."
  echo "To remove them later: ./uninstall.sh --purge"
fi
