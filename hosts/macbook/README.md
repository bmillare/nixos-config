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
SSH aliases are managed by `modules/home/personal-ssh.nix`, shared with Dykestraw.
Private keys remain outside Nix: `~/.ssh/id_ed25519` (personal),
`~/.ssh/brent_spynk_ai_ed25519_key` (work), and `~/.ssh/test_keypari1.pem`
(legacy hosts). On this Mac, the latter two are symlinks to the existing keys.
`github.com` retains the shared work identity; `github.com_personal` uses the
personal identity. Dykestraw uses its current LAN IP until stable DNS or a
DHCP reservation is configured.

The initial SSH migration applied only the generated SSH file. The subsequent
Emacs migration activated the full Mac Home Manager configuration, which now
owns `~/.ssh/config` and the Emacs startup files. To build an SSH-only update
for inspection from this repository:

```sh
nix build --out-link "$HOME/.local/state/nix/ssh-config/current" \
  'path:.#homeConfigurations."bmillare@macbook".config.home.file.".ssh/config".source'
```

Both personal clients use `macbook` and `dykestraw` aliases and exactly the
same authorization list: `modules/ssh-keys/personal-authorized-keys`.
This is the deduplicated union of their previous keys (four public keys).
`personal-ssh.nix` installs it on both machines; Dykestraw also references the
same list through NixOS `authorizedKeys.keyFiles`. Private keys stay outside Nix.

Home Manager installs the shared authorization list as a regular mode-600 file
using `personalAuthorizedKeys`, because sshd rejected the Nix-store symlink.
To refresh only that file without activating unrelated Home Manager changes:

```sh
nix build --out-link "$HOME/.local/state/nix/ssh-config/authorized-keys" \
  'path:.#homeConfigurations."bmillare@macbook".config.home.file.".ssh/authorized_keys.source".source'
install -m 600 "$HOME/.local/state/nix/ssh-config/authorized-keys" "$HOME/.ssh/.authorized_keys.hm-new"
mv -f "$HOME/.ssh/.authorized_keys.hm-new" "$HOME/.ssh/authorized_keys"
```

The original manual config is backed up as
`~/.ssh/config.before-home-manager-20261109-092533`. Home Manager now manages both SSH and Emacs. The old Mac init is preserved
in `modules/home/emacs/archived.el` and is not loaded. Restart Emacs after
activation to pick up the shared configuration.
 Home Manager manages Git configuration,
including the shared `bmillare` identity (Brent Millare, brent.millare@gmail.com).
Back up an existing Git configuration before activation; carry over any local
settings you still need. GitHub CLI credential-helper integration remains disabled.

Home Manager runs Syncthing as a launchd user agent. The previous native app's
start-at-login setting was already disabled; do not also launch that app. The
existing Syncthing identity is preserved in
`~/Library/Application Support/Syncthing`. A backup of the original configuration,
keys and database is in the sibling `syncthing-before-home-manager-93mh96ee`
directory. Treat both directories as private.

The projects folder is paired with dykestraw using the shared
`modules/home/personal-project-sync.nix` module. After verifying the initial copy,
both machines use Send & Receive for non-repository files: edits and deletions
propagate in either direction. Git working trees are excluded on both peers. Received changes retain up to
2 old file versions per file for at most 30 days, with hourly cleanup.
This bounds count and age, not total bytes, and does not back up local edits.
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
`custom_venv1`) are excluded too. The verified generated directory
`/llama_cpp/llama.cpp/build` is excluded explicitly; other build directories,
source, documentation, and assets remain included. Already copied ignored
files are not deleted.

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

## Git repositories and Syncthing

`modules/home/project-repositories.stignore` lists existing Git working trees
relative to `~/projects`. Home Manager installs these exclusions on both personal
machines. Git metadata and working files stay local; use Git to transfer changes.
The legacy repository rooted at `~/projects` is a special case: only its three
tracked notes are excluded individually, so unrelated documents still sync.
If that repository starts tracking more files, add those paths to the exclusions.

The November 2026 migration restored missing `.git` directories on dykestraw from
Mac metadata snapshots, including existing local-only history, refs, staged changes,
and shallow-clone boundaries. Existing working files were preserved. Snapshots and
validation records are under `~/.local/state/git-sync-migration-20261109` on each
machine. These snapshots may contain private repository history; keep them local.

For repositories with a hosted origin, commit and push on the machine where you
edit, then pull on the other machine after checking its working tree is clean.
Uncommitted edits and untracked files inside excluded repositories no longer follow
you automatically. Commit files that you need on both machines.

Local-only repositories have direct peer remotes: `dykestraw` on Mac and `macbook`
on dykestraw. Until a bare-repository host is provisioned, commit on the source,
then fetch and merge on the destination. For example, to bring Mac's `bm_tools`
changes to dykestraw, after committing them on Mac:

```sh
cd ~/projects/bm_tools
git status
git fetch macbook
git merge --ff-only macbook/master
```

Use the repository's actual branch name. Resolve local work or divergence before
merging. Do not push directly into another machine's checked-out branch. No
blacksheep hosting was provisioned by this migration.

Prefer `~/repos` (outside Syncthing) for new clones and new repositories, cloning
separately on each machine. If a new repository must live under `~/projects`, add
its root-relative path to `project-repositories.stignore` and activate the ignore
rules on BOTH machines before cloning or initializing it. Syncthing does not
infer working-tree exclusions from the presence of a `.git` directory.
Since `nixos-config` itself is now excluded, distribute configuration changes with
Git and activate Home Manager independently on each machine.
