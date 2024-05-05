#version 300 es

precision lowp float;
in vec2 vertexPosition;
in vec2 vertexUV;
uniform mat4 transform;
uniform mat4 projection;
uniform uint index;

flat out uint vIndex;
out vec2 uv;

void main() {
  gl_Position = projection * transform * vec4(vertexPosition, 0.0, 1.0);
  uv = vertexUV;
  vIndex = index;
}

