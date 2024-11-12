# Build and flash the firmware

Use the DevContainer provided in the root of the repository or install the requirements listed below.

## Requirements

Make sure to have the https://docs.espressif.com/projects/esp-idf/en/stable/esp32/get-started/index.html[esp-idf installed]:

1. Clone the repository: `git clone -b v5.3.1 --recursive https://github.com/espressif/esp-idf.git`
2. Run the install script: `install.ps1|sh|fish|bat`

To export the required variables in you current shell, run the `export.ps1|sh|fish|bat` file. Afterwards the `idf.py` tool is registered in you current shell and can be used.

## Set the target architecture

By default, the firmware will be built for the `esp32` target.
If you want to change the target to esp32c3, run the following command:

```
idf.py set-target esp32c3
```

## Building the project

Run `idf.py build` in the root folder of your project.

If all is configured correctly, the resulting binary can be found in the folder `build/` under the name `zig-sample-idf.bin`.

In case of errors, make sure to have installed all the requirements and have run `export.bat` form the esp-idf in your current shell.

== Flashing the binary to the device

Connect the ESP32 device to you USB port.

The device can now be flashed with the command `idf.py flash`. Usually, if only one device is attached, the command finds the correct device for flashing automatically.

In case the device can not be found, has never been flashed or has some other error that is stopping the device form being recognized as a serial port device, you can manuall set the device into boot mode. Just hold the `boot` button pressed while pressing and releasing the `reset` button. Release the `boot` button after releasing the `reset` button.