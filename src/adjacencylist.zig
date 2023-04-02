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

    pub fn init(allocator: std.mem.Allocator, count: u16, generatorType: ?ListGenerator.Type) !AdjacencyList {
        var vertices = try allocator.alloc(?*DestNode, count);
        std.mem.set(?*DestNode, vertices, null);
        var list = AdjacencyList{
            .vertices = vertices,
            .allocator = allocator,
        };
        if (generatorType) |generation| {
            switch (generation) {
                .complete => try ListGenerator.complete_gen(&list),
                .cycle => try ListGenerator.cycle_gen(&list),
                .random => {},
            }
        }
        return list;
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

    pub fn print(self: AdjacencyList, writer: anytype) !void {
        try writer.print("# Vertices: {}\n", .{self.vertices.len});

        for (self.vertices) |head, vertice| {
            try writer.print("V{} ->", .{vertice});
            var current = head;
            while (current) |node| {
                try writer.print(" {}", .{node.id});
                current = node.next;
            }
            try writer.print("{c}", .{'\n'});
        }
    }
};

pub const ListGenerator = struct {
    pub const Type = enum { complete, cycle, random };

    fn complete_gen(list: *AdjacencyList) !void {
        var vA: u16 = 0;
        while (vA < list.vertices.len - 1) : (vA += 1) {
            var vB: u16 = vA + 1;
            while (vB < list.vertices.len) : (vB += 1) {
                try list.insertEdge(vA, vB);
            }
        }
    }

    fn cycle_gen(list: *AdjacencyList) !void {
        try list.insertEdge(0, @intCast(u16, list.vertices.len - 1));
        var v: u16 = 0;
        while (v < list.vertices.len - 1) : (v += 1) {
            try list.insertEdge(v, v + 1);
        }
    }
};
