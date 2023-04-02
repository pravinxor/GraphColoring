const std = @import("std");
const ajlist = @import("adjacencylist.zig");

pub fn main() !void {}

test "initialize adjacency list" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5);
    defer list.deinit();
}

test "inserting edges into the adjacency list" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5);
    defer list.deinit();

    try list.insertEdge(1, 2);
    try list.insertEdge(2, 3);
    try list.insertEdge(0, 4);
}

test "print function" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5);
    defer list.deinit();

    try list.insertEdge(1, 2);
    try list.insertEdge(2, 3);
    try list.insertEdge(0, 4);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try list.print(stdout);
    try bw.flush();
}
