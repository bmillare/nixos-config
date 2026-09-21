# Installing dykestraw

The custom ISO boots a Surface kernel and includes both this repository and the
prebuilt `dykestraw` system closure. None of the commands below run
automatically.

## Build and write the ISO on crayfish

```console
nix build .#dykestraw-installer --out-link result-dykestraw-installer
ls -lh result-dykestraw-installer/iso/
```

Write the resulting ISO to the USB stick using the full USB block device, not a
partition on it. Confirm its identity and size with `lsblk` immediately before
writing it. Do not assume that it will always have the same `/dev/sdX` name.

## Boot and inspect the Surface

Boot the Surface from USB with Secure Boot disabled. At the live prompt:

```console
sudo -i
lsblk -o NAME,PATH,SIZE,MODEL,TYPE,FSTYPE,MOUNTPOINTS
```

The commands below assume the internal SSD is `/dev/nvme0n1`. Stop if `lsblk`
does not make that identity unambiguous. They permanently erase that disk.

## Partition, encrypt, and format

```console
sgdisk --zap-all /dev/nvme0n1
sgdisk --new=1:1MiB:+1GiB --typecode=1:ef00 --change-name=1:EFI /dev/nvme0n1
sgdisk --new=2:0:0 --typecode=2:8309 --change-name=2:dykestraw-luks /dev/nvme0n1
partprobe /dev/nvme0n1

mkfs.fat -F 32 -n EFI /dev/nvme0n1p1
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

pvcreate /dev/mapper/cryptroot
vgcreate dykestraw /dev/mapper/cryptroot
lvcreate --size 16GiB --name swap dykestraw
lvcreate --extents 100%FREE --name root dykestraw

mkswap --label swap /dev/dykestraw/swap
mkfs.ext4 -L nixos /dev/dykestraw/root
```

## Mount and install

```console
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/EFI /mnt/boot
swapon /dev/disk/by-label/swap

# Preserve a Wi-Fi connection created in the installer with nmtui.
mkdir -p /mnt/etc/NetworkManager/system-connections
cp -a /etc/NetworkManager/system-connections/. \
  /mnt/etc/NetworkManager/system-connections/
chmod 600 /mnt/etc/NetworkManager/system-connections/*

nixos-install --flake /etc/nixos-config#dykestraw --no-root-password
nixos-enter --root /mnt -c 'passwd bmillare'
```

After setting the password, reboot and remove the USB stick. The first boot asks
for the LUKS passphrase. Once networking is connected, verify SSH from crayfish:

```console
ssh bmillare@dykestraw.local
```

If `.local` discovery is not yet available, use the address shown by
`ip address` on dykestraw. Authenticate Tailscale separately with
`sudo tailscale up` after login.

## Routine rebuilds from crayfish

From this repository on crayfish:

```console
nixos-rebuild switch --flake .#dykestraw \
  --target-host bmillare@dykestraw.local \
  --sudo --ask-sudo-password
```

Because the command runs on crayfish, the build happens there and the resulting
closure is copied to dykestraw before activation.

## Touch-only use in Niri

Waybar has three touch controls on the left:

- **Overview** toggles Niri's overview. Tap a window to select it, scroll with
  one finger, or long-press a window to move it.
- **Apps** opens fuzzel. Show the keyboard first if you want to type a search.
- **Keyboard** starts wvkbd on the first tap and toggles its visibility on later
  taps. Its own hide key also works; tap the Waybar button to bring it back.

The keyboard is manual: focusing a text field or detaching the Type Cover does
not automatically show it. It starts on demand and stops with the graphical
session. This is a desktop-session setup; boot-time LUKS entry, console login,
and swaylock unlocking still require a physical keyboard.

The settings live in `hosts/dykestraw/home.nix`. The bar is 48 logical pixels
high, and wvkbd uses a height of 240 in landscape and 300 in portrait. Changing
these does not configure automatic screen rotation.

Apply from dykestraw with `sudo nixos-rebuild switch --flake .#dykestraw` or use
the remote rebuild command above. If the running bar has not refreshed, run
`systemctl --user restart waybar.service`. To troubleshoot the keyboard:

```console
systemctl --user status wvkbd.service
journalctl --user -u wvkbd.service -b
```

Upstream documentation: [wvkbd](https://github.com/jjsullivan5196/wvkbd) and
[Niri overview](https://niri-wm.github.io/niri/Overview.html).
