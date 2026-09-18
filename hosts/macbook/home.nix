{ lib, pkgs, ... }:

{
  imports = [
    ../../modules/home/common-development.nix
    ../../modules/home/personal-project-sync.nix
  ];

  home = {
    username = "bmillare";
    homeDirectory = "/Users/bmillare";
    stateVersion = "26.05";
  };

  # Bootstrap without replacing the Mac's existing Git identity/configuration.
  programs.git.enable = lib.mkForce false;
  programs.gh.gitCredentialHelper.enable = lib.mkForce false;
  # Preserve the local tool PATH setup from the previous ~/.profile.
  programs.bash.profileExtra = ''
    if [ -f "$HOME/.local/bin/env" ]; then
      . "$HOME/.local/bin/env"
    fi
  '';
  home.packages = [ pkgs.git ];

  # Determinate Nix manages the daemon; Home Manager manages user applications.
  nix.enable = false;

  launchd.agents.syncthing.config.RunAtLoad = true;
  home.activation.syncthingLogDirectory = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
    run mkdir -p "$HOME/Library/Logs/Syncthing"
  '';
  # Ventura's launchctl lacks the --wait flag used by this HM release.
  # Unload changed agents first so the subsequent bootstrap can succeed.
  home.activation.syncthingVenturaCompatibility = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
    if [[ "$(/usr/bin/sw_vers -productVersion)" == 13.* ]]; then
      for agent in syncthing syncthing-init; do
        agent_name="org.nix-community.home.$agent"
        if ! cmp -s "$newGenPath/LaunchAgents/$agent_name.plist" "$HOME/Library/LaunchAgents/$agent_name.plist" \
          && /bin/launchctl print "gui/$(id -u)/$agent_name" >/dev/null 2>&1; then
          run /bin/launchctl bootout "gui/$(id -u)/$agent_name"
        fi
      done
    fi
  '';
}
