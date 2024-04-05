const std = @import("std");

pub const CompressionMethod = enum(u16) {
    store = 0,
    deflate = 8,
    _,
};

// Local file header
// https://en.wikipedia.org/wiki/ZIP_(file_format)#Local_file_header
//
// | Offset | Bytes | Description                                                      |
// | ------ | ----- | ---------------------------------------------------------------- |
// |      0 |     4 | Local file header signature = 0x04034b50 (PK♥♦ or "PK\3\4")      |
// |      4 |     2 | Version needed to extract (minimum)                              |
// |      6 |     2 | General purpose bit flag                                         |
// |      8 |     2 | Compression method; e.g. none = 0, DEFLATE = 8 (or "\0x08\0x00") |
// |     10 |     2 | File last modification time                                      |
// |     12 |     2 | File last modification date                                      |
// |     14 |     4 | CRC-32 of uncompressed data                                      |
// |     18 |     4 | Compressed size (or 0xffffffff for ZIP64)                        |
// |     22 |     4 | Uncompressed size (or 0xffffffff for ZIP64)                      |
// |     26 |     2 | File name length (n)                                             |
// |     28 |     2 | Extra field length (m)                                           |
// |     30 |     n | File name                                                        |
// |   30+n |     m | Extra field                                                      |

const LocalFileHeader = struct {
    const signature: u32 = 0x04034b50;

    mininum_version: u16,
    flags: u16,
    compression_method: CompressionMethod,
    last_modification_time: u16,
    last_modification_date: u16,
    crc32: u32,
    compressed_size: u32,
    uncompressed_size: u32,

    file_name: []const u8,
    extra_field: []const u8,

    pub fn read(self: *LocalFileHeader, buffer: []const u8) !u32 {
        if (buffer.len < 30) {
            return error.Invalid;
        }

        if (std.mem.readInt(u32, buffer[0..4], .little) != LocalFileHeader.signature) {
            return error.Invalid;
        }

        self.mininum_version = std.mem.readInt(u16, buffer[4..6], .little);
        self.flags = std.mem.readInt(u16, buffer[6..8], .little);
        self.compression_method = @enumFromInt(std.mem.readInt(u16, buffer[8..10], .little));
        self.last_modification_time = std.mem.readInt(u16, buffer[10..12], .little);
        self.last_modification_date = std.mem.readInt(u16, buffer[12..14], .little);
        self.crc32 = std.mem.readInt(u32, buffer[14..18], .little);
        self.compressed_size = std.mem.readInt(u32, buffer[18..22], .little);
        self.uncompressed_size = std.mem.readInt(u32, buffer[22..26], .little);

        const n = std.mem.readInt(u16, buffer[26..28], .little);
        const m = std.mem.readInt(u16, buffer[28..30], .little);

        if (buffer.len < 30 + n + m) {
            return error.Invalid;
        }

        self.file_name = buffer[30 .. 30 + n];
        self.extra_field = buffer[30 + n .. 30 + n + m];

        return 30 + n + m;
    }
};

// Central directory file header
// https://en.wikipedia.org/wiki/ZIP_(file_format)#Central_directory_file_header
//
// | Offset | Bytes | Description                                                     |
// | ------ | ----- | --------------------------------------------------------------- |
// |      0 |     4 | Central directory file header signature = 0x02014b50            |
// |      4 |     2 | Version made by                                                 |
// |      6 |     2 | Version needed to extract (minimum)                             |
// |      8 |     2 | General purpose bit flag                                        |
// |      10|     2 | Compression method                                              |
// |      12|     2 | File last modification time                                     |
// |      14|     2 | File last modification date                                     |
// |      16|     4 | CRC-32 of uncompressed data                                     |
// |      20|     4 | Compressed size (or 0xffffffff for ZIP64)                       |
// |      24|     4 | Uncompressed size (or 0xffffffff for ZIP64)                     |
// |      28|     2 | File name length (n)                                            |
// |      30|     2 | Extra field length (m)                                          |
// |      32|     2 | File comment length (k)                                         |
// |      34|     2 | Disk number where file starts (or 0xffff for ZIP64)             |
// |      36|     2 | Internal file attributes                                        |
// |      38|     4 | External file attributes                                        |
// |      42|     4 | Relative offset of local file header (or 0xffffffff for ZIP64). |
// |      46|     n | File name                                                       |
// |    46+n|     m | Extra field                                                     |
// |  46+n+m|     k | File comment                                                    |

const CentralDirectoryFileHeader = struct {
    const signature: u32 = 0x02014b50;

    signature: [4]u8,
    version: u16,
    mininum_version: u16,
    flags: u16,
    compression_method: CompressionMethod,
    last_modification_time: u16,
    last_modification_date: u16,
    crc32: u32,
    compressed_size: u32,
    uncompressed_size: u32,

    disk_number: u16,
    internal_file_attributes: u16,
    external_file_attributes: u32,
    local_file_header_offset: u32,

    file_name: []const u8,
    extra_field: []const u8,
    file_comment: []const u8,

    pub fn read(self: *CentralDirectoryFileHeader, buffer: []const u8) !u32 {
        if (buffer.len < 46) {
            return error.Invalid;
        }

        if (std.mem.readInt(u32, buffer[0..4], .little) != CentralDirectoryFileHeader.signature) {
            return error.Invalid;
        }

        self.version = std.mem.readInt(u16, buffer[4..6], .little);
        self.mininum_version = std.mem.readInt(u16, buffer[6..8], .little);
        self.flags = std.mem.readInt(u16, buffer[8..10], .little);
        self.compression_method = @enumFromInt(std.mem.readInt(u16, buffer[10..12], .little));
        self.last_modification_time = std.mem.readInt(u16, buffer[12..14], .little);
        self.last_modification_date = std.mem.readInt(u16, buffer[14..16], .little);
        self.crc32 = std.mem.readInt(u32, buffer[16..20], .little);
        self.compressed_size = std.mem.readInt(u32, buffer[20..24], .little);
        self.uncompressed_size = std.mem.readInt(u32, buffer[24..28], .little);
        self.uncompressed_size = std.mem.readInt(u32, buffer[24..28], .little);

        const n = std.mem.readInt(u16, buffer[28..30], .little);
        const m = std.mem.readInt(u16, buffer[30..32], .little);
        const k = std.mem.readInt(u16, buffer[32..34], .little);

        self.disk_number = std.mem.readInt(u16, buffer[34..36], .little);
        self.internal_file_attributes = std.mem.readInt(u16, buffer[36..38], .little);
        self.external_file_attributes = std.mem.readInt(u32, buffer[38..42], .little);
        self.local_file_header_offset = std.mem.readInt(u32, buffer[42..46], .little);

        if (buffer.len < 46 + n + m + k) {
            return error.Invalid;
        }

        self.file_name = buffer[46 .. 46 + n];
        self.extra_field = buffer[46 + n .. 46 + n + m];
        self.file_comment = buffer[46 + n + m .. 46 + n + m + k];

        return 46 + n + m + k;
    }
};

// End of central directory record (EOCD)
// https://en.wikipedia.org/wiki/ZIP_(file_format)#End_of_central_directory_record_(EOCD)
//
// | Offset | Bytes | Description                                                                                  |
// | ------ | ----- | -------------------------------------------------------------------------------------------- |
// |      0 |     4 | End of central directory signature = 0x06054b50                                              |
// |      4 |     2 | Number of this disk (or 0xffff for ZIP64)                                                    |
// |      6 |     2 | Disk where central directory starts (or 0xffff for ZIP64)                                    |
// |      8 |     2 | Number of central directory records on this disk (or 0xffff for ZIP64)                       |
// |     10 |     2 | Total number of central directory records (or 0xffff for ZIP64)                              |
// |     12 |     4 | Size of central directory (bytes) (or 0xffffffff for ZIP64)                                  |
// |     16 |     4 | Offset of start of central directory, relative to start of archive (or 0xffffffff for ZIP64) |
// |     20 |     2 | Comment length (n)                                                                           |
// |     22 |     n | Comment                                                                                      |

const EndOfCentralDirectoryRecord = struct {
    const signature: u32 = 0x06054b50;

    disk_number: u16,
    central_directory_disk_number: u16,
    record_count_disk: u16,
    record_count_total: u16,
    central_directory_size: u32,
    central_directory_offset: u32,
    comment: []const u8,

    pub fn read(self: *EndOfCentralDirectoryRecord, buffer: []const u8) !usize {
        if (buffer.len < 22) {
            return error.Invalid;
        }

        if (std.mem.readInt(u32, buffer[0..4], .little) != EndOfCentralDirectoryRecord.signature) {
            return error.Invalid;
        }

        self.disk_number = std.mem.readInt(u16, buffer[4..6], .little);
        self.central_directory_disk_number = std.mem.readInt(u16, buffer[6..8], .little);
        self.record_count_disk = std.mem.readInt(u16, buffer[8..10], .little);
        self.record_count_total = std.mem.readInt(u16, buffer[10..12], .little);
        self.central_directory_size = std.mem.readInt(u32, buffer[12..16], .little);
        self.central_directory_offset = std.mem.readInt(u32, buffer[16..20], .little);

        const n = std.mem.readInt(u16, buffer[20..22], .little);
        if (buffer.len < 22 + n) {
            return error.Invalid;
        }

        self.comment = buffer[22 .. 22 + n];
        return 22 + n;
    }
};

pub const Iterator = struct {
    const Stream = std.io.FixedBufferStream([]const u8);
    const Reader = std.io.GenericReader(*Stream, Stream.ReadError, Stream.read);

    pub const Entry = struct {
        name: []const u8,
        crc32: u32,

        compression_method: CompressionMethod,
        compressed_data: []const u8,
        decompressor: *std.compress.flate.Decompressor(Reader),

        /// decompress returns the actual CRC-32 of the decompressed bytes,
        /// which should be validated against the expected value entry.crc32
        pub fn decompress(self: Entry, writer: anytype) !u32 {
            var hash = std.hash.Crc32.init();

            switch (self.compression_method) {
                .store => {
                    const chunk_size = 4096;

                    var offset: usize = 0;
                    while (offset < self.compressed_data.len) : (offset += chunk_size) {
                        const end = @min(self.compressed_data.len, offset + chunk_size);
                        const chunk = self.compressed_data[offset..end];
                        try writer.writeAll(chunk);
                        hash.update(chunk);
                    }
                },
                .deflate => {
                    var stream = std.io.fixedBufferStream(self.compressed_data);
                    self.decompressor.setReader(stream.reader());
                    while (try self.decompressor.next()) |chunk| {
                        try writer.writeAll(chunk);
                        hash.update(chunk);
                    }
                },
                _ => return error.UnsupportedCompressionMethod,
            }

            return hash.final();
        }
    };

    decompressor: std.compress.flate.Decompressor(Reader),
    map: []align(std.mem.page_size) const u8,
    eocd: EndOfCentralDirectoryRecord,
    central_directory_offset: u32,
    n: u16,

    pub fn init(file: std.fs.File) !Iterator {
        const stat = try file.stat();
        const map = try std.posix.mmap(null, stat.size, std.posix.PROT.READ, .{ .TYPE = .SHARED }, file.handle, 0);

        // 22 is minimum length of an empty ZIP archive.
        if (map.len < 22) {
            return error.Invalid;
        }

        // The EOCD record can technically contain a variable-length comment
        // at the end, which makes ZIP file parsing ambiguous, since a valid
        // comment could contain the bytes of another valid EOCD record.
        // Comments are extremely rare in practice, so we only support parsing
        // EOCD records with zero-length comments at the very end of the file.
        var eocd: EndOfCentralDirectoryRecord = undefined;
        _ = try eocd.read(map[map.len - 22 ..]);

        // Don't support multi-disk archives
        if (eocd.disk_number != 0 or eocd.central_directory_disk_number != 0) {
            return error.Invalid;
        }

        if (eocd.record_count_disk != eocd.record_count_total) {
            return error.Invalid;
        }

        // This empty stream is replaced using decompressor.setReader
        // when actually called from File.decompress
        const empty_buffer: []const u8 = &.{};
        var stream = std.io.fixedBufferStream(empty_buffer);
        const decompressor = std.compress.flate.decompressor(stream.reader());

        return .{ .decompressor = decompressor, .map = map, .eocd = eocd, .central_directory_offset = 0, .n = 0 };
    }

    pub fn deinit(self: Iterator) void {
        std.posix.munmap(self.map);
    }

    pub fn next(self: *Iterator) !?Entry {
        if (self.n >= self.eocd.record_count_total or self.central_directory_offset >= self.eocd.central_directory_size) {
            return null;
        }

        const start = self.eocd.central_directory_offset + self.central_directory_offset;
        if (start >= self.map.len) {
            return error.Invalid;
        }

        var header: CentralDirectoryFileHeader = undefined;
        self.central_directory_offset += try header.read(self.map[start..]);
        self.n += 1;

        // Don't support multi-disk archives
        if (header.disk_number != 0) {
            return error.Invalid;
        }

        var offset = header.local_file_header_offset;
        if (offset >= self.map.len) {
            return error.Invalid;
        }

        var local_file_header: LocalFileHeader = undefined;
        offset += try local_file_header.read(self.map[offset..]);

        if (local_file_header.compressed_size != header.compressed_size) {
            return error.Invalid;
        }

        if (local_file_header.uncompressed_size != header.uncompressed_size) {
            return error.Invalid;
        }

        if (local_file_header.compression_method != header.compression_method) {
            return error.Invalid;
        }

        if (local_file_header.crc32 != header.crc32) {
            return error.Invalid;
        }

        if (offset + header.compressed_size >= self.map.len) {
            return error.Invalid;
        }

        const compressed_data = self.map[offset .. offset + header.compressed_size];

        return .{
            .name = header.file_name,
            .crc32 = header.crc32,

            .decompressor = &self.decompressor,
            .compression_method = header.compression_method,
            .compressed_data = compressed_data,
        };
    }
};

pub fn pipeToFileSystem(dest: std.fs.Dir, source: std.fs.File) !void {
    var iter = try Iterator.init(source);
    defer iter.deinit();

    while (try iter.next()) |entry| {
        const file = try dest.createFile(entry.name, .{});
        defer file.close();

        const crc32 = try entry.decompress(file.writer());
        if (crc32 != entry.crc32) {
            return error.Corrupt;
        }
    }
}
