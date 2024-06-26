const sdl = @import("Window.zig").sdl;
const gl = @import("gl");
const std = @import("std");
const math = std.math;
const Vertex = @import("Vertex.zig");
const zm = @import("zmath");
const Self = @This();
const gridSize = @import("Snake.zig").gridSize;

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
    const vertex_shader = try compilerShaderPart(allocator, gl.VERTEX_SHADER, vertex_source);
    defer gl.deleteShader(vertex_shader);

    const fragment_shader = try compilerShaderPart(allocator, gl.FRAGMENT_SHADER, fragment_source);
    defer gl.deleteShader(fragment_shader);

    const program = gl.createProgram();
    if (program == 0)
        return error.OpenGlFailure;
    errdefer gl.deleteProgram(program);

    gl.attachShader(program, vertex_shader);
    defer gl.detachShader(program, vertex_shader);

    gl.attachShader(program, fragment_shader);
    defer gl.detachShader(program, fragment_shader);

    gl.linkProgram(program);

    var link_status: gl.GLint = undefined;
    gl.getProgramiv(program, gl.LINK_STATUS, &link_status);

    if (link_status != gl.TRUE) {
        var info_log_length: gl.GLint = undefined;
        gl.getProgramiv(program, gl.INFO_LOG_LENGTH, &info_log_length);

        const info_log = try allocator.alloc(u8, @intCast(info_log_length));
        defer allocator.free(info_log);

        gl.getProgramInfoLog(program, @intCast(info_log.len), null, info_log.ptr);

        std.log.info("failed to compile shader:\n{s}", .{info_log});

        return error.InvalidShader;
    }

    return program;
}

fn compilerShaderPart(allocator: std.mem.Allocator, shader_type: gl.GLenum, source: [:0]const u8) !gl.GLuint {
    const shader = gl.createShader(shader_type);
    if (shader == 0)
        return error.OpenGlFailure;
    errdefer gl.deleteShader(shader);

    var sources = [_][*c]const u8{source.ptr};
    var lengths = [_]gl.GLint{@intCast(source.len)};

    gl.shaderSource(shader, 1, &sources, &lengths);

    gl.compileShader(shader);

    var compile_status: gl.GLint = undefined;
    gl.getShaderiv(shader, gl.COMPILE_STATUS, &compile_status);

    if (compile_status != gl.TRUE) {
        var info_log_length: gl.GLint = undefined;
        gl.getShaderiv(shader, gl.INFO_LOG_LENGTH, &info_log_length);

        const info_log = try allocator.alloc(u8, @intCast(info_log_length));
        defer allocator.free(info_log);

        gl.getShaderInfoLog(shader, @intCast(info_log.len), null, info_log.ptr);

        std.log.info("failed to compile shader:\n{s}", .{info_log});

        return error.InvalidShader;
    }

    return shader;
}

pub fn create(context: sdl.SDL_GLContext, allocator: std.mem.Allocator, screenWidth: u32, screenHeight: u32) Self {

    gl.load(context, getProcAddress) catch {
        @panic("Could not load GL context");
    };
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

    gl.genVertexArrays(1, &vao);
    if (vao == 0) {
        @panic("Could not generate vertex array");
    }

    gl.genBuffers(1, &vbo);
    if (vbo == 0) {
        @panic("Could not generate vertex buffer");
    }

    gl.genBuffers(1, &ebo);
    if (ebo == 0) {
        @panic("Could not generate ebo buffer");
    }

    // Bind buffers
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, 6 * @sizeOf(c_uint), &indices, gl.STATIC_DRAW);

    // bind data
    // position
    gl.enableVertexAttribArray(0); 
    gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "x")));

    // uv
    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "u")));

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

    // gl.enable(gl.CULL_FACE);
    gl.enable(gl.BLEND);

    var texture: gl.GLuint = undefined;
    gl.genTextures(1, &texture);

    // gl.bindTexture(gl.TEXTURE_2D_ARRAY, texture);
    gl.bindTexture(gl.TEXTURE_2D_ARRAY, texture);
    // gl.texImage3D(gl.TEXTURE_2D_ARRAY, 0, gl.RGBA, fontSurface.*.w, fontSurface.*.h, 16, 0, mode, gl.UNSIGNED_BYTE, fontSurface.*.pixels);
    gl.texImage3D(gl.TEXTURE_2D_ARRAY, 0, gl.RGBA, 16, 32, 10, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    // gl.texStorage3D(gl.TEXTURE_2D_ARRAY, 1, gl.UNSIGNED_BYTE, 16, 32, 1);

    var buf: [6]u8 = undefined;
    for (0..10) |i| {
        const numAsString = std.fmt.bufPrint(&buf, "{d}.png\x00", .{i}) catch {
            @panic("Failed to format string.");
        };
        const fontSurface = sdl.IMG_Load(numAsString.ptr) orelse {
            @panic("Missing texture");
        };
        defer sdl.SDL_FreeSurface(fontSurface);
        gl.texSubImage3D(gl.TEXTURE_2D_ARRAY, 0, 0, 0, @intCast(i), 16, 32, 1, gl.RGBA, gl.UNSIGNED_BYTE, fontSurface.*.pixels);
    }
    // gl.texImage2D(gl.TEXTURE_2D, 0, @intCast(mode), fontSurface.*.w, fontSurface.*.h, 0, mode, gl.UNSIGNED_BYTE, fontSurface.*.pixels);
    gl.generateMipmap(gl.TEXTURE_2D_ARRAY);

    gl.bindTexture(gl.TEXTURE_2D_ARRAY, 0);


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
    gl.deleteProgram(self.program);
    gl.deleteProgram(self.texProgram);
    gl.deleteVertexArrays(1, &self.vao);
    gl.deleteBuffers(1, &self.vbo);
    gl.deleteBuffers(1, &self.ebo);
    gl.deleteTextures(1, &self.scoreTexture);
}

pub fn beginDraw(_: *Self) void {
}

pub fn clear(_: *Self) void {
    gl.clearColor(0.6, 0.72, 0.06, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);
}

pub fn drawScore(self: *Self, score: usize) void {
    gl.useProgram(self.texProgram);
    gl.bindTexture(gl.TEXTURE_2D_ARRAY, self.scoreTexture);

    gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    const projection = zm.orthographicRhGl(@floatFromInt(640), @floatFromInt(480), -1, 1);
    const uniformProjection = gl.getUniformLocation(self.texProgram, "projection");
    gl.uniformMatrix4fv(uniformProjection, 1, gl.TRUE, zm.arrNPtr(&projection));

    const uniformIndex = gl.getUniformLocation(self.texProgram, "index");

    var tempscore = score;
    var offset: i64 = 0;

    while (tempscore > 0 or offset == 0) {
        const digit = tempscore % 10;
        gl.uniform1ui(uniformIndex, @intCast(digit));
        self.drawRectangle(self.texProgram, 624 - 16 * offset, 448, 16, 32);
        tempscore = tempscore / 10;
        offset = offset + 1;
    }

    gl.bindTexture(gl.TEXTURE_2D_ARRAY, 0);
    gl.useProgram(0);
}

pub fn drawRectangle(self: *Self, program: gl.GLuint, x: i64, y: i64, w: i64, h: i64) void {
    const transform = zm.mul(zm.scaling(@floatFromInt(w), @floatFromInt(h), 0), zm.translation(@floatFromInt(x - @divFloor(self.screenWidth, 2)), @floatFromInt(y - @divFloor(self.screenHeight, 2)), 0));

    gl.bindVertexArray(self.vao);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
    const uniformTransform = gl.getUniformLocation(program, "transform");
    gl.uniformMatrix4fv(uniformTransform, 1, gl.FALSE, zm.arrNPtr(&transform));

    gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);
    gl.bindVertexArray(0);
}

pub fn drawSquare(self: *Self, x: i64, y: i64) void {
    gl.useProgram(self.program);
    const projection = zm.orthographicRhGl(@floatFromInt(640), @floatFromInt(480), -1, 1);
    const uniformProjection = gl.getUniformLocation(self.program, "projection");
    // Transposition is needed because GLSL uses column-major matrices by default
    gl.uniformMatrix4fv(uniformProjection, 1, gl.TRUE, zm.arrNPtr(&projection));
    const uniformRGB = gl.getUniformLocation(self.program, "drawColor");
    gl.uniform3f(uniformRGB, 0.06, 0.2, 0.06);
    self.drawRectangle(self.program, x, y, 15, 15);
}
