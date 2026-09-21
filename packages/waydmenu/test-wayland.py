#!/usr/bin/env python3
"""Optional integration test: python3 test-wayland.py /path/to/waydmenu.
Requires sway, wtype, and grim in PATH. Uses a private headless compositor.
"""
import os
from pathlib import Path
import subprocess as sp
import sys
import tempfile
import time

binary = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory(prefix="waydmenu-test-") as tmp:
    root = Path(tmp)
    config = root / "sway.conf"
    config.write_text('output HEADLESS-1 mode 1280x900\nseat seat0 fallback true\nxwayland disable\n')
    env = dict(os.environ, XDG_RUNTIME_DIR=tmp, WLR_BACKENDS="headless", WLR_RENDERER="pixman", WLR_LIBINPUT_NO_DEVICES="1")
    for key in ("WAYLAND_DISPLAY", "DISPLAY", "SWAYSOCK"):
        env.pop(key, None)
    log = open(root / "sway.log", "w+")
    compositor = sp.Popen(["sway", "-c", str(config)], env=env, stdout=log, stderr=log)
    menu = None
    try:
        for _ in range(100):
            sockets = [p for p in root.glob("wayland-*") if not p.name.endswith(".lock")]
            if sockets:
                env["WAYLAND_DISPLAY"] = sockets[0].name
                break
            if compositor.poll() is not None:
                log.seek(0)
                raise RuntimeError(log.read())
            time.sleep(.05)
        else:
            raise RuntimeError("headless compositor did not start")

        def case(name, data, keys, expected, code=0, screenshot=False):
            global menu
            menu = sp.Popen([binary, "-p", "Choose:", "-d", "Type to filter\\nEnter selects; Escape cancels."], env=env, stdin=sp.PIPE, stdout=sp.PIPE, stderr=sp.PIPE)
            menu.stdin.write(data)
            menu.stdin.close()
            menu.stdin = None
            time.sleep(.25)
            if screenshot:
                sp.run(["grim", "/tmp/waydmenu-preview.png"], env=env, check=True)
            sp.run(["wtype", "-s", "100", *keys], env=env, check=True, timeout=5)
            out, err = menu.communicate(timeout=5)
            assert (menu.returncode, out) == (code, expected), (name, menu.returncode, out, err)
            assert not err, (name, err)
            print("PASS", name)
            menu = None

        data = b"Alpha beta\tone\nAlpha gamma\ttwo\textra\nalpha beta\tthree\n"
        case("initial focus and selection", data, ["-k", "Return"], b"one\n", screenshot=True)
        case("token filtering and hidden value", data, ["gamma Alpha", "-k", "Return"], b"two\textra\n")
        case("case insensitive", data, ["alpha", "-k", "Return"], b"one\n")
        case("arrow selection", data, ["-k", "Down", "-k", "Return"], b"two\textra\n")
        case("key repeat", data, ["-P", "Down", "-s", "1000", "-p", "Down", "-k", "Return"], b"three\n")
        many = b"".join(f"item {i}\tvalue {i}\n".encode() for i in range(100))
        case("scroll beyond visible rows", many, ["-k", "Page_Down", "-k", "Page_Down", "-k", "Return"], b"value 34\n")
        case("cursor editing", data, ["Alpa", "-k", "Left", "h", "-k", "Return"], b"one\n")
        case("unicode input and deletion", "café\tcoffee\n".encode(), ["caféx", "-k", "BackSpace", "-k", "Return"], b"coffee\n")
        case("CRLF and empty lines", b"\r\nplain\r\n", ["-k", "Return"], b"plain\n")
        case("empty value", b"label\t\n", ["-k", "Return"], b"\n")
        case("cancel", data, ["-k", "Escape"], b"", 1)
        case("no matches enter does not exit", data, ["missing", "-k", "Return", "-k", "Escape"], b"", 1)
        case("empty input", b"", ["-k", "Return", "-k", "Escape"], b"", 1)
    finally:
        if menu and menu.poll() is None:
            menu.kill()
            menu.wait()
        compositor.terminate()
        compositor.wait(timeout=5)
        log.close()
