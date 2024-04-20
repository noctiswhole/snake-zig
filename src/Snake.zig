const std = @import("std");
const Node = @import("Node.zig");
const enums = @import("enums.zig");
const GridItem = enums.GridItem;
const Direction = enums.Direction;
const Position = @import("Position.zig");
const Snake = @This();
const gridWidth = 40;
const gridHeight = 30;
pub const gridSize = 16;

length: u32,
head: *Node,
tail: *Node,
directionCurrent: Direction,
directionToGo: Direction,
allocator: std.mem.Allocator,
foodPosition: Position,
isGameRunning: bool,
grid: [gridWidth][gridHeight]GridItem,

pub fn init(alloc: std.mem.Allocator) !Snake {
    var startHead = try alloc.create(Node);
    startHead.position = .{.x = 5, .y = 5};
    startHead.previous = null;
    var startTail = try alloc.create(Node);
    startHead.next = startTail;
    startTail.position = .{.x = 5, .y = 5};
    startTail.next = null;
    startTail.previous = startHead;

    return .{
        .grid = .{.{.blank} ** gridHeight} ** gridWidth,
        .length = 2,
        .head = startHead,
        .tail = startTail,
        .allocator = alloc,
        .directionCurrent = .east,
        .directionToGo = .east,
        .foodPosition = .{.x = 10, .y = 10},
        .isGameRunning = true,
    };
}

// move tail to head at position
pub fn moveTo(self: *Snake, position: Position) void {
    var node = self.tail;

    // update grid for collision detection
    self.grid[@intCast(node.position.x)][@intCast(node.position.y)] = .blank;
    self.grid[@intCast(position.x)][@intCast(position.y)] = .snake;

    // move the tail to the head
    self.tail = node.previous orelse @panic("what how does the previous node not exist");
    self.tail.next = null;
    self.head.previous = node;
    node.next = self.head;
    node.position = position;
    self.head = node;
}

// Advance snake forward and handle any collisions and food
pub fn tick(self: *Snake) !void {
    // Calculate new head position and signal exit if oob or collision
    var positionNew = self.head.position;
    if (self.directionToGo == .south) {
        if (positionNew.y == 0) {
            self.isGameRunning = false;
        } else {
            positionNew.y -= 1;
        }
    } else if (self.directionToGo == .north) {
        if (positionNew.y + 1 >= gridHeight) {
            self.isGameRunning = false;
        } else {
            positionNew.y += 1;
        }
    } else if (self.directionToGo == .east) {
        if (positionNew.x + 1 >= gridWidth) {
            self.isGameRunning = false;
        } else {
            positionNew.x += 1;
        }
    } else if (self.directionToGo == .west) {
        if (positionNew.x == 0) {
            self.isGameRunning = false;
        } else {
            positionNew.x -= 1;
        }
    }

    if (self.grid[positionNew.x][positionNew.y] == .snake) {
        self.isGameRunning = false;
    }

    if (!self.isGameRunning) {
        return;
    }

    if (std.meta.eql(positionNew, self.foodPosition)) {
        // Grow snake if it finds food
        var newNode = try self.createNode(positionNew);
        newNode.next = self.head;
        self.head.previous = newNode;
        self.head = newNode;
        self.length += 1;
        self.generateNewFood();
    } else {
        self.moveTo(positionNew);
    }
}

fn generateNewFood(self: *Snake) void {
    const maxPos = gridWidth * gridHeight;
    const rnd = std.crypto.random;
    var foodPos = rnd.intRangeAtMost(u32, 0, maxPos - self.length);
    var pos: u16 = 0;
    while (foodPos > 0) {
        if (self.grid[pos % 40][pos / 40] != .snake) {
            foodPos -= 1;
        }
        pos += 1;
        if (pos > maxPos) {
            @panic("pos greater than maxPos");
        }
    }
    self.foodPosition = .{ .x = @intCast(pos % 40), .y = @intCast(pos / 40) };
}

pub fn setDirectionToGo(self: *Snake, direction: Direction) void {
    // make sure player can't go directly backwards
    if (self.directionToGo != .north and direction == .south) {
        self.directionToGo = direction;
    } else if (self.directionToGo != .south and direction == .north) {
        self.directionToGo = direction;
    } else if (self.directionToGo != .east and direction == .west) {
        self.directionToGo = direction;
    } else if (self.directionToGo != .west and direction == .east) {
        self.directionToGo = direction;
    }
}

pub fn createNode(self: *Snake, position: Position) !*Node {
    var node = try self.allocator.create(Node);
    node.position = position;
    node.next = null;
    node.previous = null;
    return node;
}

pub fn reset(self: *Snake) void {
    // destroy all extra nodes
    var curr: ?*Node = self.head.next;
    while (curr) |current| {
        curr = current.next;
        if (!std.meta.eql(current, self.tail)) {
            self.allocator.destroy(current);
        }
    }

    // reset snake variables
    self.head.next = self.tail;
    self.tail.previous = self.head;
    const position = Position{.x = 5, .y = 5};
    self.head.position = position;
    self.tail.position = position;
    self.directionCurrent = .east;
    self.directionToGo = .east;
    self.length = 2;
    self.generateNewFood();
    self.grid = .{.{.blank} ** gridHeight} ** gridWidth;
    self.isGameRunning = true;
}
