{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../homes/brent/home.nix
  ];

  system.stateVersion = "26.05";

  networking.hostName = "crayfish";
  networking.networkmanager.enable = true;
  networking.firewall.allowedUDPPorts = [
    5353
  ];
  networking.firewall.allowedTCPPorts = [
    8080
  ];
  # You need this to broadcast your hostname to local network
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enables IPv4 mDNS resolution
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

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

  # Raise the iGPU GTT (unified-memory) ceiling for large local LLMs.
  # The Radeon 8060S maps model weights + KV cache through GTT; the kernel
  # default ttm.pages_limit is ~half of RAM (~31 GiB on this 64 GB box),
  # which is too small for a ~30 GiB Q8 model + 30k-context KV (~37 GiB total).
  # Bump the ceiling to 48 GiB (12582912 * 4 KiB pages), leaving 16 GiB for the
  # OS. It is a ceiling, not a reservation — only what the GPU actually
  # allocates is used. amdgpu.gttsize (MiB) is set to match.
  boot.kernelParams = [
    "ttm.pages_limit=12582912"
    "ttm.page_pool_size=12582912"
    "amdgpu.gttsize=49152"
  ];

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  services.openssh.enable = true;
  services.fwupd.enable = true;

  # Tailscale mesh VPN. `openFirewall` opens the UDP port for direct
  # (non-relayed) connections. After the first rebuild, authenticate with
  # `sudo tailscale up`.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # SMB share of ~/projects for native access from macOS Finder/apps.
  # Set the Samba password once after rebuild: `sudo smbpasswd -a brent`
  # (Samba keeps its own password DB, separate from the system login.)
  services.samba = {
    enable = true;
    openFirewall = true; # opens TCP 445/139 and UDP 137/138
    settings = {
      global = {
        "server string" = "crayfish";
        "netbios name" = "crayfish";
        security = "user";
        "min protocol" = "SMB2";
        # macOS interop: route Apple metadata into xattr streams instead of
        # AppleDouble sidecar files, and handle illegal NTFS chars cleanly.
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:nfs_aces" = "no";
      };
      projects = {
        path = "/home/brent/projects";
        browseable = "yes";
        writable = "yes";
        "valid users" = "brent";
        "force user" = "brent";
        "create mask" = "0644";
        "directory mask" = "0755";
        "follow symlinks" = "yes"; # links within the share resolve
        # Keep macOS junk off the server side.
        "veto files" = "/.DS_Store/._*/.AppleDouble/.AppleDesktop/Network Trash Folder/";
        "delete veto files" = "yes";
      };
    };
  };

  # Advertise SMB over the mDNS stack already enabled below, so crayfish
  # appears under "Network" in Finder without typing an address.
  services.avahi.extraServiceFiles.smb = ''
    <?xml version="1.0" standalone='no'?>
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
      <name replace-wildcards="yes">%h</name>
      <service>
        <type>_smb._tcp</type>
        <port>445</port>
      </service>
      <service>
        <type>_device-info._tcp</type>
        <port>0</port>
        <txt-record>model=RackMac</txt-record>
      </service>
    </service-group>
  '';

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
