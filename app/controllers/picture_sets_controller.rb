class PictureSetsController < ApplicationController

  protect_from_forgery with: :exception

  def show
    @picture_set = PictureSet.find params[:id]
  end

  def list
    render json: PictureSet.all
  end

  def create
    render json: PictureSet.create
  end

  def destroy
    PictureSet.find params[:id]
  end


end
