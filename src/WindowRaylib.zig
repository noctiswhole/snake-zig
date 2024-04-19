const Self = @This();

const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn create(width: u32, height: u32) Self {
    rl.InitWindow(@intCast(width), @intCast(height), "Snake");
    rl.SetTargetFPS(30);
    return .{};
}

pub fn destroy(_: Self) void {
    rl.CloseWindow();
}

pub fn shouldQuit() bool {
    return rl.WindowShouldClose();
}
