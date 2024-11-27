import os
import pty

from invoke import task

BUILD_PATH = os.path.join("firmware", "blink", "build")


@task
def flash_firmware(c):
    bootloader = os.path.join(BUILD_PATH, "bootloader", "bootloader.bin")
    partition_table = os.path.join(BUILD_PATH, "partition_table", "partition-table.bin")
    firmware = os.path.join(BUILD_PATH, "zig-sample-idf.bin")
    c.run(
        f"esptool.py --chip esp32c3 -b 460800 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_size 4MB --flash_freq 80m 0x0 {bootloader} 0x8000 {partition_table} 0x10000 {firmware}"
    )


@task
def monitor(c):
    c.run("tio --auto-connect latest", pty=True)
