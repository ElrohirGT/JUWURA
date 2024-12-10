const std = @import("std");
const dotenv = @import("dotenv");
const zap = @import("zap");
const pg = @import("pg");
const ProjectsWeb = @import("endpoints/project.zig");
const juwura = @import("juwura");
const logz = @import("logz");

pub const log = std.log.scoped(.juwura);

fn on_request(r: zap.Request) void {
    r.setHeader("Server", "JUWURA") catch unreachable;
    r.sendBody(
        \\ <html><body>
        \\ <h1>This is a simple Websocket chatroom example</h1>
        \\ </body></html>
    ) catch unreachable;
}

pub fn main() !void {
    log.info("Initializing allocator...", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    log.info("Allocator initialized!", .{});

    // initialize a logging pool
    log.info("Initializing logging pool...", .{});
    try logz.setup(allocator, .{
        .level = .Info,
        .pool_size = 100,
        .buffer_size = 4096,
        .large_buffer_count = 8,
        .large_buffer_size = 16384,
        .output = .stdout,
        .encoding = .logfmt,
    });
    defer logz.deinit();
    log.info("Logging pool initialized!", .{});

    logz.info().string("msg", "Initializing env variables...").log();
    try dotenv.load(allocator, .{ .override = false });
    logz.info().string("msg", "Env variables initialized!").log();

    const pool_size = 10;
    const conn_timeout_ms = 10_000;
    const postgres_url = std.posix.getenv("POSTGRES_URL") orelse {
        logz.err().string("msg", "No POSTGRES_URL env variable supplied!").log();
        std.posix.exit(1);
    };
    const uri = try std.Uri.parse(postgres_url);
    const pool = pg.Pool.initUri(allocator, uri, pool_size, conn_timeout_ms) catch |err| {
        logz.err().string("msg", "Failed to connect to DB!").err(err).string("url", postgres_url).log();
        std.posix.exit(1);
    };
    defer pool.deinit();

    var listener = zap.Endpoint.Listener.init(allocator, .{
        .port = 3000,
        .on_request = on_request,
        .log = true,
        .max_clients = 100_000,
        .max_body_size = 1000 * 1024 * 1024,
    });

    logz.info().string("msg", "Initializing endpoints...").log();
    var projects = ProjectsWeb.init(allocator, pool, "/projects");
    try listener.register(projects.endpoint());
    logz.info().string("msg", "Endpoints initialized!").log();

    try listener.listen();
    logz.info().string("msg", "Listening on 0.0.0.0:3000").log();

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
