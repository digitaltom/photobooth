[![Master Status](https://github.com/digitaltom/photobooth//actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/digitaltom/photobooth/actions)
[![Code Climate](https://codeclimate.com/github/digitaltom/photobooth.png)](https://codeclimate.com/github/digitaltom/photobooth)
[![Coverage Status](https://coveralls.io/repos/github/digitaltom/photobooth/badge.svg?branch=master&)](https://coveralls.io/github/digitaltom/photobooth?branch=master)
[![Dependencies](https://badgen.net/dependabot/digitaltom/photobooth/?icon=dependabot)](https://badgen.net/dependabot/digitaltom/photobooth/?icon=dependabot)

# Photobooth

This application is supposed to run on a linux machine which is connected to a [gphoto](http://www.gphoto.org/) supported camera ([list](http://www.gphoto.org/proj/libgphoto2/support.php)).

I've build it to run on a Raspberry Pi with [openSUSE](https://en.opensuse.org/HCL:Raspberry_Pi3)/[Raspbian (Debian)](https://www.raspberrypi.org/downloads/raspbian/), connected to a Nikon D60 camera. See below for install instructions.

The app is a *[Ruby on Rails](https://rubyonrails.org/)* server with a *[Hotwire](https://hotwired.dev/)* (Turbo and Stimulus) frontend. It needs no Node.js.
A background job (Solid Queue) takes the pictures and renders the GIF. The job sends each step to the screen with Turbo Streams.
Any tablet or notebook with a web browser in the same Wi-Fi as the Raspberry Pi works as a screen.

## Hardware Setup

The general hardware setup looks like this:

```
                                      +--------------+
                                      |              |
                                      |    Camera    |
                                      |              |
                                      +------^-------+
                                             |
                                   USB Cable |
                                             | gphoto library                                   
+--------------------+               +-------v------------+                               
|                    |               |                    |
|  Tablet /Notebook  |     Wifi      | Photobooth server  |
|    with Browser    +-------------> | (eg. Raspberry Pi) |
|                    |               |                    |
+--------------------+               +-------+------------+
                                             | gpio ports
                                       Wires |
                                             |
                                      +------v--------+
                                      |  o o o o o o  |
                                      |  Status LEDs  |
                                      |               |
                                      +---------------+
```

## Deploy

The Photobooth can run on any Linux server, for building a portable photo booth I recommend running it on a Raspberry Pi.

From SD card to photo booth in three steps:

1. Write the image of the latest [release](https://github.com/digitaltom/photobooth/releases) to an SD card:
   `xzcat photobox-<version>.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync`
2. Put the SD card into the Pi, connect the camera and boot.
3. Connect the tablet to the WLAN `Photobox` (password `photobox`), then open `http://10.42.0.1/kiosk`.

### Usage

The app has these pages:

- `/kiosk`: The record UI for the tablet, with the gallery below the button.
- `/`: The gallery for the guests. It shows new sets without a reload.
- `/sets/<id>`: One set with the GIF, the 4 single pictures and the downloads.

### More details

[deploy/README.md](deploy/README.md) explains the ready SD card image for the Raspberry Pi, how the image is built, updates, network commands and a manual install without the image.

## Development

[DEVELOPMENT.md](DEVELOPMENT.md) explains the local setup, the options, the fake camera, the status LEDs, the tests, the fonts and the operations commands.

Anything is not working when following this manual? Please open an [issue](https://github.com/digitaltom/photobooth/issues) in the github project!


## My Photobooth:

My current photobox setup is a Raspberry Pi 3, a Nikon D60 with a Nikkor 35mm lens and a Nexus 7 tablet. All build into an old wooden suitcase. It can run completely from battery for 2-3 hours.  

It was already used at multiple parties and weddings.

![party_box](https://user-images.githubusercontent.com/582520/43478387-0dd809d4-94fe-11e8-8464-9873e775c56c.jpg)

![wedding_box](https://user-images.githubusercontent.com/582520/32445572-765e1e0a-c306-11e7-92b4-99331baf6092.png)

Images licensed by [![https://creativecommons.org/licenses/by/4.0/](https://licensebuttons.net/l/by/3.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)
