class PicturesController < ApplicationController

  protect_from_forgery with: :exception

  def index
    render json: PictureSet.all
  end

  def create
    render json: PictureSet.create
  end

end
