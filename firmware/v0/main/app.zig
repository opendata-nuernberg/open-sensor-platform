const std = @import("std");
const builtin = @import("builtin");

const idf = @import("zig_idf");
const i2c = idf.i2c;

const sht40 = @import("sht40.zig");

const OnboardLed = @import("onboard_led.zig").OnboardLed;
const tag = "osp";

export fn app_main() callconv(.C) void {
    // This allocator is safe to use as the backing allocator w/ arena allocator
    // std.heap.raw_c_allocator

    // custom allocators (based on raw_c_allocator)
    // idf.heap.HeapCapsAllocator
    // idf.heap.MultiHeapAllocator
    // idf.heap.vPortAllocator

    var heap = idf.heap.HeapCapsAllocator.init(.MALLOC_CAP_8BIT);
    var arena = std.heap.ArenaAllocator.init(heap.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    log.info("Hello, world from Zig!", .{});

    log.info(
        \\[Zig Info]
        \\* Version: {s}
        \\* Compiler Backend: {s}
        \\
    , .{
        @as([]const u8, builtin.zig_version_string), // fix esp32p4(.xesppie) fmt-slice bug
        @tagName(builtin.zig_backend),
    });

    idf.ESP_LOG(allocator, tag,
        \\[ESP-IDF Info]
        \\* Version: {s}
        \\
    , .{idf.Version.get().toString(allocator)});

    idf.ESP_LOG(
        allocator,
        tag,
        \\[Memory Info]
        \\* Total:   {d}
        \\* Free:    {d}
        \\* Minimum: {d}
        \\
    ,
        .{
            heap.totalSize(),
            heap.freeSize(),
            heap.minimumFreeSize(),
        },
    );

    idf.ESP_LOG(
        allocator,
        tag,
        "Let's have a look at your shiny {s} - {s} system! :)\n\n",
        .{
            @tagName(builtin.cpu.arch),
            builtin.cpu.model.name,
        },
    );

    if (idf.xTaskCreate(blinkclock, "blink", 1024 * 2, null, 5, null) == 0) {
        @panic("Error: Task blinkclock not created!\n");
    }

    if (idf.xTaskCreate(sht4x_task, "sht4x", 1024 * 6, null, 4, null) == 0) {
        @panic("Error: Task sht4x_task not created!\n");
    }
}

// comptime function
fn blinkLED(delay_ms: u32) !void {
    const led = OnboardLed{};

    try led.init();

    while (true) {
        log.info("LED: ON", .{});
        try led.on();

        idf.vTaskDelay(delay_ms / idf.portTICK_PERIOD_MS);

        log.info("LED: OFF", .{});
        try led.off();

        idf.vTaskDelay(delay_ms / idf.portTICK_PERIOD_MS);
    }
}

// Task functions (must be exported to C ABI) - runtime functions

export fn sht4x_task(_: ?*anyopaque) void {
    const i2cmb: idf.sys.i2c_master_bus_config_t = .{
        .i2c_port = 0,
        .sda_io_num = .GPIO_NUM_5,
        .scl_io_num = .GPIO_NUM_6,
        .clk_source = idf.sys.i2c_clock_source_t.I2C_CLK_SRC_XTAL,
        .glitch_ignore_cnt = 7,
    };
    var i2c_bus_handle: idf.sys.i2c_master_bus_handle_t = undefined;
    i2c.BUS.add(&i2cmb, &i2c_bus_handle) catch unreachable;

    const sht40_sensor = try sht40.Sht40.init(i2c_bus_handle);

    log.info("Probing device sht4x", .{});

    if (!sht40_sensor.probe()) {
        log.err("Device not found", .{});
    }

    log.info("Device FOUND!", .{});

    while (true) {
        if (sht40_sensor.read_temparature()) |temperature| {
            log.info("Temperature: {d} °C", .{temperature});
        } else |err| switch (err) {
            sht40.Sht40Error.WriteFailed => {
                log.err("Write to sht40 i2c sensor failed!", .{});
            },
            sht40.Sht40Error.ReadFailed => {
                log.err("Read from sht40 i2c sensor failed!", .{});
            },
        }
        idf.vTaskDelay(2000 / idf.portTICK_PERIOD_MS);
    }
}

export fn blinkclock(_: ?*anyopaque) void {
    blinkLED(1000) catch |err|
        @panic(@errorName(err));
}

// override the std panic function with idf.panic
pub const panic = idf.panic;
const log = std.log.scoped(.@"esp-idf");
pub const std_options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    // Define logFn to override the std implementation
    .logFn = idf.espLogFn,
};
