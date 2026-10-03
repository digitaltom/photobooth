# Raspberry Pi image

This folder holds the files for the Photobox SD card image and for a [manual install](#manual-install).
For the app development, see [DEVELOPMENT.md](../DEVELOPMENT.md).

## Install the image

Each release `v*` has a ready SD card image for the Raspberry Pi 3 or newer (Raspberry Pi OS Lite, 64-bit).

1. Download `photobox-<version>.img.xz` from the [releases](https://github.com/digitaltom/photobooth/releases).
2. Write it to the SD card with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) ("Use custom"). Do not use the OS customization of the Imager.
   Alternative: `xzcat photobox-<version>.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress`
3. Optional: edit `photobox.yml` on the boot partition of the SD card (WLAN name, passwords, SSH key).
4. Boot the Pi. The first boot reboots once.
5. Connect to the WLAN `Photobox` (password `photobox`). Open `http://10.42.0.1/kiosk`, or log in with `ssh root@10.42.0.1` (password `photobox`).

Change both passwords in `photobox.yml` before an event. The guests share the WLAN with the Pi.

Emergency access: connect an Ethernet cable to the laptop, then `ssh root@photobox.local`.

The root file system is read-only, so a power loss cannot damage it. To update the app over the network, use `photobox-update latest`. To update the OS, flash a new image.

## Files

| File | Purpose |
| --- | --- |
| `photobox.service` | systemd service: Puma and the Solid Queue jobs in one process |
| `photobox.nft` | nftables rule: port 80 to Puma on port 3000 |
| `image/setup-chroot.sh` | runs in the image chroot: packages, Ruby, gems, services |
| `image/photobox.yml` | default settings on the boot partition |
| `image/photobox-network` | applies `photobox.yml` at each boot: hotspot, root password, SSH key |
| `image/photobox-firstboot` | runs once on the first boot |
| `image/photobox-update` | installs or switches the app release |

## Build

`bin/build-image` builds the image. It asks for sudo, because it uses a loop device.

```sh
bin/build-image            # version from git describe
bin/build-image v1.2       # explicit version
XZ=1 bin/build-image       # release build: .img.xz and photobox-os-list.json
```

Flash a raw image with `sudo dd if=tmp/image/photobox-<version>.img of=/dev/sdX bs=4M conv=fsync status=progress`.

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

### Local build

On an arm64 computer, the build runs natively. On x86_64, the chroot needs the qemu binfmt for arm64 with the `F` flag:

- openSUSE: `sudo zypper in qemu-linux-user`
- Debian, Ubuntu: `sudo apt-get install qemu-user-static binfmt-support`

Then check that `/proc/sys/fs/binfmt_misc/qemu-aarch64` exists. Ruby compiles in QEMU, so a local build takes more than one hour.

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
| `/var/lib/photobox/current` | 3 | link to the active release. `photobox-update` changes it. |
| `/opt/photobox` | 2 | link to `/var/lib/photobox/current`. `photobox.service` uses this path, so the service file is the same for the image and for a [manual install](#manual-install). |
| `/var/lib/photobox/photobox.env` | 3 | `SECRET_KEY_BASE` and `PHOTOBOX_STORAGE`, written by `photobox-firstboot` |
| `/var/lib/photobox/sets/` | 3 | the photos (gallery), see below |
| `/run/photobox/` | RAM | the SQLite databases (`PHOTOBOX_DB_DIR`). They hold only volatile data. `db:prepare` creates them again at each start. |
| `/usr/local/sbin/photobox-*` | 2 | the scripts of the image |
| logs | RAM | the app writes to the journal (`journalctl -u photobox`). The journal is in the RAM overlay, so it is lost at reboot. |

Put files that must stay on the data partition, or in `photobox.yml`.

### Gallery images

The app stores each picture set in its own folder in `PHOTOBOX_STORAGE`. On the image, this is `/var/lib/photobox/sets/` on the data partition. The folder name is the date and time of the photo:

```
/var/lib/photobox/sets/2026-10-03_14-05-12/
  2026-10-03_14-05-12_1.jpg ... _4.jpg                    the 4 photos of the camera
  2026-10-03_14-05-12_1_polaroid.png ... _4_polaroid.png  the polaroid images
  2026-10-03_14-05-12_animation.gif                       the animation
```

The gallery shows each folder that has an `_animation.gif` file. The app reads the folders at each request. A database is not necessary, so the photos stay after a reboot and after an app update.

On a manual install, the sets are in `storage/sets` in the app folder. To use another folder, set `PHOTOBOX_STORAGE` or `storage_path` in the options.

To copy the photos to the laptop, use this command:

```sh
scp -r root@10.42.0.1:/var/lib/photobox/sets .
```

### First boot

`photobox-firstboot` runs once, then it reboots the Pi:

1. Create the SSH host keys, so that every Pi has its own keys.
2. Write `SECRET_KEY_BASE` and `PHOTOBOX_STORAGE=/var/lib/photobox/sets` to `/var/lib/photobox/photobox.env`.
3. Grow the data partition to the size of the SD card.
4. Add `overlayroot=tmpfs:recurse=0` to `cmdline.txt`. This makes the root file system read-only from the next boot. `recurse=0` keeps the data partition writable.

### Each boot

`photobox-network` reads `/boot/firmware/photobox.yml` and does these steps:

1. Set the root password.
2. If `ssh_authorized_key` is set, write it to `/root/.ssh/authorized_keys`.
3. Unblock the WLAN and set the WLAN country.
4. Create the NetworkManager hotspot `photobox` (address `10.42.0.1`). An empty `wifi_password` makes an open WLAN.

`photobox.yml` has flat `key: value` lines only. Put values that contain ` #` in quotes.

## Updates

The app and Ruby are in the release folder on the data partition. An app update does not change the root file system.

```sh
photobox-update latest                    # latest GitHub release, needs internet
photobox-update /tmp/photobox-app.tar.zst # file from the laptop (scp it with its .sha256 file)
photobox-update list                      # installed releases, * = current
photobox-update use <version>             # switch back (rollback)
```

`photobox-update` keeps the 3 newest releases.

To update the OS, flash a new image. Do not flash before you copy the photos. A new image deletes all data on the SD card. If you need them, copy `photobox.yml` and the sets in `/var/lib/photobox/sets` first.

## Manual install

Use this only if you do not use the image, for example on another Linux server. Start with Raspberry Pi OS Lite or another Debian-based system.

1. Create the app user: `sudo useradd --system --create-home --groups plugdev,gpio photobox`
2. Clone the repo to `/opt/photobox` and give it to the user: `sudo chown -R photobox /opt/photobox`
3. Install Ruby (version in `.ruby-version`), for example with [rbenv](https://github.com/rbenv/rbenv).
4. Install the packages: `sudo apt-get install gphoto2 imagemagick gpiod libsqlite3-dev`
5. As the `photobox` user, in `/opt/photobox`, run these commands:
   - `bundle install`
   - `echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" > config/photobox.env`
   - `RAILS_ENV=production bin/rails assets:precompile`
6. Install the service:
   - `sudo cp deploy/photobox.service /etc/systemd/system/`
   - `sudo systemctl enable --now photobox`
7. Redirect port 80 to Puma on port 3000:
   - `sudo cp deploy/photobox.nft /etc/nftables.d/` (or include it from `/etc/nftables.conf`)
   - `sudo nft -f deploy/photobox.nft`
8. Optional: `cp config/options.yml config/options-local.yml`, then set your options in `config/options-local.yml`.

The service runs Puma and the Solid Queue jobs in one process. The queue and cable databases are in `/run/photobox` (RAM), because they only hold volatile data.

The picture sets are in `storage/sets`. To use another folder, set `PHOTOBOX_STORAGE` or `storage_path`.

To make a hotspot like the one of the image (address `10.42.0.1`), use this command:

```sh
nmcli con add type wifi ifname wlan0 con-name photobox autoconnect yes \
  ssid Photobox mode ap 802-11-wireless.band bg ipv4.method shared \
  wifi-sec.key-mgmt wpa-psk wifi-sec.psk "<password>"
```

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

On the image, put the font on the data partition, for example `/var/lib/photobox/fonts/simplicity.ttf`. Then set the absolute path in `/opt/photobox/config/options-local.yml`:

```yaml
default:
  font: '/var/lib/photobox/fonts/simplicity.ttf'
```

`options-local.yml` is part of the release folder. Set it again after each app update.
