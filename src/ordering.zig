const std = @import("std");
const adjlist = @import("adjacencylist.zig");
const dlist = @import("degreelist.zig");
const vertice = @import("vertice.zig");
var stderr = std.io.getStdErr().writer();

pub fn smallestLastVertex(adj: *adjlist.AdjacencyList, degrees: *dlist.DegreeList, allocator: std.mem.Allocator) ![]*vertice.Node {
    var ordering = try allocator.alloc(*vertice.Node, adj.vertices.len);

    var count_removed: u16 = 0;
    while (count_removed < adj.vertices.len) : (count_removed += 1) {
        var smallest_vertex = degrees.smallest_degree().?;
        try adj.removeVertice(degrees, smallest_vertex);
        degrees.remove(smallest_vertex);
        smallest_vertex.removed = true;
        ordering[count_removed] = smallest_vertex;
        try adj.print(stderr);
    }
    return ordering;
}

pub fn smallestOriginalDegreeLast(degrees: *const dlist.DegreeList, size: u16, allocator: std.mem.Allocator) ![]*vertice.Node {
    var ordering = try allocator.alloc(*vertice.Node, size);
    var k: u16 = 1;
    for (degrees.degrees) |degree| {
        var node = degree;
        while (node) |n| {
            ordering[size - k] = n;
            node = n.next;
            k += 1;
        }
    }
    return ordering;
}
