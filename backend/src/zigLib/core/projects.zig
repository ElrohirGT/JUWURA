const std = @import("std");
const pg = @import("pg");
const zap = @import("zap");

const uwu_lib = @import("../root.zig");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.db;

pub const Project = struct {
    id: i32,
    name: []const u8,
    photo_url: []const u8,
    icon: []const u8,
    owner: []const u8,

    pub fn deinit(self: Project, alloc: std.mem.Allocator) void {
        alloc.free(self.name);
        alloc.free(self.photo_url);
        alloc.free(self.icon);
        alloc.free(self.owner);
    }
};

/// Initializes a project from a DB row.
///
/// All data from the row that would be freed from it needs to be copied over to the project struct, since now the owner is the Project instance.
fn projectFromDB(alloc: std.mem.Allocator, row: pg.QueryRow) Project {
    const id = row.get(i32, 0);
    const name = alloc.dupe(u8, row.get([]u8, 1)) catch unreachable;
    const url = alloc.dupe(u8, row.get([]u8, 2)) catch unreachable;
    const icon = alloc.dupe(u8, row.get([]u8, 3)) catch unreachable;
    const owner = alloc.dupe(u8, row.get([]u8, 4)) catch unreachable;

    return Project{
        .id = id,
        .name = name,
        .photo_url = url,
        .icon = icon,
        .owner = owner,
    };
}

pub const CreateProjectRequest = struct {
    email: []const u8,
    name: []const u8,
    photo_url: []const u8,
    now_timestamp: i64,
    icon: [4]u8,
    members: [][]const u8,
};
pub const CreateProjectResponse = struct { project: Project };
pub fn create_project(alloc: std.mem.Allocator, pool: *pg.Pool, req: CreateProjectRequest) !CreateProjectResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = pool.acquire() catch |err| {
        uwu_log.logErr("Error aquiring DB connection!").err(err).src(@src()).log();
        return error.NoDBConnectionAquired;
    };
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    conn.begin() catch |err| {
        var l = uwu_log.logErr("Error while beginning transaction!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();
        return error.QueryError;
    };
    const project: Project = project_creation_block: {
        const query = "INSERT INTO project (name, photo_url, icon, owner) VALUES ($1, $2, $3, $4) RETURNING *";
        const params = .{ req.name, req.photo_url, req.icon, req.email };
        uwu_log.logInfo("Creating project in DB...")
            .string("query", query)
            .string("name", req.name)
            .string("photo_url", req.photo_url)
            .string("icon", &req.icon)
            .string("owner", req.email)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Error while creating DB project!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction!").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        } orelse unreachable;
        defer dataRow.deinit() catch unreachable;

        break :project_creation_block projectFromDB(alloc, dataRow);
    };
    uwu_log.logInfo("Project created!")
        .int("id", project.id)
        .string("name", project.name)
        .string("photo_url", project.photo_url)
        .string("icon", project.icon)
        .string("owner", project.owner)
        .log();

    const response = CreateProjectResponse{ .project = project };

    const default_types = [_][]const u8{ "TEXT", "DATE", "CHOICE", "NUMBER", "ASSIGNEE" };
    var default_fields = std.StringArrayHashMap(usize).init(alloc);
    try default_fields.put("Title", 0); // The title field is of type TEXT!
    try default_fields.put("Due Date", 1); // The title field is of type DATE!
    try default_fields.put("Status", 2); // And so on...
    try default_fields.put("Priority", 2);
    try default_fields.put("Sprint", 3);
    try default_fields.put("Assignees", 4);
    try default_fields.put("Description", 0);

    uwu_log.logInfo("Adding default fields types...").log();
    const task_field_type_ids: [default_types.len]i32 = field_ids: {
        var query_buff = std.ArrayList(u8).init(alloc);
        defer query_buff.deinit();

        var writer = query_buff.writer();
        _ = try writer.write("INSERT INTO task_field_type (name, project_id) VALUES ");
        for (default_types, 0..) |type_name, i| {
            try writer.print("('{s}', {d})", .{ type_name, project.id });
            if (i + 1 == default_types.len) {
                _ = try writer.write(",");
            }
            _ = try writer.write("\n");
        }
        _ = try writer.write("RETURNING *");
        const query = try query_buff.toOwnedSlice();
        const result = conn.query(query, .{}) catch |err| {
            var l = uwu_log.logErr("Error while creating DB project!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction!").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        };
        defer result.deinit();

        var types_ids = std.mem.zeroes([default_types.len]i32);
        var idx: usize = 0;
        while (result.next() catch |err| {
            var l = uwu_log.logErr("Error while adding default field types!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction!").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        }) |row| : (idx += 1) {
            types_ids[idx] = row.get(i32, 0);
        }

        break :field_ids types_ids;
    };
    uwu_log.logInfo("Default fields types added!").log();

    uwu_log.logInfo("Adding default fields...").log();
    {
        var query_buff = std.ArrayList(u8).init(alloc);
        defer query_buff.deinit();

        var writer = query_buff.writer();
        _ = try writer.write("INSERT INTO task_field (project_id, task_field_type_id, name) VALUES ");
        for (default_fields.keys(), 0..) |field_name, i| {
            const type_id = task_field_type_ids[default_fields.get(field_name).?];
            try writer.print("({d}, {d}, '{s}')", .{ project.id, type_id, field_name });

            if (i + 1 == default_fields.keys().len) {
                _ = try writer.write(",");
            }
            _ = try writer.write("\n");
        }

        const query = try query_buff.toOwnedSlice();
        _ = conn.exec(query, .{}) catch |err| {
            var l = uwu_log.logErr("Error while adding default fields!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction!").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        };
    }
    uwu_log.logInfo("Default fields added!").log();

    uwu_log.logInfo("Adding members to project...").log();
    for (req.members) |memberEmail| {
        add_member_to_project(memberEmail, conn, project.id, req.now_timestamp) catch return error.QueryError;
    }
    uwu_log.logInfo("Members added!").log();

    uwu_log.logInfo("Adding creator to project...").log();
    add_member_to_project(req.email, conn, project.id, req.now_timestamp) catch return error.QueryError;
    uwu_log.logInfo("Creator added!").log();

    conn.commit() catch |err| {
        var l = uwu_log.logErr("Error while committing transaction!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();
        return error.QueryError;
    };

    return response;
}

pub const UpdateProjectRequest = struct {
    id: i32,
    name: []const u8,
    photo_url: []const u8,
    now_timestamp: i64,
    icon: [4]u8,
    members: [][]const u8,
};
pub const UpdateProjectResponse = struct { project: Project };
pub fn update_project(alloc: std.mem.Allocator, pool: *pg.Pool, req: UpdateProjectRequest) !UpdateProjectResponse {
    uwu_log.logInfo("Getting DB connection...").log();
    const conn = pool.acquire() catch |err| {
        uwu_log.logErr("Error aquiring DB connection!").err(err).src(@src()).log();
        return error.NoDBConnectionAquired;
    };
    defer conn.release();
    uwu_log.logInfo("Connection aquired!").log();

    conn.begin() catch |err| {
        var l = uwu_log.logErr("Error while beginning transaction!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();
        return error.QueryError;
    };
    const project: Project = project_creation_block: {
        const query =
            \\ UPDATE project SET
            \\ name = $2,
            \\ photo_url = $3,
            \\ icon = $4
            \\ WHERE id = $1
            \\ RETURNING *
        ;
        const params = .{ req.id, req.name, req.photo_url, req.icon };
        uwu_log.logInfo("Updating project in DB...")
            .string("query", query)
            .int("id", req.id)
            .string("name", req.name)
            .string("photo_url", req.photo_url)
            .string("icon", &req.icon)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Error while updating DB project!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction!").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        } orelse return error.NoProjectFound;
        defer dataRow.deinit() catch unreachable;

        break :project_creation_block projectFromDB(alloc, dataRow);
    };
    uwu_log.logInfo("Project updated!")
        .int("id", project.id)
        .string("name", project.name)
        .string("photo_url", project.photo_url)
        .string("icon", project.icon)
        .string("owner", project.owner)
        .log();

    uwu_log.logInfo("Checking if the owner isn't removed from the members...").log();
    const owner_found = for (req.members) |r_member| {
        if (std.mem.eql(u8, r_member, project.owner)) {
            break true;
        }
    } else false;
    if (!owner_found) {
        uwu_log.logErr("The owner is being removed from the project!").log();
        conn.rollback() catch |err| {
            var l = uwu_log.logErr("Error while rolling back transaction!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();
        };
        return error.QueryError;
    }
    uwu_log.logInfo("The owner is still a member!").log();

    const response = UpdateProjectResponse{ .project = project };

    const previous_members: [][]const u8 = previous_members_block: {
        const query =
            \\SELECT (select CAST(count(user_id) as integer) from project_member where project_id=$1), user_id
            \\FROM project_member 
            \\WHERE project_id = $1
        ;
        const params = .{project.id};
        uwu_log.logInfo("Obtaining previous project members")
            .string("query", query)
            .int("project_id", project.id)
            .log();

        var rows: *pg.Result = conn.query(query, params) catch |err| {
            var l = uwu_log.logErr("Error while obtaining previous project members!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };

            return error.QueryError;
        };
        defer rows.deinit();

        const firstRow = rows.next() catch |err| {
            var l = uwu_log.logErr("Error while getting first member row!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        } orelse break :previous_members_block &[0][]const u8{};
        const members_count: usize = @intCast(firstRow.get(i32, 0));
        const first_member = try alloc.dupe(u8, firstRow.get([]const u8, 1));

        var members = try std.ArrayList([]const u8).initCapacity(alloc, members_count);
        try members.append(first_member);
        while (rows.next() catch |err| {
            var l = uwu_log.logErr("Error while getting member!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while rolling back transaction").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        }) |row| {
            const email = try alloc.dupe(u8, row.get([]const u8, 1));
            try members.append(email);
        }

        break :previous_members_block try members.toOwnedSlice();
    };

    uwu_log.logInfo("Diffing members...").log();
    var members_to_remove = try std.ArrayList([]const u8).initCapacity(alloc, previous_members.len);
    defer members_to_remove.deinit();

    var members_to_add = try std.ArrayList([]const u8).initCapacity(alloc, req.members.len);
    defer members_to_add.deinit();

    for (previous_members) |p_member| {
        const found = for (req.members) |r_member| {
            if (std.mem.eql(u8, p_member, r_member)) {
                break true;
            }
        } else false;

        if (!found) {
            try members_to_remove.append(p_member);
        }
    }

    for (req.members) |r_member| {
        const found = for (previous_members) |p_member| {
            if (std.mem.eql(u8, p_member, r_member)) {
                break true;
            }
        } else false;

        if (!found) {
            try members_to_add.append(r_member);
        }
    }

    uwu_log.logInfo("Removing members from project...").log();
    for (members_to_remove.items) |member_email| {
        remove_member_from_project(conn, member_email, project.id) catch return error.QueryError;
    }
    uwu_log.logInfo("Members removed!").log();

    uwu_log.logInfo("Adding members to project...").log();
    for (members_to_add.items) |member_email| {
        add_member_to_project(member_email, conn, project.id, req.now_timestamp) catch return error.QueryError;
    }
    uwu_log.logInfo("Members added!").log();

    conn.commit() catch |err| {
        var l = uwu_log.logErr("Error while committing transaction!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();
        return error.QueryError;
    };

    return response;
}

fn add_member_to_project(memberEmail: []const u8, conn: *pg.Conn, projectId: i32, now_timestamp: i64) !void {
    const query = "INSERT INTO project_member (project_id, user_id, last_visited) VALUES ($1, $2, $3)";
    const params = .{ projectId, memberEmail, now_timestamp };

    uwu_log.logDebug("Adding member to project...")
        .string("query", query)
        .int("projectId", projectId)
        .string("userEmail", memberEmail)
        .int("last_visited", now_timestamp)
        .log();
    _ = conn.exec(query, params) catch |err| {
        var l = uwu_log.logErr("Error while adding member to project!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();

        return err;
    };
    uwu_log.logDebug("Member added to project!").log();
}

fn remove_member_from_project(conn: *pg.Conn, member_email: []const u8, project_id: i32) !void {
    const query = "DELETE FROM project_member WHERE project_id=$1 AND user_id=$2";
    const params = .{ project_id, member_email };

    uwu_log.logDebug("Removing member from project...")
        .string("query", query)
        .int("project_id", project_id)
        .string("user_email", member_email)
        .log();
    _ = conn.exec(query, params) catch |err| {
        var l = uwu_log.logErr("Error while removing member from project!").src(@src());
        uwu_db.logPgError(l, err, conn);
        l.log();

        return err;
    };
    uwu_log.logDebug("Member removed from project!").log();
}
