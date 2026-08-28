{ config, lib, pkgs, ... }:

# Psynk staging lanes — N isolated network namespaces for running the Psynk dev
# stack in parallel on this box.
#
# WHY THIS EXISTS
#
# The stack's ports are already parameterised (PSYNK_DEV_PGPORT,
# PSYNKER_SERVER_PORT, PSYNK_DEV_OPERA_PORT, PSYNK_DEV_FE_PORT), so port
# collisions were never the real constraint. Two things are genuinely singular:
#
#   1. `http://localhost:5173/auth/callback` is registered in the shared dev
#      Auth0 tenant. Move the frontend port and hosted provider login breaks.
#   2. The CDP debugging port (9222) the headless browser drives.
#
# Both are `localhost` problems, not port problems — which is why the fix is a
# network namespace rather than more configuration. A browser inside lane 3
# hitting http://localhost:5173 reaches lane 3's Vite, and Auth0 redirects back
# to the *same registered callback URL*, which resolves to a different stack in
# each lane. Every lane reuses the one registration, concurrently, unchanged.
# OPERA_PUBLIC_BASE_URL stays http://localhost:5173 everywhere too.
#
# This only works because the headless browser runs inside the lane as well.
#
# WHAT A LANE IS NOT
#
# A lane is a network namespace, not a container. Processes keep the host
# filesystem, so direnv, the nix devshell, and each workspace's working tree
# resolve exactly as they do outside — `live/scripts/dev-standup` runs unchanged
# and Vite hot reload is intact. That is the whole point: the agents verify
# uncommitted diffs, which a build-from-a-pushed-ref deployment cannot do.
#
# The PID namespace is shared. That is safe here because the dev scripts stop
# services by pidfile and PGDATA (lib.sh `stop_bg` / `stop_postgres`), never by
# process-name pattern. Keep it that way, or lanes will start killing each
# other's services.
#
# WHAT THIS DOES NOT FIX
#
# `opera dba reset` / `dba seed` write the mock personas into the SHARED dev
# Auth0 tenant and re-assert their passwords globally (opera #140). Network
# isolation does nothing about that: a fresh reset in one lane can invalidate a
# live session in another. Lanes make parallel *use* safe, not parallel fresh
# seeding.
#
# USAGE
#
#   live/scripts/lane status
#   live/scripts/lane exec 3 -- live/scripts/dev-standup
#   live/scripts/lane shell 3
#
# The user-facing `lane` wrapper lives in ~/projects/psynk-ws-tools (shared by
# every workspace); this file only provides the namespaces and the entry point.

let
  laneCount = 3;

  # Deliberately NOT 10.231.1.0/24 — that is psynk-it's `br-cradle` subnet for
  # the real Cradle staging slots, which this box can reach over Tailscale.
  subnet = "10.231.2";
  bridge = "br-lanes";

  # The uplink NAT masquerades through. Ethernet on this box; if it ever moves
  # to wifi this becomes wlp192s0 (or the lanes lose outbound, which they need
  # for the Auth0 round trip).
  uplink = "enp191s0";

  lanes = lib.range 1 laneCount;
  laneName = n: "lane${toString n}";
  laneAddr = n: "${subnet}.${toString (10 + n)}";
  # veth host side. IFNAMSIZ caps interface names at 15 chars.
  hostVeth = n: "${laneName n}-h";
  laneUnit = n: "psynk-${laneName n}.service";

  # Runs inside the lane's namespaces, still as root, and is the last thing to
  # hold privilege before the caller's command starts.
  #
  # A network namespace does NOT isolate unix domain sockets: they live in the
  # filesystem. psynker and opera both hardcode /tmp/psynk-bifrost with no env
  # override (psynker/bifrost/bifrost.py:19, opera src/bifrost/mod.rs:45-47), so
  # a second stack dies at boot with "Bifrost socket already has a live
  # listener" no matter how many lanes exist. Found by running a real stack in
  # lane 3 while another workspace had one up on the host.
  #
  # `ip netns exec` has already unshared the mount namespace (that is how it
  # swaps in the lane's resolv.conf) and made / rslave, so this bind is private
  # to the lane and invisible to the host and to every other lane. Fixing it
  # here rather than in the product keeps the "lanes need no product changes"
  # property, and covers any future fixed-path socket the same way.
  laneMount = pkgs.writeShellScript "psynk-lane-mount" ''
    set -euo pipefail
    lane="$1"; uid="$2"; gid="$3"; shift 3

    priv="/run/psynk-lanes/$lane/bifrost"
    ${pkgs.coreutils}/bin/mkdir -p "$priv" /tmp/psynk-bifrost
    ${pkgs.coreutils}/bin/chown "$uid:$gid" "$priv"
    ${pkgs.util-linux}/bin/mount --bind "$priv" /tmp/psynk-bifrost

    exec ${pkgs.util-linux}/bin/setpriv \
      --reuid="$uid" --regid="$gid" --init-groups -- "$@"
  '';

  # Entry point. Joins the lane's namespaces as root, then drops to the calling
  # user before exec'ing anything of theirs.
  #
  # `ip netns exec` is used rather than a bare `nsenter --net` because it also
  # unshares the mount namespace and bind-mounts /etc/netns/<lane>/resolv.conf
  # over /etc/resolv.conf. The lanes need that: this host's resolver is
  # Tailscale MagicDNS at 100.100.100.100, which is only reachable through
  # tailscale0 in the host namespace.
  #
  # The privilege drop is `setpriv --reuid`, which sets the real, effective AND
  # saved uid (verified: Uid: 1 1 1 1), so the exec'd command cannot climb back
  # to root. Net effect of the sudo rule below is therefore exactly "run a
  # command as yourself, in a lane" — it does not hand out passwordless root,
  # which would quietly undo security.sudo.wheelNeedsPassword.
  #
  # Every binary is referenced by absolute store path so that the SETENV-tagged
  # sudo rule cannot be used to hijack a lookup during the root-held window.
  laneEnter = pkgs.writeShellScriptBin "psynk-lane-enter" ''
    set -euo pipefail

    if [ "$#" -lt 2 ]; then
      echo "usage: psynk-lane-enter <lane> <command> [args...]" >&2
      exit 2
    fi

    lane="$1"; shift

    case "$lane" in
      ${lib.concatMapStringsSep "|" laneName lanes}) ;;
      *)
        echo "psynk-lane-enter: unknown lane '$lane'" >&2
        exit 2
        ;;
    esac

    if [ ! -e "/run/netns/$lane" ]; then
      echo "psynk-lane-enter: $lane is not up (try: systemctl start psynk-$lane)" >&2
      exit 1
    fi

    # Refuse to run as root-for-real: without sudo there is no uid to drop to,
    # and silently staying root would defeat the entire design.
    if [ -z "''${SUDO_UID:-}" ] || [ -z "''${SUDO_GID:-}" ]; then
      echo "psynk-lane-enter: must be invoked through sudo" >&2
      exit 2
    fi

    exec ${pkgs.iproute2}/bin/ip netns exec "$lane" \
      ${laneMount} "$lane" "$SUDO_UID" "$SUDO_GID" "$@"
  '';

  mkLaneService = n:
    lib.nameValuePair "psynk-${laneName n}" {
      description = "Psynk staging lane ${toString n} (network namespace)";
      wantedBy = [ "multi-user.target" ];
      after = [ "psynk-lanes-bridge.service" ];
      bindsTo = [ "psynk-lanes-bridge.service" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ns=${laneName n}
        vh=${hostVeth n}

        [ -e "/run/netns/$ns" ] || ip netns add "$ns"

        # Recreate the pair whenever the host side is missing: a half-torn-down
        # lane can leave a stale eth0 inside the namespace, and `ip link add`
        # would then fail with EEXIST on the peer name.
        if ! ip link show "$vh" >/dev/null 2>&1; then
          ip netns exec "$ns" ip link del eth0 2>/dev/null || true
          ip link add "$vh" type veth peer name eth0 netns "$ns"
        fi

        ip link set "$vh" master ${bridge}
        ip link set "$vh" up

        # Loopback must be brought up explicitly — a fresh namespace has it
        # DOWN, and without it 127.0.0.1 (i.e. every service in the lane) is
        # unreachable even from inside the lane itself.
        ip netns exec "$ns" ip link set lo up
        ip netns exec "$ns" ip addr replace ${laneAddr n}/24 dev eth0
        ip netns exec "$ns" ip link set eth0 up
        ip netns exec "$ns" ip route replace default via ${subnet}.1
      '';
      preStop = ''
        ip link del ${hostVeth n} 2>/dev/null || true
        ip netns del ${laneName n} 2>/dev/null || true
      '';
    };

  # Lanes cannot use the host's resolver (Tailscale MagicDNS on 100.100.100.100
  # is bound to tailscale0 in the host namespace). Public resolvers reached
  # through the NAT, matching what psynk-it's Cradle slots use.
  mkLaneResolvConf = n:
    lib.nameValuePair "netns/${laneName n}/resolv.conf" {
      text = ''
        nameserver 1.1.1.1
        nameserver 1.0.0.1
      '';
    };

  # The shared lane bridge. Built by hand rather than via networking.bridges so
  # that its lifecycle is explicit and visible in `systemctl status`, and so it
  # does not have to interleave with NetworkManager's view of the world.
  bridgeService = {
    description = "Psynk staging lane bridge (${bridge})";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip link show ${bridge} >/dev/null 2>&1 || ip link add name ${bridge} type bridge
      ip addr replace ${subnet}.1/24 dev ${bridge}
      ip link set ${bridge} up
    '';
    preStop = ''
      ip link del ${bridge} 2>/dev/null || true
    '';
  };
in {
  systemd.services = lib.listToAttrs (map mkLaneService lanes) // {
    psynk-lanes-bridge = bridgeService;
  };

  environment.etc = lib.listToAttrs (map mkLaneResolvConf lanes);

  # NetworkManager manages this host; left alone it would try to autoconfigure
  # the bridge and the veth stubs (and DHCP on them), fighting the units above.
  networking.networkmanager.unmanaged = [
    "interface-name:${bridge}"
    "interface-name:lane*-h"
  ];

  # Lanes need outbound internet for the Auth0 round trip and for nix/pnpm/cargo
  # fetches. This also enables net.ipv4.ip_forward.
  networking.nat = {
    enable = true;
    externalInterface = uplink;
    internalInterfaces = [ bridge ];
  };

  # Lanes are this user's own processes on this user's own box — same trust
  # domain as the host, so no point filtering between them.
  networking.firewall.trustedInterfaces = [ bridge ];

  environment.systemPackages = [ laneEnter ];

  # NOPASSWD because the agents invoke this constantly and an interactive prompt
  # would deadlock them; SETENV because the command being run needs the caller's
  # PATH/direnv environment to find the nix devshell. Safe on both counts only
  # because of the saved-uid drop documented on laneEnter above.
  #
  # The rule is written against the stable profile path, not the store path:
  # sudo matches the command as typed, and the store path changes on every
  # rebuild.
  security.sudo.extraRules = [{
    users = [ "brent" ];
    commands = [{
      command = "/run/current-system/sw/bin/psynk-lane-enter";
      options = [ "NOPASSWD" "SETENV" ];
    }];
  }];
}
