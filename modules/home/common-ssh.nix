{ ... }:

{
  # Shared outgoing connections; private keys are provisioned separately.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # work github is default
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
    # cradle sits on breakds's LAN; cradle.local only resolves from octavian.
    #
    # IdentityFile must be repeated here rather than relying on the
    # "*.psynk.ai" block below — neither "cradle.local" nor the 10.231.1.x
    # slot addresses match that pattern, so without it ssh never offers the
    # key and the hop fails with "Permission denied (publickey)".
    #
    # IdentitiesOnly must be on this block too, not just the slots: the jump
    # hop otherwise offers every key in the agent and dies with "Too many
    # authentication failures" before the container is ever reached.
    settings."cradle" = {
      HostName = "cradle.local";
      User = "brent";
      ProxyJump = "octavian";
      IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
      IdentitiesOnly = true;
    };
    # The psynk staging containers on cradle. Root-by-key only (no normal
    # users), and the 10.231.1.0/24 bridge is not routed on the LAN, so
    # cradle is the only way in.
    #
    # Kept as separate flat blocks on purpose. Collapsing them into a shared
    # "slot1 slot2 slot3" block plus per-host HostName overrides works only
    # because of ssh's first-value-wins ordering, and home-manager emits
    # these sorted by attribute name rather than declaration order. The flat
    # form is order-independent.
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
    # Psynk deployment fleet (cradle1, cradle2, freshpath/trial1, pilot1,
    # demo*, brand1). They all authorize this key via psynk-it
    # nix/data/keys/brent.pub, but without a match block ssh never offers it
    # and falls back to the personal id_ed25519 → "Permission denied
    # (publickey)". Wildcarded so a new host needs no edit here.
    #
    # `User` is only a default: an explicit `root@host` or
    # `--target-host brent@host` still wins. Root login is refused on these
    # boxes, so deploys go through brent + passwordless sudo:
    #   nixos-rebuild switch --flake .#cradle2 \
    #     --target-host brent@cradle2.psynk.ai --sudo
    settings."*.psynk.ai" = {
      User = "brent";
      IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
      IdentitiesOnly = true;
    };
  };
}
