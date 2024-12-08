//! JUWURA Project endpoints
const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");

pub const Self = @This();
const log = std.log.scoped(.ProjectEndpoint);

alloc: std.mem.Allocator = undefined,
ep: zap.Endpoint = undefined,
pool: *pg.Pool,

const Project = struct {
    id: i32,
    name: []u8,
    photo_url: ?[]u8 = null,
};

pub fn init(a: std.mem.Allocator, pool: *pg.Pool, path: []const u8) Self {
    return .{ .alloc = a, .pool = pool, .ep = zap.Endpoint.init(.{ .path = path, .get = get_projects, .post = post_project }) };
}

pub fn endpoint(self: *Self) *zap.Endpoint {
    return &self.ep;
}

const PostProjectRequest = struct { email: []u8, name: []u8, photo_url: ?[]u8 };
const PostProjectResponse = struct { project: Project };
fn post_project(e: *zap.Endpoint, r: zap.Request) void {
    const self: *Self = @fieldParentPtr("ep", e);

    log.info("Parsing body...", .{});
    const body = r.body orelse unreachable;
    const parsed = std.json.parseFromSlice(PostProjectRequest, self.alloc, body, .{}) catch unreachable;
    defer parsed.deinit();

    const request = parsed.value;
    log.info("Body parsed!", .{});

    log.info("Getting DB connection...", .{});
    const conn = self.pool.acquire() catch unreachable;
    defer conn.release();
    log.info("Connection aquired!", .{});

    log.info("Querying DB...", .{});
    const result = conn.query("INSERT INTO project (name, photo_url) VALUES ($1, $2) RETURNING *", .{ request.name, request.photo_url }) catch unreachable;
    defer result.deinit();
    log.info("Query done!", .{});

    log.info("Creating response...", .{});
    const dataRow = (result.next() catch unreachable) orelse unreachable;
    const id = dataRow.get(i32, 0);
    const name = dataRow.get([]u8, 1);
    const url = dataRow.get(?[]u8, 2);

    const response = PostProjectResponse{ .project = Project{ .id = id, .photo_url = url, .name = name } };
    log.info("Done creating response!", .{});

    var jsonResponse = std.ArrayList(u8).init(self.alloc);
    std.json.stringify(response, .{}, jsonResponse.writer()) catch unreachable;

    r.sendJson((jsonResponse.toOwnedSlice() catch unreachable)) catch unreachable;
}

fn get_projects(e: *zap.Endpoint, r: zap.Request) void {
    const self: *Self = @fieldParentPtr("ep", e);
    const conn = self.pool.acquire() catch unreachable;
    defer conn.release();

    // We need to cast to integer in order to make pg.zig understand the type to obtain.
    var row = (conn.row("SELECT COUNT(*)::INTEGER FROM project", .{}) catch unreachable) orelse unreachable;
    defer row.deinit() catch {};

    const count = row.get(i32, 0);

    var body: [255]u8 = undefined;
    _ = std.fmt.bufPrint(&body,
        \\ <html><body>
        \\ <h1>Welcome to PROJECTS endpoint! Current count: {d}</h1>
        \\ </body></html>
    , .{count}) catch unreachable;
    r.sendBody(&body) catch unreachable;
}
