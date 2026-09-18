{ inputs, pkgs, ... }:

let
  dykestrawWallpapers = [
    (pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/dharmx/walls/main/painting/a_painting_of_flowers_and_a_glass_of_wine.jpg";
      hash = "sha256-vuDnxBuISkVSVYb1RxVVo9DC8cpBDHuPhuVuDw/b+pw=";
    })
    (pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/dharmx/walls/main/apocalypse/a_woman_standing_in_front_of_a_window.jpg";
      hash = "sha256-AMJQp2GbtK/0+9U0KXZeuDEGHkQiMeHEV131Gk9zpY8=";
    })
    (pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/dharmx/walls/main/chillop/a_cartoon_of_a_space_ship_and_a_man_standing_on_a_rocky_surface.jpg";
      hash = "sha256-2YyesgpK3ZkeFhAYQcX8S1QEy5zDKDZLdWiBJqFvA+k=";
    })
    (pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/dharmx/walls/main/stalenhag/a_group_of_tall_buildings_with_cartoon_characters_on_them.jpg";
      hash = "sha256-KvVNLQQW4xmGamMK047pqYiPUWdsGjuArG+ypC7QI5Q=";
    })
    (pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/dharmx/walls/main/chillop/a_cartoon_of_a_car.jpg";
      hash = "sha256-ugNRMmT8BWDSneRut3n1I9pEE3/a4COxAdpprirEVs4=";
    })
  ];

  runDykestrawWallpaper = pkgs.writeShellScript "dykestraw-wallpaper" ''
    set -euo pipefail

    wallpapers=(
      ${builtins.concatStringsSep "\n      " (map toString dykestrawWallpapers)}
    )
    wallpaper_count="''${#wallpapers[@]}"
    wallpaper_state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/dykestraw-wallpaper"
    wallpaper_state_file="$wallpaper_state_dir/next-index"
    next_index=0

    ${pkgs.coreutils}/bin/mkdir -p "$wallpaper_state_dir"
    if [[ -r "$wallpaper_state_file" ]]; then
      read -r saved_index < "$wallpaper_state_file" || true
      if [[ "$saved_index" =~ ^[0-9]+$ ]]; then
        next_index=$((saved_index % wallpaper_count))
      fi
    fi

    selected_image="''${wallpapers[$next_index]}"
    next_index=$(((next_index + 1) % wallpaper_count))
    printf '%s\n' "$next_index" > "$wallpaper_state_file"

    exec ${pkgs.swaybg}/bin/swaybg -i "$selected_image" -m fill
  '';
in
{
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.bmillare = {
    imports = [
      ../../modules/home/bmillare.nix
      ../../modules/home/personal-project-sync.nix
    ];

    programs = {
      # Use native Wayland windows in Niri without requiring Xwayland.
      emacs.package = pkgs.emacs-pgtk;

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

    # Start from the default configuration shipped with this exact Niri
    # package, customizing input, display, spacing, and startup. This keeps new upstream
    # defaults when Niri is upgraded without maintaining a copied config.
    xdg.configFile."niri/config.kdl" = {
      force = true;
      text = builtins.replaceStrings
        [
          ''// options "grp:win_space_toggle,compose:ralt,ctrl:nocaps"''
          ''/-output "eDP-1" {''
          ''mode "1920x1080@120.030"''
          ''position x=1280 y=0''
          ''spawn-at-startup "waybar"''
          ''Mod+D hotkey-overlay-title="Run an Application: fuzzel"''
          ''gaps 16''
          "\n    touchpad {\n"
          "\n        natural-scroll\n"
          "focus-ring {\n        // Uncomment this line to disable the focus ring.\n        // off\n\n        // How many logical pixels the ring extends out from the windows.\n        width 4"
          "// prefer-no-csd"
          "numlock\n"
        ]
        [
          ''options "ctrl:swapcaps"''
          ''output "eDP-1" {''
          ''mode "2736x1824@59.959"''
          ''// position x=1280 y=0''
          ''// spawn-at-startup "waybar"''
          ''Mod+Space hotkey-overlay-title="Run an Application: fuzzel"''
          ''gaps 4''
          "\n    touchpad {\n        // Slow touchpad scrolling to 15% of the default speed.\n        scroll-factor 0.15\n"
          "\n        // natural-scroll: disabled for the preferred Type Cover scroll direction.\n"
          "focus-ring {\n        // Uncomment this line to disable the focus ring.\n        // off\n\n        // How many logical pixels the ring extends out from the windows.\n        width 3"
          "prefer-no-csd"
          "numlock\n        repeat-rate 35\n        repeat-delay 200\n"
        ]
        (builtins.readFile "${pkgs.niri.src}/resources/default-config.kdl");
    };

    systemd.user.services.swaybg = {
      Unit = {
        Description = "Dykestraw desktop wallpaper";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = runDykestrawWallpaper;
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.swaybg-rotate = {
      Unit = {
        Description = "Advance to the next dykestraw wallpaper";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user restart swaybg.service";
      };
    };

    systemd.user.timers.swaybg-rotate = {
      Unit = {
        Description = "Rotate the dykestraw wallpaper every 30 minutes";
        PartOf = [ "graphical-session.target" ];
      };
      Timer = {
        OnActiveSec = "30min";
        OnUnitActiveSec = "30min";
        Unit = "swaybg-rotate.service";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
