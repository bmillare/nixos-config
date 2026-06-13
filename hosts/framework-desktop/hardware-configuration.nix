# Replace this file with the output generated on the Framework Desktop:
#
#   sudo nixos-generate-config --root /mnt
#   cp /mnt/etc/nixos/hardware-configuration.nix hosts/framework-desktop/hardware-configuration.nix
#
# This placeholder keeps the flake readable before installation, but it is not a
# substitute for real hardware and filesystem configuration.
{ lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
}
