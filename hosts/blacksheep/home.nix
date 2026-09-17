{ pkgs, ... }:

{
  imports = [
    ../../modules/home/bmillare.nix
  ];
  # Standalone HM manages the client's configuration. A multi-user daemon
  # must also allow these caches in /etc/nix/nix.conf; user config cannot
  # grant daemon trust. Use the same URLs and public keys from this data file.
  nix = {
    package = pkgs.nix;
    settings =
      let
        caches = import ../../modules/nix-caches.nix;
      in
      {
        extra-substituters = caches.substituters;
        extra-trusted-public-keys = caches.trusted-public-keys;
      };
  };
}
