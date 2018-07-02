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

  context 'unavailable set' do

    before do
      visit '/?rw/#/picture_set/2018-04-10_11-22-3/'
    end

    it 'shows error' do
      expect(page).to have_text('PictureSet not found')
    end
  end

  context 'delete set' do

    before do
      visit '/?rw/#/picture_set/00example'
    end

    it 'shows error' do
      expect_any_instance_of(PictureSet).to receive(:destroy)
      click_button('Delete this set')
    end
  end

end
