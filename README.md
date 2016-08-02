[![Build Status](https://travis-ci.org/digitaltom/photobooth.png?branch=master)](https://travis-ci.org/digitaltom/photobooth)
[![Dependency Status](https://gemnasium.com/digitaltom/photobooth.svg)](https://gemnasium.com/digitaltom/photobooth)
[![Code Climate](https://codeclimate.com/github/digitaltom/photobooth.png)](https://codeclimate.com/github/digitaltom/photobooth)
[![Coverage Status](https://coveralls.io/repos/digitaltom/photobooth/badge.svg?branch=master&service=github)](https://coveralls.io/github/digitaltom/photobooth?branch=master)

# Photobooth

This application is supposed to run on a linux machine which is connected to a gphoto supported camera.
I've build it to run on a raspberry pi 2 with openSUSE, connected to a Nikon D60 camera.
It also runs on a raspberry pi 3 with raspbian, see INSTALL file for an installation manual. 

The Angular.js frontend uses a Rails server on the backend to trigger and process the pictures.
Because this is a webapp, any tablet with a web-browser connected to the same wifi as the raspi
will work as a screen.

LEDs can get connected to the raspberry pi's gpio ports.
It uses port 23 for 'ready', port 4 for 'picture 1', port 5 for 'picture 2',
port 6 for 'picture 3', port 17 for 'picture 4' and port 24 for 'image processing'.

=== TODO:===

* User access to images via wifi

=== Prototype pictures:===

![alt tag](https://raw.github.com/digitaltom/photobooth/master/public/images/readme/box_front.jpg)
![alt tag](https://raw.github.com/digitaltom/photobooth/master/public/images/readme/internals.jpg)
![alt tag](https://raw.github.com/digitaltom/photobooth/master/public/images/readme/picture_list.jpg)
![alt tag](https://raw.github.com/digitaltom/photobooth/master/public/images/readme/picture_list2.jpg)

