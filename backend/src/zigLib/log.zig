const std = @import("std");
const logz = @import("logz");

pub fn init(alloc: std.mem.Allocator) !void {
    try logz.setup(alloc, .{
        .level = .Info,
        .pool_size = 100,
        .buffer_size = 4096,
        .large_buffer_count = 8,
        .large_buffer_size = 16384,
        .output = .stdout,
        .encoding = .logfmt,
    });
}

pub fn deinit() void {
    logz.deinit();
}

pub fn logInfo(msg: []const u8) logz.Logger {
    return logz.info().string("msg", msg);
}

pub fn logDebug(msg: []const u8) logz.Logger {
    return logz.debug().string("msg", msg);
}

pub fn logWarn(msg: []const u8) logz.Logger {
    return logz.warn().string("msg", msg);
}

pub fn logErr(msg: []const u8) logz.Logger {
    return logz.err().string("msg", msg);
}
