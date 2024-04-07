const Position = @import("Position.zig");
const Node = @This();

position: Position,
next: ?*Node,
previous: ?*Node,
