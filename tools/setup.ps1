<#
  setup.ps1 - the Quick start (README, Getting Started). Setup.cmd runs this.

  From a plain download to a "Wing Commander" shortcut in this folder:
    1. check the tools (Python 3, CMake, Git, Visual Studio 2022 C++ build
       tools) and offer to install what is missing
    2. copy your CD's WC1 folder into original\wc1
    3. fetch the pcrecomp toolkit next to this folder, at the tested commit
    4. lift WC.EXE to C (tools\lift.py wc1)
    5. build with CMake/MSVC and run the self-test
    6. put a shortcut in this folder

  Every step is skipped when its result is already there (-Force redoes the
  lift), so running it again after a failure carries on. Details go to
  setup.log. It runs exactly the commands README "Step by step" lists.

  Nothing from the game is downloaded or bundled: the files come from your own
  disc, and everything generated from them stays in work\ and build\.

    -GameDir <drive or folder>   the CD (E:\), its WC1 folder, or a copy of it
    -Yes                         answer yes to every install question

  Under recomp-launcher (RECOMP_LAUNCHER=1) it never waits for Enter.
#>
param([string]$GameDir = "", [switch]$Yes, [switch]$Force)
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root
$Log = Join-Path $Root "setup.log"
"=== setup $(Get-Date -Format s)" | Out-File $Log -Encoding utf8

# The toolkit commit this game was last lifted, built and run against
# (README, "Building from source"). A commit, not a branch: main moves.
$PcrecompUrl = "https://github.com/sp00nznet/pcrecomp.git"
$PcrecompRef = "pcrecomp-dos16-wc"

function Say($m) { Write-Host $m; $m | Out-File $Log -Append -Encoding utf8 }
function Fail($m) {
    Write-Host ""
    Write-Host "Setup stopped: $m" -ForegroundColor Red
    Write-Host "Details are in $Log. Fix that and run Setup.cmd again; finished steps are skipped."
    if (-not $Yes -and $env:RECOMP_LAUNCHER -ne "1") { Read-Host "Press Enter to close" | Out-Null }
    exit 1
}
trap { Fail "$_" }
function Run($what, [scriptblock]$cmd) {
    Say "  $what"
    # native tools write progress to stderr; under "Stop" PowerShell 5.1 would
    # turn every such line into a terminating error
    $ErrorActionPreference = "Continue"
    $out = & $cmd 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    $out | Out-File $Log -Append -Encoding utf8
    if ($code -ne 0) { Fail "$what failed (exit code $code)." }
}
function Ask($q) {
    if ($Yes) { Say "$q yes"; return $true }
    $a = Read-Host "$q [y/N]"
    return $a -match '^(y|yes)$'
}
function Have($exe) { return [bool](Get-Command $exe -ErrorAction SilentlyContinue) }

Say "Wing Commander (DOS): static recompilation setup"
Say "You need your own Wing Commander & Wing Commander II CD (or a copy of its WC1 folder) and about 1 GB free."

# ---- 1. tools ---------------------------------------------------------------
Say "[1/6] Checking the tools"
# `python` may be the Microsoft Store alias that only opens the Store; the py
# launcher is what a python.org install puts on PATH.
function Find-Py {
    if (Have "py") { return "py" }
    if ((Have "python") -and ((& python --version 2>&1) -match "Python 3")) { return "python" }
    return $null
}
$py = Find-Py
$need = @()
if (-not $py) { $need += @{ name = "Python 3"; id = "Python.Python.3.12"; size = "about 30 MB"; why = "runs the lifter (tools\lift.py)" } }
if (-not (Have "cmake")) { $need += @{ name = "CMake"; id = "Kitware.CMake"; size = "about 35 MB"; why = "configures the build" } }
if (-not (Have "git")) { $need += @{ name = "Git"; id = "Git.Git"; size = "about 60 MB"; why = "fetches the pcrecomp toolkit" } }
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = if (Test-Path $vswhere) { & $vswhere -latest -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath } else { $null }
if (-not $vs) { $need += @{ name = "Visual Studio 2022 Build Tools (C++)"; id = "Microsoft.VisualStudio.2022.BuildTools"; size = "about 2 GB"; why = "compiles the lifted C"; args = "--override `"--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended`"" } }

foreach ($n in $need) {
    Say "Missing: $($n.name), needed because it $($n.why). Download: $($n.size)."
    if (-not (Have "winget")) { Fail "Install $($n.name) yourself (winget is not available), then run Setup again." }
    if (-not (Ask "Install $($n.name) now with winget?")) { Fail "Setup needs $($n.name). Install it and run Setup again." }
    $wargs = @("install", "--id", $n.id, "-e", "--accept-package-agreements", "--accept-source-agreements")
    if ($n.args) { $wargs += $n.args }
    Run "installing $($n.name)" { winget @wargs }
}
if ($need.Count) {
    # a fresh install is on the machine PATH but not in this window's
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    $py = Find-Py
    if (-not $py) { Fail "Python installed, but this window can't see it. Close it and run Setup.cmd again." }
}
Say "  Python: $py"

# ---- 2. the game ------------------------------------------------------------------
Say "[2/6] Copying your game into original\wc1"
$dest = Join-Path $Root "original\wc1"
# A folder is the game when WC.EXE is in it; the CD keeps it in \WC1.
function Game-Folder($p) {
    if (-not $p) { return $null }
    foreach ($c in @($p, (Join-Path $p "WC1"))) { if (Test-Path (Join-Path $c "WC.EXE")) { return $c } }
    return $null
}
if (Test-Path (Join-Path $dest "WC.EXE")) {
    Say "  already copied."
} else {
    $src = Game-Folder $GameDir
    if (-not $src) {
        # every drive's \WC1: the disc, or a mounted image
        foreach ($d in (Get-PSDrive -PSProvider FileSystem)) { $src = Game-Folder $d.Root; if ($src) { break } }
    }
    if (-not $src -and -not $Yes -and $env:RECOMP_LAUNCHER -ne "1") {
        $src = Game-Folder (Read-Host "Where is the game? (the CD's drive, or the folder holding WC.EXE)")
    }
    if (-not $src) { Fail "WC.EXE was not found. Insert the Wing Commander CD (or mount its image) and run Setup again, or give -GameDir <folder holding WC.EXE>." }
    Say "  copying from $src"
    New-Item -ItemType Directory -Force $dest | Out-Null
    # all of it: the data files, the voices and the VIDEO folder
    Copy-Item -Path (Join-Path $src "*") -Destination $dest -Recurse -Force
}

# ---- 3. the toolkit ----------------------------------------------------------------
Say "[3/6] Fetching the pcrecomp toolkit"
if ($env:PCRECOMP_HOME -and (Test-Path "$env:PCRECOMP_HOME\tools\lift\codeblob16.py")) {
    $pcr = $env:PCRECOMP_HOME
} else {
    $pcr = Join-Path (Split-Path $Root -Parent) "pcrecomp-dos16-wc"
    if (-not (Test-Path "$pcr\tools\lift\codeblob16.py")) {
        Run "fetching pcrecomp into $pcr (about 20 MB)" { git clone --quiet $PcrecompUrl $pcr }
        Run "checking out pcrecomp $PcrecompRef" { git -C $pcr checkout --quiet $PcrecompRef }
    } else {
        # someone's existing checkout: used as it is, never switched
        Say "  using your checkout at $pcr (tested with $PcrecompRef)"
    }
}
$pcr = (Resolve-Path $pcr).Path
$env:PCRECOMP_HOME = $pcr

# ---- 4. lift ---------------------------------------------------------------------
Say "[4/6] Lifting WC.EXE to C"
if ((Test-Path "work\wc1\gen\recomp_dispatch.c") -and -not $Force) {
    Say "  already lifted (work\wc1\gen)."
} else {
    Run "py tools\lift.py wc1" { & $py tools\lift.py wc1 }
}

# ---- 5. build ----------------------------------------------------------------------
Say "[5/6] Building (a few minutes)"
Run "configuring" { cmake -B build -A Win32 "-DPCRECOMP_HOME=$pcr" }
Run "compiling" { cmake --build build --config Release --target wingcommander selftest -- -m }
$exe = Join-Path $Root "build\Release\wingcommander.exe"
if (-not (Test-Path $exe)) { Fail "The build finished but $exe is missing." }
Run "self-test (the hardware models, no game data)" { & build\Release\selftest.exe }
# The .DRV drivers exist only once the game has unpacked them: one headless run
# captures them into work\wc1\blobs, then they are lifted and built in.
if (-not (Test-Path "work\wc1\blobs\*.bin")) {
    Run "capturing the drivers (one headless run)" { & $exe --headless --seconds 20 | Out-Null }
    Run "lifting again, with the drivers" { & $py tools\lift.py wc1 }
    Run "compiling again" { cmake --build build --config Release --target wingcommander -- -m }
}

# ---- 6. shortcut -------------------------------------------------------------------
Say "[6/6] Making the shortcut"
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $Root "Wing Commander.lnk"))
$lnk.TargetPath = $exe
$lnk.WorkingDirectory = $Root   # it finds original\wc1 and saves\wc1 from here
$lnk.Save()
Say "Done. Double-click 'Wing Commander' in this folder to play. Alt+Enter toggles fullscreen."
if (-not $Yes -and $env:RECOMP_LAUNCHER -ne "1") { Read-Host "Press Enter to close" | Out-Null }
