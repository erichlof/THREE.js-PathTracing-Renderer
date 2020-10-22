precision highp float;
precision highp int;
precision highp sampler2D;

uniform float uOneOverSampleCounter;
uniform sampler2D tPathTracedImageTexture;

void main()
{
        vec3 pixelColor = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy), 0).rgb * uOneOverSampleCounter;
        pixelColor = ReinhardToneMapping(pixelColor);
        //pixelColor = Uncharted2ToneMapping(pixelColor);
        //pixelColor = OptimizedCineonToneMapping(pixelColor);
        //pixelColor = ACESFilmicToneMapping(pixelColor);
        pc_fragColor = clamp(vec4( pow(pixelColor, vec3(0.4545)), 1.0 ), 0.0, 1.0);
}