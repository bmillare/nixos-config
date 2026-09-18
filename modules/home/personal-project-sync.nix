{
  config,
  lib,
  pkgs,
  ...
}:

let
  ignoreFile = pkgs.writeText "projects.stignore" ''
    // Machine-specific environments and generated files
    .git
    .DS_Store
    node_modules
    __pycache__
    .direnv
    .venv
    venv
    venv[0-9]*
    *_venv
    *_venv[0-9]*
    .stignore.before-hm-*
    // Models and the live Mac browser profile stay local
    *.gguf
    /startup/browser_control/tmp
    // Locally provisioned credentials
    /psynk_startup/credentials
    /*.pem
  '';
in
{
  # Keep ignores regular files, including for rollback to 2.1.2, which rejects
  # symlinked ignores. Install after Home Manager removes any old symlink.
  home.activation.projectSyncIgnores =
    lib.hm.dag.entryBetween [ "reloadSystemd" "setupLaunchAgents" ] [ "linkGeneration" ]
      ''
        run mkdir -p "$HOME/projects"
        run install -m600 ${ignoreFile} "$HOME/projects/.stignore"
      '';

  services.syncthing = {
    enable = true;
    package = pkgs.callPackage ../../packages/syncthing.nix { };
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        macbook = {
          id = "4LZH34U-INLNJ6P-LSA6KJX-IQULELZ-JFR6R43-5UKOV77-66HPV2S-JXHXIQW";
          addresses = [
            "tcp://Brents-MacBook-Pro.local:22000"
            "dynamic"
          ];
        };
        dykestraw = {
          id = "H7DHWHZ-QXKZIUD-QPZJXUT-A7UXUEI-HJX3SHJ-NKW3ROT-IS2U2OA-IC6MSQK";
        };
      };
      folders.projects = {
        id = "76zuh-norim";
        type = "sendreceive";
        path = "${config.home.homeDirectory}/projects";
        devices = [
          "macbook"
          "dykestraw"
        ];
        paused = false;
        # macOS and Linux have different permission conventions.
        ignorePerms = true;
        # Prefer downloading blocks over expensive cross-file SQLite lookups
        # on this LAN. Hash verification and same-file block reuse still apply.
        blockIndexing = false;
        versioning = {
          type = "simple";
          params.keep = "10";
        };
      };
    };
  };
}
