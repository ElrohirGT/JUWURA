//! JUWURA Project endpoints
//!
//! This module is based on the endpoint example inside `zap`.
//! The **whole file** acts as a struct that can be initialized with the `init` function.
const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
const uwu_lib = @import("juwura");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.utils.db;
const uwu_projects = uwu_lib.http.projects;

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

fn post_project(e: *zap.Endpoint, r: zap.Request) void {
    const self: *Self = @fieldParentPtr("ep", e);

    uwu_log.logInfo("Parsing body...").log();
    const body = r.body orelse {
        uwu_log.logErr("No body found on request!").log();
        r.setStatus(.bad_request);
        r.sendBody("NO BODY FOUND") catch unreachable;
        return;
    };

    const parsed = std.json.parseFromSlice(uwu_projects.CreateProjectRequest, self.alloc, body, .{}) catch |err| {
        uwu_log.logErr("Error in body parsing!").src(@src()).err(err).string("body", body).log();

        if (uwu_lib.errIsFromUnion(err, std.json.ParseFromValueError)) {
            uwu_log.logInfo("The body is malformed, responding 404...").log();
            r.setStatus(.bad_request);
            r.sendBody("INCORRECT BODY") catch unreachable;
        } else {
            uwu_log.logInfo("The error is internal to the server...").log();
            r.setStatus(.internal_server_error);
            r.sendBody("INTERNAL SERVER ERROR") catch unreachable;
        }

        return;
    };
    defer parsed.deinit();

    const request = parsed.value;
    uwu_log.logInfo("Body parsed!").log();

    const response = uwu_db.retryOperation(
        .{ .max_retries = 5 },
        uwu_projects.create_project,
        .{ self.alloc, self.pool, request },
        &[_]anyerror{},
    ) catch |err| switch (err) {
        uwu_projects.CreateProjectErrors.NoDBConnectionAquired => {
            r.setStatus(.internal_server_error);
            r.sendBody("NO DB CONNECTION AQUIRED") catch unreachable;
            return;
        },
        uwu_projects.CreateProjectErrors.QueryError => {
            r.setStatus(.bad_request);
            r.sendBody("QUERY ERROR") catch unreachable;
            return;
        },
    };
    const responseBody = uwu_lib.toJson(self.alloc, response) catch unreachable;
    defer self.alloc.free(responseBody);
    defer response.project.deinit(self.alloc);

    uwu_log.logInfo("Responding with body...").string("body", responseBody).log();
    r.sendJson(responseBody) catch unreachable;
}
