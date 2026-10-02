# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox kiosk', js: true do

  before do
    visit '/kiosk'
  end

  it 'counts down and starts the capture job' do
    expect(CaptureJob).to receive(:perform_later)

    click_button('take a picture')
    expect(page).to have_content 'Take pose!'
    expect(page).to have_css('#kiosk-status img.countdown-img', count: 4)
  end

end
