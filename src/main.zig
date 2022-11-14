//! This program mimics `mktemp -d` but the generated directory name
//! is drawn from two wordlists; Exactly like how Docker generates container names.
//!
//! Some helpful resources:
//!   - [coreutil's mktemp.c](http://git.savannah.gnu.org/cgit/coreutils.git/tree/src/mktemp.c)
//!   - [Gnulib's tempname.c](http://git.savannah.gnu.org/cgit/gnulib.git/tree/lib/tempname.c)
//!   - [Python's tempfile module](https://github.com/python/cpython/blob/main/Lib/tempfile.py)

const std = @import("std");
const os = std.os;
const O = os.O;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const ng = @import("name_generator.zig");

/// The maximum number of names that will be tried before giving up
const attempts = if (@hasDecl(os, "TMP_MAX")) os.TMP_MAX else 10_000;

const CreateError = os.OpenError || os.MakeDirError;

fn createFile(path: []const u8) !void {
    const fd = try os.open(path, O.RDWR | O.CREAT | O.EXCL, 0o600);
    os.close(fd);
}

fn createDir(path: []const u8) !void {
    try os.mkdir(path, 0o700);
}

pub fn main() !u8 {
    var createFn: fn ([]const u8) CreateError!void = undefined;

    // TODO: parse args and select correct function
    createFn = createDir;

    const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
    var prng_state = std.rand.DefaultPrng.init(seed);
    const prng = prng_state.random();

    var iter = ng.NameGenerator.init(prng);

    var buf: [64]u8 = undefined;
    var i: usize = 0;
    while (i < attempts) : (i += 1) {
        // TODO: support other system's defaults
        // TODO: support TMPDIR environment variable
        // TODO: replace this with std.fs.join, probably
        const path = try std.fmt.bufPrint(buf[0..], "/tmp/{s}", .{iter.next()});

        createFn(path) catch continue;

        try stdout.print("{s}\n", .{path});
        return 0;
    }

    try stderr.print("failed to create {s}\n", .{"dir"});
    return 1;
}
