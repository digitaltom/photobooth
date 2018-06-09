require 'rails_helper'

feature 'Photobox take picture', js: true do

  it 'shows countdown modal' do
    visit '/?rw/#/'
    click_button('take a picture')
    expect(page).to have_content 'Take pose!'
  end

end
