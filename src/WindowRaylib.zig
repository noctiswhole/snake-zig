const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn createWindow(width: u32, height: u32) void {
    rl.InitWindow(@intCast(width), @intCast(height), "Snake");

    rl.SetTargetFPS(30); // Set our game to run at 60 frames-per-second
}

pub fn destroyWindow() void {
    rl.CloseWindow();
}

pub fn shouldQuit() bool {
    return rl.WindowShouldClose();
}
