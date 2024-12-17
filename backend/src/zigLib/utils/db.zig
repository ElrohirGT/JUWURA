const logz = @import("logz");
const uwu_log = @import("../log.zig");
const pg = @import("pg");

pub const RetryConfig = struct {
    max_retries: usize = 3,
};

/// Tries to log a Postgres query error if it exists.
pub fn logPgError(l: logz.Logger, err: anyerror, conn: *pg.Conn) void {
    _ = l.err(err);
    if (conn.err) |pg_err| {
        _ = l.string("PGError", pg_err.message);
    }
}

/// Retries a general operation according to the config.
pub fn retryOperation(config: RetryConfig, comptime okFunc: anytype, okArgs: anytype) @TypeOf(@call(.auto, okFunc, okArgs)) {
    for (0..~@as(usize, 0)) |i| {
        if (i != 0) {
            uwu_log.logWarn("Retrying operation!").log();
        }
        return @call(.auto, okFunc, okArgs) catch |e| {
            uwu_log.logErr("Error in operation!").err(e).log();

            if (i == config.max_retries) {
                uwu_log.logErr("Operation reached max retries!").log();
                return e;
            }
            continue;
        };
    } else unreachable;
}
