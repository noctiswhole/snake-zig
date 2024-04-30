#version 310 es

precision lowp float;
in vec2 uv;
flat in uint vIndex;

out vec4 color;
uniform lowp sampler2DArray tex;

void main() {
  color = texture(tex, vec3(uv, vIndex));

}

