# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from Exception, with: :handle_exception
  rescue_from ActionController::RoutingError, with: -> { head :not_found }
  before_action :remember_kiosk
  around_action :switch_locale
  helper_method :kiosk?

  private

  # ?locale=de switches the UI to German for all following requests, ?locale=en back to English
  def switch_locale(&)
    locale = params[:locale]
    cookies.permanent[:locale] = locale if locale.in?(FastGettext.available_locales)
    I18n.with_locale(cookies[:locale].presence_in(FastGettext.available_locales) || I18n.default_locale, &)
  end

  # ?kiosk=1 turns the tablet into the kiosk for all following requests, ?kiosk=0 turns it off
  def remember_kiosk
    return unless params.key?(:kiosk)

    params[:kiosk] == '1' ? cookies.permanent[:kiosk] = '1' : cookies.delete(:kiosk)
  end

  def kiosk?
    cookies[:kiosk] == '1'
  end

  def handle_exception(exception)
    logger.error "Exception: #{exception.class}: #{exception.message}"
    logger.error exception.backtrace.join("\n")
    flash.now[:alert] = exception.message
    # Turbo form posts accept turbo_stream first, the layout only exists for html
    render html: '', layout: true, formats: :html, status: :unprocessable_content
  end

end
