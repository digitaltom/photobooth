class PictureSetsController < ApplicationController

  protect_from_forgery with: :exception

  def index
    render json: PictureSet.all
  end

  def show
    render json: PictureSet.find(params[:id])
  end

  def create
    render json: PictureSet.create
  end

  def destroy
    PictureSet.find params[:id]
  end

end
