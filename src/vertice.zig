pub const Node = struct {
    pub const Dest = struct {
        id: u16,
        next: ?*Dest,
    };
    id: u16,
    degree: u16,
    removed: bool,
    edges: ?*Dest,

    //Nodes, which are in the same degree of the current node
    prev: ?*Node,
    next: ?*Node,
};
