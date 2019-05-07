#version 410 core

in vec3 cubemapTexcoord;        // interpolated value from Rasterizer

uniform samplerCube cubeMap;    // from application

out vec4 fColor;

void main()
{
    fColor	= texture(cubeMap, cubemapTexcoord);
}
