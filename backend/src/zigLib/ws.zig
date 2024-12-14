///! Websocket module for JUWURA
const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;
const uwu_log = @import("log.zig");

/// Hashmap to store connectinos by user.
/// * Key: User email.
/// * Value: WS Connection configuration.
const ConnectionsByUser = std.StringHashMap(Connection);
/// Hashmap to store all user connections for a given project.
/// * Key: Project ID.
/// * Value: Hashmap of connections.
const UsersConnectionsByProject = std.StringHashMap(ConnectionsByUser);
/// Websocket handler according to facil.io library.
pub const WebsocketHandler = WebSockets.Handler(Connection);

/// Saves all the metadata for the websocket connection.
const Connection = struct {
    email: []const u8,
    project_id: []const u8,

    // We need to hold on to them to re-use them on every message.
    subscribeArgs: WebsocketHandler.SubscribeArgs,
    settings: WebsocketHandler.WebSocketSettings,
};

/// Manages all connections metadata.
pub const ConnectionManager = struct {
    alloc: std.mem.Allocator,
    active_projects: UsersConnectionsByProject,
    lock: std.Thread.Mutex = .{},

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .alloc = allocator, .active_projects = UsersConnectionsByProject.init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        var projects = self.active_projects.iterator();
        while (projects.next()) |kv| {
            self.alloc.free(kv.key_ptr.*);

            var connections = kv.value_ptr.*.iterator();
            while (connections.next()) |innerKv| {
                self.alloc.free(innerKv.key_ptr.*);
                self.alloc.free(innerKv.value_ptr.*);
            }

            connections.deinit();
            self.alloc.free(kv.value_ptr.*);
        }
        self.active_projects.deinit();
    }

    pub fn newConnection(self: *Self, email: []const u8, project_id: []const u8) !*Connection {
        self.lock.lock();
        defer self.lock.unlock();

        const OnCloseHandler = struct {
            var parent: *Self = undefined;
            var h_email: []const u8 = undefined;
            var h_project_id: []const u8 = undefined;

            fn on_close(connection: ?*Connection, uuid: isize) void {
                on_close_base(connection, uuid);
                parent.dropConnection(h_email, h_project_id);
            }
        };

        OnCloseHandler.parent = self;
        OnCloseHandler.h_email = email;
        OnCloseHandler.h_project_id = project_id;

        const conn = try self.alloc.create(Connection);
        conn.* = .{
            .email = email,
            .project_id = project_id,
            // NOTE: Used when subscribing to a WS!
            .subscribeArgs = .{
                .channel = project_id,
                .force_text = true,
                .context = conn,
            },
            // NOTE: Used when a connection is upgraded!
            .settings = .{
                .context = conn,
                .on_open = on_open,
                .on_close = OnCloseHandler.on_close,
                .on_message = on_message,
            },
        };

        const entry = try self.active_projects.getOrPutValue(project_id, ConnectionsByUser.init(self.alloc));
        var usersInProject = entry.value_ptr.*;
        _ = try usersInProject.getOrPutValue(email, conn.*);

        return conn;
    }

    pub fn dropConnection(self: *Self, email: []const u8, project_id: []const u8) void {
        self.lock.lock();
        defer self.lock.unlock();

        var connsByEmail: ConnectionsByUser = self.active_projects.get(project_id) orelse return;
        const conn = connsByEmail.get(email) orelse return;

        _ = connsByEmail.remove(email);
        _ = self.active_projects.remove(project_id);

        self.alloc.destroy(&conn);

        // NOTE: Maybe don't do this?
        self.alloc.free(email);
        self.alloc.free(project_id);
    }
};

fn on_open(connection: ?*Connection, handle: WebSockets.WsHandle) void {
    if (connection) |conn| {
        _ = WebsocketHandler.subscribe(handle, &conn.subscribeArgs) catch |err| {
            uwu_log.logErr("Error opening websocket").err(err).log();
            return;
        };

        var buf: [255]u8 = undefined;
        const message = std.fmt.bufPrint(&buf, "{s} joined the ws for project {s}.", .{ conn.email, conn.project_id }) catch unreachable;

        // NOTE: Sends a broadcast to all connected clients...
        WebsocketHandler.publish(.{ .channel = conn.project_id, .message = message });
        uwu_log.logInfo("New websocket connection opened!").string("innerMsg", message).log();
    }
}

fn on_close_base(connection: ?*Connection, uuid: isize) void {
    _ = uuid;

    if (connection) |conn| {
        var buf: [255]u8 = undefined;
        const message = std.fmt.bufPrint(&buf, "{s} left the ws for project {s}.", .{ conn.email, conn.project_id }) catch unreachable;

        WebsocketHandler.publish(.{ .channel = conn.project_id, .message = message });
        uwu_log.logInfo("Closed websocket connection!").string("innerMsg", message).log();
    }
}

fn on_message(connection: ?*Connection, handle: WebSockets.WsHandle, message: []const u8, is_text: bool) void {
    _ = is_text;
    _ = handle;

    if (connection) |_| {
        uwu_log.logInfo("Received a message!").string("message", message).log();
    }
}
