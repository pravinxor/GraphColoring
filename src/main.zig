const std = @import("std");
const ajlist = @import("adjacencylist.zig");
const dlist = @import("degreelist.zig");
var stderr = std.io.getStdErr().writer();

pub fn main() !void {}

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
