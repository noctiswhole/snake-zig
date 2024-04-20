#version 310 es

precision lowp float;
in vec2 vertexPosition;
in vec2 vertexUV;

out vec2 uv;

void main() {
  gl_Position = vec4(vertexPosition, 0.0, 1.0);
  uv = vertexUV;
}

