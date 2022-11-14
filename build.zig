const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("mktempz", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const test_step = b.step("test", "Run unit tests");
    const src_files = [_][]const u8{ "src/main.zig", "src/name_generator.zig" };
    for (src_files) |path| {
        const xtests = b.addTest(path);
        xtests.setTarget(target);
        xtests.setBuildMode(mode);

        test_step.dependOn(&xtests.step);
    }
}
