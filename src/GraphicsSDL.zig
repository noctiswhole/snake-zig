const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const gl = @import("gl");
const std = @import("std");
const Vertex = @import("Vertex.zig");

const Self = @This();

const vertices = [_]Vertex{
    Vertex{
        // top left
        .x = 0,
        .y = 0,
        .u = 0,
        .v = 0,
    },
    Vertex{
        // top right 
        .x = 1,
        .y = 0,
        .u = 1,
        .v = 0,
    },
    Vertex{
        // bot left
        .x = 0,
        .y = 1,
        .u = 0,
        .v = 1,
    },
    Vertex{ 
        // bot right
        .x = 1,
        .y = 1,
        .u = 1,
        .v = 1,
    },
};

const indices = [6]c_uint{
    // first triangle
    0, 1, 3, 
    // second triangle
    0, 2, 3, 
};

program: gl.GLuint,
vbo: gl.GLuint,
vao: gl.GLuint,
ebo: gl.GLuint,

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

        std.log.info("failed to compile shader:\n{any}", .{info_log});

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

pub fn create(context: sdl.SDL_GLContext, allocator: std.mem.Allocator) Self {
    gl.load(context, getProcAddress) catch {
        @panic("Could not load GL context");
    };
    const program = compileShader(allocator, @embedFile("rectangle.vert"), @embedFile("rectangle.frag")) catch {
        @panic("Could not compile shaders");
    };

    var vao: gl.GLuint = undefined;
    var vbo: gl.GLuint = undefined;
    var ebo: gl.GLuint = undefined;

    // Initialize buffers
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


    return .{
        .program = program,
        .vao = vao,
        .vbo = vbo,
        .ebo = ebo,
    };
}

pub fn destroy(self: *Self) void {
    gl.deleteProgram(self.program);
    gl.deleteVertexArrays(1, &self.vao);
    gl.deleteBuffers(1, &self.vbo);
    gl.deleteBuffers(1, &self.ebo);
}

pub fn beginDraw(self: *Self) void {
    gl.useProgram(self.program);
}

pub fn testDraw(self: *Self) void {
    gl.bindVertexArray(self.vao);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
    gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);
    gl.bindVertexArray(0);
}
