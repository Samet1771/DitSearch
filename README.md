# DitSearch

A [Claude Code](https://claude.com/claude-code) skill that researches what Reddit says
about a topic, product or question, and answers from the posts and comments it finds, with
links.

Reddit blocks AI requests, so DitSearch never touches reddit.com. It works like this:

1. Downloads whole subreddits from the [Arctic Shift](https://arctic-shift.photon-reddit.com)
   archive into a local cache.
2. Prunes them (bots, deleted and removed comments, reactions, NSFW posts) into a SQLite
   FTS5 index.
3. Searches the index with many queries.
4. Judges every hit with a local System 1 decision model:
   [Clef-Flash](https://huggingface.co/ggml-org/Clef-Flash-GGUF) on llama.cpp's
   `/v1/systemone`.
5. Writes one relevance-filtered markdown report for Claude to answer from.

Everything is one script: `ditsearch.py`, standard library only, Python 3.9+.

## Install

One command. Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/Samet1771/DitSearch/main/install.ps1 | iex
```

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/Samet1771/DitSearch/main/install.sh | sh
```

The installer puts `ditsearch.py` in `~/.DitSearch/` and the skill in
`~/.claude/skills/ditsearch/`, then downloads the Clef-Flash model (Q8_0: 9.7 GB, needs
~11.5 GB VRAM). A model already in place is not downloaded again.

Options, set before the command:
- `DITSEARCH_QUANT=Q4_K_M`: the 6.5 GB model instead (~8 GB VRAM).
- `DITSEARCH_NO_MODEL=1`: skip the model.
- `DITSEARCH_HOME=<path>`: install somewhere other than `~/.DitSearch`. `ditsearch.py`
  reads it too, so set it permanently (user environment variable, shell profile).

```powershell
$env:DITSEARCH_QUANT = 'Q4_K_M'; irm https://raw.githubusercontent.com/Samet1771/DitSearch/main/install.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/Samet1771/DitSearch/main/install.sh | DITSEARCH_QUANT=Q4_K_M sh
```

**Update:** run the install command again. It replaces the script and the skill, and keeps
your data and the model.

**Uninstall:** delete `~/.DitSearch/` and `~/.claude/skills/ditsearch/`.

**Requirements:**
- **Python 3.9+**, with SQLite 3.27 or newer (most builds have it).
- **llama.cpp build 11371 or newer**, for `/v1/systemone`. Install it with
  `winget install llama.cpp` or `brew install llama.cpp`, or take a
  [release](https://github.com/ggml-org/llama.cpp/releases).
- **A GPU** with ~11.5 GB VRAM (Q8_0) or ~8 GB (Q4_K_M). The model runs on a CPU too, but
  slowly.

Run `python ~/.DitSearch/ditsearch.py setup` to check what is missing.

## Use

Ask Claude Code something like *"What does Reddit say about breeding leopard geckos? Make
me a guide."* The skill ([SKILL.md](ditsearch/SKILL.md)) walks Claude through
these steps:
1. choosing subreddits and a date window
2. downloading
3. writing search queries and yes/no filter questions
4. testing the questions on a sample
5. filtering
6. answering from the report

The long steps (download, filter) run as background tasks with live progress. On an RTX
5070 Ti the filter takes ~0.5 s per post, comment threads included: about 4 min for 500
posts. Downloads depend on Arctic Shift's load: ~15-80 items/s when it is busy, several
hundred when it is quiet.

To run the commands yourself, see `python ~/.DitSearch/ditsearch.py --help`. The main
ones are `subs`, `download`, `flairs`, `search`, `judge`, `filter` and `show`. A bare
`--dir` name is a topic folder: `--dir gecko-breeding` means
`~/.DitSearch/research/gecko-breeding/`.

## Settings

| Variable | Use |
|---|---|
| `DITSEARCH_HOME` | data folder (default `~/.DitSearch`) |
| `DITSEARCH_LLAMA_SERVER` | path to llama-server (default: PATH, then a LlamaGUI install) |
| `DITSEARCH_MODEL` | path to the Clef-Flash gguf (default: `~/.DitSearch/models/`) |
| `DITSEARCH_PORT` | port for the local llama-server (default 8091; a busy port is skipped) |
| `DITSEARCH_SERVER_ARGS` | replaces the llama-server tuning flags (default `-ngl 99 -fa on -c 32768 -np 4 -b 8192 -ub 8192`) |

## Where data goes

Everything is in `~/.DitSearch/` (or `$DITSEARCH_HOME`):
- `ditsearch.py`: the script.
- `models/`: the model.
- `cache/archive/`: raw downloads, shared by all research topics. `ditsearch.py cache`
  lists them; delete a subreddit's folder there to free space.
- `research/<topic>/`: one folder per research topic, holding the index, search hits,
  decision cache and reports.

## Be kind to Arctic Shift

Arctic Shift is a free archive run by one person, with a load-dependent rate limit.
`ditsearch.py` paces itself to the server's per-minute budget and allows only one download
at a time per machine. Don't work around either.
