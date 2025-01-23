const std = @import("std");

const idf = @import("zig_idf");
const i2c = idf.i2c;

const DATA_LENGTH = 20;

pub const Sht40Error = error{ WriteFailed, ReadFailed };

pub const Sht40 = struct {
    i2c_bus_handle: idf.sys.i2c_master_bus_handle_t,
    i2c_device_handle: idf.sys.i2c_master_dev_handle_t,
    data: [DATA_LENGTH:0]u8,

    const Self = @This();
    // var data = [_:0]u8{0} ** DATA_LENGTH;

    pub fn init(i2c_bus_handle: idf.sys.i2c_master_bus_handle_t) !Sht40 {
        const i2c_device_sht4x_config: idf.sys.i2c_device_config_t = .{
            .dev_addr_length = idf.sys.i2c_addr_bit_len_t.I2C_ADDR_BIT_LEN_7,
            .device_address = 0x44,
            .scl_speed_hz = 100_000,
        };

        var i2c_device_handle: idf.sys.i2c_master_dev_handle_t = undefined;
        i2c.BUS.addDevice(i2c_bus_handle, &i2c_device_sht4x_config, &i2c_device_handle) catch unreachable;
        return .{
            .i2c_bus_handle = i2c_bus_handle,
            .i2c_device_handle = i2c_device_handle,
            // .data = [_:0]u8{0} ** DATA_LENGTH,
            .data = std.mem.zeroes([DATA_LENGTH:0]u8),
        };
    }

    pub fn deinit(self: Self) void {
        i2c.BUS.removeDevice(self.i2c_device_handle) catch unreachable;
    }

    pub fn probe(self: Self) bool {
        const ret_probe = idf.sys.i2c_master_probe(self.i2c_bus_handle, 0x44, 1000);
        return ret_probe != idf.sys.esp_err_t.ESP_OK;
    }

    pub fn read_temparature(self: Self) Sht40Error!i32 {
        // _ = self;
        // return 0.0;
        const data_write: [1:0]u8 = .{0xFD};
        //const data_write_ptr = @as([*:0]const u8, &data_write);
        const ret_w: idf.sys.esp_err_t = idf.sys.i2c_master_transmit(self.i2c_device_handle, &data_write, 1, 100);
        idf.vTaskDelay(1000 / idf.portTICK_PERIOD_MS);

        if (ret_w != idf.sys.esp_err_t.ESP_OK) {
            // log.err("Error while writing to i2c: {x}", .{@intFromEnum(ret_w)});
            return Sht40Error.WriteFailed;
        }

        idf.vTaskDelay(1000 / idf.portTICK_PERIOD_MS);

        const ret_r = idf.sys.i2c_master_receive(self.i2c_device_handle, @constCast(&self.data), DATA_LENGTH, 100);

        if (ret_r != idf.sys.esp_err_t.ESP_OK) {
            return Sht40Error.ReadFailed;
        }

        const st: u16 = (@as(u16, self.data[0]) << 8) | self.data[1];
        const temperature = (175 * (@as(f32, @floatFromInt(st)) / 65535)) - 45;
        return @intFromFloat(temperature * 100);
    }
};
