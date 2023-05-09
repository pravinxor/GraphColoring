const std = @import("std");
const ajlist = @import("adjacencylist.zig");
const dlist = @import("degreelist.zig");
const vertice = @import("vertice.zig");
const ordering = @import("ordering.zig");
const colorizer = @import("colorizer.zig");
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

    const start_time = std.time.nanoTimestamp();
    var list = try ajlist.AdjacencyList.init(allocator, vertices, generator, collisions);
    defer list.deinit();
    const end_time = std.time.nanoTimestamp();
    const elapsedTime = end_time - start_time;

    var action = args[4];
    if (std.mem.eql(u8, action, "print")) {
        try list.print(&writer);
    } else if (std.mem.eql(u8, action, "csv")) {
        try list.csvStats(&writer);
    } else if (std.mem.eql(u8, action, "time")) {
        // Time in μs
        try writer.print("{}\n", .{@divExact(elapsedTime, 1000)});
    }

    try buf.flush();
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

    var degree_list = try dlist.DegreeList.init(std.testing.allocator, &adjacency_list);
    defer degree_list.deinit();

    std.debug.print("\nAdjacency List:\n", .{});
    try adjacency_list.print(&stderr);
    std.debug.print("DegreeList:\n", .{});
    try degree_list.print(&stderr);
}

test "CSV graph stats" {
    var list = try ajlist.AdjacencyList.init(std.testing.allocator, 5, ajlist.ListGenerator.Type.random_skewed, 7);
    defer list.deinit();
    try list.csvStats(&stderr);
}

test "SLVO" {
    const size = 5;
    var adjacency_list = try ajlist.AdjacencyList.init(std.testing.allocator, size, ajlist.ListGenerator.Type.complete, 7);
    defer adjacency_list.deinit();
    var degree_list = try dlist.DegreeList.init(std.testing.allocator, &adjacency_list);
    defer degree_list.deinit();

    var slvo = try ordering.smallestLastVertex(&adjacency_list, &degree_list, std.testing.allocator);
    defer std.testing.allocator.free(slvo);
    std.debug.print("\n", .{});

    for (slvo) |vertex| {
        std.debug.print("[{} {}°] ", .{ vertex.id, vertex.degree });
    }

    std.debug.print("\n", .{});
}

test "SODL" {
    const size = 5;
    var adjacency_list = try ajlist.AdjacencyList.init(std.testing.allocator, size, ajlist.ListGenerator.Type.random_uniform, 7);
    defer adjacency_list.deinit();
    var degree_list = try dlist.DegreeList.init(std.testing.allocator, &adjacency_list);
    defer degree_list.deinit();

    var sodl = try ordering.smallestOriginalDegreeLast(&degree_list, size, std.testing.allocator);
    defer std.testing.allocator.free(sodl);
    std.debug.print("\n", .{});

    for (sodl) |vertex| {
        std.debug.print("[{} {}°] ", .{ vertex.id, vertex.degree });
    }
    std.debug.print("\n", .{});
}

test "SLVO Coloring" {
    const size = 5;
    var adjacency_list = try ajlist.AdjacencyList.init(std.testing.allocator, size, ajlist.ListGenerator.Type.complete, 7);
    defer adjacency_list.deinit();
    var degree_list = try dlist.DegreeList.init(std.testing.allocator, &adjacency_list);
    defer degree_list.deinit();
    var slvo = try ordering.smallestLastVertex(&adjacency_list, &degree_list, std.testing.allocator);
    defer std.testing.allocator.free(slvo);

    try colorizer.greedy_coloring(slvo, &adjacency_list, std.testing.allocator);

    std.debug.print("\n", .{});
    try adjacency_list.print(&stderr);
    for (adjacency_list.vertices) |v| {
        std.debug.print("[{} C{}] ", .{ v.id, v.color.? });
    }
    std.debug.print("\n", .{});
}
