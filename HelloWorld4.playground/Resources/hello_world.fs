#version 410 core

uniform vec2 resolution;    // dimensions of view port

out vec4 fragmentColor;

void main(void)
{
    vec2 position = (gl_FragCoord.xy) / resolution;
    fragmentColor = vec4(position, 0.0, 1.0);
}
