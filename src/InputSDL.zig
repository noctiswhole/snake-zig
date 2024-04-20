const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Key = @import("enums.zig").Key;

pub fn pollInput() void {
    sdl.SDL_PumpEvents();
}

pub fn isKeyPressed(key: Key) bool {
    const keysPressed = sdl.SDL_GetKeyboardState(null);
    switch (key) {
        .quit => {
            return keysPressed[sdl.SDL_SCANCODE_Q] == 1;
        },
        .left => {
            return keysPressed[sdl.SDL_SCANCODE_A] == 1;
        },
        .right => {
            return keysPressed[sdl.SDL_SCANCODE_D] == 1;
        },
        .down => {
            return keysPressed[sdl.SDL_SCANCODE_S] == 1;
        },
        .up => {
            return keysPressed[sdl.SDL_SCANCODE_W] == 1;
        },
        .reset => {
            return keysPressed[sdl.SDL_SCANCODE_R] == 1;
        },
        // else => {
        //     return false;
        // }
    }
}
