# frozen_string_literal: true

# Guests share the WLAN with the Pi: everything here needs the admin password (OPTS, photobox.yml overrides it).
class AdminController < ApplicationController
  SESSION_TIMEOUT = 30.minutes
  POWER_COMMANDS = %w[poweroff reboot].freeze

  before_action :require_admin, except: %i[login_form login]
  rate_limit to: 10, within: 3.minutes, only: :login,
             with: -> { redirect_to admin_login_path, alert: 'Too many attempts, wait 3 minutes.' }

  def show
    @gallery = Gallery.active
    @galleries = Gallery.all
    @devices = Network.devices
    @disk = Gallery.disk_usage
  end

  def login_form; end

  def login
    return redirect_to admin_login_path, alert: 'Wrong password' unless PhotoboxConfig.admin_password?(params[:password].to_s)

    reset_session
    session[:admin_until] = SESSION_TIMEOUT.from_now.to_i
    redirect_to admin_path
  end

  def logout
    reset_session
    redirect_to root_path
  end

  def password
    return redirect_to admin_path, alert: 'Wrong old password' unless PhotoboxConfig.admin_password?(params[:old_password].to_s)

    error = save_password
    redirect_to admin_path, error ? { alert: error } : { notice: 'Password changed' }
  end

  # the Pi 3 has no real-time clock, in the hotspot there is no NTP
  def time
    time = Time.zone.parse(params.expect(:time)) || raise(ArgumentError, 'Invalid time')
    Syscall.execute('timedatectl set-ntp false')
    Syscall.execute("timedatectl set-time '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    redirect_to admin_path, notice: "Time set to #{time.strftime('%Y-%m-%d %H:%M')}"
  end

  def caption
    Gallery.active.caption = params[:caption]
    redirect_to admin_path, notice: 'Caption saved, it applies to new sets'
  end

  def create_gallery
    activate(Gallery.create(params[:caption]))
  end

  def activate_gallery
    activate(Gallery.find(params.expect(:id)))
  end

  def power
    command = params.expect(:command)
    return head :bad_request unless POWER_COMMANDS.include?(command)

    Syscall.execute("systemctl #{command}")
    redirect_to admin_path, notice: command == 'reboot' ? 'Restarting…' : 'Shutting down…'
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
    return 'The passwords do not match' unless password == params[:password_repeat].to_s
    return 'The password needs at least 8 characters' if password.length < 8

    PhotoboxConfig.admin_password = password
    nil
  end

  def activate(gallery)
    gallery.activate!
    Turbo::StreamsChannel.broadcast_refresh_to(:gallery)
    redirect_to admin_path, notice: "Active gallery: #{gallery.caption.presence || gallery.name}"
  end
end
