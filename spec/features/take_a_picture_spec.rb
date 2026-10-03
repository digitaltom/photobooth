# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox kiosk', js: true do

  before do
    visit '/?kiosk=1'
  end

  it 'counts down and starts the capture job' do
    expect(CaptureJob).to receive(:perform_later)

    click_button('take a picture')
    expect(page).to have_content 'Take pose!'
    expect(page).to have_css('#kiosk-status img.countdown-img', count: 4)
    # the countdown hides the progress bar when it submits the form
    expect(page).to have_css('#shoot-progress', visible: :hidden, wait: 5)
  end

end
