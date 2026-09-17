{ inputs, pkgs, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.bmillare = {
    home = {
      username = "bmillare";
      homeDirectory = "/home/bmillare";
      stateVersion = "26.05";
      packages = [
        inputs.codex-cli-nix.packages.${pkgs.system}.default
        inputs.claude-code.packages.${pkgs.system}.default
        pkgs.chromium
        pkgs.jq
      ];
    };

    programs = {
      bash.enable = true;
      direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };
      firefox.enable = true;
      git = {
        enable = true;
        settings.init.defaultBranch = "main";
      };
      home-manager.enable = true;
      ssh = {
        enable = true;
        enableDefaultConfig = false;

        # Match crayfish: work GitHub is the default, with a separate alias
        # for repositories owned by the personal account.
        settings."github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."github.com_personal" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };

        # Main workstation. Its NixOS configuration authorizes the work key
        # for the brent account.
        settings."crayfish" = {
          HostName = "crayfish.local";
          User = "brent";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."octavian" = {
          HostName = "www.breakds.org";
          User = "brent";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."lorian" = {
          HostName = "lorian.local";
          User = "brent";
          ProxyJump = "octavian";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."cradle" = {
          HostName = "cradle.local";
          User = "brent";
          ProxyJump = "octavian";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."slot1" = {
          HostName = "10.231.1.2";
          User = "root";
          ProxyJump = "cradle";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."slot2" = {
          HostName = "10.231.1.3";
          User = "root";
          ProxyJump = "cradle";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."slot3" = {
          HostName = "10.231.1.4";
          User = "root";
          ProxyJump = "cradle";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
        settings."*.psynk.ai" = {
          User = "brent";
          IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
          IdentitiesOnly = true;
        };
      };
      tmux.enable = true;
      waybar = {
        enable = true;
        systemd.enable = true;

        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 38;
          spacing = 10;

          modules-left = [
            "niri/workspaces"
            "niri/window"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "network"
            "pulseaudio"
            "backlight"
            "battery"
            "tray"
          ];

          "niri/workspaces" = {
            format = "{value}";
            current-only = false;
          };
          "niri/window" = {
            format = "{title}";
            max-length = 55;
            separate-outputs = true;
          };
          clock = {
            format = "{:%a %b %d  %I:%M %p}";
            format-alt = "{:%Y-%m-%d  %H:%M:%S}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
          };
          network = {
            format-wifi = "Wi-Fi {signalStrength}%";
            format-ethernet = "Ethernet";
            format-disconnected = "Offline";
            tooltip-format-wifi = "{essid}\n{ipaddr}";
            tooltip-format-ethernet = "{ifname}\n{ipaddr}";
          };
          pulseaudio = {
            format = "Vol {volume}%";
            format-muted = "Muted";
            scroll-step = 5;
          };
          backlight = {
            format = "Light {percent}%";
            scroll-step = 5;
          };
          battery = {
            interval = 30;
            states = {
              warning = 20;
              critical = 10;
            };
            format = "Bat {capacity}%";
            format-charging = "Bat {capacity}% +";
            format-plugged = "Bat {capacity}% AC";
            tooltip-format = "{timeTo} remaining\n{power:.1f} W";
          };
          tray = {
            icon-size = 18;
            spacing = 8;
          };
        };

        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: sans-serif;
            font-size: 14px;
            min-height: 0;
          }

          window#waybar {
            background: rgba(24, 24, 27, 0.96);
            color: #f4f4f5;
          }

          #workspaces button {
            padding: 0 10px;
            color: #a1a1aa;
            background: transparent;
          }

          #workspaces button.active,
          #workspaces button.focused {
            color: #18181b;
            background: #93c5fd;
          }

          #workspaces button.urgent {
            color: #18181b;
            background: #fca5a5;
          }

          #window {
            color: #d4d4d8;
          }

          #clock,
          #network,
          #pulseaudio,
          #backlight,
          #battery,
          #tray {
            padding: 0 8px;
          }

          #battery.warning {
            color: #fbbf24;
          }

          #battery.critical {
            color: #f87171;
          }
        '';
      };
    };
  };
}
