///! Websocket module for JUWURA
const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
const WebSockets = zap.WebSockets;

const uwu_lib = @import("juwura");
const uwu_tasks = uwu_lib.core.tasks;
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.db;
const uwu_senku = uwu_lib.core.senku;

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

    // Helper objects used for logic
    allocator: std.mem.Allocator,
    pool: *pg.Pool,

    // We need to hold on to them to re-use them on every message.
    subscribeArgs: WebsocketHandler.SubscribeArgs,
    settings: WebsocketHandler.WebSocketSettings,
};

/// Manages all connections metadata.
pub const ConnectionManager = struct {
    alloc: std.mem.Allocator,
    pool: *pg.Pool,
    active_projects: UsersConnectionsByProject,
    lock: std.Thread.Mutex = .{},

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, pool: *pg.Pool) Self {
        return .{
            .alloc = allocator,
            .pool = pool,
            .active_projects = UsersConnectionsByProject.init(allocator),
        };
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
            .allocator = self.alloc,
            .pool = self.pool,
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
            uwu_log.logErr("Error opening websocket").src(@src()).err(err).log();
            return;
        };

        var buf = std.ArrayList(u8).init(conn.allocator);
        defer buf.deinit();
        buf.writer().print("{s} joined the ws for project {s}", .{ conn.email, conn.project_id }) catch unreachable;

        const message = buf.toOwnedSlice() catch unreachable;
        defer conn.allocator.free(message);
        uwu_log.logInfo("New websocket connection opened!").string("innerMsg", message).log();

        // NOTE: Sends a broadcast to all connected clients in the project...
        const response = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .user_connected = conn.email }) catch unreachable;
        WebsocketHandler.publish(.{ .channel = conn.project_id, .message = response });
    }
}

fn on_close_base(connection: ?*Connection, uuid: isize) void {
    _ = uuid;

    if (connection) |conn| {
        var buf = std.ArrayList(u8).init(conn.allocator);
        defer buf.deinit();
        buf.writer().print("{s} left the ws for project {s}", .{ conn.email, conn.project_id }) catch unreachable;

        const message = buf.toOwnedSlice() catch unreachable;
        defer conn.allocator.free(message);
        uwu_log.logInfo("Closed websocket connection!").string("innerMsg", message).log();

        const response = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .user_disconnected = conn.email }) catch unreachable;
        WebsocketHandler.publish(.{ .channel = conn.project_id, .message = response });
    }
}

const WebsocketAPIError = error{ MalformedMessage, InternalServerError } || uwu_tasks.Errors || uwu_senku.Errors;

const WebsocketRequest = union(enum) {
    create_task: uwu_tasks.CreateTaskRequest,
    update_task: uwu_tasks.UpdateTaskRequest,
    edit_task_field: uwu_tasks.EditTaskFieldRequest,
    get_senku_state: uwu_senku.GetSenkuStateRequest,
};
const WebsocketResponse = union(enum) {
    err: WebsocketAPIError,
    user_connected: []const u8,
    user_disconnected: []const u8,
    create_task: uwu_tasks.CreateTaskResponse,
    update_task: uwu_tasks.UpdateTaskResponse,
    edit_task_field: uwu_tasks.EditTaskFieldResponse,
    get_senku_state: uwu_senku.GetSenkuStateResponse,
};

fn on_message(connection: ?*Connection, handle: WebSockets.WsHandle, message: []const u8, is_text: bool) void {
    _ = is_text;

    if (connection) |conn| {
        const parsed = std.json.parseFromSlice(WebsocketRequest, conn.allocator, message, .{}) catch |err| {
            uwu_log.logErr("Error in parsing ws message!")
                .src(@src()).err(err)
                .string("userId", conn.email)
                .string("projectId", conn.project_id)
                .string("payload", message)
                .log();

            if (uwu_lib.errIsFromUnion(err, std.json.ParseFromValueError)) {
                uwu_log.logInfo("The message payload is malformed, responding with invalid request...").log();
                const server_error = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .err = WebsocketAPIError.MalformedMessage }) catch unreachable;
                defer conn.allocator.free(server_error);
                WebsocketHandler.write(handle, server_error, true) catch unreachable;
            } else {
                uwu_log.logInfo("The error is internal to the server...").log();
                const server_error = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .err = WebsocketAPIError.InternalServerError }) catch unreachable;
                defer conn.allocator.free(server_error);
                WebsocketHandler.write(handle, server_error, true) catch unreachable;
            }
            return;
        };
        defer parsed.deinit();
        uwu_log.logInfo("Received a valid message!").string("message", message).log();

        const request = parsed.value;
        switch (request) {
            .create_task => {
                const response: uwu_tasks.CreateTaskResponse = uwu_lib.retryOperation(
                    .{ .max_retries = 3 },
                    uwu_tasks.create_task,
                    .{ conn.allocator, conn.pool, request.create_task },
                    &[_]anyerror{error.ProjectDoesntExists},
                ) catch |err| {
                    uwu_log.logErr("An error occurred creating a task!")
                        .src(@src())
                        .err(err)
                        .string("message", message)
                        .log();
                    const serve_error = uwu_lib.toJson(
                        conn.allocator,
                        WebsocketResponse{ .err = WebsocketAPIError.CreateTaskError },
                    ) catch unreachable;
                    defer conn.allocator.free(serve_error);

                    WebsocketHandler.write(handle, serve_error, true) catch unreachable;
                    return;
                };
                defer response.task.deinit(conn.allocator);

                const json_response = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .create_task = response }) catch unreachable;
                defer conn.allocator.free(json_response);

                WebsocketHandler.publish(.{ .channel = conn.project_id, .message = json_response });
            },
            .update_task => {
                const response: uwu_tasks.UpdateTaskResponse = uwu_lib.retryOperation(
                    .{ .max_retries = 3 },
                    uwu_tasks.update_task,
                    .{ conn.allocator, conn.pool, request.update_task },
                    &[_]anyerror{error.NoTaskFoundWithID},
                ) catch |err| {
                    uwu_log.logErr("An error occurred updating a task!").src(@src()).err(err).string("message", message).log();
                    const serve_error = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .err = WebsocketAPIError.UpdateTaskError }) catch unreachable;
                    defer conn.allocator.free(serve_error);

                    WebsocketHandler.write(handle, serve_error, true) catch unreachable;
                    return;
                };
                defer response.task.deinit(conn.allocator);

                const json_response = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .update_task = response }) catch unreachable;
                defer conn.allocator.free(json_response);

                WebsocketHandler.publish(.{ .channel = conn.project_id, .message = json_response });
            },
            .edit_task_field => {
                const response: uwu_tasks.EditTaskFieldResponse = uwu_lib.retryOperation(.{ .max_retries = 3 }, uwu_tasks.edit_task_field, .{ conn.allocator, conn.pool, request.edit_task_field }, &[_]anyerror{}) catch |err| {
                    uwu_log.logErr("An error occurred updating a task field!").src(@src()).err(err).string("message", message).log();
                    const serve_error = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .err = WebsocketAPIError.EditTaskFieldError }) catch unreachable;
                    defer conn.allocator.free(serve_error);

                    WebsocketHandler.write(handle, serve_error, true) catch unreachable;
                    return;
                };

                const json_response = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .edit_task_field = response }) catch unreachable;
                defer conn.allocator.free(json_response);

                WebsocketHandler.publish(.{ .channel = conn.project_id, .message = json_response });
            },

            .get_senku_state => {
                const response: uwu_senku.GetSenkuStateResponse = uwu_lib.retryOperation(.{ .max_retries = 3 }, uwu_senku.get_senku_state, .{ conn.allocator, conn.pool, request.get_senku_state }, &[_]anyerror{}) catch |err| {
                    uwu_log.logErr("An error ocurred getting the senku state!").src(@src()).err(err).string("message", message).log();
                    const serve_error = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .err = WebsocketAPIError.GetSenkuStateError }) catch unreachable;
                    defer conn.allocator.free(serve_error);

                    WebsocketHandler.write(handle, serve_error, true) catch unreachable;
                    return;
                };

                const json_response = uwu_lib.toJson(conn.allocator, WebsocketResponse{ .get_senku_state = response }) catch unreachable;
                defer conn.allocator.free(json_response);

                WebsocketHandler.write(handle, json_response, true) catch unreachable;
            },
        }
    }
}
