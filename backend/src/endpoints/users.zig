//! JUWURA User endpoints
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

/// Struct that represents a user in JUWURA
const AppUser = struct { email: []const u8, name: []const u8, photo_url: []const u8 };

pub fn init(a: std.mem.Allocator, pool: *pg.Pool, path: []const u8) Self {
    return .{ .alloc = a, .pool = pool, .ep = zap.Endpoint.init(.{ .path = path, .get = get_user }) };
}

pub fn endpoint(self: *Self) *zap.Endpoint {
    return &self.ep;
}

const GetUserParams = struct { email: []const u8 };
const GetUserResponse = struct { user: AppUser };
fn get_user(e: *zap.Endpoint, r: zap.Request) void {
    const self: *Self = @fieldParentPtr("ep", e);

    juwura.logInfo("Parsing body...").log();
    // Expected to fail since is a GET request.
    // No body should be present...
    r.parseBody() catch {};
    juwura.logInfo("Body parsed!").log();

    juwura.logInfo("Parsing queries...").log();
    r.parseQuery();

    const maybeEmail = r.getParamStr(self.alloc, "email", false) catch |err| {
        juwura.logErr("Couldn't retrieve `email` GET param!").err(err).log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    };
    const emailResource = maybeEmail orelse {
        juwura.logErr("`email` GET param is null!").log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    };

    defer emailResource.deinit();
    const email: []const u8 = emailResource.str;

    if (email.len == 0) {
        juwura.logErr("`email` GET param is empty!").log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    }

    const get_params = GetUserParams{ .email = email };
    juwura.logInfo("Queries parsed!").log();

    juwura.logInfo("Getting DB connection...").log();
    const conn = self.pool.acquire() catch |err| {
        juwura.logErr("Error in DB connection").err(err).log();
        r.setStatus(.internal_server_error);
        r.sendBody("NO DB CONNECTION AQUIRED") catch unreachable;
        return;
    };
    defer conn.release();
    juwura.logInfo("Connection aquired!").log();

    const user: AppUser = user_get_block: {
        const query = "SELECT * FROM app_user WHERE email = $1 LIMIT 1";
        const params = .{get_params.email};

        juwura.logInfo("Selecting user in DB...")
            .string("query", query)
            .string("email", get_params.email)
            .log();
        var dataRow = conn.row(query, params) catch |err| {
            juwura.manageQueryError(&r, conn, err);
            return;
        } orelse {
            juwura.logErr("No user found with email found!").string("email", get_params.email).log();
            r.setStatus(.not_found);
            r.sendBody("USER DOESN'T EXISTS") catch unreachable;
            return;
        };

        defer dataRow.deinit() catch unreachable;
        const db_email = dataRow.get([]const u8, 0);
        const name = dataRow.get([]const u8, 1);
        const photo_url = dataRow.get([]const u8, 2);

        const app_user = AppUser{ .email = db_email, .name = name, .photo_url = photo_url };
        break :user_get_block app_user;
    };
    juwura.logInfo("User selected!")
        .string("email", user.email)
        .string("name", user.name)
        .string("photo_url", user.photo_url)
        .log();

    const response = GetUserResponse{ .user = user };
    const responseBody = juwura.toJson(self.alloc, response) catch unreachable;

    juwura.logInfo("Responding with body...").string("body", responseBody).log();
    r.sendJson(responseBody) catch unreachable;
}
