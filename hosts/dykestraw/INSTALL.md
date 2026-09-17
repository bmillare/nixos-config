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
