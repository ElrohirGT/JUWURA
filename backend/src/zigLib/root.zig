const std = @import("std");
const zap = @import("zap");
const logz = @import("logz");

pub fn logInfo(msg: []const u8) logz.Logger {
    return logz.info().string("msg", msg);
}

pub fn logWarn(msg: []const u8) logz.Logger {
    return logz.warn().string("msg", msg);
}

pub fn logErr(msg: []const u8) logz.Logger {
    return logz.err().string("msg", msg);
}

/// Converts a given value into a JSON.
/// Because the JSON can be arbitrarily large it needs an allocator.
pub fn toJson(alloc: std.mem.Allocator, value: anytype) ![]u8 {
    var buffer = std.ArrayList(u8).init(alloc);
    defer buffer.deinit();

    try std.json.stringify(value, .{}, buffer.writer());
    for (buffer.items) |char| {
        std.log.debug("{c}", .{char});
    }

    return buffer.toOwnedSlice();
}

pub fn on_request(r: zap.Request) void {
    r.setHeader("Server", "JUWURA") catch unreachable;
    r.sendBody(
        \\ <html><body>
        \\ <h1>This is a simple Websocket chatroom example</h1>
        \\ </body></html>
    ) catch unreachable;
}
