# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox send picture set by email', js: true do

  context 'navigating from index page' do
    before do
      visit '/'
      find(:css, 'img.gallery-img', match: :first).click
      click_link('Send by email')
    end

    it 'shows the email send form' do
      expect(page).to have_text('Get your picture send to you immediately')
    end

    it 'can go back to picture set' do
      click_link('Back')
      expect(page).to have_css('.fullscreen img')
    end
  end

  context 'sending email' do
    before do
      visit '/#!/picture_set/00example/email'
    end

    it 'sends mail to entered address' do
      fill_in 'email', with: 'test@digitalflow.de'
      find('a', text: 'Send email').click
      expect(page).to have_content('Successfully sent email to test@digitalflow.de')
    end
  end

end
