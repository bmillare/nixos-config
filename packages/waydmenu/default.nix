{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
  pname = "waydmenu";
  version = "0.1.0";
  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      !(builtins.elem (builtins.baseNameOf path)
        [ "result" "waydmenu" "layer-shell.h" "layer-shell.c" "xdg-shell.c" ])
      || path == toString ./.;
  };
  nativeBuildInputs = [ pkgs.pkg-config pkgs.wayland-scanner ];
  buildInputs = [ pkgs.wayland pkgs.libxkbcommon pkgs.cairo pkgs.pango ];
  WAYLAND_PROTOCOLS = "${pkgs.wayland-protocols}/share/wayland-protocols";
  doCheck = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 waydmenu $out/bin/waydmenu
    runHook postInstall
  '';
}
