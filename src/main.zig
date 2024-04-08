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
    const gamepad = 5;

    // rl.initWindow(screenWidth, screenHeight, "Snake");
    rl.InitWindow(screenWidth, screenHeight, "Snake");
    defer rl.CloseWindow(); // Close window and OpenGL context

    rl.SetTargetFPS(30); // Set our game to run at 60 frames-per-second
    var snake = try Snake.init(gpa.allocator(), 50, 30);
    var scoreText: [12:0]u8 = undefined;
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
        if (rl.IsKeyPressed(rl.KEY_A) or rl.IsGamepadButtonPressed(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) {
            snake.setDirectionToGo(.west);
        } else if (rl.IsKeyPressed(rl.KEY_D) or rl.IsGamepadButtonPressed(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) {
            snake.setDirectionToGo(.east);
        } else if (rl.IsKeyPressed(rl.KEY_S) or rl.IsGamepadButtonPressed(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_DOWN)) {
            snake.setDirectionToGo(.south);
        } else if (rl.IsKeyPressed(rl.KEY_W) or rl.IsGamepadButtonPressed(gamepad, rl.GAMEPAD_BUTTON_LEFT_FACE_UP)) {
            snake.setDirectionToGo(.north);
        } else if (rl.IsKeyPressed(rl.KEY_R)) {
            snake.reset();
        }

        var nextNode: ?*Node = snake.head;
        rl.DrawRectangle(snake.foodPosition.x * gridSize, snake.foodPosition.y * gridSize, gridSize, gridSize, rl.RED);

        while (nextNode) |node| {
            rl.DrawRectangle(node.position.x * gridSize, node.position.y * gridSize, gridSize, gridSize, rl.BLACK);
            nextNode = node.next;
        }
        
        if (snake.isGameRunning) {
            try snake.tick();
        } else {
            rl.DrawText("Press R to reset.", 315, 225, 20, rl.LIGHTGRAY);
        }

        _ = try std.fmt.bufPrint(&scoreText, "Score: {d}\x00", .{snake.length - 2});
        rl.DrawText(@ptrCast(&scoreText), 10, 10, 20, rl.LIGHTGRAY);

        //----------------------------------------------------------------------------------
    }
}
