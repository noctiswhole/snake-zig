#version 310 es

precision lowp float;
in vec2 vertexPosition;
in vec2 vertexUV;
uniform vec2 position;
uniform mat4 projection;
uniform vec3 hello;

out vec2 uv;
out vec3 ourColor;

void main() {
  gl_Position = projection * vec4(vertexPosition + position, 0.0, 1.0);
  uv = vertexUV;
  ourColor = hello;
}

