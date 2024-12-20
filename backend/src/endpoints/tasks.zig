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
const uwu_tasks = uwu_lib.core.tasks;

pub const Self = @This();

alloc: std.mem.Allocator = undefined,
ep: zap.Endpoint = undefined,
pool: *pg.Pool,

pub fn init(a: std.mem.Allocator, pool: *pg.Pool, path: []const u8) Self {
    return .{ .alloc = a, .pool = pool, .ep = zap.Endpoint.init(.{
        .path = path,
        .get = get_task,
    }) };
}

pub fn endpoint(self: *Self) *zap.Endpoint {
    return &self.ep;
}

fn get_task(e: *zap.Endpoint, r: zap.Request) void {
    const self: *Self = @fieldParentPtr("ep", e);

    uwu_log.logInfo("Parsing body...").log();
    // Expected to fail since is a GET request.
    // No body should be present...
    r.parseBody() catch {};
    uwu_log.logInfo("Body parsed!").log();

    uwu_log.logInfo("Parsing queries...").log();
    r.parseQuery();

    const maybeTaskId = r.getParamStr(self.alloc, "taskId", false) catch |err| {
        uwu_log.logErr("Couldn't retrieve `taskId` GET param!").src(@src()).err(err).log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    };
    const taskIdResource = maybeTaskId orelse {
        uwu_log.logErr("`taskId` GET param is null!").log();
        r.setStatus(.bad_request);
        r.sendBody("BAD REQUEST PARAMS") catch unreachable;
        return;
    };

    defer taskIdResource.deinit();
    const task_id: i32 = std.fmt.parseInt(i32, taskIdResource.str, 10) catch |err| {
        uwu_log.logErr("TaskId must be a number!").err(err).log();
        r.setStatus(.bad_request);
        r.sendBody("TASK_ID MUST BE A NUMBER") catch unreachable;
        return;
    };

    const get_params = uwu_tasks.GetTaskRequest{ .task_id = task_id };
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

    const response: uwu_tasks.GetTaskResponse = uwu_lib.retryOperation(
        .{ .max_retries = 3 },
        uwu_tasks.get_task,
        .{ self.alloc, self.pool, get_params },
        &[_]anyerror{error.NoTaskFound},
    ) catch |err| switch (err) {
        error.NoTaskFound => {
            r.setStatus(.not_found);
            r.sendBody("TASK DOESN'T EXISTS") catch unreachable;
            return;
        },
        else => {
            r.setStatus(.internal_server_error);
            r.sendBody("INTERNAL ERROR") catch unreachable;
            return;
        },
    };

    const json_response = uwu_lib.toJson(self.alloc, response) catch unreachable;
    defer self.alloc.free(json_response);

    uwu_log.logInfo("Responding with body...").string("body", json_response).log();
    r.sendJson(json_response) catch unreachable;
}
