#version 330 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 texcoord0;

out vec2 v_uv;                  // unused?

void main(void) {
    gl_Position = position; 	// clip space
    v_uv = texcoord0;
}
