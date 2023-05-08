const std = @import("std");
const vertice = @import("vertice.zig");
const adjlist = @import("adjacencylist.zig");
/// An Array of Doubly-LinkedLists, indexed by degree
pub const DegreeList = struct {
    degrees: []?*vertice.Node,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, adj: *const adjlist.AdjacencyList) !DegreeList {
        var degrees = try allocator.alloc(?*vertice.Node, adj.vertices.len);
        std.mem.set(?*vertice.Node, degrees, null);
        var degree_list = DegreeList{ .degrees = degrees, .allocator = allocator };

        var n: u16 = 0;
        while (n < adj.vertices.len) : (n += 1) {
            try degree_list.insert(adj.vertices[n].degree, &adj.vertices[n]);
        }
        return degree_list;
    }

    const InsertError = error{TaintedNode};

    pub fn smallest_degree(self: *const DegreeList) ?*vertice.Node {
        var n: u16 = 0;
        while (n < self.degrees.len) : (n += 1) {
            if (self.degrees[n]) |v| {
                return v;
            }
        }
        return null;
    }

    /// Inserts a new vertice into the degree list. This function requires that the inserted vertice does not hold any existing data, besides its id, since it is overwritten
    pub fn insert(self: *DegreeList, degree: u16, v: *vertice.Node) !void {
        if (v.prev != null or v.next != null) {
            return InsertError.TaintedNode;
        }
        var head = self.degrees[degree];
        v.prev = null;
        v.next = head;
        if (head) |node| {
            node.prev = v;
        }
        self.degrees[degree] = v;
    }

    /// Removes the specified vertice from the degreelist, and detatches its reference from other vertices with the same degree
    pub fn remove(self: *DegreeList, v: *vertice.Node) void {
        if (v.prev) |prev| {
            prev.next = v.next;
        } else { // If there is no previous node, v is assumed to be the head
            self.degrees[v.degree] = v.next;
        }
        if (v.next) |next| {
            next.prev = v.prev;
        }
        v.prev = null;
        v.next = null;
    }

    pub fn print(self: *const DegreeList, writer: *std.fs.File.Writer) !void {
        var n: u16 = 0;
        while (n < self.degrees.len) : (n += 1) {
            try writer.print("[{}°]: ", .{n});
            var current = self.degrees[n];
            while (current) |v| {
                if (v.prev) |_| {
                    try writer.print(", ", .{});
                }
                try writer.print("{}", .{v.id});
                current = v.next;
            }
            try writer.print("{c}", .{'\n'});
        }
    }

    pub fn deinit(self: *DegreeList) void {
        self.allocator.free(self.degrees);
    }
};
