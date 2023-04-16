const std = @import("std");
const ajlist = @import("adjacencylist.zig");

pub fn main() !void {}

test "initialize adjacency list" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, null, null);
    defer list.deinit();
    var writer = std.io.getStdErr().writer();
    try list.print(&writer);
}

test "inserting edges into the adjacency list" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, null, null);
    defer list.deinit();

    try list.insertEdge(1, 2);
    try list.insertEdge(2, 3);
    try list.insertEdge(0, 4);
    var writer = std.io.getStdErr().writer();
    try list.print(&writer);
}

test "cycle graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.cycle, null);
    defer list.deinit();

    var writer = std.io.getStdErr().writer();
    try list.print(&writer);
}

test "complete graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.complete, null);
    defer list.deinit();

    var writer = std.io.getStdErr().writer();
    try list.print(&writer);
}

test "uniform graph generator" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.random_uniform, 7);
    defer list.deinit();

    var writer = std.io.getStdErr().writer();
    try list.print(&writer);
}
