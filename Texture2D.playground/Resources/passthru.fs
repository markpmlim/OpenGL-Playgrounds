#version 330 core

in vec2 TexCoords;
uniform sampler2D image;

out vec4 fragmentColor;

void main(void)
{
    //vec2 position = (gl_FragCoord.xy  * 2.0 -  resolution) / min(resolution.x, resolution.y);
    //vec2 position = (gl_FragCoord.xy) / resolution;
    //fragmentColor = vec4(position, 0.0, 1.0);
    fragmentColor = texture(image, TexCoords);
}
