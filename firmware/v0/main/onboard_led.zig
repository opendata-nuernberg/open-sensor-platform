const idf = @import("zig_idf");

pub const OnboardLed = struct {
    const Self = @This();

    pin: idf.sys.gpio_num_t = .GPIO_NUM_0,

    pub fn init(self: Self) !void {
        try idf.gpio.Direction.set(
            self.pin,
            .GPIO_MODE_OUTPUT,
        );
    }

    pub fn on(self: Self) !void {
        try idf.gpio.Level.set(self.pin, 1);
    }

    pub fn off(self: Self) !void {
        try idf.gpio.Level.set(self.pin, 0);
    }
};
