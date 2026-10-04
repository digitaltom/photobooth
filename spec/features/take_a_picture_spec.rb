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

  it 'quits the countdown without a picture' do
    expect(CaptureJob).not_to receive(:perform_later)

    click_button('take a picture')
    find('button[aria-label="Quit"]').click
    expect(page).to have_no_css('#shoot-dialog[open]')
    # longer than the countdown
    sleep 2.5
  end

  it 'quits the countdown on a tap outside, without any other action' do
    expect(CaptureJob).not_to receive(:perform_later)

    click_button('take a picture')
    expect(page).to have_css('#shoot-dialog[open]')
    # the dialog is 95% wide, the top left corner is backdrop
    page.driver.browser.mouse.click(x: 5, y: 5)
    expect(page).to have_no_css('#shoot-dialog[open]')
    expect(page).to have_current_path('/?kiosk=1')
    # longer than the countdown
    sleep 2.5
  end

  it 'closes the QR code dialog with its close button' do
    click_button('Connect your phone')
    find('#wifi-qr-dialog button[aria-label="Close"]').click
    expect(page).to have_no_css('#wifi-qr-dialog[open]')
  end

  it 'closes the QR code dialog on a tap outside, without a picture' do
    expect(CaptureJob).not_to receive(:perform_later)

    click_button('Connect your phone')
    expect(page).to have_css('#wifi-qr-dialog[open]')
    # tap on the backdrop, right over the shoot button
    x, y = evaluate_script('(r => [r.x + r.width / 2, r.y + r.height / 2])' \
                           "(document.querySelector('.shoot_button').getBoundingClientRect())")
    page.driver.browser.mouse.click(x: x, y: y)
    expect(page).to have_no_css('#wifi-qr-dialog[open]')
    expect(page).to have_no_css('#shoot-dialog[open]')
  end

end
