#version 330

in lowp vec4 colorVarying;
out lowp vec4 fragmentColor;

void main()
{
	fragmentColor = colorVarying;
}

