#version 330

in vec4 position;
in vec3 normal;

out lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

void main()
{
	vec3 eyeNormal = normalize(normalMatrix * normal);
	vec3 lightPosition = vec3(0.0, 0.0, 1.0);
	vec4 diffuseColor = vec4(0.4, 0.4, 1.0, 1.0);

	//  view/eye space
	float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));

	colorVarying = diffuseColor * nDotVP;

	gl_Position = modelViewProjectionMatrix * position;
}

