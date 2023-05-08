const std = @import("std");
const adjlist = @import("adjacencylist.zig");
const dlist = @import("degreelist.zig");
const vertice = @import("vertice.zig");

pub fn smallestLastVertex(adj: *adjlist.AdjacencyList, degrees: *dlist.DegreeList, allocator: std.mem.Allocator) ![]*vertice.Node {
    var ordering = try allocator.alloc(*vertice.Node, adj.vertices.len);

    var count_removed: u16 = 0;
    while (count_removed < adj.vertices.len) : (count_removed += 1) {
        var smallest_vertex = degrees.smallest_degree().?;
        try adj.removeVertice(degrees, smallest_vertex);
        degrees.remove(smallest_vertex);
        smallest_vertex.removed = true;
        ordering[count_removed] = smallest_vertex;
    }
    return ordering;
}
