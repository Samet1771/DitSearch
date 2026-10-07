#!/bin/sh
# RedSearch installer for macOS and Linux:
#   curl -fsSL https://raw.githubusercontent.com/Samet1771/RedSearch/main/install.sh | sh
# Puts rr.py in ~/.RedSearch, the skill in ~/.claude/skills/reddit-research, and fetches
# the Clef-Flash model (9.7 GB; REDSEARCH_QUANT=Q4_K_M for the 6.5 GB one,
# REDSEARCH_NO_MODEL=1 to skip it).
set -e
raw=https://raw.githubusercontent.com/Samet1771/RedSearch/main/reddit-research
home_dir=${REDSEARCH_HOME:-$HOME/.RedSearch}
skill=$HOME/.claude/skills/reddit-research

python=
for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info < (3, 9))' 2>/dev/null; then
        python=$c
        break
    fi
done
[ -n "$python" ] || { echo "Python 3.9+ not found. Install it and run this again." >&2; exit 1; }

mkdir -p "$home_dir" "$skill"
echo "Installing RedSearch into $home_dir"
curl -fsSL "$raw/rr.py" -o "$home_dir/rr.py"
curl -fsSL "$raw/SKILL.md" -o "$skill/SKILL.md"
rm -f "$skill/rr.py"  # older versions kept it there

if [ -z "$REDSEARCH_NO_MODEL" ]; then
    "$python" "$home_dir/rr.py" setup --download --quant "${REDSEARCH_QUANT:-Q8_0}"
else
    "$python" "$home_dir/rr.py" setup
fi
echo
echo "Done. Ask Claude Code e.g. 'What does Reddit say about <topic>?'"
