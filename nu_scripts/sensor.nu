
const BUILD_PATH = ["firmware", "v0", "build"] | path join

export def flash [] {
    const bootloader = [$BUILD_PATH, "bootloader", "bootloader.bin"] | path join 
    const partition_table = [$BUILD_PATH, "partition_table", "partition-table.bin"] | path join 
    const firmware = [$BUILD_PATH, "zig-sample-idf.bin"] | path join 
    esptool.py --chip esp32c3 -b 460800 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_size 4MB --flash_freq 80m 0x0 $bootloader 0x8000 $partition_table 0x10000 $firmware
}

export def monitor [] {
    tio --auto-connect latest
}