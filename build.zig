const std = @import("std");
const LazyPath = std.Build.LazyPath;

pub fn build(b: *std.Build) void {
    const zip = b.addModule("zip", .{ .root_source_file = LazyPath.relative("src/zip.zig") });

    // Tests
    const tests = b.addTest(.{ .root_source_file = LazyPath.relative("src/zip_test.zig") });
    tests.root_module.addImport("zip", zip);
    const run_tests = b.addRunArtifact(tests);

    b.step("test", "Run tests").dependOn(&run_tests.step);
}
