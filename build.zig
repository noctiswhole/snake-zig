const std = @import("std");
// const emcc = @import("emcc.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    //web exports are completely separate
    const exe = b.addExecutable(.{ .name = "snake-zig", .root_source_file = .{ .path = "src/main.zig" }, .optimize = optimize, .target = target });

    exe.linkLibC();
    exe.linkSystemLibrary("raylib");

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run snake-zig");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}

