# Testing: the self-test, headless runs and scripted input

```
build\Release\wingcommander.exe                                   # play, in a window
build\Release\wingcommander.exe --headless --seconds 40 --shot-at "20000:C:\tmp\wc.bmp"
build\Release\wingcommander.exe --headless --keys "8000:ENTER,9000:SPACE" --record run.mp4
build\Release\selftest.exe                                         # the hardware models, no game data
```

| Flag | |
|---|---|
| `--data DIR`, `--save DIR` | the game's files (default `original\wc1`), saves (default `saves\wc1`) |
| `--headless` | no window, no audio device; time is deterministic |
| `--realtime` | headless, but on the wall clock |
| `--record OUT.mp4` | video and audio through ffmpeg |
| `--seconds N` | quit after N seconds of emulated time |
| `--keys LIST` | scripted input, `ms:KEY[+holdms],...`; `CLICK@x;y` clicks and `MOVE@x;y` hovers at mouse coordinates (0-639, 0-199) |
| `--shot FILE.bmp`, `--shot-at "ms:file.bmp,..."` | the last frame at exit, or frames at emulated times |
| `--wav OUT.wav` | write the audio |
| `--mute`, `--scale N`, `--fullscreen`, `--display sharp\|pixel\|crt` | sound off, window size, fullscreen (Alt+Enter toggles), display mode |
| `--trace` | log DOS and EMS calls to stderr |

The full list is at the top of [`src/main.c`](src/main.c).


## The self-test

`build\Release\selftest.exe` checks the hardware models (VGA, x87, Sound
Blaster/AdLib) with no game data, so it runs anywhere, netlab included.
Expected: `selftest: all passed`.

## Checking a change against the game

There is no conformance harness yet ([ROADMAP.md](../ROADMAP.md)). Headless
time is deterministic, so a `--keys` script replays exactly: Esc through the
intro, the *Claw Marks* copy question (page 31; Maniac's age is 23),
`CLICK@167;57` for "Start Vega Campaign", then the sign-in. A change is
checked by running such a script with `--shot-at` and looking at the frames.
Runs are headless, so nothing takes over a screen.
