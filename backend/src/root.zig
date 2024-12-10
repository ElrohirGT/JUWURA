const std = @import("std");
const zap = @import("zap");
const logz = @import("logz");

pub fn logInfo(msg: []const u8) logz.Logger {
    return logz.info().string("msg", msg);
}

pub fn logWarn(msg: []const u8) logz.Logger {
    return logz.warn().string("msg", msg);
}

pub fn logErr(msg: []const u8) logz.Logger {
    return logz.err().string("msg", msg);
}

pub fn on_request(r: zap.Request) void {
    r.setHeader("Server", "JUWURA") catch unreachable;
    r.sendBody(
        \\ <html><body>
        \\ <h1>This is a simple Websocket chatroom example</h1>
        \\ </body></html>
    ) catch unreachable;
}
