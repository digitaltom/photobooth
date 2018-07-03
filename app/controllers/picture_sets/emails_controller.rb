# frozen_string_literal: true

module PictureSets
  class EmailsController < ApplicationController

    def create
      picture_set = PictureSet.find(params[:picture_set_id])
      t = Thread.new do
        ::PictureSetMailer.image_email(params[:email], picture_set).deliver_now
      end
      t.abort_on_exception = true
      render json: ''
    end
  end
end
