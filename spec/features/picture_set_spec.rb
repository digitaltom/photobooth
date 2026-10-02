# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox picture set view', js: true do

  before do
    visit '/'
    find(:css, 'img.gallery-img', match: :first).click
  end

  it 'shows the animation and the single pictures' do
    expect(page).to have_css('img.gallery-img')
    expect(page).to have_css('img.img-responsive', count: 4)
    expect(page).to have_link('Download GIF')
  end

end
