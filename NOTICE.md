# Notice

The MIT license in [LICENSE](LICENSE) covers what is ours in this repository:
the runtime, the lifter driver, the setup scripts, the tests and the
documentation. It does not cover the games.

*Wing Commander* and *Wing Commander II* are © 1990-1991 Origin Systems (now
Electronic Arts), and are not ours to license. Their executables, data, voices
and disc are not in this repository and are excluded by `.gitignore`.

- You need your own copy of the game to use any of this. Setup copies your CD
  (or a copy of its `WC1` folder) into `original/wc1/`; the pipeline reads it
  from there.
- Lifted code is a derivative work of the binary it came from. Anything the
  pipeline writes into `work/` (the lifted C is `work/wc1/gen/`, the captured
  drivers `work/wc1/blobs/`) carries whatever license the original carries,
  not this one. The MIT grant stops at our own work.
- `tools/wc1_seeds.txt` is a list of 61 `segment:offset` entry points our own
  runs found; it holds no code or data from the game.

## Third-party code

| Path | Upstream | Version | License |
|---|---|---|---|
| `third_party/ymfm/` | [ymfm](https://github.com/aaronsgiles/ymfm), © 2021 Aaron Giles; OPL family sources only, unmodified | 2021 sources | BSD-3-Clause, [LICENSES/BSD-3-Clause-ymfm.txt](LICENSES/BSD-3-Clause-ymfm.txt) |

The runtime (`src/`) and `tools/lift.py` began as the
[Mario Is Missing DOS recomp](https://github.com/sp00nznet/marioismissing-dos)'s,
before it [Corridor 7](https://github.com/sp00nznet/corridor7)'s and
[Blake Stone](https://github.com/sp00nznet/blakestone)'s; all are our own MIT
work. The build uses, but does not include, the
[pcrecomp](https://github.com/sp00nznet/pcrecomp) toolkit (MIT).
