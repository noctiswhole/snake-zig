#version 310 es

precision lowp float;
in vec2 uv;
flat in uint vIndex;

out vec4 color;
uniform lowp sampler2DArray tex;

void main() {
  highp vec4 texcolor = texture(tex, vec3(uv, vIndex));
  if (texcolor .rgb == vec3(1, 0, 1)) {
      discard;
    }
  color = vec4(texcolor.rgb, 1);

}

