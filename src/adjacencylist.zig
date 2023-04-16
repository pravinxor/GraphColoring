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
    pub fn containsEdge(self: *const AdjacencyList, id_a: u16, id_b: u16) !bool {
        try self.check_ids(id_a, id_b);

        var a = id_a;
        var b = id_b;
        if (a > b) {
            swap(&a, &b);
        }

        var current = self.vertices[a];
        while (current) |node| {
            if (node.id == b) {
                return true;
            }
            current = node.next;
        }
        return false;
    }

    fn swap(a: *u16, b: *u16) void {
        var temp = a.*;
        a.* = b.*;
        b.* = temp;
    }
    /// Inserts @DestNode in both indices of @AdjacencyList.vertices, connected by @a and @b
    /// Note: This does NOT check if the edge has already been inserted
    pub fn insertEdge(self: *AdjacencyList, id_a: u16, id_b: u16) !void {
        try self.check_ids(id_a, id_b);

        var a = id_a;
        var b = id_b;
        if (a > b) {
            swap(&a, &b);
        }

        var nodeA = try self.allocator.create(DestNode);

        nodeA.* = .{
            .id = b,
            .next = self.vertices[a],
        };

        //...and replace the existing head of the origin's linkedlist
        self.vertices[a] = nodeA;
    }

    pub fn print(self: *const AdjacencyList, writer: *std.fs.File.Writer) !void {
        try writer.print("# Vertices: {}\n", .{self.vertices.len});
        for (self.vertices) |head, vertice| {
            var current = head;
            while (current) |node| {
                try writer.print("{}<->{} ", .{ vertice, node.id });
                current = node.next;
            }
            try writer.print("{c}", .{'\n'});
        }
    }

    /// Serializes the structure of the @AdjacencyList and writes in the @writer
    pub fn serialize(self: *const AdjacencyList, writer: anytype) !void {
        try writer.writeIntNative(u16, @intCast(u16, self.vertices.len));
        for (self.vertices) |head| {
            var current = head;
            while (current) |node| {
                try writer.writeIntLittle(u16, @intCast(u16, node.id));
                current = node.next;
            }
            try writer.writeIntLittle(u16, 0);
        }
    }

    /// Deserializes the data from a @reader containing the structure of the @AdjacencyList
    pub fn deserialize(allocator: std.mem.Allocator, reader: anytype) !AdjacencyList {
        const order = try reader.readIntLittle(u16);
        var list = try AdjacencyList.init(allocator, order, null, null);
        var n: u16 = 0;
        while (n < order) : (n += 1) {
            while (true) {
                const dest = try reader.readIntLittle(u16);
                if (dest == 0) {
                    break;
                }
                try list.insertEdge(n, dest);
            }
        }
        return list;
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
                vA = rng.random().uintLessThan(u16, @intCast(u16, list.vertices.len));
                vB = rng.random().uintLessThan(u16, @intCast(u16, list.vertices.len));
            }
            try list.insertEdge(vA, vB);
        }
    }
};
