const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");

// Modules
pub const core = @import("core/root.zig");
pub const log = @import("log.zig");
pub const db = @import("db.zig");

/// Checks if a number is inside the interval [min, max).
pub fn betweenMaxExclusive(a: i32, min: i32, max: i32) bool {
    return a >= min and a < max;
}

/// Duplicates an array of `ValueType`s if the `value` is not null.
/// The caller owns the memory so make sure to call `free` afterwards.
///
/// It can fail because it needs to allocate.
pub fn dupeIfNotNull(comptime ValueType: type, alloc: std.mem.Allocator, value: ?[]ValueType) !?[]ValueType {
    if (value) |inner| {
        return try alloc.dupe(ValueType, inner);
    } else {
        return null;
    }
}

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
    return buffer.toOwnedSlice();
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

/// Configuration for retrying an operation with the function `retryOperation`.
pub const RetryConfig = struct {
    max_retries: usize = 3,
};

/// Retries a general operation according to the config.
pub fn retryOperation(config: RetryConfig, comptime okFunc: anytype, okArgs: anytype, comptime breakOnErrors: []const anyerror) @TypeOf(@call(.auto, okFunc, okArgs)) {
    for (0..~@as(usize, 0)) |i| {
        if (i != 0) {
            log.logWarn("Retrying operation!").log();
        }
        return @call(.auto, okFunc, okArgs) catch |e| {
            log.logErr("Error in operation!").err(e).log();

            for (0..breakOnErrors.len) |j| {
                const current = breakOnErrors[j];

                if (current == e) {
                    return e;
                }
            }

            if (i == config.max_retries) {
                log.logErr("Operation reached max retries!").log();
                return e;
            }
            continue;
        };
    } else unreachable;
}
