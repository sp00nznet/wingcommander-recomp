# Building

`Setup.cmd` runs exactly these steps; this is the same thing by hand.

## Step by step

Prerequisites: Windows 10/11, Python 3.10+ (`py --version`), CMake 3.20+,
Git, and Visual Studio 2022 (or its Build Tools) with *Desktop development
with C++*. ffmpeg on `PATH` only for `--record`.

1. **The toolkit**, beside this folder (`main`):
   ```
   git clone https://github.com/sp00nznet/pcrecomp ..\pcrecomp
   set PCRECOMP_HOME=%CD%\..\pcrecomp
   ```
   Without `PCRECOMP_HOME`, `tools\lift.py` and CMake look for
   `..\pcrecomp`.
2. **Your game files**: copy the CD's `WC1` folder, all of it, into
   `original\wc1\` (so that `original\wc1\WC.EXE` exists). For Wing
   Commander II, `WING2\GAMEDAT\*` and `WING2\WC2.EXE` into `original\wc2\`.
3. **Lift**:
   ```
   > py tools\lift.py wc1
     overlays: 40 placed resident, 162253 bytes, 867 entries
   WC.EXE: DGROUP 1231, ... functions, ... instructions lifted, ...
     -> ...\work\wc1\gen
   ```
4. **Build** (a few minutes):
   ```
   cmake -B build -A Win32 -DPCRECOMP_HOME=%PCRECOMP_HOME%
   cmake --build build --config Release --target wingcommander selftest -- -m
   build\Release\selftest.exe
   ```
5. **Capture the drivers.** A fresh lift has never seen the `.DRV` code.
   Run it headless, which captures what it unpacks into `work\wc1\blobs\`
   (the entry points it needs are already in `tools\wc1_seeds.txt`), keep
   only `36B4.bin` and `3B93.bin` (a first run also captures junk segments,
   such as `08F2.bin` and `2B00.bin`, whose lift breaks the link), then lift
   and build again. The first run exits with code 3 and sees only `36B4`
   (TM.DRV); do it a second time for `3B93` (SUPERTM.DRV):
   ```
   build\Release\wingcommander.exe --headless --seconds 20
   del work\wc1\blobs\08F2.bin work\wc1\blobs\2B00.bin
   py tools\lift.py wc1
   cmake --build build --config Release --target wingcommander -- -m
   ```
   When both are in, the lift prints
   `blobs: 36B4 (17 entries) at 10000, 3B93 (36 entries) at 11000`.
6. **Play**, from this folder (it reads `original\wc1` and keeps saves in
   `saves\wc1`): `build\Release\wingcommander.exe`. Esc skips the intro.
   The copy check asks a question from the *Claw Marks* manual. "Start Vega
   Campaign" is clicked with the mouse.

The usual trip-ups: `python` opening the Microsoft Store (that is Windows'
alias placeholder; use `py`); a freshly installed tool not being on `PATH`
until you open a new window; and a `..\pcrecomp` on `main`, which lacks
`codeblob16.py` and `vroomm.py`.

## Notes

How the pieces fit is
[docs/architecture.md](docs/architecture.md) (the pipeline and the machine
model, from Blake Stone); what this game needed (the disc, VROOMM, EMS, and
the drivers it unpacks at run time) is [docs/lifting.md](docs/lifting.md).
The self-test builds without any game data, so it builds and runs on its own.


On [netlab](https://github.com/sp00nznet/recomp-netlab) the recipe is
`wingcommander-recomp`; its QA is the self-test.
