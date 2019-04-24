#version 330 core

in vec3 cubemapTexcoord;        // interpolated value

uniform samplerCube cubeMap;    // from application

out vec4 fColor;

void main()
{
    fColor	= texture(cubeMap, cubemapTexcoord);
}
