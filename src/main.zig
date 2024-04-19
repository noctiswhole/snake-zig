// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const Snake = @import("Snake.zig");
const Node = @import("Node.zig");
const Window = @import("WindowSDL.zig");
const Graphics = @import("GraphicsRaylib.zig");
const Input = @import("InputSDL.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 480;
    const gridSize = 16;
    // const gamepad = 0;

    var window = Window.create(screenWidth, screenHeight);
    defer window.destroy();

    var snake = try Snake.init(gpa.allocator(), 50, 30);
    // var scoreText: [12:0]u8 = undefined;
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!window.shouldQuit()) { // Detect window close button or ESC key
        // Update
        if (Input.isKeyPressed(.left)) {
            snake.setDirectionToGo(.west);
        } else if (Input.isKeyPressed(.right)) {
            snake.setDirectionToGo(.east);
        } else if (Input.isKeyPressed(.down)) {
            snake.setDirectionToGo(.south);
        } else if (Input.isKeyPressed(.up)) {
            snake.setDirectionToGo(.north);
        } else if (Input.isKeyPressed(.reset)) {
            snake.reset();
        }

        // Draw
        Graphics.beginDrawing();
        defer Graphics.endDrawing();
        Graphics.clear();

        Graphics.drawRectangle(snake.foodPosition.x * gridSize, snake.foodPosition.y * gridSize, gridSize, gridSize);

        var nextNode: ?*Node = snake.head;
        while (nextNode) |node| {
            Graphics.drawRectangle(node.position.x * gridSize, node.position.y * gridSize, gridSize, gridSize);
            nextNode = node.next;
        }
        
        if (snake.isGameRunning) {
            try snake.tick();
        } else {
            // rl.DrawText("Press R to reset.", 315, 225, 20, rl.LIGHTGRAY);
        }

        // _ = try std.fmt.bufPrint(&scoreText, "Score: {d}\x00", .{snake.length - 2});
        // rl.DrawText(@ptrCast(&scoreText), 10, 10, 20, rl.LIGHTGRAY);

        //----------------------------------------------------------------------------------
    }
}
