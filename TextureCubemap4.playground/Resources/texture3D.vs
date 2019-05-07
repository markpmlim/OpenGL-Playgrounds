#version 410 core
// per-vertex lighting
layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec3 vertexNormal;  // unused

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

out vec3 cubemapTexcoord;

// Must be re-declared if separate shader programs are used.
out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    cubemapTexcoord = vertexPosition;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
