const std = @import("std");
const dotenv = @import("dotenv");
const zap = @import("zap");
const pg = @import("pg");
const uwu_lib = @import("juwura");
const uwu_ws = uwu_lib.ws;
const uwu_log = uwu_lib.log;
const logz = @import("logz");

const ProjectsHttp = @import("endpoints/projects.zig");
const UsersHttp = @import("endpoints/users.zig");

fn on_request(r: zap.Request) void {
    r.setHeader("Server", "JUWURA") catch unreachable;
    r.sendBody(
        \\ <html><body>
        \\ <h1>This is a simple Websocket chatroom example</h1>
        \\ </body></html>
    ) catch unreachable;
}

var GlobalWsConnectionManager: uwu_ws.ConnectionManager = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    defer switch (gpa.deinit()) {
        .leak => std.log.warn("There were memory leaks!", .{}),
        .ok => {},
    };
    const allocator = gpa.allocator();

    const WsHandler = struct {
        var alloc: std.mem.Allocator = undefined;

        fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
            uwu_log.logInfo("Received upgrade to WS connection...").log();
            if (!std.mem.eql(u8, target_protocol, "websocket")) {
                uwu_log.logWarn("received illegal protocol!").string("protocol", target_protocol).log();

                r.setStatus(.bad_request);
                r.sendBody("400 - BAD REQUEST") catch unreachable;
                return;
            }

            uwu_log.logInfo("Parsing body and queries...").log();
            r.parseBody() catch {};
            r.parseQuery();

            const email = uwu_lib.getQueryParam(alloc, &r, "email") orelse return;
            const project_id = uwu_lib.getQueryParam(alloc, &r, "projectId") orelse return;

            const conn = GlobalWsConnectionManager.newConnection(email, project_id) catch |err| {
                uwu_log.logErr("Error creating ws connection!").err(err).log();
                return;
            };

            uwu_ws.WebsocketHandler.upgrade(r.h, &conn.settings) catch |err| {
                uwu_log.logErr("Error upgrading the connection to websocket!").err(err).log();
                return;
            };

            uwu_log.logInfo("WS connection upgraded!").log();
        }
    };

    WsHandler.alloc = allocator;

    // initialize a logging pool
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

    uwu_log.logInfo("Initializing WS connection manager...").log();
    GlobalWsConnectionManager = uwu_ws.ConnectionManager.init(allocator);
    uwu_log.logInfo("Done!").log();

    uwu_log.logInfo("Initializing env variables...").log();
    dotenv.load(allocator, .{ .override = false }) catch |err| {
        uwu_log.logErr("Error initializing env variables").err(err).log();
    };
    uwu_log.logInfo("Env variables initialized!").log();

    uwu_log.logInfo("Initializing DB pool...").log();
    const pool_size = 10;
    const conn_timeout_ms = 10_000;
    const postgres_url = std.posix.getenv("POSTGRES_URL") orelse {
        uwu_log.logErr("No POSTGRES_URL env variable supplied!").log();
        std.posix.exit(1);
    };
    const uri = try std.Uri.parse(postgres_url);
    const pool = pg.Pool.initUri(allocator, uri, pool_size, conn_timeout_ms) catch |err| {
        uwu_log.logErr("Failed to connect to DB!").err(err).string("url", postgres_url).log();
        std.posix.exit(1);
    };
    defer pool.deinit();

    var listener = zap.Endpoint.Listener.init(allocator, .{
        .port = 3000,
        .on_request = on_request,
        .on_upgrade = WsHandler.on_upgrade,
        .log = true,
        .max_clients = 100_000,
        .max_body_size = 1000 * 1024 * 1024,
    });
    uwu_log.logInfo("DB Pool initialized!").log();

    uwu_log.logInfo("Initializing endpoints...").log();

    var projects = ProjectsHttp.init(allocator, pool, "/projects");
    try listener.register(projects.endpoint());

    var users = UsersHttp.init(allocator, pool, "/users");
    try listener.register(users.endpoint());

    uwu_log.logInfo("Endpoints initialized!").log();

    try listener.listen();
    uwu_log.logInfo("Listening on 0.0.0.0:3000").log();

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
