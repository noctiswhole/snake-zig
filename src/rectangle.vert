#version 310 es

precision lowp float;
in vec2 vertexPosition;
in vec2 vertexUV;
uniform vec2 position;
uniform mat4 projection;
uniform vec3 drawColor;

out vec2 uv;
out vec3 ourColor;

void main() {
  gl_Position = projection * vec4(vertexPosition + position - vec2(320, 240), 0.0, 1.0);
  uv = vertexUV;
  ourColor = drawColor;
}

