# RedSearch installer for Windows:
#   irm https://raw.githubusercontent.com/Samet1771/RedSearch/main/install.ps1 | iex
# Puts rr.py in ~/.RedSearch, the skill in ~/.claude/skills/reddit-research, and fetches
# the Clef-Flash model (9.7 GB; set $env:REDSEARCH_QUANT = 'Q4_K_M' for the 6.5 GB one,
# or $env:REDSEARCH_NO_MODEL = '1' to skip it).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$raw = 'https://raw.githubusercontent.com/Samet1771/RedSearch/main/reddit-research'
$home_ = if ($env:REDSEARCH_HOME) { $env:REDSEARCH_HOME } else { Join-Path $HOME '.RedSearch' }
$skill = Join-Path $HOME '.claude\skills\reddit-research'

$python = $null
foreach ($c in @(@('py', '-3'), @('python'), @('python3'))) {
    if (Get-Command $c[0] -ErrorAction SilentlyContinue) {
        $v = & $c[0] @($c[1..9] | Where-Object { $_ }) -c 'import sys; print(sys.version_info >= (3, 9))' 2>$null
        if ($v -eq 'True') { $python = $c; break }
    }
}
if (-not $python) { throw 'Python 3.9+ not found. Install it (winget install Python.Python.3.12) and run this again.' }

New-Item -ItemType Directory -Force $home_, $skill | Out-Null
Write-Host "Installing RedSearch into $home_"
Invoke-WebRequest "$raw/rr.py" -OutFile (Join-Path $home_ 'rr.py') -UseBasicParsing
Invoke-WebRequest "$raw/SKILL.md" -OutFile (Join-Path $skill 'SKILL.md') -UseBasicParsing
Remove-Item (Join-Path $skill 'rr.py') -ErrorAction SilentlyContinue  # older versions kept it there

$rr = @($python[1..9] | Where-Object { $_ }) + @((Join-Path $home_ 'rr.py'))
if (-not $env:REDSEARCH_NO_MODEL) {
    $quant = if ($env:REDSEARCH_QUANT) { $env:REDSEARCH_QUANT } else { 'Q8_0' }
    & $python[0] @rr setup --download --quant $quant
} else {
    & $python[0] @rr setup
}
Write-Host "`nDone. Ask Claude Code e.g. 'What does Reddit say about <topic>?'"
