#version 330 core
// per-vertex lighting
layout( location = 0 ) in vec3 vertexPosition;
layout( location = 1 ) in vec4 vertexColor;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

out vec4  color;

void main()
{
    // Pass the color attribute to the fragment shader
    color = vertexColor;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
}
