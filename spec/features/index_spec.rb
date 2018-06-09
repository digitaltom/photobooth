require 'rails_helper'

feature 'Photobox index view', js: true do

  before do
    visit '/'
  end

  context 'in read-only mode' do
    it 'shows a link to github' do
      expect(page).to have_content 'github.com/digitaltom/photobooth'
    end
  end

  context 'in rw mode' do
  end

end
