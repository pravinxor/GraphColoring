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

    pub fn init(allocator: std.mem.Allocator, count: u16, generatorType: ?ListGenerator.Type, conflicts: ?u32) !AdjacencyList {
        // Allocate array of pointers (and set them to null, because they may have nonzero values in them already)
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
                .random_uniform => try ListGenerator.uniform_gen(&list, conflicts.?),
            }
        }
        return list;
    }

    pub fn deinit(self: *AdjacencyList) void {
        // Free the nodes in the linkedlist of each vertice
        for (self.vertices) |head| {
            var current = head;
            while (current) |node| {
                var next = node.next;
                self.allocator.destroy(node);
                current = next;
            }
        }

        self.allocator.free(self.vertices);
    }

    /// Returns an error if the ids are not in the correct bounds. Returns nothing on success
    /// Used to determine if the vertices (a and b) are actually in the AdjacencyList
    fn check_ids(self: *const AdjacencyList, a: u16, b: u16) !void {
        if (a < 0 or a >= self.vertices.len) {
            return AccessError.IdxAOutOfBounds;
        } else if (b < 0 or b >= self.vertices.len) {
            return AccessError.IdxBOutOfBounds;
        }
    }

    const AccessError = error{ IdxAOutOfBounds, IdxBOutOfBounds };
    pub fn containsEdge(self: *const AdjacencyList, a: u16, b: u16) !bool {
        try self.check_ids(a, b);

        var node = self.vertices[a];
        while (node) |current| {
            if (current.id == b) {
                return true;
            }
            node = current.next;
        }
        return false;
    }

    /// Inserts @DestNode in both indices of @AdjacencyList.vertices, connected by @a and @b
    /// Note: This does NOT check if the edge has already been inserted
    pub fn insertEdge(self: *AdjacencyList, a: u16, b: u16) !void {
        try self.check_ids(a, b);

        var nodeA = try self.allocator.create(DestNode);
        errdefer self.allocator.destroy(nodeA);
        var nodeB = try self.allocator.create(DestNode);
        errdefer self.allocator.destroy(nodeB);

        // Assign the nodes to their destination...
        nodeA.* = .{
            .id = b,
            .next = self.vertices[a],
        };
        nodeB.* = .{
            .id = a,
            .next = self.vertices[b],
        };

        //...and replace the existing head of the origin's linkedlist
        self.vertices[a] = nodeA;
        self.vertices[b] = nodeB;
    }

    pub fn print(self: *const AdjacencyList, writer: anytype) !void {
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
    pub const Type = enum { complete, cycle, random_uniform };
    const GeneratorError = error{TooManyConflicts};

    fn complete_gen(list: *AdjacencyList) !void {
        // Connect the edges by choosing the origin node, and creating edges between it and every node ahead of it
        var vA: u16 = 0;
        while (vA < list.vertices.len - 1) : (vA += 1) {
            var vB: u16 = vA + 1;
            while (vB < list.vertices.len) : (vB += 1) {
                try list.insertEdge(vA, vB);
            }
        }
    }

    fn cycle_gen(list: *AdjacencyList) !void {
        // Create a cycle between every vertice, by connecting it to the vertice @id + 1
        var v: u16 = 0;
        while (v < list.vertices.len - 1) : (v += 1) {
            try list.insertEdge(v, v + 1);
        }

        // The first (@0) and last (@vertices.len) vertices are only connected to 1 vertice, so connect those two together
        try list.insertEdge(0, @intCast(u16, list.vertices.len - 1));
    }

    fn uniform_gen(list: *AdjacencyList, conflicts: u32) !void {
        if (conflicts > list.vertices.len * (list.vertices.len - 1) / 2) {
            return GeneratorError.TooManyConflicts;
        }
        const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
        var rng = std.rand.DefaultPrng.init(seed);

        var i: u32 = 0;
        while (i < conflicts) : (i += 1) {
            var vA: u16 = 0;
            var vB: u16 = 0;
            while (vA == vB or try list.containsEdge(vA, vB)) {
                vA = rng.random().int(u16) % @intCast(u16, list.vertices.len);
                vB = rng.random().int(u16) % @intCast(u16, list.vertices.len);
            }
            try list.insertEdge(vA, vB);
        }
    }
};
