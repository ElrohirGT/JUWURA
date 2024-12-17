const std = @import("std");
const pg = @import("pg");
const uwu_lib = @import("../root.zig");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.utils.db;

pub const Errors = error{ CreateTaskError, DeleteTaskError, UpdateTaskError };

pub const Task = struct {
    id: i32,
    project_id: i32,
    type: []const u8,
    name: ?[]const u8 = null,
    due_date: ?i64 = null,
    status: ?[]const u8 = null,
    sprint: ?i32 = null,
    priority: ?[]const u8 = null,
};

/// Duplicates an array of `ValueType`s if the `value` is not null.
/// The caller owns the memory so make sure to call `free` afterwards.
///
/// It can fail because it needs to allocate.
fn dupeIfNotNull(comptime ValueType: type, alloc: std.mem.Allocator, value: ?[]ValueType) !?[]ValueType {
    if (value) |inner| {
        return try alloc.dupe(ValueType, inner);
    } else {
        return null;
    }
}

fn taskFromDB(alloc: std.mem.Allocator, row: *pg.QueryRow) !Task {
    const id = row.get(i32, 0);
    const p_id = row.get(i32, 1);
    const t_type = try alloc.dupe(u8, row.get([]u8, 2));
    const name = try dupeIfNotNull(u8, alloc, row.get(?[]u8, 3));
    const due_date = row.get(?i64, 4);
    const status = try dupeIfNotNull(u8, alloc, row.get(?[]u8, 5));
    const sprint = row.get(?i32, 6);
    const priority = try dupeIfNotNull(u8, alloc, row.get(?[]u8, 7));

    return Task{ .id = id, .project_id = p_id, .type = t_type, .name = name, .due_date = due_date, .status = status, .sprint = sprint, .priority = priority };
}

pub const CreateTaskRequest = struct {
    project_id: i32,
    task_type: []const u8,
};
pub const CreateTaskResponse = struct { task: Task };
pub fn create_task(alloc: std.mem.Allocator, pool: *pg.Pool, req: CreateTaskRequest) !CreateTaskResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    const task: Task = task_creation_block: {
        const query = "INSERT INTO task (project_id, type) VALUES ($1, $2) RETURNING *";
        const params = .{ req.project_id, req.task_type };
        uwu_log.logInfo("Creating task in project!")
            .int("projectId", req.project_id)
            .string("type", req.task_type)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Internal error creating task!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();
            return err;
        } orelse unreachable;
        defer dataRow.deinit() catch unreachable;

        break :task_creation_block try taskFromDB(alloc, &dataRow);
    };

    uwu_log.logInfo("Task created!")
        .int("id", task.id)
        .int("project_id", task.project_id)
        .string("type", task.type)
        .log();

    return CreateTaskResponse{ .task = task };
}

pub const UpdateTaskRequest = struct { id: i32, project_id: i32, type: []const u8, name: ?[]const u8, due_date: ?i64, status: ?[]const u8, sprint: ?i32, priority: ?[]const u8 };
pub const UpdateTaskResponse = struct { task: Task };
pub fn update_task(alloc: std.mem.Allocator, pool: *pg.Pool, req: UpdateTaskRequest) !UpdateTaskResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    const task: Task = task_creation_block: {
        const query =
            \\ UPDATE task SET
            \\ type = $1,
            \\ name = $2,
            \\ due_date = $3,
            \\ status = $4,
            \\ sprint = $5,
            \\ priority = $6
            \\ WHERE id = $7
            \\ RETURNING *
        ;
        const params = .{ req.type, req.name, req.due_date, req.status, req.sprint, req.priority, req.id };
        uwu_log.logInfo("Updating task in project...")
            .int("id", req.id)
            .string("type", req.type)
            .string("name", req.name)
            .int("due_date", req.due_date)
            .string("status", req.status)
            .int("sprint", req.sprint)
            .string("priority", req.priority)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Internal error updating task!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();
            return err;
        } orelse unreachable;

        // var dataRow = try conn.row(query, params) orelse unreachable;
        defer dataRow.deinit() catch unreachable;
        break :task_creation_block taskFromDB(alloc, &dataRow) catch unreachable;
    };
    uwu_log.logInfo("Task updated!")
        .int("id", task.id)
        .string("type", task.type)
        .string("name", task.name)
        .int("due_date", task.due_date)
        .string("status", task.status)
        .int("sprint", task.sprint)
        .string("priority", task.priority)
        .log();

    return UpdateTaskResponse{ .task = task };
}
