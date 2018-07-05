# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox take picture', js: true do

  before do
    visit '/?rw/#/'
  end

  it 'shows countdown modal' do
    expect(PictureSet).to receive(:create)

    click_button('take a picture')
    expect(page).to have_content 'Take pose!'
    sleep(3)
  end

end
