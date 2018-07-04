# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from Exception, with: :handle_exception

  def index
    render 'layouts/application'
  end

  private

  def handle_exception(exception)
    logger.error "Exception: #{exception.class}: #{exception.message}"
    logger.error exception.backtrace.join("\n")
    render json: { error: exception.message }.to_json, status: :unprocessable_entity
  end

end
