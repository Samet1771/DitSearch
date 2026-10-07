# RedSearch

A [Claude Code](https://claude.com/claude-code) skill that researches what Reddit says
about a topic, product or question, and answers from the posts and comments it finds, with
links.

Reddit blocks AI requests, so RedSearch never touches reddit.com. It works like this:

1. Downloads whole subreddits from the [Arctic Shift](https://arctic-shift.photon-reddit.com)
   archive into a local cache.
2. Prunes them (bots, deleted and removed comments, reactions, NSFW posts) into a SQLite
   FTS5 index.
3. Searches the index with many queries.
4. Judges every hit with a local System 1 decision model:
   [Clef-Flash](https://huggingface.co/ggml-org/Clef-Flash-GGUF) on llama.cpp's
   `/v1/systemone`.
5. Writes one relevance-filtered markdown report for Claude to answer from.

Everything is one script: `rr.py`, standard library only, Python 3.9+.

## Install

One command. Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/Samet1771/RedSearch/main/install.ps1 | iex
```

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/Samet1771/RedSearch/main/install.sh | sh
```

The installer puts `rr.py` in `~/.RedSearch/`, the skill in
`~/.claude/skills/reddit-research/`, and downloads the Clef-Flash model (Q8_0: 9.7 GB,
needs ~11.5 GB VRAM). Set `REDSEARCH_QUANT=Q4_K_M` first for the 6.5 GB version (~8 GB
VRAM), or `REDSEARCH_NO_MODEL=1` to skip the model. Run it again to update; it keeps your
data and the model.

**Requirements:**
- **Python 3.9+**, with SQLite 3.27 or newer (most builds have it).
- **llama.cpp build 11371 or newer**, for `/v1/systemone`. Install it with
  `winget install llama.cpp` or `brew install llama.cpp`, or take a
  [release](https://github.com/ggml-org/llama.cpp/releases). The model runs on a CPU too,
  but slowly.

Run `python ~/.RedSearch/rr.py setup` to check what is missing.

## Use

Ask Claude Code something like *"What does Reddit say about breeding leopard geckos? Make
me a guide."* The skill ([SKILL.md](reddit-research/SKILL.md)) walks Claude through
these steps:
1. choosing subreddits and a date window
2. downloading
3. writing search queries and yes/no filter questions
4. testing the questions on a sample
5. filtering
6. answering from the report

The long steps (download, filter) run as background tasks with live progress.

To run the commands yourself, see `python ~/.RedSearch/rr.py --help`. The main ones are `subs`,
`download`, `flairs`, `search`, `judge`, `filter` and `show`.

## Where data goes

Everything is in `~/.RedSearch/` (or `$REDSEARCH_HOME`):
- `rr.py`: the script.
- `models/`: the model.
- `cache/archive/`: raw downloads, shared by all research topics. `rr.py cache` lists them.
- `research/<topic>/`: one folder per research topic, holding the index, search hits,
  decision cache and reports.

## Be kind to Arctic Shift

Arctic Shift is a free archive run by one person, with a load-dependent rate limit.
`rr.py` paces itself to the server's per-minute budget and allows only one download at a
time per machine. Don't work around either.
