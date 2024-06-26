const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");
const Snake = @import("Snake.zig");
const Node = @import("Node.zig");
const Window = @import("Window.zig");
const Graphics = @import("Graphics.zig");
const Input = @import("Input.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 640;
    const screenHeight = 480;
    const allocator = gpa.allocator();
    // const gamepad = 0;

    var window = Window.create(screenWidth, screenHeight);
    defer window.destroy();

    var graphics = Graphics.create(window.context, allocator, screenWidth, screenHeight);

    var snake = try Snake.init(allocator);
    //--------------------------------------------------------------------------------------

    var lastUpdate: usize = 0;
    // Main game loop
    while (!window.shouldQuit()) { // Detect window close button or ESC key
        const ticks: usize = sdl.SDL_GetTicks64();
        // Update
        if (ticks - lastUpdate > 32) {
            lastUpdate = ticks;
            var event: sdl.SDL_Event = undefined;
            while (sdl.SDL_PollEvent(&event) != 0) {
                switch (event.type) {
                    sdl.SDL_QUIT => {
                        window.quit = true;
                    },
                    sdl.SDL_JOYHATMOTION => {
                        if (event.jhat.value == sdl.SDL_HAT_LEFT) {
                            std.debug.print("Left pressed", .{});
                            snake.setDirectionToGo(.west);
                        }
                        if (event.jhat.value == sdl.SDL_HAT_RIGHT) {
                            std.debug.print("Right pressed", .{});
                            snake.setDirectionToGo(.east);
                        }
                        if (event.jhat.value == sdl.SDL_HAT_UP) {
                            std.debug.print("Up pressed", .{});
                            snake.setDirectionToGo(.north);
                        }
                        if (event.jhat.value == sdl.SDL_HAT_DOWN) {
                            std.debug.print("Down pressed", .{});
                            snake.setDirectionToGo(.south);
                        }
                    },
                    sdl.SDL_JOYBUTTONDOWN => {
                        std.debug.print("Pressed {d}\n", .{event.jbutton.button});
                        if (event.jbutton.button == 4) {
                            snake.reset();
                        }
                        if (event.jbutton.button == 11) {
                            window.quit = true;
                        }
                    },
                    sdl.SDL_KEYDOWN => {
                        if (event.key.keysym.scancode == sdl.SDL_SCANCODE_A) {
                            snake.setDirectionToGo(.west);
                        }
                        if (event.key.keysym.scancode == sdl.SDL_SCANCODE_D) {
                            snake.setDirectionToGo(.east);
                        }
                        if (event.key.keysym.scancode == sdl.SDL_SCANCODE_W) {
                            snake.setDirectionToGo(.north);
                        }
                        if (event.key.keysym.scancode == sdl.SDL_SCANCODE_S) {
                            snake.setDirectionToGo(.south);
                        }
                        if (event.key.keysym.scancode == sdl.SDL_SCANCODE_R) {
                            snake.reset();
                        }
                    },
                    else => {
                    }
                }
            }

            // Draw
            window.beginDrawing();
            defer window.endDrawing();
            graphics.clear();


            // Graphics.drawRectangle(snake.foodPosition.x * gridSize, snake.foodPosition.y * gridSize, gridSize, gridSize);
            graphics.drawSquare(snake.foodPosition.x * Snake.gridSize, snake.foodPosition.y * Snake.gridSize);

            var nextNode: ?*Node = snake.head;
            while (nextNode) |node| {
                graphics.drawSquare(node.position.x * Snake.gridSize, node.position.y * Snake.gridSize);
                // Graphics.drawRectangle(node.position.x * gridSize, node.position.y * gridSize,gridSize, gridSize);
                nextNode = node.next;
            }
            
            if (snake.isGameRunning) {
                try snake.tick();
            } else {
                // rl.DrawText("Press R to reset.", 315, 225, 20, rl.LIGHTGRAY);
            }

            graphics.drawScore(snake.length - 2);

        }
    }
}
