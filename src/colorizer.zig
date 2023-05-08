const std = @import("std");
const vertice = @import("vertice.zig");
const adjlist = @import("adjacencylist.zig");

/// Fills in the color property of the Nodes in @vertices based on the ordering that they are passed in with
pub fn greedy_coloring(vertices: []*vertice.Node, adj: *const adjlist.AdjacencyList, allocator: std.mem.Allocator) !void {
    var available = try allocator.alloc(bool, vertices.len);
    defer allocator.free(available);

    for (vertices) |v| {
        std.mem.set(bool, available, true);

        // mark conflicts as unavailable in the @available array
        var current = v.edges;
        while (current) |node| {
            if (adj.vertices[node.id].color) |color| {
                std.debug.print("\n{} has conflict {}C", .{ node.id, color });
                available[color] = false;
            }
            current = node.next;
        }
        for (available) |state, idx| {
            if (state) {
                v.color = @intCast(u16, idx);
                break;
            }
        }
    }
}
