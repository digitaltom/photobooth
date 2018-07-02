require 'rails_helper'

feature 'Photobox send picture set by email', js: true do

  context 'navigating from index page' do
    before do
      visit '/'
      find(:css, 'img.gallery-img', match: :first).click
      click_link('Send per email')
    end

    it 'shows the email send form' do
      expect(page).to have_text('Get your picture send to you immediately')
    end

    it 'can go back to picture set' do
      click_link('Back')
      expect(page).to have_css('.fullscreen img')
    end
  end

end
