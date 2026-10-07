#!/bin/sh
# DitSearch installer for macOS and Linux:
#   curl -fsSL https://raw.githubusercontent.com/Samet1771/DitSearch/main/install.sh | sh
# Puts ditsearch.py in ~/.DitSearch, the skill in ~/.claude/skills/ditsearch, and fetches
# the Clef-Flash model (9.7 GB; DITSEARCH_QUANT=Q4_K_M for the 6.5 GB one,
# DITSEARCH_NO_MODEL=1 to skip it).
set -e
raw=https://raw.githubusercontent.com/Samet1771/DitSearch/main/ditsearch
home_dir=${DITSEARCH_HOME:-$HOME/.DitSearch}
skill=$HOME/.claude/skills/ditsearch

python=
for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info < (3, 9))' 2>/dev/null; then
        python=$c
        break
    fi
done
[ -n "$python" ] || { echo "Python 3.9+ not found. Install it and run this again." >&2; exit 1; }

mkdir -p "$home_dir" "$skill"
echo "Installing DitSearch into $home_dir"
curl -fsSL "$raw/ditsearch.py" -o "$home_dir/ditsearch.py"
curl -fsSL "$raw/SKILL.md" -o "$skill/SKILL.md"

# older versions: the skill was called reddit-research and kept the script (and model) in its folder
old=$HOME/.claude/skills/reddit-research
if [ -d "$old" ]; then
    mkdir -p "$home_dir/models"
    find "$old" -name '*.gguf' | while read -r f; do
        [ -e "$home_dir/models/$(basename "$f")" ] || mv "$f" "$home_dir/models/"
    done
    rm -rf "$old"
fi
rm -f "$home_dir/rr.py"

if [ -z "$DITSEARCH_NO_MODEL" ]; then
    "$python" "$home_dir/ditsearch.py" setup --download --quant "${DITSEARCH_QUANT:-Q8_0}"
else
    "$python" "$home_dir/ditsearch.py" setup
fi
echo
echo "Done. Ask Claude Code e.g. 'What does Reddit say about <topic>?'"
