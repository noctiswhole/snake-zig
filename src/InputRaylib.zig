const rl = @cImport({
    @cInclude("raylib.h");
});

pub const Key = enum {
    up,
    down,
    left,
    right,
    reset,
};

pub fn IsKeyPressed(key: Key) bool {
    switch (key) {
        .left => return (rl.IsKeyPressed(rl.KEY_A) or rl.IsGamepadButtonPressed(0, rl.GAMEPAD_BUTTON_LEFT_FACE_LEFT)),
        .right => return (rl.IsKeyPressed(rl.KEY_D) or rl.IsGamepadButtonPressed(0, rl.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)),
        .down => return (rl.IsKeyPressed(rl.KEY_S) or rl.IsGamepadButtonPressed(0, rl.GAMEPAD_BUTTON_LEFT_FACE_DOWN)),
        .up => return (rl.IsKeyPressed(rl.KEY_W) or rl.IsGamepadButtonPressed(0, rl.GAMEPAD_BUTTON_LEFT_FACE_UP)),
        .reset => return (rl.IsKeyPressed(rl.KEY_R)),
    }
}
