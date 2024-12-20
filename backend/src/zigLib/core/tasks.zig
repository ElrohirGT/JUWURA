const std = @import("std");
const pg = @import("pg");

const uwu_lib = @import("../root.zig");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.db;

pub const Errors = error{
    CreateTaskError,
    DeleteTaskError,
    UpdateTaskError,
    EditTaskFieldError,
};

/// Represents a field for a given task.
pub const TaskField = struct {
    id: i32,
    name: []const u8,
    type: []const u8,
    value: ?[]const u8 = null,

    /// Deallocates all strings from this TaskField instance.
    pub fn deinit(self: TaskField, alloc: std.mem.Allocator) void {
        alloc.free(self.name);
        alloc.free(self.type);
        if (self.value) |inner| {
            alloc.free(inner);
        }
    }

    pub fn fromDB(alloc: std.mem.Allocator, row: pg.Row) !TaskField {
        const id = row.get(i32, 0);
        const name = try alloc.dupe(u8, row.get([]const u8, 1));
        const field_type = try alloc.dupe(u8, row.get([]const u8, 2));
        const value = try uwu_lib.dupeIfNotNull(u8, alloc, row.get(?[]u8, 3));

        return TaskField{
            .id = id,
            .name = name,
            .type = field_type,
            .value = value,
        };
    }
};
/// Container for all task data.
pub const Task = struct {
    id: i32,
    parent_id: ?i32 = null,
    project_id: i32,
    short_title: []const u8,
    icon: []const u8,
    fields: []TaskField,

    /// Frees all the memory associated with the task.
    /// This includes the task fields!
    pub fn deinit(self: Task, alloc: std.mem.Allocator) void {
        alloc.free(self.short_title);
        alloc.free(self.icon);

        for (self.fields) |field| {
            field.deinit(alloc);
        }
    }

    pub fn fromDB(alloc: std.mem.Allocator, row: pg.QueryRow) !Task {
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
};

pub const GetTaskRequest = struct { task_id: i32 };
pub const GetTaskResponse = struct { task: Task };
pub fn get_task(alloc: std.mem.Allocator, pool: *pg.Pool, req: GetTaskRequest) !GetTaskResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    var task: Task = get_task_block: {
        const query =
            \\ SELECT * FROM task WHERE id = $1
        ;
        const params = .{req.task_id};
        uwu_log.logInfo("Getting task from DB...")
            .int("task_id", req.task_id)
            .log();

        var row = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Error getting task!").src(@src()).int("task_id", req.task_id);
            uwu_db.logPgError(l, err, conn);
            l.log();
            return err;
        } orelse return error.NoTaskFound;
        defer row.deinit() catch {};

        break :get_task_block try Task.fromDB(alloc, row);
    };

    const task_fields: []TaskField = get_task_fields: {
        // Selects:
        // - task_field_id
        // - task_field_name
        // - task_field_type_name
        // - task_field_value
        const query =
            \\ select
            \\ 	tf.id,
            \\ 	tf."name",
            \\ 	tft."name",
            \\ 	tfft.value
            \\ from
            \\ 	task_field tf
            \\ left join task_fields_for_task tfft on
            \\ 	tf.id = tfft.task_field_id
            \\ left join task_field_type tft on
            \\ 	tft.id = tf.task_field_type_id
            \\ left join task t on
            \\ 	t.id = tfft.task_id
            \\ where
            \\ 	tfft.task_id = $1
            \\ 	and tf.project_id = t.project_id 
        ;
        const params = .{req.task_id};
        uwu_log.logInfo("Getting task fields...")
            .string("query", query)
            .int("task_id", req.task_id)
            .log();

        var result = conn.query(query, params) catch |err| {
            var l = uwu_log.logErr("Error getting task fields!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();
            return err;
        };
        defer result.deinit();

        const assumed_fields_per_task = 8;
        var field_list = try std.ArrayList(TaskField).initCapacity(alloc, assumed_fields_per_task);
        defer field_list.deinit();

        while (result.next() catch |err| {
            var l = uwu_log.logErr("Error getting next task field!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();
            return err;
        }) |row| {
            const field = try TaskField.fromDB(alloc, row);
            try field_list.append(field);
        }

        break :get_task_fields try field_list.toOwnedSlice();
    };

    uwu_log.logInfo("Got task fields!").int("quantity", task_fields.len).log();

    task.fields = task_fields;
    return GetTaskResponse{ .task = task };
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

        break :task_creation_block try Task.fromDB(alloc, dataRow);
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
        break :task_creation_block Task.fromDB(alloc, dataRow) catch unreachable;
    };
    uwu_log.logInfo("Task updated!")
        .int("task_id", task.id)
        .int("parent_id", task.parent_id)
        .string("short_title", task.short_title)
        .log();

    return UpdateTaskResponse{ .task = task };
}

pub const EditTaskFieldRequest = struct {
    task_id: i32,
    task_field_id: i32,
    value: ?[]const u8 = null,
};
pub const EditTaskFieldResponse = struct { task: Task };
pub fn edit_task_field(alloc: std.mem.Allocator, pool: *pg.Pool, req: EditTaskFieldRequest) !EditTaskFieldResponse {
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

    {
        const query =
            \\ INSERT INTO task_fields_for_task (task_id, task_field_id, value)
            \\ VALUES ($1, $2, $3)
            \\ ON CONFLICT DO UPDATE SET
            \\ value = $3
            \\ WHERE task_id = $1 AND task_field_id = $2
        ;
        const params = .{ req.task_id, req.task_field_id, req.value };
        uwu_log.logInfo("Inserting/Updating task field...")
            .string("query", query)
            .int("task_id", req.task_id)
            .int("task_field_id", req.task_field_id)
            .string("value", req.value)
            .log();

        _ = conn.exec(query, params) catch |err| {
            var l = uwu_log.logErr("Internal error inserting/updating task field!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error rolling back transaction!").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
                return rollBackErr;
            };

            return err;
        };
    }

    uwu_log.logInfo("Task updated/inserted!").log();

    const response: GetTaskResponse = try get_task(alloc, pool, GetTaskRequest{ .task_id = req.task_id });
    return EditTaskFieldResponse{ .task = response.task };
}
