const sdl = @import("sdl");
const std = @import("std");

const Self = @This();
screen: *sdl.SDL_Window,
context: sdl.SDL_GLContext,
renderer: *sdl.SDL_Renderer,
quit: bool = false,

pub fn create(width: u32, height: u32) Self {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        @panic("");
    }
    const screen = sdl.SDL_CreateWindow("Snake", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, @intCast(width), @intCast(height), sdl.SDL_WINDOW_OPENGL) orelse
    {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        @panic("");
    };
    const renderer = sdl.SDL_CreateRenderer(screen, -1, sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_TARGETTEXTURE) orelse {
        sdl.SDL_Log("Unable to create renderer: %s", sdl.SDL_GetError());
        @panic("");
    };

    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_ES);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 0);
    _ = sdl.SDL_GL_SetSwapInterval(0);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24);
    const context = sdl.SDL_GL_CreateContext(screen);



    return .{
        .screen = screen,
        .context = context,
        .renderer = renderer,
    };
}

pub fn shouldQuit(self: *Self) bool {
    return self.quit;
}

pub fn destroy(self: *Self) void {
    sdl.SDL_DestroyWindow(self.screen);
    sdl.SDL_DestroyRenderer(self.renderer);
    sdl.SDL_GL_DeleteContext(self.context);
    sdl.SDL_Quit();
}

pub fn beginDrawing(_: Self) void {
}

pub fn endDrawing(self: *Self) void {
    sdl.SDL_GL_SwapWindow(self.screen);
}

pub fn clear(self: *Self) void {
    _ = sdl.SDL_RenderClear(self.renderer);
}
