ArduPilot SITL Docker image
===========================

This image is inspired by [radarku/ardupilot-sitl](https://hub.docker.com/r/radarku/ardupilot-sitl) but supports newer
versions of [ArduPilot](https://ardupilot.org) and allows using [FlightGear](https://www.flightgear.org) for
visualisation.

Usage
-----

To start SITL with 5076 port available for [MAVLink](https://mavlink.io/en/) connection:

```shell
docker run -p 5760:5760 sitin/ardupilot-sitl:latest
```

Check [`docker-compose.yml`](docker-compose.yml) for details.

### Environment variables

The following environment variables, when set, produce the corresponding arguments to
[`sim_vehicle.py`](https://github.com/ArduPilot/ardupilot/blob/master/Tools/autotest/sim_vehicle.py) (check 
[docs](https://ardupilot.org/dev/docs/using-sitl-for-ardupilot-testing.html)): 

- `INSTANCE`: `--instance=${INSTANCE}`
- `VEHICLE`: `--vehicle=${VEHICLE}`
- `FRAME`: `--frame=${FRAME}`
- `SPEEDUP`: `--speedup=${SPEEDUP}`
- `LOCATION`: `--location=${LOCATION}`
- `USE_DIR`: `--use-dir=${USE_DIR}` (in addition the corresponding directory will be created)

If at least one of the `LATITUDE`, `LONGITUDE`, `ALTITUDE` or `DIRECTION` are set, then custom location parameter will
be passed as well: `--custom-location=${LATITUDE},${LONGITUDE},${ALTITUDE},${DIRECTION}`.

- `NO_WIPE_EEPROM`: set to 1 to skip vehicle memory wipe during start (excludes `--wipe-eeprom` parameter).
- `SILENT_START`: set to `true` to skip debug messages.

### State preservation

If `USE_DIR` environment variable is passed, then the corresponding directory will be used for simulation state.

Set `NO_WIPE_EEPROM=1` to keep skip memory wiping.

### FlightGear

This image supports [FlightGear](https://www.flightgear.org).

To run FlightGear you need to extract the contents of `/ardupilot/Tools/autotest` from container:

```shell
docker cp sitin/ardupilot-sitl:/ardupilot/Tools/autotest ./autotest
```

Then you can run `fg_quad_view.sh` or ` fg_plane_view.sh` as described in ArduPilot
[docs](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html):

```shell
cd ./autotest
./fg_quad_view.sh
```

#### OS X Caveats

OS X has a working FlightGear distribution available via [Homebrew](https://brew.sh):

```shell
brew install flightgear
```

However, it does not install `fgfs`. Until this won't be fixed, we suggest adding proxy script `fgfs.sh` to
`/Applications/FlightGear.app/Contents/MacOS/`:

```shell
#!/usr/bin/env sh

/Applications/FlightGear.app/Contents/MacOS/fgfs ${*}
```

Then it can be linked to `/opt/homebrew/bin/`

```shell
ln -s /Applications/FlightGear.app/Contents/MacOS/fgfs.sh /opt/homebrew/bin/fgfs
```

Development
-----------

### Setup

Initialise project

```shell
make init
```

Set parameters in `.env`.

Build project

```shell
make build
```

### Testing

Extract autotest files from the image:

```shell
make autotest-init
```

Start FlightGear (see [OS X caveats](#os-x-caveats)):

```shell
make fgfs
```

Start SITL:

```shell
make up
```

Start MAVProxy:

```shell
make mavproxy
```

### Tear down

Clean project:

```shell
make clean
```
