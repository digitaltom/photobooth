class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  rescue_from Exception, :with => :handle_exception

  def index
    render :text => '', :layout => true
  end

  private

  def handle_exception(exception)
    render json: {error: exception.message}.to_json, status: 422
  end

end
