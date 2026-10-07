# DitSearch installer for Windows:
#   irm https://raw.githubusercontent.com/Samet1771/DitSearch/main/install.ps1 | iex
# Puts ditsearch.py in ~/.DitSearch, the skill in ~/.claude/skills/ditsearch, and fetches
# the Clef-Flash model (9.7 GB; set $env:DITSEARCH_QUANT = 'Q4_K_M' for the 6.5 GB one,
# or $env:DITSEARCH_NO_MODEL = '1' to skip it).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$raw = 'https://raw.githubusercontent.com/Samet1771/DitSearch/main/ditsearch'
$home_ = if ($env:DITSEARCH_HOME) { $env:DITSEARCH_HOME } else { Join-Path $HOME '.DitSearch' }
$skill = Join-Path $HOME '.claude\skills\ditsearch'

$python = $null
foreach ($c in @(@('py', '-3'), @('python'), @('python3'))) {
    if (Get-Command $c[0] -ErrorAction SilentlyContinue) {
        $v = & $c[0] @($c[1..9] | Where-Object { $_ }) -c 'import sys; print(sys.version_info >= (3, 9))' 2>$null
        if ($v -eq 'True') { $python = $c; break }
    }
}
if (-not $python) { throw 'Python 3.9+ not found. Install it (winget install Python.Python.3.12) and run this again.' }

New-Item -ItemType Directory -Force $home_, $skill | Out-Null
Write-Host "Installing DitSearch into $home_"
Invoke-WebRequest "$raw/ditsearch.py" -OutFile (Join-Path $home_ 'ditsearch.py') -UseBasicParsing
Invoke-WebRequest "$raw/SKILL.md" -OutFile (Join-Path $skill 'SKILL.md') -UseBasicParsing

# older versions: the skill was called reddit-research and kept the script (and model) in its folder
$old = Join-Path $HOME '.claude\skills\reddit-research'
if (Test-Path $old) {
    $models = Join-Path $home_ 'models'
    New-Item -ItemType Directory -Force $models | Out-Null
    Get-ChildItem $old -Recurse -Filter '*.gguf' | ForEach-Object {
        if (-not (Test-Path (Join-Path $models $_.Name))) { Move-Item $_.FullName $models }
    }
    Remove-Item $old -Recurse -Force
}
Remove-Item (Join-Path $home_ 'rr.py') -ErrorAction SilentlyContinue

$cmd = @($python[1..9] | Where-Object { $_ }) + @((Join-Path $home_ 'ditsearch.py'))
if (-not $env:DITSEARCH_NO_MODEL) {
    $quant = if ($env:DITSEARCH_QUANT) { $env:DITSEARCH_QUANT } else { 'Q8_0' }
    & $python[0] @cmd setup --download --quant $quant
} else {
    & $python[0] @cmd setup
}
Write-Host "`nDone. Ask Claude Code e.g. 'What does Reddit say about <topic>?'"
