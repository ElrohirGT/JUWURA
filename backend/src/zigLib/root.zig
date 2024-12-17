const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
pub const ws = @import("ws/root.zig");
pub const http = @import("http/root.zig");
pub const log = @import("log.zig");
pub const utils = @import("./utils/root.zig");

/// Checks if a given error belongs to a given error union.
pub fn errIsFromUnion(err: anyerror, comptime ErrorSet: type) bool {
    return inline for (comptime std.meta.fields(ErrorSet)) |f| {
        if (@field(anyerror, f.name) == err) break true;
    } else false;
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

/// Common logic for managing errors inside DB queries.
/// This method responds to the HTTP request, so no longer action is needed.
pub fn manageQueryError(conn: *const pg.Conn, err: anyerror) void {
    var l = log.logErr("Error in query").err(err);
    if (err == error.PG) {
        if (conn.err) |pge| {
            l = l.string("pg_error", pge.message);
        }
    }

    l.log();
}

/// Common logic for managing errors inside DB queries in transactions.
/// This method responds to the HTTP request, so no longer action is needed.
pub fn manageTransactionError(conn: *pg.Conn, err: anyerror) !void {
    manageQueryError(conn, err);
    conn.rollback() catch |rollbackErr| {
        var l = log.logErr("Error in rollback").err(rollbackErr);
        if (err == error.PG) {
            if (conn.err) |pge| {
                l = l.string("pg_error", pge.message);
            }
        }
        l.log();
        return rollbackErr;
    };
    // utils.db.retryOperation(.{}, pg.Conn.rollback, .{conn}) catch unreachable;
}

/// Gets a query parameter from the request URL. Checks if is not null and not empty!
///
/// To use this method you previously had to call all the necessary methods of `zap.Request.getParamStr`. Which at the time of writing are:
/// * `zap.Request.parseBody()`
/// * `zap.Request.parseQuery()`
/// In that order respectively.
///
/// It sets response body and status headers when an error occurs so you just need to return.
pub fn getQueryParam(alloc: std.mem.Allocator, r: *const zap.Request, name: []const u8) ?[]const u8 {
    const maybe = r.getParamStr(alloc, name, false) catch |err| {
        log.logErr("Couldn't retrieve the query param!").string("param", name).src(@src()).err(err).log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return null;
    };
    const resource = maybe orelse {
        log.logErr("GET query param is null!").string("param", name).log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return null;
    };

    defer resource.deinit();
    // NOTE: We copy because we need to own the str, if not the defer above use will mark it as free!
    // TODO: Find a way to not allocate here?
    const paramValue = alloc.dupe(u8, resource.str) catch unreachable;

    if (paramValue.len == 0) {
        log.logErr("GET query param is empty!").string("param", name).log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return null;
    }

    return paramValue;
}
