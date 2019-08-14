# avionics-build

This package replaces the legacy `missionmule/muleOS-gen` build system due to
its very opaque documentation and non-intuitive build process. This build script
condenses all necessary build steps to set up the payload firmware stack into a
single executable. It has the benefit of being much simpler to update as well as
enabling the build to take place on top of the newest Debian OS builds and
therefore stay up-to-date as much as possible.

Note: As of August 9, 2019, the latest Raspbian image that doesn't fail when
the access point is connected to is `2019-04-08-raspbian-stretch-lite.zip`. In
later images, there is a memory dump that's triggered when connecting to the
access point from another computer. This seems to be rooted in the OS itself,
as the problem is replicable over different hardware.

To setup the firmware, do the following:

Add `wpa_supplicant.conf` and `ssh` files to `boot` volume after flashing latest
Raspbian image.

Inside the new image, run `sudo raspi-config`. Go to `5 Interfacing Options` > `P6 Serial`. Answer "no" to SSH over serial. Answer "yes" to serial port hardware.

```
sudo apt update
sudo apt install git -y
git clone -v https://github.com/missionmule/avionics-build.git
cd avionics-build
sudo chmod +x ./run.sh
sudo ./run.sh
```

Always run a full verification test flight to confidently certify a new payload.

## Troubleshooting

If the client daemon is failing to start, ensure that `serve` is installed globally with `sudo yarn add global serve`
