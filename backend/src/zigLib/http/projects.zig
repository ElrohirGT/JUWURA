const std = @import("std");
const pg = @import("pg");
const zap = @import("zap");
const uwu_lib = @import("../root.zig");
const uwu_log = uwu_lib.log;
const uwu_db = uwu_lib.utils.db;

pub const Project = struct {
    id: i32,
    name: []const u8,
    photo_url: []const u8,
    icon: []const u8,

    pub fn deinit(self: Project, alloc: std.mem.Allocator) void {
        alloc.free(self.name);
        alloc.free(self.photo_url);
        alloc.free(self.icon);
    }
};

pub const CreateProjectErrors = error{
    NoDBConnectionAquired,
    QueryError,
};

pub const CreateProjectRequest = struct {
    email: []const u8,
    name: []const u8,
    photo_url: []const u8,
    now_timestamp: i64,
    icon: [4]u8,
    members: [][]const u8,
};
pub const CreateProjectResponse = struct { project: Project };
pub fn create_project(alloc: std.mem.Allocator, pool: *pg.Pool, req: CreateProjectRequest) CreateProjectErrors!CreateProjectResponse {
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
        const query = "INSERT INTO project (name, photo_url, icon) VALUES ($1, $2, $3) RETURNING *";
        const params = .{ req.name, req.photo_url, req.icon };
        uwu_log.logInfo("Creating project in DB...")
            .string("query", query)
            .string("name", req.name)
            .string("photo_url", req.photo_url)
            .string("icon", &req.icon)
            .log();

        var dataRow = conn.row(query, params) catch |err| {
            var l = uwu_log.logErr("Error while creating DB project!").src(@src());
            uwu_db.logPgError(l, err, conn);
            l.log();

            conn.rollback() catch |rollBackErr| {
                var lo = uwu_log.logErr("Error while creating DB project!").src(@src());
                uwu_db.logPgError(lo, rollBackErr, conn);
                lo.log();
            };
            return error.QueryError;
        } orelse unreachable;
        defer dataRow.deinit() catch unreachable;

        const id = dataRow.get(i32, 0);
        const name = alloc.dupe(u8, dataRow.get([]u8, 1)) catch unreachable;
        const url = alloc.dupe(u8, dataRow.get([]u8, 2)) catch unreachable;
        const icon = alloc.dupe(u8, dataRow.get([]u8, 3)) catch unreachable;

        break :project_creation_block Project{ .id = id, .name = name, .photo_url = url, .icon = icon };
    };
    uwu_log.logInfo("Project created!")
        .int("id", project.id)
        .string("name", project.name)
        .string("photo_url", project.photo_url)
        .string("icon", project.icon)
        .log();

    const response = CreateProjectResponse{ .project = project };

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
