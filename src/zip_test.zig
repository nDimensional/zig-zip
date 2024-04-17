const std = @import("std");
const zip = @import("zip");

fn createFile(dir: std.fs.Dir, name: []const u8, content: []const u8) !void {
    if (std.mem.lastIndexOfScalar(u8, name, std.fs.path.sep)) |last_index| {
        if (last_index == 0 or last_index == name.len - 1) {
            return error.InvalidPath;
        }

        var leaf_dir = try dir.makeOpenPath(name[0..last_index], .{ .iterate = true });
        defer leaf_dir.close();

        const file = try leaf_dir.createFile(name[last_index + 1 ..], .{});
        defer file.close();
        try file.writeAll(content);
    } else {
        const file = try dir.createFile(name, .{});
        defer file.close();
        try file.writeAll(content);
    }
}

/// only iterates over the entries of `expected`, so strict equality
/// can be checked by calling this twice with reversed arguments.
fn compareDirectories(expected: std.fs.Dir, actual: std.fs.Dir) !void {
    var expected_iter = expected.iterate();
    while (try expected_iter.next()) |entry| {
        switch (entry.kind) {
            .file => {
                const expected_file = try expected.openFile(entry.name, .{});
                defer expected_file.close();

                const actual_file = try actual.openFile(entry.name, .{});
                defer actual_file.close();

                try compareFiles(expected_file, actual_file);
            },
            .directory => {
                var expected_subdir = try expected.openDir(entry.name, .{ .iterate = true });
                defer expected_subdir.close();

                var actual_subdir = try actual.openDir(entry.name, .{ .iterate = true });
                defer actual_subdir.close();

                try compareDirectories(expected_subdir, actual_subdir);
            },
            else => {},
        }
    }
}

fn compareFiles(expected: std.fs.File, actual: std.fs.File) !void {
    const expected_stat = try expected.stat();
    const expected_map = try std.posix.mmap(null, expected_stat.size, std.posix.PROT.READ, .{ .TYPE = .SHARED }, expected.handle, 0);
    defer std.posix.munmap(expected_map);

    const actual_stat = try expected.stat();
    const actual_map = try std.posix.mmap(null, actual_stat.size, std.posix.PROT.READ, .{ .TYPE = .SHARED }, actual.handle, 0);
    defer std.posix.munmap(actual_map);

    try std.testing.expectEqualSlices(u8, expected_map, actual_map);
}

const Entry = struct { name: []const u8, content: []const u8 };

fn testUnzip(allocator: std.mem.Allocator, entries: []const Entry) !void {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const path = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(path);

    try tmp.dir.makeDir("source");
    var source = try tmp.dir.openDir("source", .{ .iterate = true });
    defer source.close();

    var argv = std.ArrayList([]const u8).init(allocator);
    defer argv.deinit();

    // try argv.append("zip");
    // try argv.append("archive.zip");
    // for (entries) |entry| try argv.append(entry.name);

    for (entries) |entry| {
        try createFile(source, entry.name, entry.content);
    }

    {
        const result = try std.ChildProcess.run(.{
            .allocator = allocator,
            .cwd_dir = source,
            .argv = &.{ "zip", "-r", "../archive.zip", ".", "-i", "*" },
        });

        // const stderr = std.io.getStdErr().writer();
        // try stderr.writeByte('\n');
        // try stderr.print("STDERR: \n{s}\n", .{result.stderr});
        // try stderr.print("STDOUT: \n{s}\n", .{result.stdout});

        allocator.free(result.stderr);
        allocator.free(result.stdout);

        switch (result.term) {
            .Exited => |code| try std.testing.expectEqual(@as(u8, 0), code),
            else => @panic("unexpected child process termination"),
        }
    }

    try tmp.dir.makeDir("archive");
    var dest = try tmp.dir.openDir("archive", .{ .iterate = true });
    defer dest.close();

    {
        const archive = try tmp.dir.openFile("archive.zip", .{});
        defer archive.close();

        try zip.pipeToFileSystem(dest, archive);
    }

    // try source.deleteFile("archive.zip");
    try compareDirectories(source, dest);
    try compareDirectories(dest, source);
}

test "empty archive" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    try testUnzip(gpa.allocator(), &.{});
}

test "two small text files" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    try testUnzip(gpa.allocator(), &.{
        .{ .name = "foo.txt", .content = "foofoofoofoobarbarbarbarbazbazbazbaz" },
        .{ .name = "alphabet.txt", .content = "abcdefghijklmnopqrstuvwxyz" },
    });
}

test "subdirectories" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    try testUnzip(gpa.allocator(), &.{
        .{ .name = "foo/foo.txt", .content = "foofoofoofoobarbarbarbarbazbazbazbaz" },
        .{ .name = "bar/alphabet.txt", .content = "abcdefghijklmnopqrstuvwxyz" },
    });
}

test "many nested subdirectories" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    try testUnzip(gpa.allocator(), &.{
        .{ .name = "foo/foo.txt", .content = "foofoofoofoobarbarbarbarbazbazbazbaz" },
        .{ .name = "foo/bar/baz/alphabet.txt", .content = "abcdefghijklmnopqrstuvwxyz" },
        .{ .name = "foo/bar/foo.txt", .content = "foofoofoofoobarbarbarbarbazbazbazbaz" },
    });
}
