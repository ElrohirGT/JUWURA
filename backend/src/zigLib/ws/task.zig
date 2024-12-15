const std = @import("std");
const pg = @import("pg");
const uwu_log = @import("../log.zig");

pub const Errors = error{ CreateTaskError, DeleteTaskError, UpdateTaskError };

pub const Task = struct { id: i32, project_id: i32, type: []const u8 };

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

        var dataRow = try conn.row(query, params) orelse unreachable;
        defer dataRow.deinit() catch unreachable;

        const id = dataRow.get(i32, 0);
        const p_id = dataRow.get(i32, 1);
        const t_type = try alloc.dupe(u8, dataRow.get([]u8, 2));

        uwu_log.logInfo("Task created!")
            .int("id", id).int("project_id", p_id)
            .string("type", t_type)
            .log();

        break :task_creation_block Task{ .id = id, .project_id = p_id, .type = t_type };
    };

    return CreateTaskResponse{ .task = task };
}
