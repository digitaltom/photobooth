# Raspberry Pi image

This folder holds the files for the Photobox SD card image for Raspberry Pi.
For the app development, see [DEVELOPMENT.md](../DEVELOPMENT.md).

## Install the image

Each release `v*` has a ready SD card image for the Raspberry Pi 3 or newer (Raspberry Pi OS Lite, 64-bit).

1. Download `photobox-<version>.img.xz` from the [releases](https://github.com/digitaltom/photobooth/releases).
2. Write it to the SD card with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) ("Use custom"). Do not use the OS customization of the Imager.
   Alternative: `test -b /dev/sdX && xzcat photobox-<version>.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync,nocreat status=progress`. If `/dev/sdX` is not a block device (for example, a regular file from an earlier `dd`), the command does nothing.
3. Optional: edit `photobox.yml` on the boot partition of the SD card (WLAN name, passwords, SSH key).
4. Boot the Pi. The first boot reboots once.
5. Connect to the open WLAN `Photobox`. Open `http://10.42.0.1/?kiosk=1`, or log in with `ssh root@10.42.0.1` (password `photobox`).

Change the root password in `photobox.yml` before an event and reboot.

Emergency access: connect an Ethernet cable to the laptop, then `ssh root@photobox.local`.

The root file system is read-only, so a power loss cannot damage it. To update the app over the network, use `photobox-update latest`. To update the OS, flash a new image.

## Files

| File | Purpose |
| --- | --- |
| `photobox.service` | systemd service: Puma and the Solid Queue jobs in one process |
| `polkit-photobox.rules` | lets the app set the time, shut down, restart and start the app update (admin menu) |
| `photobox.nft` | nftables rule: port 80 to Puma on port 3000 |
| `image/setup-chroot.sh` | runs in the image chroot: packages, Ruby, gems, services |
| `image/photobox.yml` | default settings on the boot partition |
| `image/photobox-network` | applies `photobox.yml` at each boot: hotspot, root password, SSH key |
| `image/photobox-firstboot` | runs once on the first boot |
| `image/photobox-update` | installs or switches the app release |
| `image/photobox-upload.service` | runs `photobox-update` for an app release from the admin menu |

## Build

`bin/build-image` builds the image. It asks for sudo, because it uses a loop device.

On an arm64 computer, the build runs natively. On x86_64, the chroot needs the qemu binfmt for arm64 with the `F` flag:

- openSUSE: `sudo zypper in qemu-linux-user`
- Debian, Ubuntu: `sudo apt-get install qemu-user-static binfmt-support`

Then check that `/proc/sys/fs/binfmt_misc/qemu-aarch64` exists. Ruby compiles in QEMU, so the first build on x86_64 takes more than one hour. If `tmp/image/cache/` has Ruby, the gems and the apt packages, a build takes about 10 minutes.

```sh
bin/build-image            # version from git describe
bin/build-image v1.2       # explicit version
XZ=1 bin/build-image       # release build: .img.xz and photobox-os-list.json
```

`tmp/image/cache/` keeps Ruby, the gems and the apt packages for the next build. To do a clean build, delete this directory.

The output is in `tmp/image/`:

- `photobox-<version>.img`: the SD card image. With `XZ=1`, it is `photobox-<version>.img.xz`.
- `photobox-app.tar.zst`: the app release for `photobox-update`
- `photobox-os-list.json`: the repository file for Raspberry Pi Imager (`rpi-imager --repo <url>`), with `XZ=1` only
- a `.sha256` file for the app release, and with `XZ=1` also for the image

The build does these steps:

1. Download the latest Raspberry Pi OS Lite (arm64) and check its sha256. The download stays in `tmp/image/` as a cache. To use another base image, set `BASE_URL`.
2. Make the image larger. The root partition gets 512 MB more (it is read-only after the first boot). A new data partition (1 GB, ext4, label `photobox-data`) comes after it.
3. Mount the partitions with a loop device. Copy the tracked files of the repo (without `spec/`) into `/var/lib/photobox/releases/<version>`. Uncommitted changes to tracked files are included.
4. Install the scripts, the services and the default `photobox.yml`. Add the data partition to `/etc/fstab`. Remove the resize step of Raspberry Pi OS from `cmdline.txt`, because it can only grow the last partition.
5. Run `image/setup-chroot.sh` in a chroot:
   - Install the security updates and the packages.
   - Compile Ruby (version from `.ruby-version`) with ruby-build into `<release>/vendor/ruby`.
   - Run `bundle install` (without development and test) and `assets:precompile`.
   - Remove the build packages again.
   - Create the user `photobox` and enable the services. Allow the SSH login for root.
6. Pack the release as `photobox-app.tar.zst`, zero the free blocks (`fstrim`). With `XZ=1`, compress the image with xz.

To look into an image without a flash, mount it with a loop device:

```sh
loop=$(sudo losetup -P --find --show tmp/image/photobox-<version>.img)
sudo mount ${loop}p1 /mnt      # boot partition, for example /mnt/photobox.yml
sudo umount /mnt
sudo losetup -d $loop
```

Use `p2` for the root partition and `p3` for the data partition.

Flash a raw image with `test -b /dev/sdX && sudo dd if=tmp/image/photobox-<version>.img of=/dev/sdX bs=4M conv=fsync,nocreat status=progress`. If `/dev/sdX` is not a block device, the command does nothing.

To verify the SD card before the first boot, run `sudo cmp tmp/image/photobox-<version>.img /dev/sdX`. If the output is only `cmp: EOF on tmp/image/photobox-<version>.img`, the card is correct. To show the version on the card, mount partition 3 and run `readlink <mountpoint>/current`.


### CI build

`.github/workflows/image.yml` runs the tests, then `bin/build-image` on the `ubuntu-24.04-arm` runner. The build takes some minutes there.

- Push a tag `v*`: the workflow creates a GitHub release with the image, the app release and the Imager JSON.
- Start the workflow manually: the workflow uploads the image as a workflow artifact. It creates no release.

## The image

### Partitions

The SD card has three partitions:

| Partition | Size | Mount point | Writable | Content |
| --- | --- | --- | --- | --- |
| 1, FAT, label `bootfs` | 512 MB | `/boot/firmware` | yes | firmware, kernel, `cmdline.txt`, `photobox.yml` |
| 2, ext4, label `rootfs` | about 2.8 GB | `/` | no, after the first boot | Raspberry Pi OS and the packages |
| 3, ext4, label `photobox-data` | 1 GB, then the rest of the SD card | `/var/lib/photobox` | yes | app releases, settings, photos |

The boot partition uses FAT, so you can edit `photobox.yml` on any computer.

The root partition is read-only. `overlayroot` puts a layer in RAM (tmpfs) on top of it. Programs can write to `/`, but the changes stay in RAM only. All changes are lost at reboot. Thus, a power loss cannot damage the OS.

The data partition is the only partition that keeps changes. `photobox-firstboot` grows it to the size of the SD card. The data partition is the last partition, so it can grow.

### File system locations

| Path | Partition | Content |
| --- | --- | --- |
| `/boot/firmware/photobox.yml` | 1 | WLAN, passwords and SSH key, read at each boot |
| `/var/lib/photobox/releases/<version>/` | 3 | one app release: the app code, Ruby (`vendor/ruby`), the gems (`vendor/bundle`), the compiled assets |
| `/var/lib/photobox/current` | 3 | link to the active release. `photobox-update` changes it. `photobox.service` uses this path. |
| `/var/lib/photobox/photobox.env` | 3 | `SECRET_KEY_BASE` and `PHOTOBOX_STORAGE`, written by `photobox-firstboot` |
| `/var/lib/photobox/galleries/` | 3 | the photos (gallery), see below |
| `/usr/local/sbin/photobox-*` | 2 | the scripts of the image |
| logs | RAM | the app writes to the journal (`journalctl -u photobox`). The journal is in the RAM overlay, so it is lost at reboot. |

Put files that must stay on the data partition, or in `photobox.yml`.

### Gallery images

The app stores each gallery in its own folder in `PHOTOBOX_STORAGE`. On the image, this is `/var/lib/photobox/galleries/` on the data partition. The name of a gallery folder is the caption. If you change the caption in the admin menu, the folder gets the new name. The file `event.yml` in the gallery folder has the caption and the creation time. Each picture set has its own folder in the gallery folder. The name of this folder is the date and time of the photo:

```
/var/lib/photobox/galleries/freya-wird-50/2026-10-03_14-05-12/
  2026-10-03_14-05-12_1.jpg ... _4.jpg                    the 4 photos of the camera
  2026-10-03_14-05-12_1_polaroid.png ... _4_polaroid.png  the polaroid images
  2026-10-03_14-05-12_animation.gif                       the animation
```

The gallery shows each folder that has an `_animation.gif` file. The app reads the folders at each request. A database is not necessary, so the photos stay after a reboot and after an app update.

To copy the photos to the laptop, use this command:

```sh
scp -r root@10.42.0.1:/var/lib/photobox/galleries .
```

### First boot

`photobox-firstboot` runs once, then it reboots the Pi:

1. Create the SSH host keys, so that every Pi has its own keys.
2. Write `SECRET_KEY_BASE` and `PHOTOBOX_STORAGE=/var/lib/photobox/galleries` to `/var/lib/photobox/photobox.env`.
3. Grow the data partition to the size of the SD card.
4. Add `overlayroot=tmpfs:recurse=0` to `cmdline.txt`. This makes the root file system read-only from the next boot. `recurse=0` keeps the data partition writable.

On a Raspberry Pi 3, the first boot takes about 1–2 minutes longer than a normal boot.

### Each boot

`photobox-network` reads `/boot/firmware/photobox.yml` and does these steps:

1. Set the root password.
2. If `ssh_authorized_key` is set, write it to `/root/.ssh/authorized_keys`.
3. Unblock the WLAN and set the WLAN country.
4. Create the NetworkManager hotspot `photobox` (address `10.42.0.1`). The WLAN is open by default. To use WPA2, set `wifi_password`.

The hotspot is a captive portal. Its DNS answers all names with `10.42.0.1`, so phones open the gallery when they connect. Guests on the hotspot have no internet access, also when `eth0` has a connection.

## Updates

The app and Ruby are in the release folder on the data partition. An app update does not change the root file system.

```sh
photobox-update latest                    # latest GitHub release, needs internet
photobox-update /tmp/photobox-app.tar.zst # file from the laptop (scp it with its .sha256 file)
photobox-update list                      # installed releases, * = current
photobox-update use <version>             # switch back (rollback)
```

`photobox-update` keeps the 3 newest releases.

You can also upload `photobox-app.tar.zst` in the admin menu (System). The app saves the file in `/var/lib/photobox/upload/`. Then it starts `photobox-upload.service`, which runs `photobox-update` as root. The admin menu shows the version and the commit of the current release. If the version does not change after the upload, run `journalctl -u photobox-upload`. The upload does not check a `.sha256` file.

To update the OS, flash a new image. Do not flash before you copy the photos. A new image deletes all data on the SD card. If you need them, copy `photobox.yml` and the sets in `/var/lib/photobox/galleries` first.

## Useful commands on the Pi

Service and logs:

```sh
systemctl status photobox
journalctl -u photobox -f
journalctl -u photobox-network -u photobox-firstboot
```

Network (NetworkManager):

```sh
nmcli dev status                          # state of the network devices
nmcli con show                            # all connections
nmcli dev wifi list                       # WLANs in range
nmcli -f autoconnect-priority,name con    # priority of the connections
nmcli con mod <name> conn.autoconnect-p 10
```

The connection files are in `/etc/NetworkManager/system-connections`. On the image they are in the RAM overlay, so they are lost at reboot. `photobox-network` creates the hotspot again at each boot. If you change a file manually, run `systemctl restart NetworkManager`.

Make the root file system writable: on the laptop, remove `overlayroot=tmpfs:recurse=0` from `cmdline.txt` on the boot partition. Add it again when you are done.

## Fonts

For the font settings, see [DEVELOPMENT.md](../DEVELOPMENT.md#fonts).

On the image, put the font on the data partition, for example `/var/lib/photobox/fonts/simplicity.ttf`. Then set the absolute path in `/var/lib/photobox/current/config/options-local.yml`:

```yaml
default:
  font: '/var/lib/photobox/fonts/simplicity.ttf'
```

`options-local.yml` is part of the release folder. Set it again after each app update.
