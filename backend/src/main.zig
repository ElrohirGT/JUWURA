const std = @import("std");
const dotenv = @import("dotenv");
const zap = @import("zap");
const pg = @import("pg");
const juwura = @import("juwura");

pub const log = std.log.scoped(.juwura);

var pool: *pg.Pool = undefined;

// fn on_request(r: zap.Request) void {
//     r.setHeader("Server", "JUWURA") catch unreachable;
//     r.sendBody(
//         \\ <html><body>
//         \\ <h1>This is a simple Websocket chatroom example</h1>
//         \\ </body></html>
//     ) catch unreachable;
// }

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();

    try dotenv.load(allocator, .{ .override = false });

    const pool_size = 10;
    const conn_timeout_ms = 10_000;
    const postgres_url = std.posix.getenv("POSTGRES_URL") orelse unreachable;
    const uri = try std.Uri.parse(postgres_url);
    pool = pg.Pool.initUri(allocator, uri, pool_size, conn_timeout_ms) catch |err| {
        log.err("Failed to connect: {}", .{err});
        std.posix.exit(1);
    };
    defer pool.deinit();

    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = juwura.on_request,
        .log = true,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
