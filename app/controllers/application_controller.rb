# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from Exception, with: :handle_exception
  helper_method :rw_mode?

  private

  # record mode, opened with /?rw/ (legacy) or /?rw=1
  def rw_mode?
    params.key?(:rw) || params.key?('rw/')
  end

  # keep record mode on all generated links and redirects
  def default_url_options
    rw_mode? ? { rw: 1 } : {}
  end

  def handle_exception(exception)
    logger.error "Exception: #{exception.class}: #{exception.message}"
    logger.error exception.backtrace.join("\n")
    flash.now[:alert] = exception.message
    # Turbo form posts accept turbo_stream first, the layout only exists for html
    render html: '', layout: true, formats: :html, status: :unprocessable_content
  end

end
