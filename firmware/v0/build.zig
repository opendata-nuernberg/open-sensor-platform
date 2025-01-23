const std = @import("std");
const zig_idf = @import("zig_idf");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{
        .whitelist = zig_idf.espressif_targets,
        .default_target = zig_idf.espressif_targets[0],
    });
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "app_zig",
        .root_source_file = b.path("main/app.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zig_idf_dep = b.dependency("zig_idf", .{
        .target = target,
        .optimize = optimize,
    });

    lib.root_module.addImport("zig_idf", zig_idf_dep.module("zig_idf"));

    lib.linkLibC(); // stubs for libc

    try zig_idf.includeDeps(b, lib);

    b.installArtifact(lib);
}
