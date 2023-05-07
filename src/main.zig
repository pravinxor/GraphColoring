const std = @import("std");
const ajlist = @import("adjacencylist.zig");
const dlist = @import("degreelist.zig");
const vertice = @import("vertice.zig");
var stderr = std.io.getStdErr().writer();

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    std.debug.print("Arguments: {s}\n", .{args});

    const out = std.io.getStdOut();
    var buf = std.io.bufferedWriter(out.writer());
    var writer = buf.writer();

    var vertices = try std.fmt.parseInt(u16, args[1], 10);
    var collisions = try std.fmt.parseInt(u32, args[2], 10);
    var generator: ?ajlist.ListGenerator.Type = null;
    if (std.mem.eql(u8, args[3], "cycle")) {
        generator = ajlist.ListGenerator.Type.cycle;
    } else if (std.mem.eql(u8, args[3], "complete")) {
        generator = ajlist.ListGenerator.Type.complete;
    } else if (std.mem.eql(u8, args[3], "uniform")) {
        generator = ajlist.ListGenerator.Type.random_uniform;
    } else if (std.mem.eql(u8, args[3], "skewed")) {
        generator = ajlist.ListGenerator.Type.random_skewed;
    } else if (std.mem.eql(u8, args[3], "qskewed")) {
        generator = ajlist.ListGenerator.Type.random_square;
    }

    var list = try ajlist.AdjacencyList.init(allocator, vertices, generator, collisions);
    defer list.deinit();
    try list.print(&writer);
}

test "initialize adjacency list" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, null, null);
    defer list.deinit();
}

test "inserting edges into the adjacency list" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, null, null);
    defer list.deinit();

    try list.insertEdge(1, 2);
    try list.insertEdge(2, 3);
    try list.insertEdge(0, 4);
    try list.print(&stderr);
}

test "cycle graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.cycle, null);
    defer list.deinit();
    try list.print(&stderr);
}

test "complete graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.complete, null);
    defer list.deinit();
    try list.print(&stderr);
}

test "uniform random graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.random_uniform, 7);
    defer list.deinit();
    try list.print(&stderr);
}

test "skewed random graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.random_skewed, 7);
    defer list.deinit();
    try list.print(&stderr);
}

test "skewed quadratic bias graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.random_square, 7);
    defer list.deinit();
    try list.print(&stderr);
}

test "Serialization and Deserialization" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 4, ajlist.ListGenerator.Type.cycle, null);
    defer list.deinit();

    std.debug.print("\nOriginal List:\n", .{});
    try list.print(&stderr);

    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    try list.serialize(buf.writer());

    std.debug.print("Deserialized List:\n", .{});
    var reader = std.io.fixedBufferStream(buf.items);

    var dserList = try ajlist.AdjacencyList.deserialize(std.testing.allocator, &reader.reader());
    defer dserList.deinit();

    try dserList.print(&stderr);
}

test "DegreeList" {
    const size = 5;
    var adjacency_list = try ajlist.AdjacencyList.init(std.testing.allocator, size, ajlist.ListGenerator.Type.random_uniform, 7);
    defer adjacency_list.deinit();

    var degree_list = try dlist.DegreeList.init(std.testing.allocator, size);
    defer degree_list.deinit();

    var n: u16 = 0;
    while (n < adjacency_list.vertices.len) : (n += 1) {
        try degree_list.insert(adjacency_list.vertices[n].degree, &adjacency_list.vertices[n]);
    }

    try stderr.print("\nAdjacency List:\n", .{});
    try adjacency_list.print(&stderr);
    try stderr.print("DegreeList:\n", .{});
    try degree_list.print(&stderr);
}

test "CSV graph stats" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.random_skewed, 7);
    defer list.deinit();
    try list.csv_stats(&stderr);
}

test "Ordering" {
    const size = 5;
    var adjacency_list = try ajlist.AdjacencyList.init(std.testing.allocator, size, ajlist.ListGenerator.Type.random_uniform, 7);
    defer adjacency_list.deinit();
    var degree_list = try dlist.DegreeList.init(std.testing.allocator, size);
    defer degree_list.deinit();
    var ordering = std.ArrayList(vertice.Node).init(std.testing.allocator);
    defer ordering.deinit();

    var n: u16 = 0;
    while (n < adjacency_list.vertices.len) : (n += 1) {
        try degree_list.insert(adjacency_list.vertices[n].degree, &adjacency_list.vertices[n]);
    }

    var count_removed: u16 = 0;
    while (count_removed < size) : (count_removed += 1) {
        var smallest_vertex = degree_list.smallest_degree().?;
        try adjacency_list.removeVertice(&degree_list, smallest_vertex);
        degree_list.remove(smallest_vertex);
        smallest_vertex.removed = true;
        try ordering.append(smallest_vertex.*);
    }
    std.debug.print("{c}", .{'\n'});

    var k: u16 = size;
    while (k > 0) : (k -= 1) {
        var vertex: vertice.Node = ordering.items[k - 1];
        try stderr.print("[{} {}°] ", .{ vertex.id, vertex.degree });
    }
    std.debug.print("{c}", .{'\n'});
}
