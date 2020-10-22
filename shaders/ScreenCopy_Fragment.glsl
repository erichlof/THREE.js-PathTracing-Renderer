precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D tPathTracedImageTexture;

void main()
{	
	pc_fragColor = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy), 0);	
} 
