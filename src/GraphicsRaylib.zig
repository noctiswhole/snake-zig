const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn beginDrawing() void {
    rl.BeginDrawing();
}

pub fn endDrawing() void {
    rl.EndDrawing();
}

pub fn clear() void {
    rl.ClearBackground(rl.RAYWHITE);
}

pub fn drawRectangle(x: usize, y: usize, width: usize, height: usize) void {
    rl.DrawRectangle(@intCast(x), @intCast(y), @intCast(width), @intCast(height), rl.RED);
}
