// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const Snake = @import("Snake.zig");
const Node = @import("Node.zig");
// const rl = @import("raylib");
const rl = @cImport({
    @cInclude("raylib.h");
});
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 480;
    const gridSize = 16;

    // rl.initWindow(screenWidth, screenHeight, "Snake");
    rl.InitWindow(screenWidth, screenHeight, "Snake");
    defer rl.CloseWindow(); // Close window and OpenGL context

    rl.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
    var snake = try Snake.init(gpa.allocator(), 50, 30);
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);
        if (rl.IsKeyPressed(rl.KEY_A)) {
            snake.setDirectionToGo(.west);
        } else if (rl.IsKeyPressed(rl.KEY_D)) {
            snake.setDirectionToGo(.east);
        } else if (rl.IsKeyPressed(rl.KEY_S)) {
            snake.setDirectionToGo(.south);
        } else if (rl.IsKeyPressed(rl.KEY_W)) {
            snake.setDirectionToGo(.north);
        }

        var nextNode: ?*Node = snake.head;

        while (nextNode) |node| {
            rl.DrawRectangle(node.position.x * gridSize, node.position.y * gridSize, gridSize, gridSize, rl.BLACK);
            nextNode = node.next;
        }
        
        rl.DrawRectangle(snake.foodPosition.x * gridSize, snake.foodPosition.y * gridSize, gridSize, gridSize, rl.RED);
        try snake.tick();

        // rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY);
        //----------------------------------------------------------------------------------
    }
}
