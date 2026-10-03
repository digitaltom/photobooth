# Development

For the install on a Raspberry Pi or another server, see [deploy/README.md](deploy/README.md).

## Setup

1. Install Ruby (version in `.ruby-version`), for example with [rbenv](https://github.com/rbenv/rbenv).
2. Install the packages: `gphoto2`, `imagemagick`, `gpiod` and `libsqlite3-dev`.
3. Run `bin/setup`.
4. Start the server: `bin/rails server`. Then open `http://localhost:3000/kiosk`.

## Options

`config/options.yml` holds the settings. The `default` block is merged with the block of the current environment.
`config/options-local.yml` overrides them. Git ignores this file.

For development without a camera, use the `fake` camera. It copies the sample images from `lib/fake_camera`:

```yaml
development:
  camera: 'fake'
```

## Status LEDs

LEDs can get connected to the Raspberry Pi's [gpio ports](https://www.raspberrypi.org/documentation/usage/gpio/).
It uses port 23 for 'ready', the ports 4,5,6,17  for picture 1-4 and port 24 for 'image processing'.
The app sets them with `gpioset` from libgpiod. Set the chip with `gpio_chip` in the options.

## Tests and linting

```sh
bin/rspec
bin/rubocop --parallel
```

The `test` environment always uses the `fake` camera.

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

## Fonts

The default font for the Polaroid caption is Rock Salt in `fonts/` (Apache License 2.0). To use another font, set `font` in `config/options-local.yml` to a `.ttf` path or to an ImageMagick font name. A good caption font is for example [Simplicity](https://www.dafont.com/simplicity-6.font).

Do not commit fonts that are for personal use only (for example Simplicity). Keep them outside git.

To show the font names that ImageMagick knows, run `magick -list font`.
