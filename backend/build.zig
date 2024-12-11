const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "backend",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/zigLib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const main_exe = b.addExecutable(.{
        .name = "backend",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_exe.root_module.addImport("juwura", &lib.root_module);

    const zap_dep = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
        .openssl = false, // set to true to enable TLS support
    });
    main_exe.root_module.addImport("zap", zap_dep.module("zap"));
    lib.root_module.addImport("zap", zap_dep.module("zap"));

    const pg_dep = b.dependency("pg", .{ .target = target, .optimize = optimize });
    main_exe.root_module.addImport("pg", pg_dep.module("pg"));

    const log_dep = b.dependency("logz", .{ .target = target, .optimize = optimize });
    main_exe.root_module.addImport("logz", log_dep.module("logz"));
    lib.root_module.addImport("logz", log_dep.module("logz"));

    const dotenv_dep = b.dependency("dotenv", .{ .target = target, .optimize = optimize });
    main_exe.root_module.addImport("dotenv", dotenv_dep.module("dotenv"));
    main_exe.linkSystemLibrary("c"); // Needed because of dotenv...

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(main_exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_main_cmd = b.addRunArtifact(main_exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_main_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_main_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_main_cmd.step);

    const ws_example_run_step = b.step("run-ws", "Run the WS example");
    const ws_example_build_step = b.step("build-ws", "Build the WS example");

    const ws_example_exe = b.addExecutable(.{
        .name = "wsExample",
        .root_source_file = b.path("./src/examples/wsExample.zig"),
        .target = target,
        .optimize = optimize,
    });
    ws_example_exe.root_module.addImport("zap", zap_dep.module("zap"));

    const ws_example_run = b.addRunArtifact(ws_example_exe);
    ws_example_run_step.dependOn(&ws_example_run.step);

    const ws_example_build = b.addInstallArtifact(ws_example_exe, .{});
    ws_example_build_step.dependOn(&ws_example_build.step);

    const db_example_run_step = b.step("run-db", "Run the DB example");
    const db_example_build_step = b.step("build-db", "Build the DB example");

    const db_example_exe = b.addExecutable(.{
        .name = "wsExample",
        .root_source_file = b.path("./src/examples/dbExample.zig"),
        .target = target,
        .optimize = optimize,
    });
    db_example_exe.root_module.addImport("pg", pg_dep.module("pg"));
    db_example_exe.root_module.addImport("dotenv", dotenv_dep.module("dotenv"));
    db_example_exe.linkSystemLibrary("c"); // Needed because of dotenv...

    const db_example_run = b.addRunArtifact(db_example_exe);
    db_example_run_step.dependOn(&db_example_run.step);

    const db_example_build = b.addInstallArtifact(db_example_exe, .{});
    db_example_build_step.dependOn(&db_example_build.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
