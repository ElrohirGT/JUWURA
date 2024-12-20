const logz = @import("logz");
const pg = @import("pg");
const uwu_log = @import("root.zig").log;

/// Tries to log a Postgres query error if it exists.
pub fn logPgError(l: logz.Logger, err: anyerror, conn: *pg.Conn) void {
    _ = l.err(err);
    if (conn.err) |pg_err| {
        _ = l.string("PGError", pg_err.message);
    }
}
