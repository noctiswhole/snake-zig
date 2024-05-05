// const sdl = @import("Window.zig").sdl;
const sdl = @import("sdl");
// const gl = @import("gl");
const gl = @cImport({
    @cInclude("GLES3/gl31.h");
});
const std = @import("std");
const math = std.math;
const Vertex = @import("Vertex.zig");
const zm = @import("zmath");
const Self = @This();
const gridSize = @import("Snake.zig").gridSize;

pub const comptime_file_paths = [_][]const u8{
    "assets/0.bmp",
    "assets/1.bmp",
    "assets/2.bmp",
    "assets/3.bmp",
    "assets/4.bmp",
    "assets/5.bmp",
    "assets/6.bmp",
    "assets/7.bmp",
    "assets/8.bmp",
    "assets/9.bmp",
};

const EmbeddedFile = struct {
    path: []const u8,
    content: []const u8,
};

pub var embedded_files1 = std.ArrayList(EmbeddedFile).init(std.heap.ArenaAllocator);

const RGB = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

const vertices = [_]Vertex{
    Vertex{
        // top left
        .x = 0,
        .y = 0,
        .u = 0,
        .v = 1,
    },
    Vertex{
        // top right 
        .x = 1,
        .y = 0,
        .u = 1,
        .v = 1,
    },
    Vertex{
        // bot left
        .x = 0,
        .y = 1,
        .u = 0,
        .v = 0,
    },
    Vertex{ 
        // bot right
        .x = 1,
        .y = 1,
        .u = 1,
        .v = 0,
    },
};

const indices = [6]c_uint{
    // first triangle
    2, 3, 0,  
    // second triangle
    3, 0, 1, 
};

program: gl.GLuint,
texProgram: gl.GLuint,
vbo: gl.GLuint,
vao: gl.GLuint,
ebo: gl.GLuint,
screenWidth: i64,
screenHeight: i64,
scoreTexture: gl.GLuint,

pub fn getProcAddress(p: ?*anyopaque, proc: [:0]const u8) ?*align(4) const anyopaque {
    _ = p;
    return SDL_GL_GetProcAddress(proc);
}
extern fn SDL_GL_GetProcAddress(proc: ?[*:0]const u8) ?*align(4) const anyopaque;

fn compileShader(allocator: std.mem.Allocator, vertex_source: [:0]const u8, fragment_source: [:0]const u8) !gl.GLuint {
    const vertex_shader = try compilerShaderPart(allocator, gl.GL_VERTEX_SHADER, vertex_source);
    defer gl.glDeleteShader(vertex_shader);

    const fragment_shader = try compilerShaderPart(allocator, gl.GL_FRAGMENT_SHADER, fragment_source);
    defer gl.glDeleteShader(fragment_shader);

    const program = gl.glCreateProgram();
    if (program == 0)
        return error.OpenGlFailure;
    errdefer gl.glDeleteProgram(program);

    gl.glAttachShader(program, vertex_shader);
    defer gl.glDetachShader(program, vertex_shader);

    gl.glAttachShader(program, fragment_shader);
    defer gl.glDetachShader(program, fragment_shader);

    gl.glLinkProgram(program);

    var link_status: gl.GLint = undefined;
    gl.glGetProgramiv(program, gl.GL_LINK_STATUS, &link_status);

    if (link_status != gl.GL_TRUE) {
        var info_log_length: gl.GLint = undefined;
        gl.glGetProgramiv(program, gl.GL_INFO_LOG_LENGTH, &info_log_length);

        const info_log = try allocator.alloc(u8, @intCast(info_log_length));
        defer allocator.free(info_log);

        gl.glGetProgramInfoLog(program, @intCast(info_log.len), null, info_log.ptr);

        std.log.info("failed to compile shader:\n{s}", .{info_log});

        return error.InvalidShader;
    }

    return program;
}

fn compilerShaderPart(allocator: std.mem.Allocator, shader_type: gl.GLenum, source: [:0]const u8) !gl.GLuint {
    const shader = gl.glCreateShader(shader_type);
    if (shader == 0)
        return error.OpenGlFailure;
    errdefer gl.glDeleteShader(shader);

    var sources = [_][*c]const u8{source.ptr};
    var lengths = [_]gl.GLint{@intCast(source.len)};

    gl.glShaderSource(shader, 1, &sources, &lengths);

    gl.glCompileShader(shader);

    var compile_status: gl.GLint = undefined;
    gl.glGetShaderiv(shader, gl.GL_COMPILE_STATUS, &compile_status);

    if (compile_status != gl.GL_TRUE) {
        var info_log_length: gl.GLint = undefined;
        gl.glGetShaderiv(shader, gl.GL_INFO_LOG_LENGTH, &info_log_length);

        const info_log = try allocator.alloc(u8, @intCast(info_log_length));
        defer allocator.free(info_log);

        gl.glGetShaderInfoLog(shader, @intCast(info_log.len), null, info_log.ptr);

        std.log.info("failed to compile shader:\n{s}", .{info_log});

        return error.InvalidShader;
    }

    return shader;
}

pub fn create(context: sdl.SDL_GLContext, allocator: std.mem.Allocator, screenWidth: u32, screenHeight: u32) Self {
    _ = sdl.IMG_Init(sdl.IMG_INIT_PNG);
        _ = context;
    // gl.glLoad(context, getProcAddress) catch {
    //     @panic("Could not load GL context");
    // };
    const program = compileShader(allocator, @embedFile("rectangle.vert"), @embedFile("rectangle.frag")) catch {
        @panic("Could not compile shaders");
    };

    const texProgram = compileShader(allocator, @embedFile("rectangle_tex.vert"), @embedFile("rectangle_tex.frag")) catch {
        @panic("Could not compile shaders");
    };

    // Initialize buffers
    var vao: gl.GLuint = undefined;
    var vbo: gl.GLuint = undefined;
    var ebo: gl.GLuint = undefined;

    gl.glGenVertexArrays(1, &vao);
    if (vao == 0) {
        @panic("Could not generate vertex array");
    }

    gl.glGenBuffers(1, &vbo);
    if (vbo == 0) {
        @panic("Could not generate vertex buffer");
    }

    gl.glGenBuffers(1, &ebo);
    if (ebo == 0) {
        @panic("Could not generate ebo buffer");
    }

    // Bind buffers
    gl.glBindVertexArray(vao);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, ebo);
    gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, 6 * @sizeOf(c_uint), &indices, gl.GL_STATIC_DRAW);

    // bind data
    // position
    gl.glEnableVertexAttribArray(0); 
    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "x")));

    // uv
    gl.glEnableVertexAttribArray(1);
    gl.glVertexAttribPointer(1, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "u")));

    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0);
    gl.glBindVertexArray(0);
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, 0);

    // gl.enable(gl.CULL_FACE);
    gl.glEnable(gl.GL_BLEND);

    var texture: gl.GLuint = undefined;
    gl.glGenTextures(1, &texture);

    gl.glBindTexture(gl.GL_TEXTURE_2D_ARRAY, texture);
    gl.glBindTexture(gl.GL_TEXTURE_2D_ARRAY, texture);
    // gl.texImage3D(gl.TEXTURE_2D_ARRAY, 0, gl.RGBA, fontSurface.*.w, fontSurface.*.h, 16, 0, mode, gl.UNSIGNED_BYTE, fontSurface.*.pixels);
    gl.glTexImage3D(gl.GL_TEXTURE_2D_ARRAY, 0, gl.GL_RGBA, 16, 32, 10, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, null);

    inline for (0..comptime_file_paths.len) |i| {
        const tex = @embedFile(comptime_file_paths[i]);
        const rw = sdl.SDL_RWFromConstMem(tex, tex.len) orelse {
            @panic("lol");
        };
        const fontSurface = sdl.SDL_LoadBMP_RW(rw, 0) orelse {
            @panic("also lol");
        };
        defer sdl.SDL_FreeSurface(fontSurface);
        gl.glTexSubImage3D(gl.GL_TEXTURE_2D_ARRAY, 0, 0, 0, @intCast(i), 16, 32, 1, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, fontSurface.*.pixels);
    }

    gl.glGenerateMipmap(gl.GL_TEXTURE_2D_ARRAY);
    gl.glBindTexture(gl.GL_TEXTURE_2D_ARRAY, 0);

    return .{
        .program = program,
        .vao = vao,
        .vbo = vbo,
        .ebo = ebo,
        .screenWidth = screenWidth,
        .screenHeight = screenHeight,
        .scoreTexture = texture,
        .texProgram = texProgram,
    };
}

pub fn destroy(self: *Self) void {
    sdl.TTF_Quit();
    gl.glDeleteProgram(self.program);
    gl.glDeleteProgram(self.texProgram);
    gl.glDeleteVertexArrays(1, &self.vao);
    gl.glDeleteBuffers(1, &self.vbo);
    gl.glDeleteBuffers(1, &self.ebo);
    gl.glDeleteTextures(1, &self.scoreTexture);
}

pub fn beginDraw(_: *Self) void {
}

pub fn clear(_: *Self) void {
    gl.glClearColor(0.6, 0.72, 0.06, 1);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
}

pub fn drawScore(self: *Self, score: usize) void {
    gl.glUseProgram(self.texProgram);
    gl.glBindTexture(gl.GL_TEXTURE_2D_ARRAY, self.scoreTexture);

    gl.glTexParameteri(gl.GL_TEXTURE_2D_ARRAY, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D_ARRAY, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D_ARRAY, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR);
    gl.glTexParameteri(gl.GL_TEXTURE_2D_ARRAY, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR);

    const projection = zm.orthographicRhGl(@floatFromInt(640), @floatFromInt(480), -1, 1);
    const uniformProjection = gl.glGetUniformLocation(self.texProgram, "projection");
    gl.glUniformMatrix4fv(uniformProjection, 1, gl.GL_TRUE, zm.arrNPtr(&projection));

    const uniformIndex = gl.glGetUniformLocation(self.texProgram, "index");

    var tempscore = score;
    var offset: i64 = 0;

    while (tempscore > 0 or offset == 0) {
        const digit = tempscore % 10;
        gl.glUniform1ui(uniformIndex, @intCast(digit));
        self.drawRectangle(self.texProgram, 624 - 16 * offset, 448, 16, 32);
        tempscore = tempscore / 10;
        offset = offset + 1;
    }

    gl.glBindTexture(gl.GL_TEXTURE_2D_ARRAY, 0);
    gl.glUseProgram(0);
}

pub fn drawRectangle(self: *Self, program: gl.GLuint, x: i64, y: i64, w: i64, h: i64) void {
    const transform = zm.mul(zm.scaling(@floatFromInt(w), @floatFromInt(h), 0), zm.translation(@floatFromInt(x - @divFloor(self.screenWidth, 2)), @floatFromInt(y - @divFloor(self.screenHeight, 2)), 0));

    gl.glBindVertexArray(self.vao);
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
    const uniformTransform = gl.glGetUniformLocation(program, "transform");
    gl.glUniformMatrix4fv(uniformTransform, 1, gl.GL_FALSE, zm.arrNPtr(&transform));

    gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_INT, null);
    gl.glBindVertexArray(0);
}

pub fn drawSquare(self: *Self, x: i64, y: i64) void {
    gl.glUseProgram(self.program);
    const projection = zm.orthographicRhGl(@floatFromInt(640), @floatFromInt(480), -1, 1);
    const uniformProjection = gl.glGetUniformLocation(self.program, "projection");
    // Transposition is needed because GLSL uses column-major matrices by default
    gl.glUniformMatrix4fv(uniformProjection, 1, gl.GL_TRUE, zm.arrNPtr(&projection));
    const uniformRGB = gl.glGetUniformLocation(self.program, "drawColor");
    gl.glUniform3f(uniformRGB, 0.06, 0.2, 0.06);
    self.drawRectangle(self.program, x, y, 15, 15);
}
