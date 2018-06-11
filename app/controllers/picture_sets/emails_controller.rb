module PictureSets
  class EmailsController < ApplicationController

    def create
      picture_set = PictureSet.find(params[:picture_set_id])
      Thread.new do
        ::PictureSetMailer.image_email(params[:email], picture_set).deliver_now
      end
      render json: ''
    end
  end
end
