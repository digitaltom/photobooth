# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox gallery', js: true do

  before do
    visit '/'
  end

  it 'does not show the button to take a picture' do
    expect(page).to_not have_content 'take a picture'
  end

  it 'shows a link to github' do
    expect(page).to have_content 'github.com/digitaltom/photobooth'
  end

  it 'shows picture sets' do
    expect(page).to have_selector('img.gallery-img')
  end

end
