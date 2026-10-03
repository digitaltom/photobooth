#!/bin/bash
# Runs inside the chroot of the Raspberry Pi OS image, called by bin/build-image.
# The app source is already in /var/lib/photobox/releases/<version> (data partition).
set -euxo pipefail

ver=$1
app=/var/lib/photobox/releases/$ver
export DEBIAN_FRONTEND=noninteractive

runtime_pkgs=(gphoto2 imagemagick gpiod sqlite3 libyaml-0-2 network-manager avahi-daemon openssh-server
              nftables overlayroot cloud-guest-utils zstd curl iw rfkill
              dnsmasq-base wpasupplicant)  # NetworkManager only recommends them, the hotspot needs both
build_pkgs=(build-essential git libssl-dev libyaml-dev libffi-dev zlib1g-dev libsqlite3-dev)
# /mnt is the build cache (tmp/image/cache), bind-mounted by bin/build-image.
# ponytail: old Ruby and bundle versions pile up there, delete tmp/image/cache by hand
mkdir -p /mnt/apt/partial
apt-get update
apt-get -o Dir::Cache::Archives=/mnt/apt install -y --no-install-recommends "${runtime_pkgs[@]}" "${build_pkgs[@]}"

# Ruby lives in the release, so an app update (photobox-update) can also update Ruby
ruby_ver=$(cat "$app/.ruby-version")
if [ ! -d "/mnt/ruby-$ruby_ver" ]; then
  git clone --depth 1 https://github.com/rbenv/ruby-build /tmp/ruby-build
  RUBY_CONFIGURE_OPTS="--enable-load-relative --disable-install-doc" \
    /tmp/ruby-build/bin/ruby-build "$ruby_ver" "/mnt/ruby-$ruby_ver"
  rm -rf /tmp/ruby-build
fi
cp -a "/mnt/ruby-$ruby_ver" "$app/vendor/ruby"
export PATH=$app/vendor/ruby/bin:$PATH
cd "$app"
bundle_cache=/mnt/bundle-$ruby_ver-$(sha256sum Gemfile.lock | cut -c1-16)
[ ! -d "$bundle_cache" ] || cp -a "$bundle_cache" vendor/bundle
bundle config set --local deployment true
bundle config set --local without 'development test'
bundle install --jobs "$(nproc)"
[ -d "$bundle_cache" ] || cp -a vendor/bundle "$bundle_cache"
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile
rm -rf "$app/tmp/cache"

apt-get purge -y --auto-remove "${build_pkgs[@]}"
apt-get clean

id photobox || useradd --system --create-home --groups plugdev,gpio,video photobox
chown -R photobox:photobox "$app"
ln -sfn "releases/$ver" /var/lib/photobox/current
ln -sfn /var/lib/photobox/current /opt/photobox

cp "$app/deploy/photobox.service" /etc/systemd/system/
mkdir -p /etc/nftables.d
cp "$app/deploy/photobox.nft" /etc/nftables.d/
printf '#!/usr/sbin/nft -f\ninclude "/etc/nftables.d/*.nft"\n' > /etc/nftables.conf

echo 'PermitRootLogin yes' > /etc/ssh/sshd_config.d/photobox.conf
rm -f /etc/ssh/ssh_host_*  # photobox-firstboot creates them, so every Pi has its own

echo photobox > /etc/hostname
sed -i 's/raspberrypi/photobox/g' /etc/hosts

systemctl disable userconfig.service || true  # asks for a user on the console, root login is set by photobox-network
systemctl enable ssh NetworkManager avahi-daemon nftables photobox photobox-network photobox-firstboot
