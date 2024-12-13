const std = @import("std");
const pg = @import("pg");
const uwu_lib = @import("../root.zig");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.utils.db;

pub const Errors = error{ CreateTaskError, DeleteTaskError, UpdateTaskError };

pub const TaskField = struct {
    id: i32,
    type: []const u8,
    value: []const u8,
};
pub const Task = struct {
    id: i32,
    parent_id: ?i32 = null,
    project_id: i32,
    short_title: []const u8,
    icon: []const u8,
    fields: []TaskField,

    /// Frees all the memory associated with the task...
    pub fn deinit(self: Task, alloc: std.mem.Allocator) void {
        alloc.free(self.short_title);
        alloc.free(self.icon);

        for (self.fields) |field| {
            alloc.free(field.value);
            alloc.free(field.type);
        }
    }
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
    const parent_id = row.get(?i32, 1);
    const project_id = row.get(i32, 2);
    const short_title = try alloc.dupe(u8, row.get([]const u8, 3));
    const icon = try alloc.dupe(u8, row.get([]const u8, 4));
    const fields = &[_]TaskField{};

    return Task{
        .id = id,
        .project_id = project_id,
        .parent_id = parent_id,
        .short_title = short_title,
        .icon = icon,
        .fields = fields,
    };
}

pub const CreateTaskRequest = struct {
    project_id: i32,
    parent_id: ?i32 = null,
    icon: []const u8,
};
pub const CreateTaskResponse = struct { task: Task };
pub fn create_task(alloc: std.mem.Allocator, pool: *pg.Pool, req: CreateTaskRequest) !CreateTaskResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    conn.begin() catch |err| {
        var l = uwu_log.logErr("Error beginning transaction!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();
        return err;
    };
    const task: Task = task_creation_block: {
        const display_id = id_obtaining_block: {
            const query =
                \\ UPDATE project SET
                \\ next_task_id = (SELECT next_task_id FROM project WHERE id=$1)+1
                \\ WHERE id=$1
                \\ RETURNING next_task_id;
            ;
            const params = .{req.project_id};
            uwu_log.logInfo("Obtaining new task ID...")
                .int("projectId", req.project_id)
                .log();

            var dataRow = conn.row(query, params) catch |err| {
                var l = uwu_log.logErr("Internal error creating task!").src(@src());
                uwu_db.logPgError(l, err, conn);
                l.log();

                conn.rollback() catch |rollBackErr| {
                    var lo = uwu_log.logErr("Error rolling back transaction!").src(@src());
                    uwu_db.logPgError(lo, rollBackErr, conn);
                    lo.log();
                    return rollBackErr;
                };

                return err;
            } orelse return error.ProjectDoesntExists;
            defer dataRow.deinit() catch unreachable;

            break :id_obtaining_block dataRow.get(i32, 0);
        };
        uwu_log.logInfo("New task ID obtained!").int("display_id", display_id).log();

        const short_title = std.fmt.allocPrint(alloc, "T-{d}", .{display_id}) catch unreachable;
        defer alloc.free(short_title);

        const query = "INSERT INTO task (parent_id, project_id, short_title, icon) VALUES ($1, $2, $3, $4) RETURNING *";
        const params = .{ req.parent_id, req.project_id, short_title, req.icon };
        uwu_log.logInfo("Creating task in project!")
            .int("projectId", req.project_id)
            .int("parentId", req.parent_id)
            .string("short_title", short_title)
            .string("icon", req.icon)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Internal error creating task!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollbackErr| {
                var lo = uwu_log.logErr("Error rolling back transaction!").src(@src());
                uwu_db.logPgError(lo, rollbackErr, conn);
                lo.log();
                return rollbackErr;
            };

            return err;
        } orelse unreachable;
        defer dataRow.deinit() catch unreachable;

        break :task_creation_block try taskFromDB(alloc, &dataRow);
    };
    conn.commit() catch |err| {
        var l = uwu_log.logErr("Error committing transaction!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();
        return err;
    };

    uwu_log.logInfo("Task created!")
        .int("projectId", task.project_id)
        .int("parentId", task.parent_id)
        .string("short_title", task.short_title)
        .string("icon", task.icon)
        .log();

    return CreateTaskResponse{ .task = task };
}

pub const UpdateTaskRequest = struct {
    task_id: i32,
    parent_id: ?i32 = null,
    short_title: []const u8,
    icon: []const u8,
};
pub const UpdateTaskResponse = struct { task: Task };
pub fn update_task(alloc: std.mem.Allocator, pool: *pg.Pool, req: UpdateTaskRequest) !UpdateTaskResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    const task: Task = task_creation_block: {
        const query =
            \\ UPDATE task SET
            \\ parent_id = $2,
            \\ short_title = $3,
            \\ icon = $4
            \\ WHERE id = $1
            \\ RETURNING *
        ;
        const params = .{ req.task_id, req.parent_id, req.short_title, req.icon };
        uwu_log.logInfo("Updating task in project...")
            .int("task_id", req.task_id)
            .int("parent_id", req.parent_id)
            .string("short_title", req.short_title)
            .string("icon", req.icon)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Error updating task!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();
            return err;
        } orelse return error.NoTaskFoundWithID;

        defer dataRow.deinit() catch unreachable;
        break :task_creation_block taskFromDB(alloc, &dataRow) catch unreachable;
    };
    uwu_log.logInfo("Task updated!")
        .int("task_id", task.id)
        .int("parent_id", task.parent_id)
        .string("short_title", task.short_title)
        .log();

    return UpdateTaskResponse{ .task = task };
}
