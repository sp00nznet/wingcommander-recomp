# Roadmap

## Next
- Finish the miss loop on the drivers until the game draws its first screen
  (see the README's status table), then the intro, the main menu, the bar
  and the first mission's briefing and launch.
- Commit `tools/wc1_seeds.txt` (addresses only) once the miss list settles,
  and have `Setup.cmd` run the one capture round a fresh clone needs (lift,
  build, run headless once so the drivers are captured, lift and build again).
- Sound: the drivers are lifted, so the AdLib path should come for free once
  the game is told it has one (WINGCMDR.CFG / INSTALL.DAT).
- A conformance harness (REPO_RULES section 9): scripted headless runs with a
  pass/fail count against fixed milestones (title, menu, briefing, launch),
  SKIP without game data, wired as the netlab QA beside the self-test.

## Then
- Wing Commander II: `wingcommander2` lifts and builds; run its miss loop.
  Its drivers are the same kind, so the capture should carry over.
- The Secret Missions (`SM1\`, `SM2\` on the CD) are data for WC1, and
  Special Operations (`SO1.EXE`, `SO2.EXE`) are separate WC2 executables.
- Build and publish the recomp-launcher installer.

## Toolkit (pcrecomp)
- Junk captures: a corrupted state far-calls garbage and that gets captured
  too. A capture could wait until the call is seen twice, or until the
  segment holds bytes the program read from a file.
- The blob-entry heuristics (unbounded `cs:` tables, `mov cs:[x], imm`,
  pointer runs) live in this lifter; move them beside `codeblob16.py` once a
  second game needs them.

## Leftovers from the fork
- `src/hires.c` and the lifter's renderer hooks are Blake Stone's; they find
  nothing here and are off. `run_generated()` is Corridor 7's scaler
  interpreter; nothing here reaches it. The mouse model is Mario Is Missing's.
