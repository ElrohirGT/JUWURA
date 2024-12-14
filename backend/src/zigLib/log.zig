const logz = @import("logz");

pub fn logInfo(msg: []const u8) logz.Logger {
    return logz.info().string("msg", msg);
}

pub fn logDebug(msg: []const u8) logz.Logger {
    return logz.debug().string("msg", msg);
}

pub fn logWarn(msg: []const u8) logz.Logger {
    return logz.warn().string("msg", msg);
}

pub fn logErr(msg: []const u8) logz.Logger {
    return logz.err().string("msg", msg);
}
