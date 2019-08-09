# avionics-build

This package replaces the legacy `missionmule/muleOS-gen` build system due to
its very opaque documentation and non-intuitive build process. This build script
condenses all necessary build steps to set up the payload firmware stack into a
single executable. It has the benefit of being much simpler to update as well as
enabling the build to take place on top of the newest Debian OS builds and
therefore stay up-to-date as much as possible.

To setup the firmware, do the following:

Add `wpa_supplicant.conf` and `ssh` files to `boot` volume after flashing latest
Raspbian image.

```
sudo apt update
sudo apt install git -y
git clone -v https://github.com/missionmule/avionics-build.git
sudo ./run.sh
```
