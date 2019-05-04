#version 330 core
// per-vertex lighting
layout( location = 0 ) in vec3 vertexPosition;
layout( location = 1 ) in vec3 vertexNormal;
layout( location = 2 ) in vec2 vertexTexCoords;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

out vec4  color;

void main()
{
    // Use normal as the color attribute.
    color = vec4(abs(vertexNormal), 1.0);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
