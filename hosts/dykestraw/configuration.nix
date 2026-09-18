{ inputs, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./home.nix
    ../../modules/nixos/development-caches.nix
  ];

  system.stateVersion = "26.05";

  networking = {
    hostName = "dykestraw";
    networkmanager.enable = true;
    firewall.allowedUDPPorts = [ 5353 ];
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      # Deployments are built on crayfish and copied over SSH as bmillare.
      # Members of wheel already have full sudo access on this personal host.
      trusted-users = [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  users.users.bmillare = {
    isNormalUser = true;
    description = "Brent Millare";
    extraGroups = [ "networkmanager" "surface-control" "wheel" ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIc+wMxSoktmSGv9e7yEf0SQ2Qu7A9S9SX2jqh4V0z1a brent.millare@gmail.com"
    ];
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.wheelNeedsPassword = true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # zram handles routine memory pressure without immediately writing to the
  # SSD. The lower-priority 16 GiB disk swap LV remains a last-resort buffer
  # and reserves enough space to test hibernation later.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  services = {
    openssh.enable = true;
    fwupd.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
    gnome.gnome-keyring.enable = true;
    tailscale = {
      enable = true;
      openFirewall = true;
    };
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

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

  environment.systemPackages = with pkgs; [
    alacritty
    brightnessctl
    foot
    fuzzel
    swaylock
    unzip
    wev
  ];
}
