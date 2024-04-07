const std = @import("std");
const GRID_MAX_WIDTH = 50;
const GRID_MAX_HEIGHT = 30;

const GridItem = enum {
    blank,
    food,
    snake,
};


const Position = struct {
    x: i32,
    y: i32,
};

const Direction = enum {
    north,
    south,
    east,
    west,
};



pub const Snake = struct {
    pub const Node = struct {
        position: Position,
        next: ?*Node,
        previous: ?*Node,
    };

    grid: [GRID_MAX_WIDTH][GRID_MAX_HEIGHT]GridItem,
    length: usize,
    head: *Node,
    tail: *Node,
    gridWidth: usize,
    gridHeight: usize,
    directionCurrent: Direction,
    directionToGo: Direction,
    allocator: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator, gridWidth: usize, gridHeight: usize) !Snake {
        var startHead = try alloc.create(Node);
        startHead.position = .{.x = 5, .y = 5};
        startHead.previous = null;
        var startTail = try alloc.create(Node);
        startHead.next = startTail;
        startTail.position = .{.x = 5, .y = 5};
        startTail.next = null;
        startTail.previous = startHead;

        return .{
            .grid = .{.{.blank} ** 30} ** 50,
            .length = 2,
            .head = startHead,
            .tail = startTail,
            .gridWidth = gridWidth,
            .gridHeight = gridHeight,
            .allocator = alloc,
            .directionCurrent = .west,
            .directionToGo = .west,
        };
    }

    pub fn moveTo(self: *Snake, position: Position) void {
        if (self.length == 0) {
            @panic("ERROR: Moving an empty list");
        }
        // TODO: check position first to see if we need to create a new node
        var node = self.tail;

        if (self.length > 1) {
            // move the tail to the head
            self.tail = node.previous orelse @panic("what how does the previous node not exist");
            self.tail.next = null;
            self.head.previous = node;
            node.next = self.head;
        }
        node.position = position;
        self.head = node;
    }

    pub fn tick(self: *Snake) void {
        var positionNew = self.head.position;
        positionNew.x += 1;
        self.moveTo(positionNew);
    }

    pub fn createNode(self: *Snake, position: Position) !*Node {
        var node = try self.allocator.create(Node);
        node.position = position;
        node.next = null;
        node.previous = null;
        return node;
    }

    pub fn clear(self: *Snake) void {
        var curr = self.head;
        while (curr) |current| {
            curr = current.next;
            defer self.allocator.destroy(current);
        }
        self.length = 0;
        self.head = null;
        self.tail = null;

    }

    pub inline fn deinit(self: *Snake) void {
        self.clear();
    }
};

