CC ?= cc
PKGS = wayland-client xkbcommon cairo pangocairo
CFLAGS ?= -O2 -g
CFLAGS += -std=c11 -Wall -Wextra -Wno-unused-parameter
CPPFLAGS += $(shell pkg-config --cflags $(PKGS))
LDLIBS += $(shell pkg-config --libs $(PKGS))
WAYLAND_PROTOCOLS ?= $(shell pkg-config --variable=pkgdatadir wayland-protocols)

all: waydmenu

layer-shell.h: protocols/wlr-layer-shell-unstable-v1.xml
	wayland-scanner client-header $< $@
layer-shell.c: protocols/wlr-layer-shell-unstable-v1.xml
	wayland-scanner private-code $< $@
xdg-shell.c: $(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml
	wayland-scanner private-code $< $@
waydmenu: waydmenu.c layer-shell.h layer-shell.c xdg-shell.c
	$(CC) $(CPPFLAGS) $(CFLAGS) waydmenu.c layer-shell.c xdg-shell.c -o $@ $(LDFLAGS) $(LDLIBS)
check: waydmenu
	./waydmenu --self-test
clean:
	rm -f waydmenu layer-shell.h layer-shell.c xdg-shell.c
.PHONY: all check clean
