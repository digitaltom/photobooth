# frozen_string_literal: true

require 'rails_helper'

feature 'Photobox slideshow', js: true do

  before do
    visit '/sets/2099-01-01_01-48-33/slideshow'
  end

  it 'shows the next set when the progress bar is full' do
    # a different target than the only set, so the visit is visible
    execute_script("document.querySelector('.slideshow').dataset.slideshowNextValue = '/'")
    execute_script("document.querySelector('.slideshow-progress').dispatchEvent(new Event('animationend'))")
    expect(page).to have_current_path('/')
  end

  it 'stops when you leave it' do
    click_link 'Gallery'
    expect(page).to have_current_path('/')
    # longer than the 8 seconds of the progress bar
    sleep 9
    expect(page).to have_current_path('/')
  end

end
