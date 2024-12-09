const std = @import("std");
const dotenv = @import("dotenv");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

/// Struct that saves information for a single WS connection.
const Context = struct { userName: []const u8, channel: []const u8, subscribeArgs: WebsocketHandler.SubscribeArgs, settings: WebsocketHandler.WebSocketSettings };
const WebsocketHandler = WebSockets.Handler(Context);

const ContextList = std.ArrayList(*Context);

/// Manages all websocket connections in a given channel.
const ContextManager = struct {
    allocator: std.mem.Allocator,
    channel: []const u8,
    lock: std.Thread.Mutex = .{},
    contexts: ContextList = undefined,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, channelName: []const u8) Self {
        return .{ .allocator = allocator, .channel = channelName, .contexts = ContextList.init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        for (self.contexts.items) |ctx| {
            self.allocator.free(ctx.userName);
        }

        self.contexts.deinit();
    }

    pub fn newContext(self: *Self, userName: []const u8) !*Context {
        self.lock.lock();
        defer self.lock.unlock();

        const ctx = try self.allocator.create(Context);
        ctx.* = .{
            .userName = userName,
            .channel = self.channel,
            // Used in subscribe()
            .subscribeArgs = .{
                .channel = self.channel,
                .force_text = true,
                .context = ctx,
            },
            // Used in upgrade()
            .settings = .{
                .on_open = on_open_websocket,
                .on_close = on_close_websocket,
                .on_message = handle_websocket_message,
                .context = ctx,
            },
        };

        try self.contexts.append(ctx);
        return ctx;
    }
};

var GlobalContextManager: ContextManager = undefined;

fn on_request(r: zap.Request) void {
    r.setHeader("Server", "JUWURA") catch unreachable;
    r.sendBody(
        \\ <html><body>
        \\ <h1>This is a simple Websocket chatroom example</h1>
        \\ </body></html>
    ) catch unreachable;
}

fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("Received illegal protocol: {s}", .{target_protocol});
        r.setStatus(.bad_request);
        r.sendBody("400 - BAD REQUEST") catch unreachable;
        return;
    }

    var context = GlobalContextManager.newContext(r.body) catch |err| {
        std.log.err("Error in websocketUpgrade(): {any}", .{err});
        return;
    };

    std.log.info("connection upgrade OK", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    });

    GlobalContextManager = ContextManager.init(gpa, "juwura-project-");
    defer GlobalContextManager.deinit();

    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .on_upgrade = on_upgrade,
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
