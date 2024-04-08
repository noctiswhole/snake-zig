const std = @import("std");
const Node = @import("Node.zig");
const enums = @import("enums.zig");
const GridItem = enums.GridItem;
const Direction = enums.Direction;
const Position = @import("Position.zig");
const Snake = @This();

grid: [50][30]GridItem,
length: usize,
head: *Node,
tail: *Node,
gridWidth: usize,
gridHeight: usize,
directionCurrent: Direction,
directionToGo: Direction,
allocator: std.mem.Allocator,
foodPosition: Position,
isGameRunning: bool,

pub fn init(alloc: std.mem.Allocator, comptime gridWidth: i32, comptime gridHeight: i32) !Snake {
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
        .gridWidth = gridWidth,
        .gridHeight = gridHeight,
        .allocator = alloc,
        .directionCurrent = .east,
        .directionToGo = .east,
        .foodPosition = .{.x = 10, .y = 10},
        .isGameRunning = true,
    };
}

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

pub fn tick(self: *Snake) !void {
    var positionNew = self.head.position;
    if (self.directionToGo == .north) {
        positionNew.y -= 1;
    } else if (self.directionToGo == .south) {
        positionNew.y += 1;
    } else if (self.directionToGo == .east) {
        positionNew.x += 1;
    } else if (self.directionToGo == .west) {
        positionNew.x -= 1;
    }
    if (positionNew.x < 0 or positionNew.x >= self.gridWidth or positionNew.y < 0 or positionNew.y >= self.gridHeight) {
        self.isGameRunning = false;
    } else if (self.grid[@intCast(positionNew.x)][@intCast(positionNew.y)] == .snake) {
        self.isGameRunning = false;
    } else {
        if (std.meta.eql(positionNew, self.foodPosition)) {
            var newNode = try self.createNode(positionNew);
            newNode.next = self.head;
            self.head.previous = newNode;
            self.head = newNode;
            self.length += 1;
        } else {
            self.moveTo(positionNew);
        }
    }
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
    var curr: ?*Node = self.head.next;
    while (curr) |current| {
        curr = current.next;
        if (!std.meta.eql(current, self.tail)) {
            self.allocator.destroy(current);
        }
    }
    self.head.next = self.tail;
    self.tail.previous = self.head;
    const position = Position{.x = 5, .y = 5};
    self.head.position = position;
    self.tail.position = position;
    self.directionCurrent = .east;
    self.directionToGo = .east;
    self.length = 2;
    self.grid = .{.{.blank} ** 30} ** 50;
    self.isGameRunning = true;
}
