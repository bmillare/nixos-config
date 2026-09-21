# waydmenu

Native Wayland menu migrated from `bm_tools/waydmenu`. Requires a compositor
supporting wlr-layer-shell (such as Niri). The package builds with the host's
nixpkgs and runs `make check`, the executable's self-test.

Input is one row per line: `label<TAB>value`. Selected values go to stdout;
Escape exits with status 1, errors with status 2. `-p` sets the prompt and `-d`
sets the description. The menu never executes the selected value.

Matching is case-insensitive using Unicode case folding. Each space-separated
search token must appear in the label, in any order. Display labels and output
values preserve their original case.

Runtime libraries are Wayland client, xkbcommon, Cairo, and Pango. The vendored
layer-shell protocol retains its upstream license in the XML file.
`test-wayland.py` provides optional headless Sway GUI tests.
