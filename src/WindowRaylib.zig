const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn createWindow(screenWidth: usize, screenHeight: usize) void {
    rl.InitWindow(@intCast(screenWidth), @intCast(screenHeight), "Snake");
    defer rl.CloseWindow(); // Close window and OpenGL context

    rl.SetTargetFPS(30); // Set our game to run at 60 frames-per-second
}

pub fn destroyWindow() void {
    rl.CloseWindow();
}

pub fn shouldQuit() bool {
    return rl.WindowShouldClose();
}
