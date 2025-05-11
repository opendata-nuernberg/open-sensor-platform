# open-sensor-platform
Hardware Designs and Firmware of the Open Sensor Platform


## Installation

### Dev Container Setup
This repository includes a dev container setup to run the build process inside docker.
To start the Dev-Container:

1. Install the "Dev Containers" extension in VS Code
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Dev Containers"
   - Install the extension by Microsoft

2. Open the repository in VS Code
   - File -> Open Folder -> Select this repository
   - VS Code will detect the dev container configuration
   - Click "Reopen in Container" when prompted
   - Wait for the container to build and start

The container includes all required dependencies like the ESP-IDF toolchain, QEMU emulator, and Zig compiler.

If you are not using VS Code or just want to compile from the commandline you can enter the container like this:
```
cd dev_docker
docker compose run development -- /bin/bash
make prepare # This prepares the build environment only needs to be run once!
make # This runs the default build_firmware command
```
The current Dev Container setup does not support flashing the board.
To flash the board open a different terminal (not running in the container) and type:
```
make flash_monitor
```

### tio
- MacOS: `brew install tio`
- Linux: Use your system package manager
- Windows: Using msys2: `pacman -S tio`

Exit tio: `ctrl+t q`

