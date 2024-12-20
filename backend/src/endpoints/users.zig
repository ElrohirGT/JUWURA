//! JUWURA User endpoints
//!
//! This module is based on the endpoint example inside `zap`.
//! The **whole file** acts as a struct that can be initialized with the `init` function.

const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");

const uwu_lib = @import("juwura");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.db;

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

    uwu_log.logInfo("Parsing body...").log();
    // Expected to fail since is a GET request.
    // No body should be present...
    r.parseBody() catch {};
    uwu_log.logInfo("Body parsed!").log();

    uwu_log.logInfo("Parsing queries...").log();
    r.parseQuery();

    const maybeEmail = r.getParamStr(self.alloc, "email", false) catch |err| {
        uwu_log.logErr("Couldn't retrieve `email` GET param!").src(@src()).err(err).log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    };
    const emailResource = maybeEmail orelse {
        uwu_log.logErr("`email` GET param is null!").log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    };

    defer emailResource.deinit();
    const email: []const u8 = emailResource.str;

    if (email.len == 0) {
        uwu_log.logErr("`email` GET param is empty!").log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    }

    const get_params = GetUserParams{ .email = email };
    uwu_log.logInfo("Queries parsed!").log();

    uwu_log.logInfo("Getting DB connection...").log();
    const conn = self.pool.acquire() catch |err| {
        uwu_log.logErr("Error in DB connection").src(@src()).err(err).log();
        r.setStatus(.internal_server_error);
        r.sendBody("NO DB CONNECTION AQUIRED") catch unreachable;
        return;
    };
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    const user: AppUser = user_get_block: {
        const query = "SELECT * FROM app_user WHERE email = $1 LIMIT 1";
        const params = .{get_params.email};

        uwu_log.logInfo("Selecting user in DB...")
            .string("query", query)
            .string("email", get_params.email)
            .log();
        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Error selecting user in DB...").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            r.setStatus(.bad_request);
            r.sendBody("QUERY ERROR") catch unreachable;
            return;
        } orelse {
            uwu_log.logErr("No user found with email found!").string("email", get_params.email).log();
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
    uwu_log.logInfo("User selected!")
        .string("email", user.email)
        .string("name", user.name)
        .string("photo_url", user.photo_url)
        .log();

    const response = GetUserResponse{ .user = user };
    const responseBody = uwu_lib.toJson(self.alloc, response) catch unreachable;

    uwu_log.logInfo("Responding with body...").string("body", responseBody).log();
    r.sendJson(responseBody) catch unreachable;
}
