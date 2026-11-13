# Contributing

Issues and pull requests are welcome.

## The one rule

**Nothing from the game goes in the repository.** No game files (`original/`),
no lifted C (`work/wc1/gen/`), no unpacked image or dispatch-miss lists
(`work/`), no disassembly listings, nothing generated from `WC.EXE`. The
tool ships; its output is made on each person's machine from their own copy.
`.gitignore` covers the usual paths; check `git status` before you commit
anyway. Screenshots of the game running are fine.

## Where your code comes from

Original work or MIT-compatible only. Don't port from DOSBox, ScummVM or any
other GPL emulator, and don't write code with one open: that makes it theirs.

## Before a pull request

1. Lift and build from clean: `py -3 tools\lift.py wc1`, then
   `cmake --build build --config Release` ([docs/building.md](docs/building.md)).
2. Run the self-test (no game data needed): `build\Release\selftest.exe`,
   expected `selftest: all passed`.
3. Run the change headless and keep the evidence, for example
   `build\Release\wingcommander.exe --headless --seconds 40 --keys "6000:ESC,8000:ESC,10000:ESC" --shot-at "20000:wc.bmp"`
   ([docs/testing.md](docs/testing.md)). A new hardware behavior comes with a
   self-test check.

## Where a fix belongs

- A bug in the 16-bit lifter, the VROOMM placer, `codeblob16` or the CPU model (`runtime/recomp16`)
  belongs in [pcrecomp](https://github.com/sp00nznet/pcrecomp), not here.
- The machine model (DOS, EMS, VGA, audio) and anything Wing
  Commander-specific lives here, in `src/` and `tools/lift.py`, with a comment that
  says what it fixes and why.
- A wall you got past goes in `docs/lifting.md`: what it looked like, what it
  was, what moved it.
