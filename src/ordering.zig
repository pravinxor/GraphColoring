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
        ordering[adj.vertices.len - count_removed - 1] = smallest_vertex;
    }
    return ordering;
}

/// Returns the size of the terminal clique, for SLVO orderings
pub fn slvoTerminalCliqueSize(vertices: []*vertice.Node) u16 {
    var size: u16 = 0;
    for (vertices) |v| {
        if (v.color.? == size) {
            size += 1;
        } else {
            break;
        }
    }
    return size;
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

pub fn randomOrdering(degrees: *const dlist.DegreeList, size: u16, allocator: std.mem.Allocator) ![]*vertice.Node {
    var ordering = try allocator.alloc(?*vertice.Node, size);
    std.mem.set(?*vertice.Node, ordering, null);

    const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
    var rng = std.rand.DefaultPrng.init(seed);

    for (degrees.degrees) |degree| {
        var node = degree;
        while (node) |n| {
            var k: u16 = 0;
            while (true) {
                k = rng.random().uintLessThan(u16, @intCast(u16, ordering.len));
                if (ordering[k] == null) {
                    break;
                }
            }
            ordering[k] = n;
            node = n.next;
        }
    }
    return @ptrCast([]*vertice.Node, ordering);
}
