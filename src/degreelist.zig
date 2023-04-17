const std = @import("std");
/// An Array of Doubly-LinkedLists, indexed by degree
pub const DegreeList = struct {
    const VerticeNode = struct {
        prev: ?*VerticeNode,
        next: ?*VerticeNode,
        id: u16,
    };

    degrees: []?*VerticeNode,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: u16) !void {
        var degrees = try allocator.alloc(?*VerticeNode, size);

        return DegreeList{ .degrees = degrees, .allocator = allocator };
    }

    pub fn deinit(self: *DegreeList) void {
        self.allocator.free(self.degrees);
    }
};
