#version 330 core
// per-vertex lighting
layout( location = 0 ) in vec3 vertexPosition;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

out vec3 cubemapTexcoord;       // to fragment shader

void main()
{
    cubemapTexcoord = vertexPosition;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
