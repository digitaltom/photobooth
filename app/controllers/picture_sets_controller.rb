# frozen_string_literal: true

class PictureSetsController < ApplicationController

  def index
    render json: PictureSet.all
  end

  def show
    render json: PictureSet.find(params.expect(:id))
  end

  def create
    render json: PictureSet.create
  end

  def destroy
    PictureSet.find(params.expect(:id)).destroy
    render json: ''
  end
end
