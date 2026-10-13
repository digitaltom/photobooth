# Development

For the install on a Raspberry Pi, see [deploy/README.md](deploy/README.md).

## Setup

1. Install Ruby (version in `.ruby-version`), for example with [rbenv](https://github.com/rbenv/rbenv).
2. Install the packages: `gphoto2`, `imagemagick` and `gpiod`.
3. Run `bin/setup`.
4. Start the server: `bin/rails server`. Then open `http://localhost:3000/?kiosk=1`.

## Options

`config/options.yml` holds the settings. The `default` block is merged with the block of the current environment.
`config/options-local.yml` overrides them. Git ignores this file.

For development without a camera, use the `fake` camera. It copies the sample images from `lib/fake_camera`:

```yaml
development:
  camera: 'fake'
```

The app stores the picture sets in `storage/sets`. To use another folder, set `PHOTOBOX_STORAGE` or `storage_path`.

## Status LEDs

You can connect LEDs to the [GPIO ports](https://www.raspberrypi.org/documentation/usage/gpio/) of the Raspberry Pi.
The app uses port 23 for "ready" and port 24 for "image processing".
Ports 4, 5, 6 and 17 show the pictures 1 to 4.
The app sets them with `gpioset` from libgpiod. Set the chip with `gpio_chip` in the options.

## Stream Deck

An Elgato Stream Deck Mini on USB can control the open kiosk page. The app finds the device within 2 seconds after plug in.
The app supports the Stream Deck Mini (USB ID `0fd9:0063`) only. It ignores other Stream Deck models.
Connect the Stream Deck directly to the computer or to a powered USB hub.
If the power is too low, the device disconnects when the app turns on the key lights. The log then shows `Input/output error`.

- The top middle key shows the camera icon. A press on it starts the countdown.
- The top left and top right keys show the newest and the second newest set. A press on them opens the set.
- The text under the shoot button scrolls over the lower 3 keys, in the language of the kiosk. A press on them starts the countdown.

The app reads and writes `/dev/hidrawN` and needs the udev rule [deploy/streamdeck.rules](deploy/streamdeck.rules).
The rule gives all users access to the device. The image includes the rule. On a laptop, copy it to `/etc/udev/rules.d/` and plug the device in again.

## Tests and linting

```sh
bin/rspec
bin/rubocop --parallel
```

The `test` environment always uses the `fake` camera.

## Rake tasks

- `rake picture_set:record`: Trigger a new picture from console
- `rake picture_set:recreate_polaroid_images[path]`: Re-create all polaroid images in a batch
- `rake picture_set:recreate_animations[path]`: Re-create all animations in a batch

## Fonts

To change to another font for the captions, set `font` in `config/options-local.yml` to a `.ttf` path or to an ImageMagick font name.
To show the font names that ImageMagick knows, run `magick -list font`.
