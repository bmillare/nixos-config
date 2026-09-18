# MacBook bootstrap

Standalone Home Manager on Apple Silicon, using the existing Determinate Nix
installation. No nix-darwin configuration is applied. The flake name `macbook`
does not change the macOS hostname.

From this repository on the Mac:

```sh
home-manager switch --flake '.#bmillare@macbook'
```

If Home Manager is not on the shell's PATH yet:

```sh
/nix/var/nix/profiles/default/bin/nix build \
  '.#homeConfigurations."bmillare@macbook".activationPackage'
./result/activate
```

The shared development applications are installed, with browsers left to macOS.
The existing SSH configuration and Git configuration are retained during bootstrap.

Home Manager runs Syncthing as a launchd user agent. The previous native app's
start-at-login setting was already disabled; do not also launch that app. The
existing Syncthing identity is preserved in
`~/Library/Application Support/Syncthing`. A backup of the original configuration,
keys and database is in the sibling `syncthing-before-home-manager-93mh96ee`
directory. Treat both directories as private.

The projects folder is paired with dykestraw using the shared
`modules/home/personal-project-sync.nix` module. After verifying the initial copy,
both machines use Send & Receive: edits and deletions propagate in either
direction. Received changes retain up to
10 old file versions; this does not back up local edits or replace a backup.
The obsolete FluffyRice peer is no longer configured. The old default `~/Sync`
folder is no longer shared; its files are retained.

Ignore rules are installed as regular files during Home Manager activation for
compatibility with 2.1.2 (its symlink bug was fixed in 2.1.3). Change the shared module to
edit the rules on both machines. macOS 13 also needs the host's activation hook
to unload changed launch agents without the unsupported `launchctl --wait` flag.

Syncthing is pinned to 2.1.5 through `packages/syncthing.nix` until the main
nixpkgs pin catches up. The shared folder disables `blockIndexing`: our LAN can
transfer blocks much faster than the receiver's SQLite cross-file block search.
Same-file block reuse and hash verification are retained. Filesystem watching
and fsync remain enabled. Python environments with numbered names (such as
`custom_venv1`) are excluded too; already copied ignored files are not deleted.

Before upgrading from 2.1.2, stopped-service database backups were taken at:

- Mac: `~/Library/Application Support/syncthing-before-2.1.5.yAdhi3`
- Dykestraw: `~/.local/state/syncthing-before-2.1.5.Hsrgbp`

These backups contain private device keys and should stay on their hosts.

Large inactive data was moved from `~/projects/<relative-path>` to
`~/vault/projects/<relative-path>`. No forwarding symlinks were created. Move a
file back to its original path to undo a move, checking first for a new file at
that path. The vault is outside the configured sync folder.

The active Chrome profile at `~/projects/startup/browser_control/tmp` remains in
place and is excluded from sync, along with development environments, Git
metadata and the known credentials directory. Review any additional secrets or
machine-specific files before pairing. Syncthing's GUI is local-only at
<http://127.0.0.1:8384>.
