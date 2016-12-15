##Installation of the photobooth software on a raspberry pi 3 with raspbian: 

- Download and install raspbian: https://www.raspberrypi.org/downloads/raspbian/
- Boot raspbian (connected to monitor and keyboard) and set up ssh for easy access (default login: pi:raspberry)
- Use `raspi-config` to set the password and other settings
- Change to root user with `sudo su` 
- Set your timezone: `dpkg-reconfigure tzdata`
- Setup Wifi: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md
- Install needed packages: `sudo apt-get install vim ruby git imagemagick time sqlite3 libsqlite3-dev nodejs libssl-dev gphoto2`
- Clone the photobooth repo: `cd /root; git clone https://github.com/digitaltom/photobooth.git` 
- Install the needed gems: `cd photobooth; bundle install`
- Precompile the assets: `RAILS_ENV=production rake assets:precompile`
- Autostart the app on reboot: `cp /root/photobooth/photobooth.service /etc/systemd/system/photobooth.service; systemctl enable /etc/systemd/system/photobooth.service`

Anything is not working when following this manual? Please open an issue in the github project! 
