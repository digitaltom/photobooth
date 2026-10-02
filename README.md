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

LEDs can get connected to the Raspberry Pi's [gpio ports](https://www.raspberrypi.org/documentation/usage/gpio/).
It uses port 23 for 'ready', the ports 4,5,6,17  for picture 1-4 and port 24 for 'image processing'.
The app sets them with `gpioset` from libgpiod.

The app has these pages:

- `/kiosk`: The record UI for the tablet. It shows the result with a QR code for the download.
- `/`: The gallery for the guests. It shows new sets without a reload.
- `/sets/<id>`: One set with the GIF, the 4 single pictures and the downloads.

For development without a camera, the `fake` camera in `config/options.yml` copies the sample images from `lib/fake_camera`.

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

## Server Setup

The Photobooth can run on any Linux server, for building a portable photo booth I recommend running it on a Raspberry Pi.

General instructions on how to install Rasbian on the Raspberry can be found in  [INSTALL-RASPBIAN.md](INSTALL-RASPBIAN.md)

## Network Setup

You basically have 3 options how to connect your Tablet to your Raspberry Pi server:

- Both are connected to the same wifi network. (Setup for [Raspbian Stretch](https://github.com/digitaltom/photobooth/blob/master/INSTALL-RASPBIAN.md), openSUSE)
- Your raspi acts as an access point for the tablet (Setup for [Raspbian Stretch](https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md), openSUSE)
- Your tablet acts as an access point for the raspi. (Manuals for [Iphone](https://support.apple.com/de-de/ht204023) and [Android](https://www.dasheimnetzwerk.de/einrichten/Einrichten_OS_Androidx/Kapitel_Androidx_WLAN_AP.html))

It can be tricky to find out the IP address of you raspi. An [task](https://github.com/digitaltom/photobooth/issues/21) to improve this is created.
From your notebook you can use `sudo nmap -sP 192.168.178.1/24` to discover active devices in your network.

## Software Setup

- Create the app user: `sudo useradd --system --create-home --groups plugdev,gpio photobox`
- Clone the repo to `/opt/photobox` and give it to the user: `sudo chown -R photobox /opt/photobox`
- Install Ruby 4.0.5 (for example with [rbenv](https://github.com/rbenv/rbenv)). The version is set in `.ruby-version`.
- Install the packages: `sudo apt-get install gphoto2 imagemagick gpiod libsqlite3-dev`
- As the `photobox` user, in `/opt/photobox`:
  - `bundle install`
  - `echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" > config/photobox.env`
  - `RAILS_ENV=production bin/rails assets:precompile`
- Install the service:
  - `sudo cp deploy/photobox.service /etc/systemd/system/`
  - `sudo systemctl enable --now photobox`
- Redirect port 80 to Puma on port 3000:
  - `sudo cp deploy/photobox.nft /etc/nftables.d/` (or include it from `/etc/nftables.conf`)
  - `sudo nft -f deploy/photobox.nft`
- Optional: `cp config/options.yml config/options-local.yml` and set your options in `config/options-local.yml`.

The service runs Puma and the Solid Queue jobs in one process. The queue and cable databases are in `/run/photobox` (RAM), because they only hold volatile data.
The picture sets are in `storage/sets`. Set `PHOTOBOX_STORAGE` or `storage_path` to use another folder.

## Operations

Useful commands to run the photobooth

- Control the app with systemd:
  `systemctl <start|stop|restart|status> photobox`
- See the log: `journalctl -u photobox -f`
- Rake tasks
  - `rake picture_set:record`: Trigger a new picture from console
  - `rake picture_set:recreate_polaroid_images[path]`: Re-create all polaroid images in a batch
  - `rake picture_set:recreate_animations[path]`: Re-create all animations in a batch
  - `rake picture_set:export[output,path]`: Export all images into one output directory

Anything is not working when following this manual? Please open an [issue](https://github.com/digitaltom/photobooth/issues) in the github project!


## My Photobooth:

My current photobox setup is a Raspberry Pi 3, a Nikon D60 with a Nikkor 35mm lens and a Nexus 7 tablet. All build into an old wooden suitcase. It can run completely from battery for 2-3 hours.  

It was already used at multiple parties and weddings.

![party_box](https://user-images.githubusercontent.com/582520/43478387-0dd809d4-94fe-11e8-8464-9873e775c56c.jpg)

![wedding_box](https://user-images.githubusercontent.com/582520/32445572-765e1e0a-c306-11e7-92b4-99331baf6092.png)

Images licensed by [![https://creativecommons.org/licenses/by/4.0/](https://licensebuttons.net/l/by/3.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)
