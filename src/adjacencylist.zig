const std = @import("std");

pub const AdjacencyList = struct {
    const DestNode = struct {
        /// The vertice id, which points back to its location in @AdjacencyList.vertices
        id: u16,
        next: ?*DestNode,
    };

    /// An array of linkedlists, where each index corresponds to the id of the vertice
    vertices: []?*DestNode,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, count: u16) !AdjacencyList {
        var vertices = try allocator.alloc(?*DestNode, count);
        std.mem.set(?*DestNode, vertices, null);
        return AdjacencyList{
            .vertices = vertices,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *AdjacencyList) void {
        // Free the linkedlists
        for (self.vertices) |head| {
            var current = head;
            while (current) |node| {
                var next = node.next;
                self.allocator.destroy(node);
                current = next;
            }
        }

        // Free the array
        self.allocator.free(self.vertices);
    }

    const AccessError = error{ IdxAOutOfBounds, IdxBOutOfBounds };

    /// Inserts @DestNode in both indices of @AdjacencyList.vertices, connected by @a and @b
    /// Note: This does NOT check if the edge has already been inserted
    pub fn insertEdge(self: *AdjacencyList, a: u16, b: u16) !void {
        // Check to make sure the vertices are actually available
        if (a < 0 or a >= self.vertices.len) {
            return AccessError.IdxAOutOfBounds;
        } else if (b < 0 or b >= self.vertices.len) {
            return AccessError.IdxBOutOfBounds;
        }

        // Allocate the necessary memory
        var nodeA = try self.allocator.create(DestNode);
        var nodeB = try self.allocator.create(DestNode);

        // Assign the nodes to their destination, and the existing item in the linkedlist
        nodeA.* = .{
            .id = b,
            .next = self.vertices[a],
        };
        nodeB.* = .{
            .id = a,
            .next = self.vertices[b],
        };

        // Replace the existing linkedlist destination head with the newly created nodes
        self.vertices[a] = nodeA;
        self.vertices[b] = nodeB;
    }
};
