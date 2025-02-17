#!/usr/bin/env nu

use nu_scripts/docker.nu 
use nu_scripts/sensor.nu


def main [
    --dk-start # Start the dev container
    --dk-stop # Stop the dev container
    --dk-clean # Clean the docker environment
    --dk-build # Build the dev container
    --dk-shell # Open a shell in the dev container
    --flash (-f) # Flash the firmware to the device
    --monitor (-m) # Monitor the serial output of the device
] {
    if $dk_start {
        docker start
    }
    if $dk_stop {
        docker stop
    }
    if $dk_clean {
        docker clean
    }
    if $dk_build {
        docker build
    }
    if $flash {
        sensor flash
    }
    if $monitor {
        sensor monitor
    }
}

# TODO: Inspect exported functions dynamically and add them as command line arguments
# const MODULES = ["docker" "sensor"]

# def extract_functions [module: string] {
#     help modules | where name == $module | get commands | first | get name | each {|name| 
#         $"($module) ($name)"
#     }
# }

# def main [...args] {
#     let functions = $MODULES | each {|m| extract_functions $m} | flatten
#     print $functions
#     print $args

#     for func in $functions {
#         let arg_name = $"--($func | str replace ' ' '-' | str replace '_' '-')"
        
#         # if $args | get $arg_name {
#         #     do $func
#         # }
#     }
# }
