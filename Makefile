.DEFAULT_GOAL := all

ROOT_PATH=firmware/blink
BUILD_PATH=${ROOT_PATH}/build
BOOTLOADER_PATH=${BUILD_PATH}/bootloader/bootloader.bin
PARTITION_TABLE_PATH=${BUILD_PATH}/partition_table/partition-table.bin
FIRMWARE_PATH=${BUILD_PATH}/zig-sample-idf.bin

all: build_firmware flash_firmware monitor

build_firmware:
	@echo "Building firmware"
	cd ${ROOT_PATH}; idf.py build

flash_firmware:
	@echo "Flashing firmware"
	esptool --chip esp32c3 -b 460800 --before default_reset --after hard_reset write_flash \
	--flash_mode dio --flash_size 4MB --flash_freq 80m \
	0x0 ${BOOTLOADER_PATH} 0x8000 ${PARTITION_TABLE_PATH} 0x10000 ${FIRMWARE_PATH}

monitor:
	@echo "Start monitoring"
	tio --auto-connect latest

