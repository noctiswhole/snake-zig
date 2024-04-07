// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const Snake = @import("Snake.zig");
const Node = @import("Node.zig");
const rl = @import("raylib");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 480;
    const gridSize = 16;

    rl.initWindow(screenWidth, screenHeight, "Snake");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    var snake = try Snake.init(gpa.allocator(), 50, 30);
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);

        var nextNode: ?*Node = snake.head;

        while (nextNode) |node| {
            rl.drawRectangle(node.position.x * gridSize, node.position.y * gridSize, gridSize, gridSize, rl.Color.black);
            nextNode = node.next;
        }
        defer snake.tick();


        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
        //----------------------------------------------------------------------------------
    }
}
