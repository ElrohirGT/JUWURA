//! JUWURA Project endpoints
//!
//! This module is based on the endpoint example inside `zap`.
//! The **whole file** acts as a struct that can be initialized with the `init` function.
const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
const juwura = @import("juwura");

pub const Self = @This();

alloc: std.mem.Allocator = undefined,
ep: zap.Endpoint = undefined,
pool: *pg.Pool,

/// Struct that represents a project in JUWURA
const Project = struct { id: i32, name: []u8, photo_url: []u8, icon: []u8 };

pub fn init(a: std.mem.Allocator, pool: *pg.Pool, path: []const u8) Self {
    return .{ .alloc = a, .pool = pool, .ep = zap.Endpoint.init(.{ .path = path, .post = post_project }) };
}

pub fn endpoint(self: *Self) *zap.Endpoint {
    return &self.ep;
}

const PostProjectRequest = struct { email: []u8, name: []u8, photo_url: []u8, now_timestamp: i64, icon: [4]u8, members: [][]u8 };
const PostProjectResponse = struct { project: Project };
fn post_project(e: *zap.Endpoint, r: zap.Request) void {
    const self: *Self = @fieldParentPtr("ep", e);

    juwura.logInfo("Parsing body...").log();
    const body = r.body orelse {
        juwura.logErr("No body found on request!").log();
        r.setStatus(.bad_request);
        r.sendBody("NO BODY FOUND") catch unreachable;
        return;
    };

    const parsed = std.json.parseFromSlice(PostProjectRequest, self.alloc, body, .{}) catch |err| {
        juwura.logErr("Error in body parsing!").err(err).string("body", body).log();

        switch (err) {
            std.json.ParseFromValueError.Overflow,
            std.json.ParseFromValueError.OutOfMemory,
            std.json.ParseFromValueError.UnknownField,
            std.json.ParseFromValueError.MissingField,
            std.json.ParseFromValueError.InvalidNumber,
            std.json.ParseFromValueError.InvalidEnumTag,
            std.json.ParseFromValueError.DuplicateField,
            std.json.ParseFromValueError.LengthMismatch,
            std.json.ParseFromValueError.UnexpectedToken,
            std.json.ParseFromValueError.InvalidCharacter,
            => {
                juwura.logInfo("The body is malformed, responding 404...").log();
                r.setStatus(.bad_request);
                r.sendBody("INCORRECT BODY") catch unreachable;
            },
            else => {
                juwura.logInfo("The error is internal to the server...").log();
                r.setStatus(.internal_server_error);
                r.sendBody("INTERNAL SERVER ERROR") catch unreachable;
            },
        }

        return;
    };
    defer parsed.deinit();

    const request = parsed.value;
    juwura.logInfo("Body parsed!").log();

    juwura.logInfo("Getting DB connection...").log();
    const conn = self.pool.acquire() catch |err| {
        juwura.logErr("Error in DB connection").err(err).log();
        r.setStatus(.internal_server_error);
        r.sendBody("NO DB CONNECTION AQUIRED") catch unreachable;
        return;
    };
    defer conn.release();
    juwura.logInfo("Connection aquired!").log();

    conn.begin() catch unreachable;
    const project: Project = project_creation_block: {
        const query = "INSERT INTO project (name, photo_url, icon) VALUES ($1, $2, $3) RETURNING *";
        const params = .{ request.name, request.photo_url, request.icon };
        juwura.logInfo("Creating project in DB...")
            .string("query", query)
            .string("name", request.name)
            .string("photo_url", request.photo_url)
            .string("icon", &request.icon)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            juwura.manageTransactionError(&r, conn, err);
            return;
        } orelse unreachable;
        defer dataRow.deinit() catch unreachable;

        const id = dataRow.get(i32, 0);
        const name = dataRow.get([]u8, 1);
        const url = dataRow.get([]u8, 2);
        const icon = dataRow.get([]u8, 3);

        break :project_creation_block Project{ .id = id, .name = name, .photo_url = url, .icon = icon };
    };
    juwura.logInfo("Project created!")
        .int("id", project.id)
        .string("name", project.name)
        .string("photo_url", project.photo_url)
        .string("icon", project.icon)
        .log();

    const response = PostProjectResponse{ .project = project };
    const responseBody = juwura.toJson(self.alloc, response) catch unreachable;

    juwura.logInfo("Adding members to project...").log();
    for (request.members) |memberEmail| {
        add_member_to_project(memberEmail, conn, project.id, request.now_timestamp) catch |err| {
            juwura.manageTransactionError(&r, conn, err);
            return;
        };
    }
    juwura.logInfo("Members added!").log();

    juwura.logInfo("Adding creator to project...").log();
    add_member_to_project(request.email, conn, project.id, request.now_timestamp) catch |err| {
        juwura.manageTransactionError(&r, conn, err);
        return;
    };
    juwura.logInfo("Creator added!").log();

    conn.commit() catch unreachable;
    juwura.logInfo("Responding with body...").string("body", responseBody).log();
    r.sendJson(responseBody) catch unreachable;
}

fn add_member_to_project(memberEmail: []u8, conn: *pg.Conn, projectId: i32, now_timestamp: i64) !void {
    const query = "INSERT INTO project_member (project_id, user_id, last_visited) VALUES ($1, $2, $3)";
    const params = .{ projectId, memberEmail, now_timestamp };

    juwura.logDebug("Adding member to project...")
        .string("query", query)
        .int("projectId", projectId)
        .string("userEmail", memberEmail)
        .int("last_visited", now_timestamp)
        .log();
    _ = try conn.exec(query, params);
    juwura.logDebug("Member added to project!").log();
}
