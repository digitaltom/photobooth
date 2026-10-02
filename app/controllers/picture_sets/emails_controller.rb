# frozen_string_literal: true

module PictureSets
  class EmailsController < ApplicationController
    before_action :set_picture_set

    def new; end

    def create
      email = params.expect(:email)
      picture_set = @picture_set
      t = Thread.new do
        ::PictureSetMailer.image_email(email, picture_set).deliver_now
      end
      t.abort_on_exception = true
      redirect_to root_path, notice: "Successfully sent email to #{email}"
    end

    private

    def set_picture_set
      @picture_set = PictureSet.find(params.expect(:picture_set_id))
    end
  end
end
