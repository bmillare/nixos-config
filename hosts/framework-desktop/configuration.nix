{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../homes/brent/home.nix
  ];

  system.stateVersion = "26.05";

  networking.hostName = "crayfish";
  networking.networkmanager.enable = true;
  networking.dhcpcd.extraConfig = "crayfish";

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  users.users.brent = {
    isNormalUser = true;
    description = "Brent Millare";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.bashInteractive;
  };

  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  services.openssh.enable = true;
  services.fwupd.enable = true;

  services.displayManager.gdm.enable = false;
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    config.niri = {
      default = lib.mkForce [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    emacs
    gcc
    clang
    python3
    alacritty
    fuzzel
    swaylock
    vim
    wget
    curl
    ripgrep
    sbctl
    ghostty.terminfo
  ];
}
