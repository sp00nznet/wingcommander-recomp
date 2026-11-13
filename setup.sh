#!/bin/sh
# Linux and macOS: not yet. The runtime has an SDL2 host from the Blake Stone
# recomp, but it has never been built or tested here, and there is no Wine path
# either. Use Setup.cmd on Windows. See ROADMAP.md.
echo "Wing Commander recomp: there is no Linux or macOS build yet. Use Setup.cmd on Windows." >&2
exit 1
