const pg = @import("pg");
const std = @import("std");

const uwu_lib = @import("../root.zig");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.db;

pub const Errors = error{
    GetSenkuStateError,
    CreateTaskConnectionError,
};

pub const CellCoordinates = struct { row: i32, column: i32 };

const Cell = struct {
    id: i32,
    due_date: ?[]const u8,
    title: ?[]const u8,
    status: ?[]const u8,
    icon: []const u8,
    progress: f32,
    coordinates: CellCoordinates,

    pub fn fromDBRow(alloc: std.mem.Allocator, row: pg.Row) !Cell {
        const id = row.get(i32, 0);
        const due_date = try uwu_lib.dupeIfNotNull(u8, alloc, row.get(?[]u8, 1));
        const title = try uwu_lib.dupeIfNotNull(u8, alloc, row.get(?[]u8, 2));
        const status = try uwu_lib.dupeIfNotNull(u8, alloc, row.get(?[]u8, 3));
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

const TaskConnection = struct {
    start: CellCoordinates,
    end: CellCoordinates,

    pub fn fromPgRow(row: *const pg.Row) TaskConnection {
        const t1_row = row.get(i32, 0);
        const t1_column = row.get(i32, 1);

        const t2_row = row.get(i32, 2);
        const t2_column = row.get(i32, 3);

        return .{
            .start = .{
                .row = t1_row,
                .column = t1_column,
            },
            .end = .{
                .row = t2_row,
                .column = t2_column,
            },
        };
    }

    pub fn fromPgQueryRow(row: *const pg.QueryRow) TaskConnection {
        const t1_row = row.get(i32, 0);
        const t1_column = row.get(i32, 1);

        const t2_row = row.get(i32, 2);
        const t2_column = row.get(i32, 3);

        return .{
            .start = .{
                .row = t1_row,
                .column = t1_column,
            },
            .end = .{
                .row = t2_row,
                .column = t2_column,
            },
        };
    }
};

pub const GRID_SIZE = 10;
pub const SenkuState = struct { cells: [GRID_SIZE][GRID_SIZE]?Cell, connections: []TaskConnection };

pub const GetSenkuStateRequest = struct { project_id: i32 };
pub const GetSenkuStateResponse = struct { state: SenkuState };
pub fn get_senku_state(alloc: std.mem.Allocator, pool: *pg.Pool, req: GetSenkuStateRequest) !GetSenkuStateResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    uwu_log.logInfo("Getting tasks from DB...").log();
    const tasks: []Cell = get_tasks_block: {
        const params = .{req.project_id};
        const query =
            \\select
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
            \\	)::float4 as progress,
            \\	t.senku_column,
            \\	t.senku_row
            \\from
            \\	task t
            \\where
            \\	t.project_id = $1
            \\	and t.parent_id is null
        ;

        uwu_log.logInfo("Querying DB...")
            .int("project_id", req.project_id)
            .string("query", query)
            .log();

        var result = conn.query(query, params) catch |err| {
            var l = uwu_log.logErr("Error getting tasks!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            return error.DBQueryError;
        };
        defer result.deinit();

        var tasks = std.ArrayList(Cell).init(alloc);
        while (result.next() catch |err| {
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
            tasks.append(task) catch unreachable;
        }
        defer tasks.deinit();

        break :get_tasks_block tasks.toOwnedSlice() catch unreachable;
    };

    var cells: [GRID_SIZE][GRID_SIZE]?Cell = undefined;
    inline for (0..GRID_SIZE) |i| {
        var row: [GRID_SIZE]?Cell = undefined;
        inline for (0..GRID_SIZE) |j| {
            row[j] = null;
        }
        cells[i] = row;
    }

    for (tasks) |task| {
        const cords = task.coordinates;
        const row: usize = @intCast(cords.row);
        const column: usize = @intCast(cords.column);

        cells[row][column] = task;
    }

    uwu_log.logInfo("Got epic tasks from DB!").int("count", tasks.len).log();

    uwu_log.logInfo("Getting task connections...").log();
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
            \\  and t1.parent_id is null
            \\  and t2.parent_id is null
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
        while (result.next() catch |err| {
            var l = uwu_log.logErr("Error while iterating to next task connection!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            return error.DBQueryError;
        }) |row| {
            const connection = TaskConnection.fromPgRow(&row);
            connections.append(connection) catch unreachable;
        }
        defer connections.deinit();

        break :get_connections_block connections.toOwnedSlice() catch unreachable;
    };

    uwu_log.logInfo("Task connection obtained!").log();

    uwu_log.logInfo("DONE!").log();
    const state: SenkuState = .{ .cells = cells, .connections = connections };
    return .{ .state = state };
}

pub const CreateTaskConnectionRequest = struct { origin_id: i32, target_id: i32 };
pub const CreateTaskConnectionResponse = struct { connection: TaskConnection };
pub fn create_task_connection(pool: *pg.Pool, req: CreateTaskConnectionRequest) !CreateTaskConnectionResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = try pool.acquire();
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    conn.begin() catch unreachable;
    errdefer conn.rollback() catch unreachable;

    const tasks_exist: bool = check_tasks_block: {
        const params = .{ req.origin_id, req.target_id };
        const query =
            \\select
            \\ count(*)::integer
            \\from task
            \\where id=$1 or id=$2
        ;
        var row = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("An error occurred while checking if tasks exist!").src(@src()).err(err);
            uwu_db.logPgError(l, err, conn);
            l.log();

            return err;
        } orelse unreachable;
        defer row.deinit() catch unreachable;

        const count = row.get(i32, 0);

        break :check_tasks_block count == 2;
    };

    if (!tasks_exist) {
        uwu_log.logErr("One of the tasks doesn't exist!").log();
        return error.TaskDoesntExist;
    }

    {
        const params = .{ req.origin_id, req.target_id };
        const query =
            \\ insert into task_connection (target_task, unblocked_task) values ($1, $2)
            \\ on conflict do nothing
        ;

        _ = conn.exec(query, params) catch |err| {
            var l = uwu_log.logErr("Error inserting connection!").src(@src()).err(err);
            uwu_db.logPgError(l, err, conn);
            l.log();

            return err;
        } orelse unreachable;
    }

    const connection: TaskConnection = get_task_connection: {
        const params = .{ req.origin_id, req.target_id };
        const query =
            \\ select t1.senku_row, t1.senku_column, t2.senku_row, t2.senku_column
            \\ from task_connection tc
            \\ inner join task t1 on tc.target_task = t1.id
            \\ inner join task t2 on tc.unblocked_task = t2.id
            \\ where tc.target_task = $1 and tc.unblocked_task = $2
        ;

        var row = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("An error occurred while getting task connection!").src(@src()).err(err);
            uwu_db.logPgError(l, err, conn);
            l.log();

            return err;
        } orelse unreachable;
        defer row.deinit() catch unreachable;

        break :get_task_connection TaskConnection.fromPgQueryRow(&row);
    };

    conn.commit() catch unreachable;

    return CreateTaskConnectionResponse{ .connection = connection };
}
