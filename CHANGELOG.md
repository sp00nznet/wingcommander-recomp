# Changelog

All notable changes to this project. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [SemVer](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-11

### Added
- Wing Commander (`WC1\WC.EXE` from the Wing Commander & Wing Commander II
  CD) lifted to C with pcrecomp's own 16-bit decoder and lifter, no IDA:
  40 Borland VROOMM overlays made resident (pcrecomp `tools/drm/vroomm.py`).
- Run-time code capture: the LZW-packed `TM.DRV` and `SUPERTM.DRV` drivers the
  game unpacks into its heap are captured on the first run and lifted on the
  next (pcrecomp `runtime/recomp16/codeblob.h`, `tools/lift/codeblob16.py`),
  with three ways to find a driver's entries (unbounded `cs:` tables,
  `mov cs:[x], offset` pointers, pointer runs after a return).
- Runs the intro, the *Claw Marks* copy question, the main menu and the
  new-pilot sign-in in the simulator cockpit; stops there (typing does not
  reach the sign-in). `tools/wc1_seeds.txt`: the 60 entry points the runs
  found. `--keys` knows every letter and digit.
- Wing Commander II (`WC2.EXE`) lifts too (124 overlays) and builds as
  `wingcommander2`; not run yet.
- `Setup.cmd`, a recomp-launcher manifest, the self-test (VGA, x87, OPL
  models; no game data), headless runs with scripted keys and screenshots.

### Changed
- Forked from [marioismissing-dos](https://github.com/sp00nznet/marioismissing-dos):
  its runtime (DOS, VGA, EMS, mouse, OPL) and lifter. The VROOMM placer and
  the 8087-emulator segment table moved from the lifter into pcrecomp.
