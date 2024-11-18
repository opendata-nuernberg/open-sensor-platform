const std = @import("std");
const builtin = @import("builtin");
const idf = @import("esp_idf");
const OnboardLed = @import("onboard_led.zig").OnboardLed;

const i2c = idf.i2c;

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
        \\* Total: {d}
        \\* Free: {d}
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

    arraylist(allocator) catch unreachable;

    if (builtin.mode == .Debug)
        heap.dump();

    // FreeRTOS Tasks
    if (idf.xTaskCreate(foo, "foo", 1024 * 3, null, 1, null) == 0) {
        @panic("Error: Task foo not created!\n");
    }
    if (idf.xTaskCreate(bar, "bar", 1024 * 3, null, 2, null) == 0) {
        @panic("Error: Task bar not created!\n");
    }
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

fn arraylist(allocator: std.mem.Allocator) !void {
    var arr = std.ArrayList(u32).init(allocator);
    defer arr.deinit();

    try arr.append(10);
    try arr.append(20);
    try arr.append(30);

    for (arr.items) |index| {
        idf.ESP_LOG(
            allocator,
            tag,
            "Arr value: {}\n",
            .{index},
        );
    }
}

// Task functions (must be exported to C ABI) - runtime functions

export fn sht4x_task(_: ?*anyopaque) void {
    const i2cmb: idf.sys.i2c_master_bus_config_t = .{
        .i2c_port = 0,
        .flags = std.mem.zeroes(usize),
        .sda_io_num = .GPIO_NUM_5,
        .scl_io_num = .GPIO_NUM_6,
        .clk_source = idf.sys.i2c_clock_source_t.I2C_CLK_SRC_APB,
        .glitch_ignore_cnt = 7,
    };
    var i2c_bus_handle: idf.sys.i2c_master_bus_handle_t = undefined;
    i2c.BUS.add(&i2cmb, &i2c_bus_handle) catch unreachable;

    const i2c_device_sht4x_config: idf.sys.i2c_device_config_t = .{
        .dev_addr_length = idf.sys.i2c_addr_bit_len_t.I2C_ADDR_BIT_LEN_7,
        .device_address = 0x44,
        .scl_speed_hz = 400_000,
    };
    var i2c_device_handle: idf.sys.i2c_master_dev_handle_t = undefined;
    i2c.BUS.addDevice(i2c_bus_handle, &i2c_device_sht4x_config, &i2c_device_handle) catch unreachable;
    defer i2c.removeDevice(&i2c_device_handle);

    const DATA_LENGTH = 20;
    var data: [DATA_LENGTH:0]u8 = [_:0]u8{0} ** DATA_LENGTH;
    //const data: [DATA_LENGTH:0]u8 = std.mem.zeroes([DATA_LENGTH:0]u8);
    const data_rd: [*:0]u8 = &data;

    while (true) {
        //_ = idf.sys.i2c_master_receive(i2c_device_handle, data_rd, DATA_LENGTH, -1);
        log.info("Test Value: {x}", .{100});
        data_rd[0] = data_rd[0] + 1;
        log.info("Value: {x}", .{data[0]});
        idf.vTaskDelay(2000 / idf.portTICK_PERIOD_MS);
    }
}

export fn blinkclock(_: ?*anyopaque) void {
    blinkLED(1000) catch |err|
        @panic(@errorName(err));
}

export fn foo(_: ?*anyopaque) callconv(.C) void {
    while (true) {
        log.info("Demo_Task foo printing..", .{});
        idf.vTaskDelay(2000 / idf.portTICK_PERIOD_MS);
    }
}
export fn bar(_: ?*anyopaque) callconv(.C) void {
    while (true) {
        log.info("Demo_Task bar printing..", .{});
        idf.vTaskDelay(1000 / idf.portTICK_PERIOD_MS);
    }
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

const tag = "zig-example";
