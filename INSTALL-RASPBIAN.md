## Prepare a Raspberry Pi 3 with Raspbian for Photobox setup:

- Download and install raspbian: https://www.raspberrypi.org/downloads/raspbian/
  (the minimal image is enough)
- Install to SD card: https://www.raspberrypi.org/documentation/installation/installing-images/README.md

- Boot raspbian (connected to monitor and keyboard) and login (default login: pi:raspberry)

  or

  do the setup *headless*: https://hackernoon.com/raspberry-pi-headless-install-462ccabd75d0
- Use `sudo raspi-config` to set the password and timezone
- Setup Wifi: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md
- Install needed packages: `sudo apt-get install vim ruby ruby-dev git imagemagick time sqlite3 gphoto2 libssl-dev nodejs libsqlite3-dev`
