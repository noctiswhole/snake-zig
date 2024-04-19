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
        .left => {
            return keysPressed[sdl.SDLK_a] == 1;
        },
        .right => {
            return keysPressed[sdl.SDLK_d] == 1;
        },
        .down => {
            return keysPressed[sdl.SDLK_s] == 1;
        },
        .up => {
            return keysPressed[sdl.SDLK_w] == 1;
        },
        .reset => {
            return keysPressed[sdl.SDLK_r] == 1;
        },
        // else => {
        //     return false;
        // }
    }
}
