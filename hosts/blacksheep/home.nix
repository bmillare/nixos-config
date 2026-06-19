# hosts/arch/home.nix
{ config, pkgs, inputs, ... }:

{
  # Change these to match your actual Arch username and home directory
  home.username = "bmillare";
  home.homeDirectory = "/home/bmillare";

  # Import shared configurations here!
  imports = [
    # Example: ../../modules/home/git.nix
    # Example: ../../modules/home/terminal.nix
  ];

  # You can install packages specifically for Arch here
  home.packages = with pkgs; [
    inputs.claude-code.packages.${pkgs.system}.default
    ripgrep
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Do not change this value without reading the Home Manager release notes!
  home.stateVersion = "26.05"; # Match this to your nixpkgs/home-manager version
}
