# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox picture set view', js: true do

  before do
    visit '/'
    find(:css, 'img.gallery-img', match: :first).click
  end

  it 'shows the animation and the single pictures' do
    expect(page).to have_css('img.gallery-img')
    expect(page).to have_css('img.set-picture', count: 4)
    expect(page).to have_link('Save image')
    expect(page).to have_link('Gallery', href: '/')
    expect(page).to have_css('.gallery-title a[href="/"]')
    expect(page).to have_css('.set-date', text: 'January 01, 2099 01:48')
  end

  it 'shows the QR code instead of the download on the kiosk' do
    visit '/sets/2099-01-01_01-48-33?kiosk=1'
    expect(page).to have_no_link('Save image')

    click_button('Save image')
    expect(page).to have_css('#wifi-qr-dialog[open] svg')
    find('#wifi-qr-dialog button[aria-label="Close"]').click
    expect(page).to have_no_css('#wifi-qr-dialog[open]')
  end

end
