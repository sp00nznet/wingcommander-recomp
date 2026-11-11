# Lifting Wing Commander: what it took

What this game needed beyond the Mario Is Missing recomp this repository was
forked from, in the order it turned up. Everything generic went into pcrecomp
(branch `pcrecomp-dos16-wc`).

## 1. The disc

The Wing Commander & Wing Commander II CD (USA) is one Mode 1 data track. Its
`WC1\` folder is Wing Commander already installed (`WC.EXE`, the `.VGA`,
`.V0x` and `.DRV` files); `WING2\GAMEDAT\` holds Wing Commander II, with
`WC2.EXE` one level up. The batch files on the disc only `cd` and run
`INSTALL` or `SGFIND`/`CDWEDGE` (a CD check); none of that is needed here.
`tools/setup.ps1` copies `WC1\` into `original\wc1`.

To read the image without mounting it: pcrecomp's `tools/assets/bin2iso.js`,
then `tools/assets/iso_peek.py`.

## 2. Not packed; Borland C++ with VROOMM overlays

`WC.EXE` is a plain MZ (no LZEXE, no EXEPACK; TLINK 3.0 signature at 1Ch)
whose 134 KB load image is followed by an `FBOV` block: Borland's VROOMM
overlay manager. 40 overlaid segments, 162 KB, 867 entries. `WC2.EXE` is the
same toolchain with 124 overlays (185 KB, 796 entries).

pcrecomp's `tools/drm/vroomm.py` (moved there from this lifter, where Mario Is
Missing had it per game) makes every overlay resident once, at a fixed home in
C000-DFFF, F100-FFEF and B000-B7FF; the `INT 3Fh` stub entries become far
jumps, and the overlay fixups (FBOV table offsets, not segments) become
ordinary relocations. The overlay manager still opens `WC.EXE` at start-up
(argv[0] has to name it, `src/dos.c`), but never loads anything.

## 3. EMS

The game asks for EMS (`INT 67h`) and fills it: it prints *Expanded Memory
Detected* and *Expanded Memory fully used*, and caches its data files there.
The runtime's EMS 4.0 model (256 pages, frame at E000h, from Mario Is Missing)
was enough; no change.

## 4. Code that exists only at run time: the .DRV drivers

The new problem. `TM.DRV` and `SUPERTM.DRV` (and `STRAX.DRV`, unused with
these settings) are LZW-compressed like the `.VGA` files. The game unpacks
them into its heap (36B4h and 3B93h on this machine model) and far-calls into
them through a word table at the start of each (`call far 36B4:14A0`). None of
that code is in the executable, so the first lift skips the calls, and the
game later dies of garbage (*Sorry, an error has occured while allocating
memory*).

pcrecomp now has a general answer, `runtime/recomp16/codeblob.h` and
`tools/lift/codeblob16.py`:

1. **Capture.** A dispatch miss whose target bytes are not the load image's
   (outside it, or different from it) and above the PSP dumps 64 KB from
   `seg:0000` to `work/wc1/blobs/SSSS.bin`, before the first instruction there
   runs. The first capture is kept; later runs never overwrite it.
2. **Lift.** Each capture becomes a code segment of its own at a virtual
   paragraph above 1 MB (10000h, 11000h, ...), entered at the offsets the
   misses named. Its `SEG_xxxxx` constant becomes `g_blob_seg[k]`, so `cs:`
   reads and pushed return segments are the live segment.
3. **Bind.** At run time a miss inside a known blob's segment maps straight
   to the lifted copy; an unbound segment binds when the 24 bytes at the
   entry match a lifted entry's.

The drivers call themselves through tables, so three more ways to find their
entries were needed in this lifter (`tools/lift.py`, blob segments only):

- `jmp/call word cs:[reg+disp]` with no bound in front of it: take the words
  at `disp` while each names decodable code in the blob;
- `mov word cs:[x], offset`: a routine pointer stored for a later
  `call cs:[x]` (SUPERTM's state machine sets `cs:[06C2]` this way dozens of
  times);
- the existing scan for runs of near pointers after a `ret`/`jmp`, now over
  each capture too.

What is left to the miss loop: a corrupted state jumps to garbage, and
garbage captures happen. `work/iter.sh` (local, not committed) keeps only
misses in the image's code and in the two driver segments.

## 5. How far it gets

About fifteen capture-lift-build rounds (one new driver entry each, before the
table heuristics above) took it from a garbled start to:

- the intro (concert hall, Earth, the Kilrathi fighter, the credits) with no
  misses;
- the copy check, a question from the *Claw Marks* manual typed through DOS
  `AH=07h` (headless runs ask the same one every time: page 31, Maniac's age,
  23);
- the main menu ("Start Vega Campaign", "Start Secret Missions"; the CD has no
  Secret Missions data in `WC1\`, and the game says so);
- the new-pilot sign-in, drawn in the Tiger's Claw simulator cockpit, with the
  disc's `SAVEGAME.WLD` pilot filled in.

The miss list settles at 60 entries (4 in the image's start-up, 52 in the two
drivers), committed as `tools/wc1_seeds.txt`.

## 6. Where it stops

At the sign-in, typed keys do not reach the field and the screen stops
changing, while the game keeps mapping EMS pages and polls DOS `AH=0Bh` only
occasionally. The cockpit installs the game's own keyboard handler; the next
thing to check is whether it chains to the BIOS (the sign-in reads through
DOS) and whether the frame loop is waiting on the timer driver.

## 7. Menus need the mouse; keys arrive late

"Start Vega Campaign" is chosen with a click (`--keys 14000:CLICK@167;57`);
Enter picks the highlighted Secret Missions. After the click the menu waits
for a key, and the first one only starts the fade.
