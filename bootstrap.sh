#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(pwd)"
shopt -s nullglob

# Find all n_scriptname.sh files, sorted by numeric prefix
FILES=($(find "$SCRIPT_DIR" -maxdepth 1 -type f -name '[0-9]*_*.sh' | sort))

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "❌ No numbered scripts (e.g. 1_setup.sh) found in $SCRIPT_DIR"
  exit 1
fi

echo "📦 Bootstrap Menu:"
for i in "${!FILES[@]}"; do
  FILENAME="$(basename "${FILES[$i]}")"
  NAME="${FILENAME#*_}"  # strip the prefix
  printf "  [%d] %s\n" "$((i+1))" "$NAME"
done

echo
read -rp "Select a script to run [1-${#FILES[@]}]: " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#FILES[@]} )); then
  echo "❌ Invalid selection"
  exit 1
fi

SCRIPT_TO_RUN="${FILES[$((CHOICE-1))]}"

echo
echo "🚀 Running: $(basename "$SCRIPT_TO_RUN")"
echo "────────────────────────────────────"
chmod +x "$SCRIPT_TO_RUN"
"$SCRIPT_TO_RUN"
