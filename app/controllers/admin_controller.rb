# frozen_string_literal: true

# Guests share the WLAN with the Pi: everything here needs the admin password (OPTS, photobox.yml overrides it).
class AdminController < ApplicationController
  SESSION_TIMEOUT = 30.minutes
  # photobox-upload.service installs this file (deploy/image)
  UPDATE_FILE = '/var/lib/photobox/upload/photobox-app.tar.zst'

  before_action :require_admin, except: %i[login_form login]
  rate_limit to: 10, within: 3.minutes, only: :login,
             with: -> { redirect_to admin_login_path, alert: _('Too many attempts, wait 3 minutes.') }

  def show
    @gallery = Gallery.active
    @galleries = Gallery.all
    @hotspot = Network.hotspot?
    @devices = @hotspot ? Network.devices : []
    @wlan_ip = Network.ip('wlan0') if @hotspot
    @eth_ip = Network.ip('eth0')
    @disk = Gallery.disk_usage
    @camera = Camera.info
    # written by bin/build-image, missing in development
    @version, @revision = %w[VERSION REVISION].map { |file| Rails.root.join(file).read.strip if Rails.root.join(file).exist? }
    @revision ||= Syscall.execute('git rev-parse --short HEAD').strip
    @updatable = updatable?
  end

  def login_form; end

  def login
    return redirect_to admin_login_path, alert: _('Wrong password') unless PhotoboxConfig.admin_password?(params[:password].to_s)

    reset_session
    session[:admin_until] = SESSION_TIMEOUT.from_now.to_i
    redirect_to admin_path
  end

  def logout
    reset_session
    redirect_to root_path
  end

  def password
    return redirect_to admin_path, alert: _('Wrong old password') unless PhotoboxConfig.admin_password?(params[:old_password].to_s)

    error = save_password
    redirect_to admin_path, error ? { alert: error } : { notice: _('Password changed') }
  end

  # the Pi 3 has no real-time clock, in the hotspot there is no NTP
  def time
    time = Time.zone.parse(params.expect(:time)) || raise(ArgumentError, 'Invalid time')
    Syscall.execute('timedatectl set-ntp false')
    Syscall.execute("timedatectl set-time '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    # admin_until was set with the old clock, a jump forward expires it
    session[:admin_until] = SESSION_TIMEOUT.from_now.to_i
    redirect_to admin_path, notice: format(_('Time set to %{time}'), time: time.strftime('%Y-%m-%d %H:%M'))
  end

  # empty: gphoto2 keeps the setting of the camera
  def imageformat
    PhotoboxConfig.camera_imageformat = params[:imageformat].to_s.strip
    redirect_to admin_path, notice: format(_('Image format: %{format}'), format: OPTS.camera_imageformat.presence || _('camera setting'))
  end

  def caption
    gallery = Gallery.find(params.expect(:id)).rename(params[:caption])
    # the guests see the caption as the gallery title
    Turbo::StreamsChannel.broadcast_refresh_to(:gallery) if gallery == Gallery.active
    redirect_to admin_path, notice: format(_('Gallery renamed to %{caption}'), caption: gallery.caption)
  end

  def create_gallery
    activate(Gallery.create(params[:caption]))
  end

  def activate_gallery
    activate(Gallery.find(params.expect(:id)))
  end

  # the active gallery gets the new sets, it stays
  def destroy_gallery
    gallery = Gallery.find(params.expect(:id))
    return redirect_to admin_path, alert: _('The active gallery cannot be deleted') if gallery == Gallery.active

    label = gallery.caption.presence || gallery.name
    FileUtils.rm_rf(gallery.dir)
    redirect_to admin_path, notice: format(_('Gallery deleted: %{caption}'), caption: label)
  end

  def restart
    Syscall.execute('systemctl reboot')
    redirect_to admin_path, notice: _('Restarting…')
  end

  # photobox-update runs in its own systemd unit, it restarts this app
  def update
    return redirect_to admin_path, alert: _('Updates work on the Photobox image only') unless updatable?

    FileUtils.cp(params.expect(:app).path, UPDATE_FILE)
    Syscall.execute('systemctl start --no-block photobox-upload.service')
    redirect_to admin_path, notice: _('Update started. The app restarts in about 1 minute. ' \
                                      'If the version stays the same, see journalctl -u photobox-upload.')
  end

  def wifi_sign; end

  private

  def require_admin
    return redirect_to admin_login_path unless session[:admin_until].to_i > Time.now.to_i

    session[:admin_until] = SESSION_TIMEOUT.from_now.to_i
  end

  # returns an error message, or nil when the new password is saved
  def save_password
    password = params[:new_password].to_s
    return _('The passwords do not match') unless password == params[:password_repeat].to_s
    return _('The password needs at least 8 characters') if password.length < 8

    PhotoboxConfig.admin_password = password
    nil
  end

  # setup-chroot.sh creates the upload directory, it does not exist in development
  def updatable?
    File.directory?(File.dirname(UPDATE_FILE))
  end

  def activate(gallery)
    gallery.activate!
    Turbo::StreamsChannel.broadcast_refresh_to(:gallery)
    redirect_to admin_path, notice: format(_('Active gallery: %{caption}'), caption: gallery.caption.presence || gallery.name)
  end
end
