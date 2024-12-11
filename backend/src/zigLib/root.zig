const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
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
    // for (buffer.items) |char| {
    //     std.log.debug("{c}", .{char});
    // }

    return buffer.toOwnedSlice();
}

pub fn manageQueryError(r: *const zap.Request, conn: *const pg.Conn, err: anyerror) void {
    var l = logErr("Error in query").err(err);
    if (err == error.PG) {
        if (conn.err) |pge| {
            l = l.string("pg_error", pge.message);
        }
    }

    l.log();
    r.setStatus(.internal_server_error);
    r.sendBody("QUERY ERROR") catch unreachable;
    return;
}

pub fn manageTransactionError(r: *const zap.Request, conn: *pg.Conn, err: anyerror) void {
    manageQueryError(r, conn, err);
    conn.rollback() catch unreachable;
}
