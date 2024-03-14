const std = @import("std");

const LocalFileHeader = struct {
    const signature: []const u8 = "\x04\x03\x4b\x50";

    mininum_version: u16 = 0,
    flags: u16 = 0,
    compression_method: u16 = 0,
    last_modification_time: u16 = 0,
    last_modification_date: u16 = 0,
    crc32: [4]u8 = undefined,
    compressed_size: u32 = 0xffffffff,
    uncompressed_size: u32 = 0xffffffff,
    file_name: []const u8,
    extra_field: []const u8,
};

const DataDescriptor = struct {
    const signature: []const u8 = "\x08\x07\x4b\x50";

    crc32: [4]u8 = undefined,
    compressed_size: u32 = 0xffffffff,
    uncompressed_size: u32 = 0xffffffff,
};

const DataDescriptor64 = struct {
    const signature: []const u8 = "\x08\x07\x4b\x50";

    crc32: [4]u8 = undefined,
    compressed_size: u64 = 0xffffffffffffffff,
    uncompressed_size: u64 = 0xffffffffffffffff,
};

const CentralDirectoryFileHeader = struct {
    const signature: []const u8 = "\x02\x01\x4b\x50";

    version: u16 = 0,
    mininum_version: u16 = 0,
    flags: u16 = 0,
    compression_method: u16 = 0,
    last_modification_time: u16 = 0,
    last_modification_date: u16 = 0,
    crc32: [4]u8 = "\x00\x00\x00\x00",
    compressed_size: u32 = 0xffffffff,
    uncompressed_size: u32 = 0xffffffff,
    disk_number: u16 = 0,
    internal_file_attributes: u16 = 0,
    external_file_attributes: u16 = 0,
    local_file_header_offset: u32 = 0xffffffff,
    file_name: []const u8,
    extra_field: []const u8,
    file_comment: []const u8,
};

const EndOfCentralDirectoryRecord = struct {
    const signature: []const u8 = "\x06\x05\x4b\x50";

    disk_number: u16 = 0xffff,
    central_directory_disk_number: u16 = 0xffff,
    central_directory_record_count_disk: u16 = 0xffff,
    central_directory_record_count_total: u16 = 0xffff,
    comment: []const u8,
};

pub const Options = struct {};

pub fn pipeToFileSystem(dir: std.fs.Dir, reader: anytype, options: Options) !void {
    // ...
}

pub const Iterator = struct {
    pub fn next(self: *Iterator) !?File {
        // ...
    }
};

pub const IteratorOptions = struct {};

pub fn iterator(file: std.fs.File, options: IteratorOptions) Iterator {
    // ...
}
