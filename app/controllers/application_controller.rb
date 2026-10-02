# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from Exception, with: :handle_exception
  rescue_from ActionController::RoutingError, with: -> { head :not_found }

  private

  def handle_exception(exception)
    logger.error "Exception: #{exception.class}: #{exception.message}"
    logger.error exception.backtrace.join("\n")
    flash.now[:alert] = exception.message
    # Turbo form posts accept turbo_stream first, the layout only exists for html
    render html: '', layout: true, formats: :html, status: :unprocessable_content
  end

end
