const std = @import("std");
const ajlist = @import("adjacencylist.zig");
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
