# frozen_string_literal: true

class PictureSetsController < ApplicationController
  before_action :set_picture_set, only: %i[show gallery slideshow]

  def index
    @picture_sets = PictureSet.all
  end

  def show; end

  def gallery; end

  def slideshow; end

  def create
    PictureSet.create
    redirect_to root_path
  end

  def destroy
    id = params.expect(:id)
    PictureSet.find(id).destroy
    redirect_to root_path, notice: "Pictureset #{id} destroyed"
  end

  private

  def set_picture_set
    @picture_set = PictureSet.find(params.expect(:id))
  end
end
