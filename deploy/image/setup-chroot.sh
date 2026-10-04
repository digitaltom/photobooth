#!/bin/bash
# Runs inside the chroot of the Raspberry Pi OS image, called by bin/build-image.
# The app source is already in /var/lib/photobox/releases/<version> (data partition).
set -euxo pipefail

ver=$1
app=/var/lib/photobox/releases/$ver
export DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 APT_LISTCHANGES_FRONTEND=none BUNDLE_SILENCE_ROOT_WARNING=1
rm -f /var/lib/man-db/auto-update  # no man-db index rebuild on each apt run (slow under qemu)

runtime_pkgs=(gphoto2 imagemagick gpiod libyaml-0-2 network-manager avahi-daemon openssh-server
              nftables overlayroot cloud-guest-utils zstd curl iw rfkill polkitd
              dnsmasq-base wpasupplicant)  # NetworkManager only recommends them, the hotspot needs both
build_pkgs=(build-essential libssl-dev libyaml-dev libffi-dev zlib1g-dev)
# /mnt is the build cache (tmp/image/cache), bind-mounted by bin/build-image.
# Old Ruby versions pile up there, delete tmp/image/cache by hand
mkdir -p /mnt/apt/partial
apt-get update
apt-get -o Dir::Cache::Archives=/mnt/apt full-upgrade -y
apt-get -o Dir::Cache::Archives=/mnt/apt install -y --no-install-recommends "${runtime_pkgs[@]}" "${build_pkgs[@]}"

# Ruby lives in the release, so an app update (photobox-update) can also update Ruby
ruby_ver=$(cat "$app/.ruby-version")
if [ ! -d "/mnt/ruby-$ruby_ver" ]; then
  curl -fsSL https://github.com/rbenv/ruby-build/archive/refs/heads/master.tar.gz | tar -xz -C /tmp
  RUBY_CONFIGURE_OPTS="--enable-load-relative --disable-install-doc" \
    /tmp/ruby-build-master/bin/ruby-build "$ruby_ver" "/mnt/ruby-$ruby_ver"
  rm -rf /tmp/ruby-build-master
fi
cp -a "/mnt/ruby-$ruby_ver" "$app/vendor/ruby"
export PATH=$app/vendor/ruby/bin:$PATH
cd "$app"
# one cache per Ruby version: a changed Gemfile.lock only installs the changed gems
bundle_cache=/mnt/bundle-$ruby_ver
[ ! -d "$bundle_cache" ] || cp -a "$bundle_cache" vendor/bundle
bundle config set --local deployment true
bundle config set --local without 'development test'
bundle install --jobs "$(nproc)"
bundle clean
rm -rf "$bundle_cache"
cp -a vendor/bundle "$bundle_cache"
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile
rm -rf "$app/tmp/cache"

apt-get purge -y --auto-remove "${build_pkgs[@]}"
apt-get clean

id photobox || useradd --system --create-home --groups plugdev,gpio,video photobox
chown -R photobox:photobox "$app"
# the admin menu saves an uploaded app release here, photobox-upload.service installs it
install -d -o photobox -g photobox /var/lib/photobox/upload
ln -sfn "releases/$ver" /var/lib/photobox/current

cp "$app/deploy/photobox.service" /etc/systemd/system/
cp "$app/deploy/polkit-photobox.rules" /etc/polkit-1/rules.d/50-photobox.rules
# the admin menu writes the admin password into photobox.yml on the boot partition (FAT has no owners)
sed -i -E "s#^(\S+\s+/boot/firmware\s+vfat\s+)defaults#\1defaults,gid=$(id -g photobox),fmask=0113,dmask=0002#" /etc/fstab
grep -q "/boot/firmware.*gid=$(id -g photobox)" /etc/fstab
mkdir -p /etc/nftables.d
cp "$app/deploy/photobox.nft" /etc/nftables.d/
printf '#!/usr/sbin/nft -f\ninclude "/etc/nftables.d/*.nft"\n' > /etc/nftables.conf

# Captive portal: the hotspot DNS answers all names with the Pi, Rails redirects unknown paths to the gallery
mkdir -p /etc/NetworkManager/dnsmasq-shared.d
echo 'address=/#/10.42.0.1' > /etc/NetworkManager/dnsmasq-shared.d/photobox.conf
# Raspberry Pi OS ships NetworkManager with WLAN disabled (it then soft-blocks wlan0 via rfkill).
# "nmcli radio wifi on" at boot does not stick, so fix the state file in the image.
sed -i 's/^WirelessEnabled=false/WirelessEnabled=true/' /var/lib/NetworkManager/NetworkManager.state
grep -q '^WirelessEnabled=true' /var/lib/NetworkManager/NetworkManager.state
# The admin page reads the device names from the dnsmasq leases in this 0700 folder, as user photobox.
# Search permission only: no listing, the files in it keep their own modes (secret_key is 0600).
chmod 711 /var/lib/NetworkManager

echo 'PermitRootLogin yes' > /etc/ssh/sshd_config.d/photobox.conf
rm -f /etc/ssh/ssh_host_*  # photobox-firstboot creates them, so every Pi has its own

echo photobox > /etc/hostname
sed -i 's/raspberrypi/photobox/g' /etc/hosts

systemctl disable userconfig.service || true  # asks for a user on the console, root login is set by photobox-network
systemctl enable ssh NetworkManager avahi-daemon nftables photobox photobox-network photobox-firstboot
