const std = @import("std");
const builtin = @import("builtin");
const idf = @import("zig_idf");

const tag = "zig-blink";

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

    // FreeRTOS Tasks
    if (idf.xTaskCreate(blinkclock, "blink", 1024 * 2, null, 5, null) == 0) {
        @panic("Error: Task blinkclock not created!\n");
    }
}

// comptime function
fn blinkLED(delay_ms: u32) !void {
    try idf.gpio.Direction.set(
        .GPIO_NUM_0,
        .GPIO_MODE_OUTPUT,
    );
    while (true) {
        log.info("LED: ON", .{});
        try idf.gpio.Level.set(.GPIO_NUM_0, 1);

        idf.vTaskDelay(delay_ms / idf.portTICK_PERIOD_MS);

        log.info("LED: OFF", .{});
        try idf.gpio.Level.set(.GPIO_NUM_0, 0);

        idf.vTaskDelay(delay_ms / idf.portTICK_PERIOD_MS);
    }
}

// Task functions (must be exported to C ABI) - runtime functions
export fn blinkclock(_: ?*anyopaque) void {
    blinkLED(1000) catch |err|
        @panic(@errorName(err));
}

// override the std panic function with idf.panic
pub const panic = idf.panic;
const log = std.log.scoped(.@"zig-blink");
pub const std_options = std.Options{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    // Define logFn to override the std implementation
    .logFn = idf.espLogFn,
};
