# frozen_string_literal: true

class KioskController < ApplicationController
  def show
    @picture_sets = PictureSet.all
  end
end
