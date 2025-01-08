const pg = @import("pg");
const std = @import("std");

const uwu_lib = @import("../root.zig");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.db;

pub const Errors = error{};

const CellCoordinates = struct { row: i32, column: i32 };

const Cell = struct {
    id: i32,
    due_date: i64,
    title: ?[]const u8,
    status: ?[]const u8,
    icon: []const u8,
    progress: f32,
    coordinates: CellCoordinates,

    pub fn fromDBRow(alloc: std.mem.Allocator, row: pg.Row) !Cell {
        const id = row.get(i32, 0);
        const due_date = row.get(i64, 1);
        const title = try uwu_lib.dupeIfNotNull(u8, alloc, row.get([]const u8, 2));
        const status = try uwu_lib.dupeIfNotNull(u8, alloc, row.get([]const u8, 3));
        const icon = try alloc.dupe(u8, row.get([]const u8, 4));
        const progress = row.get(f32, 5);
        const senku_column = row.get(i32, 6);
        const senku_row = row.get(i32, 7);
        const coordinates = CellCoordinates{ .row = senku_row, .column = senku_column };

        return .{
            .id = id,
            .due_date = due_date,
            .title = title,
            .status = status,
            .icon = icon,
            .progress = progress,
            .coordinates = coordinates,
        };
    }

    pub fn deinit(self: Cell, alloc: std.mem.Allocator) void {
        if (self.title) |inner| {
            alloc.free(inner);
        }
        if (self.status) |inner| {
            alloc.free(inner);
        }
        alloc.free(self.icon);
    }
};

const TaskConnection = struct { start: CellCoordinates, end: CellCoordinates };

pub const GRID_SIZE = 10;
pub const SenkuState = struct { cells: [][]?Cell, connections: []TaskConnection };

pub const GetSenkuStateRequest = struct { project_id: i32 };
pub const GetSenkuStateResponse = struct { state: SenkuState };
pub fn get_senku_state(alloc: std.mem.Allocator, pool: *pg.Pool, req: GetSenkuStateRequest) !void {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    uwu_log.logInfo("Getting tasks from DB...");
    const tasks: []Cell = get_tasks_block: {
        const params = .{req.project_id};
        const query =
            \\ select 
            \\	t.id,
            \\	(
            \\	select
            \\		tfft.value
            \\	from
            \\		task_fields_for_task tfft
            \\	inner join task_field tf on
            \\		tfft.task_field_id = tf.id
            \\	where
            \\		tf.project_id = $1
            \\		and tf.name = 'Due Date'
            \\		and tfft.task_id = t.id
            \\	) as due_date,
            \\	(
            \\	select
            \\		tfft.value
            \\	from
            \\		task_fields_for_task tfft
            \\	inner join task_field tf on
            \\		tfft.task_field_id = tf.id
            \\	where
            \\		tf.project_id = $1
            \\		and tf.name = 'Title'
            \\		and tfft.task_id = t.id
            \\	) as title,
            \\	(
            \\	select
            \\		tfft.value
            \\	from
            \\		task_fields_for_task tfft
            \\	inner join task_field tf on
            \\		tfft.task_field_id = tf.id
            \\	where
            \\		tf.project_id = $1
            \\		and tf.name = 'Status'
            \\		and tfft.task_id = t.id
            \\	) as status,
            \\	t.icon,
            \\	(
            \\	 (
            \\	select
            \\		count(*)::decimal
            \\	from
            \\		task_fields_for_task tfft
            \\	inner join task_field tf on
            \\		tfft.task_field_id = tf.id
            \\	inner join task tf2 on
            \\		tf2.id = tfft.task_id
            \\	where
            \\		tf.project_id = $1
            \\		and tf.name = 'Status'
            \\		and tf2.parent_id = t.id
            \\		and tfft.value['isDone'] = 'true'
            \\	 ) / coalesce (
            \\	 	(nullif ((
            \\	select
            \\		count(*)
            \\	from
            \\		task_fields_for_task tfft
            \\	inner join task_field tf on
            \\		tfft.task_field_id = tf.id
            \\	inner join task tf2 on
            \\		tf2.id = tfft.task_id
            \\	where
            \\		tf.project_id = $1
            \\		and tf.name = 'Status'
            \\		and tf2.parent_id = t.id),
            \\	0)),
            \\		1
            \\	 )
            \\	) as progress,
            \\	t.senku_column,
            \\	t.senku_row
            \\from
            \\	task t
            \\where
            \\	t.project_id = $1
            \\	and t.parent_id is null
        ;

        uwu_log.logInfo("Getting tasks from DB...")
            .int("project_id", req.project_id)
            .log();

        var result = conn.query(query, params) catch |err| {
            var l = uwu_log.logErr("Error getting tasks!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            return error.DBQueryError;
        };
        defer result.deinit();

        var tasks = std.ArrayList(Cell).init(alloc);
        while (try result.next() catch |err| {
            var l = uwu_log.logErr("Error while iterating to next task!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            return error.DBQueryError;
        }) |row| {
            const task = Cell.fromDBRow(alloc, row) catch |err| {
                var l = uwu_log.logErr("Error when parsing from DB result to struct!").src(@src());
                uwu_db.logPgError(l, err, conn);
                l.log();

                return error.DBQueryError;
            };
            tasks.append(task);
        }
        defer tasks.deinit();

        break :get_tasks_block tasks.toOwnedSlice() catch unreachable;
    };

    const cells = [GRID_SIZE][GRID_SIZE]?Cell{};
    for (tasks) |task| {
        const cords = task.coordinates;
        cells[cords.row][cords.column] = task;
    }

    uwu_log.logInfo("Got epic tasks from DB!").int("count", tasks.len).log();

    uwu_log.logInfo("Getting task connections...");
    const connections: []TaskConnection = get_connections_block: {
        const params = .{req.project_id};
        const query =
            \\select 
            \\	t1.senku_row as t1_row,
            \\	t1.senku_column as t1_column,
            \\	t2.senku_row as t2_row,
            \\	t2.senku_column as t2_column
            \\from
            \\	task_connection tc
            \\inner join task t1 on
            \\	t1.id = tc.target_task
            \\inner join task t2 on
            \\	t2.id = tc.unblocked_task
            \\where
            \\	t2.project_id = $1
            \\	and t1.project_id = $1
        ;

        uwu_log.logInfo("Getting task connections from DB...").int("project_id", req.project_id).log();

        var result = conn.query(query, params) catch |err| {
            var l = uwu_log.logErr("Error getting task connections!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            return error.DBQueryError;
        };
        defer result.deinit();

        var connections = std.ArrayList(TaskConnection).init(alloc);
        while (try result.next() catch |err| {
            var l = uwu_log.logErr("Error while iterating to next task connection!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            return error.DBQueryError;
        }) |row| {
            const connection = TaskConnection.fromDBRow(alloc, row) catch |err| {
                var l = uwu_log.logErr("Error when parsing from DB result to struct!").src(@src());
                uwu_db.logPgError(l, err, conn);
                l.log();

                return error.DBQueryError;
            };
            connections.append(connection);
        }
        defer connections.deinit();

        break :get_connections_block connections.toOwnedSlice() catch unreachable;
    };

    const state: SenkuState = .{ .state = cells, .connections = connections };
    return state;
}
