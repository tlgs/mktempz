const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    b.exe_dir = ".";

    const exe = b.addExecutable("mktempz", "mktempz.zig");
    exe.build_mode = .ReleaseSmall;
    exe.strip = true;
    exe.install();
}
