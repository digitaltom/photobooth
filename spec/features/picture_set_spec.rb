require 'rails_helper'

feature 'Photobox picture set view', js: true do

  context 'navigating from index page' do
    before do
      visit '/'
      find(:css, 'img.gallery-img', match: :first).click
    end

    it 'shows the picture set page' do
      expect(page).to have_css('.fullscreen img')
    end
  end
end
