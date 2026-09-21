#define _GNU_SOURCE
#include <assert.h>
#include <errno.h>
#include <locale.h>
#include <poll.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/timerfd.h>
#include <unistd.h>
#include <wayland-client.h>
#include <xkbcommon/xkbcommon.h>
#include <xkbcommon/xkbcommon-compose.h>
#include <pango/pangocairo.h>
#include "layer-shell.h"

/* Input strings are UTF-8. Output values are kept byte-for-byte. */
struct item { char *key, *value; };
static struct item *items;
static size_t count, *matches, nmatch, selected, first;
static GString *query;
static size_t cursor;
static const char *prompt = "", *description = "";
static int width = 800, height = 600, scale = 1, rows = 1, list_y;
static bool running = true, configured, dirty = true;
static int status = 1, timer_fd, repeat_rate, repeat_delay;
static uint32_t repeat_key;
static struct wl_display *display;
static struct wl_compositor *compositor;
static struct wl_shm *shm;
static struct wl_surface *surface;
static struct wl_seat *seat;
static struct wl_keyboard *keyboard;
static struct wl_pointer *pointer;
static struct zwlr_layer_shell_v1 *shell;
static struct zwlr_layer_surface_v1 *layer;
static struct xkb_context *xkb;
static struct xkb_keymap *keymap;
static struct xkb_state *state;
static struct xkb_compose_table *compose_table;
static struct xkb_compose_state *compose;
static double pointer_y;
struct buffer { struct wl_buffer *wl; void *data; size_t size; bool busy; int w, h; };
static struct buffer buffers[2];

static void fail(const char *message) { fprintf(stderr, "waydmenu: %s\n", message); exit(2); }
static bool match(const char *key, const char *search) {
    char *folded_key = g_utf8_casefold(key, -1);
    char *copy = g_utf8_casefold(search, -1), *save = NULL;
    bool ok = true;
    for (char *t = strtok_r(copy, " ", &save); t; t = strtok_r(NULL, " ", &save))
        if (!strstr(folded_key, t)) { ok = false; break; }
    g_free(folded_key);
    g_free(copy);
    return ok;
}
static void add_line(char *line) {
    if (!*line) return;
    char *tab = strchr(line, '\t');
    if (tab) *tab++ = '\0';
    items = g_realloc_n(items, count + 1, sizeof(*items));
    items[count++] = (struct item){g_utf8_make_valid(line, -1), g_strdup(tab ? tab : line)};
}
static void filter(void) {
    matches = g_realloc_n(matches, count ? count : 1, sizeof(*matches));
    nmatch = 0;
    for (size_t i = 0; i < count; i++) if (match(items[i].key, query->str)) matches[nmatch++] = i;
    selected = first = 0;
    dirty = true;
}
static void move(int delta) {
    if (!nmatch) return;
    long next = (long)selected + delta;
    selected = next < 0 ? 0 : (size_t)next >= nmatch ? nmatch - 1 : (size_t)next;
    dirty = true;
}
static void accept(void) {
    if (nmatch) {
        status = printf("%s\n", items[matches[selected]].value) < 0 || fflush(stdout) ? 2 : 0;
        running = false;
    }
}
static void color(cairo_t *cr, double r, double g, double b) { cairo_set_source_rgb(cr, r, g, b); }
static void rect(cairo_t *cr, int x, int y, int w, int h) { cairo_rectangle(cr, x, y, w, h); cairo_fill(cr); }
static PangoLayout *layout(cairo_t *cr, const char *s, int size, int w, bool wrap) {
    PangoLayout *l = pango_cairo_create_layout(cr);
    PangoFontDescription *font = pango_font_description_new();
    pango_font_description_set_family(font, "sans");
    pango_font_description_set_absolute_size(font, size * PANGO_SCALE);
    pango_layout_set_font_description(l, font);
    pango_font_description_free(font);
    pango_layout_set_text(l, s, -1);
    if (w >= 0) pango_layout_set_width(l, w * PANGO_SCALE);
    if (wrap) pango_layout_set_wrap(l, PANGO_WRAP_WORD_CHAR);
    else { pango_layout_set_single_paragraph_mode(l, true); pango_layout_set_ellipsize(l, PANGO_ELLIPSIZE_END); }
    return l;
}
static void text(cairo_t *cr, const char *s, int size, int x, int y, int w) {
    PangoLayout *l = layout(cr, s, size, w, false);
    cairo_move_to(cr, x, y); pango_cairo_show_layout(cr, l); g_object_unref(l);
}
static void released(void *data, struct wl_buffer *wl) { ((struct buffer *)data)->busy = false; }
static const struct wl_buffer_listener buffer_listener = { .release = released };
static void draw(void) {
    if (!configured || !dirty) return;
    struct buffer *b = NULL;
    for (int i = 0; i < 2; i++) if (!buffers[i].busy) { b = &buffers[i]; break; }
    if (!b) return;
    int w = width * scale, h = height * scale;
    if (b->w != w || b->h != h) {
        if (b->wl) { wl_buffer_destroy(b->wl); munmap(b->data, b->size); }
        int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, w);
        b->size = (size_t)stride * h;
        if (b->size > INT32_MAX) fail("buffer too large");
        int fd = memfd_create("waydmenu", MFD_CLOEXEC);
        if (fd < 0 || ftruncate(fd, b->size)) fail("cannot allocate shared memory");
        b->data = mmap(NULL, b->size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (b->data == MAP_FAILED) fail("cannot map shared memory");
        struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, b->size);
        b->wl = wl_shm_pool_create_buffer(pool, 0, w, h, stride, WL_SHM_FORMAT_ARGB8888);
        wl_shm_pool_destroy(pool); close(fd);
        wl_buffer_add_listener(b->wl, &buffer_listener, b);
        b->w = w; b->h = h;
    }
    cairo_surface_t *cs = cairo_image_surface_create_for_data(b->data, CAIRO_FORMAT_ARGB32, w, h, w * 4);
    cairo_t *cr = cairo_create(cs);
    cairo_scale(cr, scale, scale);
    color(cr, .10, .11, .13); cairo_paint(cr);
    int x = 14;
    if (*prompt) {
        PangoLayout *l = layout(cr, prompt, 18, width / 3, false);
        int pw; pango_layout_get_pixel_size(l, &pw, NULL);
        color(cr, .93, .94, .96); cairo_move_to(cr, x, 20); pango_cairo_show_layout(cr, l);
        x += pw + 12; g_object_unref(l);
    }
    color(cr, .18, .20, .24); rect(cr, x, 12, width - x - 12, 36);
    PangoLayout *ql = layout(cr, query->str, 18, -1, false);
    PangoRectangle caret;
    pango_layout_get_cursor_pos(ql, cursor, &caret, NULL);
    int cx = caret.x / PANGO_SCALE, available = width - x - 30;
    int shift = cx > available ? cx - available : 0;
    cairo_save(cr); cairo_rectangle(cr, x + 6, 14, width - x - 24, 32); cairo_clip(cr);
    color(cr, .93, .94, .96); cairo_move_to(cr, x + 8 - shift, 20); pango_cairo_show_layout(cr, ql);
    rect(cr, x + 8 + cx - shift, 19, 1, 22); cairo_restore(cr); g_object_unref(ql);
    list_y = 58;
    if (*description) {
        PangoLayout *l = layout(cr, description, 14, width - 28, true);
        pango_layout_set_height(l, MAX(18, height / 3) * PANGO_SCALE);
        pango_layout_set_ellipsize(l, PANGO_ELLIPSIZE_END);
        int dh; pango_layout_get_pixel_size(l, NULL, &dh);
        color(cr, .68, .71, .76); cairo_move_to(cr, 14, list_y); pango_cairo_show_layout(cr, l);
        list_y += dh + 12; g_object_unref(l);
    }
    rows = MAX(1, (height - list_y - 12) / 28);
    if (selected < first) first = selected;
    if (selected >= first + rows) first = selected - rows + 1;
    for (size_t i = first; i < nmatch && i < first + rows; i++) {
        int y = list_y + (i - first) * 28;
        if (i == selected) { color(cr, .22, .36, .55); rect(cr, 10, y, width - 20, 28); }
        color(cr, .93, .94, .96); text(cr, items[matches[i]].key, 15, 16, y + 4, width - 38);
    }
    if (!nmatch) { color(cr, .68, .71, .76); text(cr, "No matches", 15, 16, list_y + 4, width - 32); }
    if (nmatch > (size_t)rows) {
        color(cr, .48, .52, .58);
        rect(cr, width - 7, list_y + (height - list_y - 12) * first / nmatch, 3,
             MAX(8, (height - list_y - 12) * rows / (int)nmatch));
    }
    cairo_destroy(cr); cairo_surface_flush(cs); cairo_surface_destroy(cs);
    wl_surface_set_buffer_scale(surface, scale);
    wl_surface_attach(surface, b->wl, 0, 0);
    wl_surface_damage_buffer(surface, 0, 0, w, h);
    wl_surface_commit(surface); b->busy = true; dirty = false;
}
static void stop_repeat(void) { struct itimerspec t = {0}; timerfd_settime(timer_fd, 0, &t, NULL); }
static void key_action(uint32_t key) {
    if (!state) return;
    xkb_keysym_t sym = xkb_state_key_get_one_sym(state, key + 8);
    bool ctrl = xkb_state_mod_name_is_active(state, XKB_MOD_NAME_CTRL, XKB_STATE_MODS_EFFECTIVE) > 0;
    bool alt = xkb_state_mod_name_is_active(state, XKB_MOD_NAME_ALT, XKB_STATE_MODS_EFFECTIVE) > 0;
    bool logo = xkb_state_mod_name_is_active(state, XKB_MOD_NAME_LOGO, XKB_STATE_MODS_EFFECTIVE) > 0;
    if (sym == XKB_KEY_Escape) { running = false; return; }
    if (sym == XKB_KEY_Return || sym == XKB_KEY_KP_Enter) { accept(); return; }
    if (sym == XKB_KEY_Up) { move(-1); return; }
    if (sym == XKB_KEY_Down) { move(1); return; }
    if (sym == XKB_KEY_Page_Up) { move(-rows); return; }
    if (sym == XKB_KEY_Page_Down) { move(rows); return; }
    dirty = true;
    if (sym == XKB_KEY_Left) { if (cursor) cursor = g_utf8_prev_char(query->str + cursor) - query->str; return; }
    if (sym == XKB_KEY_Right) { if (cursor < query->len) cursor = g_utf8_next_char(query->str + cursor) - query->str; return; }
    if (sym == XKB_KEY_Home || (ctrl && sym == XKB_KEY_a)) { cursor = 0; return; }
    if (sym == XKB_KEY_End || (ctrl && sym == XKB_KEY_e)) { cursor = query->len; return; }
    if (sym == XKB_KEY_BackSpace) {
        if (cursor) { size_t prev = g_utf8_prev_char(query->str + cursor) - query->str; g_string_erase(query, prev, cursor - prev); cursor = prev; filter(); }
        return;
    }
    if (sym == XKB_KEY_Delete) {
        if (cursor < query->len) { g_string_erase(query, cursor, g_utf8_next_char(query->str + cursor) - (query->str + cursor)); filter(); }
        return;
    }
    if (ctrl && sym == XKB_KEY_u) { g_string_erase(query, 0, cursor); cursor = 0; filter(); return; }
    if (ctrl || alt || logo) return;
    char utf8[128]; int len = 0;
    if (compose) {
        xkb_compose_state_feed(compose, sym);
        enum xkb_compose_status s = xkb_compose_state_get_status(compose);
        if (s == XKB_COMPOSE_COMPOSING) return;
        if (s == XKB_COMPOSE_CANCELLED) { xkb_compose_state_reset(compose); return; }
        if (s == XKB_COMPOSE_COMPOSED) { len = xkb_compose_state_get_utf8(compose, utf8, sizeof utf8); xkb_compose_state_reset(compose); }
    }
    if (!len) len = xkb_state_key_get_utf8(state, key + 8, utf8, sizeof utf8);
    if (len > 0 && len < (int)sizeof utf8 && g_utf8_validate(utf8, len, NULL) && !g_unichar_iscntrl(g_utf8_get_char(utf8))) {
        g_string_insert_len(query, cursor, utf8, len); cursor += len; filter();
    }
}
static void kb_map(void *d, struct wl_keyboard *kb, uint32_t format, int fd, uint32_t size) {
    if (format != WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1 || !size) { close(fd); fail("unsupported keyboard keymap"); }
    char *map = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0); close(fd);
    if (map == MAP_FAILED) fail("cannot map keyboard keymap");
    struct xkb_keymap *km = xkb_keymap_new_from_buffer(xkb, map, size - 1, XKB_KEYMAP_FORMAT_TEXT_V1, 0);
    munmap(map, size);
    if (!km) fail("cannot parse keyboard keymap");
    stop_repeat(); xkb_state_unref(state); xkb_keymap_unref(keymap);
    keymap = km; state = xkb_state_new(keymap);
    if (!state) fail("cannot initialize keyboard state");
}
static void kb_enter(void *d, struct wl_keyboard *kb, uint32_t serial, struct wl_surface *s, struct wl_array *keys) {}
static void kb_leave(void *d, struct wl_keyboard *kb, uint32_t serial, struct wl_surface *s) { stop_repeat(); if (compose) xkb_compose_state_reset(compose); }
static void kb_key(void *d, struct wl_keyboard *kb, uint32_t serial, uint32_t time, uint32_t key, uint32_t value) {
    if (value == WL_KEYBOARD_KEY_STATE_RELEASED) { if (key == repeat_key) stop_repeat(); return; }
    stop_repeat(); key_action(key);
    if (running && keymap && repeat_rate > 0 && xkb_keymap_key_repeats(keymap, key + 8)) {
        repeat_key = key;
        long ns = 1000000000L / repeat_rate;
        struct itimerspec t = { .it_interval = {ns / 1000000000L, ns % 1000000000L},
            .it_value = {repeat_delay / 1000, (repeat_delay % 1000) * 1000000L} };
        if (!t.it_value.tv_sec && !t.it_value.tv_nsec) t.it_value.tv_nsec = 1;
        timerfd_settime(timer_fd, 0, &t, NULL);
    }
}
static void kb_mods(void *d, struct wl_keyboard *kb, uint32_t serial, uint32_t dep, uint32_t lat, uint32_t lock, uint32_t group) {
    if (state) xkb_state_update_mask(state, dep, lat, lock, 0, 0, group);
}
static void kb_repeat(void *d, struct wl_keyboard *kb, int32_t rate, int32_t delay) { repeat_rate = CLAMP(rate, 0, 1000); repeat_delay = MAX(0, delay); stop_repeat(); }
static const struct wl_keyboard_listener kb_listener = {.keymap=kb_map, .enter=kb_enter, .leave=kb_leave, .key=kb_key, .modifiers=kb_mods, .repeat_info=kb_repeat};
static void ptr_enter(void *d, struct wl_pointer *p, uint32_t serial, struct wl_surface *s, wl_fixed_t x, wl_fixed_t y) { pointer_y = wl_fixed_to_double(y); }
static void ptr_leave(void *d, struct wl_pointer *p, uint32_t serial, struct wl_surface *s) {}
static void ptr_motion(void *d, struct wl_pointer *p, uint32_t time, wl_fixed_t x, wl_fixed_t y) { pointer_y = wl_fixed_to_double(y); }
static void ptr_button(void *d, struct wl_pointer *p, uint32_t serial, uint32_t time, uint32_t button, uint32_t value) {
    if (button == 0x110 && value == WL_POINTER_BUTTON_STATE_PRESSED && pointer_y >= list_y) {
        size_t row = (pointer_y - list_y) / 28;
        if (row < (size_t)rows && first + row < nmatch) { selected = first + row; dirty = true; }
    }
}
static void ptr_axis(void *d, struct wl_pointer *p, uint32_t time, uint32_t axis, wl_fixed_t value) {
    if (axis == WL_POINTER_AXIS_VERTICAL_SCROLL && value) move(value > 0 ? 3 : -3);
}
static const struct wl_pointer_listener ptr_listener = {.enter=ptr_enter,.leave=ptr_leave,.motion=ptr_motion,.button=ptr_button,.axis=ptr_axis};
static void capabilities(void *d, struct wl_seat *s, uint32_t caps) {
    if ((caps & WL_SEAT_CAPABILITY_KEYBOARD) && !keyboard) { keyboard = wl_seat_get_keyboard(s); wl_keyboard_add_listener(keyboard, &kb_listener, NULL); }
    else if (!(caps & WL_SEAT_CAPABILITY_KEYBOARD) && keyboard) { stop_repeat(); wl_keyboard_destroy(keyboard); keyboard = NULL; }
    if ((caps & WL_SEAT_CAPABILITY_POINTER) && !pointer) { pointer = wl_seat_get_pointer(s); wl_pointer_add_listener(pointer, &ptr_listener, NULL); }
    else if (!(caps & WL_SEAT_CAPABILITY_POINTER) && pointer) { wl_pointer_destroy(pointer); pointer = NULL; }
}
static void seat_name(void *d, struct wl_seat *s, const char *name) {}
static const struct wl_seat_listener seat_listener = {.capabilities=capabilities,.name=seat_name};
static void global(void *d, struct wl_registry *r, uint32_t name, const char *interface, uint32_t version) {
    if (!strcmp(interface, "wl_compositor") && version >= 4) compositor = wl_registry_bind(r, name, &wl_compositor_interface, MIN(version, 6));
    else if (!strcmp(interface, "wl_shm")) shm = wl_registry_bind(r, name, &wl_shm_interface, 1);
    else if (!strcmp(interface, "zwlr_layer_shell_v1")) shell = wl_registry_bind(r, name, &zwlr_layer_shell_v1_interface, 1);
    else if (!strcmp(interface, "wl_seat") && !seat) {
        /* v4 avoids pointer frame events; it still supplies keyboard repeat_info. */
        seat = wl_registry_bind(r, name, &wl_seat_interface, MIN(version, 4));
        wl_seat_add_listener(seat, &seat_listener, NULL);
    }
}
static void removed(void *d, struct wl_registry *r, uint32_t name) {}
static const struct wl_registry_listener registry_listener = {.global=global,.global_remove=removed};
static void configure(void *d, struct zwlr_layer_surface_v1 *l, uint32_t serial, uint32_t w, uint32_t h) {
    zwlr_layer_surface_v1_ack_configure(l, serial);
    if (w) width = w;
    if (h) height = h;
    if (width > 8192 || height > 8192) fail("surface too large");
    configured = dirty = true;
}
static void closed(void *d, struct zwlr_layer_surface_v1 *l) { running = false; }
static const struct zwlr_layer_surface_v1_listener layer_listener = {.configure=configure,.closed=closed};
static void surface_enter(void *d, struct wl_surface *s, struct wl_output *o) {}
static void surface_leave(void *d, struct wl_surface *s, struct wl_output *o) {}
static void preferred_scale(void *d, struct wl_surface *s, int32_t factor) { scale = CLAMP(factor, 1, 4); dirty = true; }
static void preferred_transform(void *d, struct wl_surface *s, uint32_t transform) {}
static const struct wl_surface_listener surface_listener = {.enter=surface_enter,.leave=surface_leave,.preferred_buffer_scale=preferred_scale,.preferred_buffer_transform=preferred_transform};

static void self_test(void) {
    assert(match("Alpha beta gamma", "gamma Alpha"));
    assert(match("Alpha beta", "alpha"));
    assert(match("alpha BETA", "ALPHA beta"));
    assert(!match("Alpha beta", "gamma"));
    assert(match("CAFÉ Straße", "café STRASSE"));
    assert(match("Alpha beta", "  beta   Alpha "));
    assert(match("café 日本語", "日本 café"));
    char a[] = "label\tvalue\tmore", b[] = "plain", c[] = "", e[] = "empty\t";
    add_line(a); add_line(b); add_line(c); add_line(e);
    assert(count == 3 && !strcmp(items[0].value, "value\tmore") && !strcmp(items[1].value, "plain") && !*items[2].value);
    query = g_string_new("LABEL"); filter(); assert(nmatch == 1 && matches[0] == 0);
    assert(!strcmp(items[0].key, "label") && !strcmp(items[0].value, "value\tmore"));
    g_string_assign(query, "missing"); filter(); assert(nmatch == 0);
    g_string_assign(query, ""); filter(); move(100); assert(selected == 2); move(-100); assert(selected == 0);
    puts("waydmenu: self-tests passed");
}
int main(int argc, char **argv) {
    setlocale(LC_ALL, "");
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--self-test")) { self_test(); return 0; }
        if (!strcmp(argv[i], "--help")) { puts("Usage: waydmenu [-p prompt] [-d description]\nRead lines from stdin; optional first tab separates label from output.\nEnter accepts, Escape cancels; arrows navigate and edit."); return 0; }
        if ((!strcmp(argv[i], "-p") || !strcmp(argv[i], "-d")) && i + 1 < argc) {
            bool p = !strcmp(argv[i], "-p");
            char *valid = g_utf8_make_valid(argv[++i], -1);
            if (p) prompt = valid;
            else { char **parts = g_strsplit(valid, "\\n", -1); description = g_strjoinv("\n", parts); g_strfreev(parts); g_free(valid); }
        } else fail("expected -p prompt or -d description (see --help)");
    }
    char *line = NULL; size_t capacity = 0; ssize_t len;
    while ((len = getline(&line, &capacity, stdin)) >= 0) {
        if (memchr(line, '\0', len)) fail("NUL bytes are not supported in input");
        while (len && (line[len - 1] == '\n' || line[len - 1] == '\r')) line[--len] = '\0';
        add_line(line);
    }
    free(line); if (ferror(stdin)) fail("cannot read stdin");
    query = g_string_new(""); filter();
    timer_fd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
    if (timer_fd < 0) fail("cannot create keyboard repeat timer");
    xkb = xkb_context_new(0); if (!xkb) fail("cannot initialize xkbcommon");
    compose_table = xkb_compose_table_new_from_locale(xkb, setlocale(LC_CTYPE, NULL), 0);
    if (compose_table) compose = xkb_compose_state_new(compose_table, 0);
    display = wl_display_connect(NULL); if (!display) fail("cannot connect to Wayland");
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    if (wl_display_roundtrip(display) < 0) fail("cannot read Wayland globals");
    if (!compositor || !shm || !shell || !seat) fail("requires Wayland compositor v4, shared memory, layer-shell, and a seat");
    surface = wl_compositor_create_surface(compositor);
    wl_surface_add_listener(surface, &surface_listener, NULL);
    layer = zwlr_layer_shell_v1_get_layer_surface(shell, surface, NULL, ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY, "waydmenu");
    zwlr_layer_surface_v1_add_listener(layer, &layer_listener, NULL);
    zwlr_layer_surface_v1_set_size(layer, width, height);
    zwlr_layer_surface_v1_set_anchor(layer, ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP);
    zwlr_layer_surface_v1_set_margin(layer, 100, 0, 0, 0);
    zwlr_layer_surface_v1_set_keyboard_interactivity(layer, ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_EXCLUSIVE);
    wl_surface_commit(surface);
    while (running) {
        if (wl_display_dispatch_pending(display) < 0) fail("Wayland connection lost");
        if (!running) break;
        draw();
        while (wl_display_prepare_read(display) != 0) {
            if (wl_display_dispatch_pending(display) < 0) fail("Wayland connection lost");
        }
        int flushed = wl_display_flush(display);
        if (flushed < 0 && errno != EAGAIN) { wl_display_cancel_read(display); fail("Wayland flush failed"); }
        struct pollfd fds[] = {{wl_display_get_fd(display), POLLIN | (flushed < 0 ? POLLOUT : 0), 0}, {timer_fd, POLLIN, 0}};
        int ready = poll(fds, 2, -1);
        if (ready < 0) { wl_display_cancel_read(display); if (errno == EINTR) continue; fail("poll failed"); }
        if (fds[0].revents & POLLIN) { if (wl_display_read_events(display) < 0) fail("Wayland read failed"); }
        else wl_display_cancel_read(display);
        if (fds[0].revents & (POLLERR | POLLHUP | POLLNVAL)) fail("Wayland disconnected");
        if (wl_display_dispatch_pending(display) < 0) fail("Wayland dispatch failed");
        if (running && (fds[1].revents & POLLIN)) {
            uint64_t ticks;
            if (read(timer_fd, &ticks, sizeof ticks) == sizeof ticks)
                for (uint64_t i = 0; i < MIN(ticks, 32) && running; i++) key_action(repeat_key);
        }
    }
    zwlr_layer_surface_v1_destroy(layer); wl_surface_destroy(surface);
    wl_display_flush(display); wl_display_disconnect(display); close(timer_fd);
    return status;
}
