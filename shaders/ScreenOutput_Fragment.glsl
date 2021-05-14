precision highp float;
precision highp int;
precision highp sampler2D;

uniform float uOneOverSampleCounter;
uniform sampler2D tPathTracedImageTexture;


void main()
{
        vec4 m[9];
        m[0] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(-1,1)), 0);
        m[1] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(0,1)), 0);
        m[2] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(1,1)), 0);

        m[3] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(-1,0)), 0);
        m[4] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(0,0)), 0);
        m[5] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(1,0)), 0);

        m[6] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(-1,-1)), 0);
        m[7] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(0,-1)), 0);
        m[8] = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy + vec2(1,-1)), 0);

        vec4 centerPixel = m[4];
        vec3 filteredPixelColor;
	float threshold = 1.0;
        int count = 1;


        // 3x3 kernel (good for half screen resolutions (pixelRatio = 0.5))
        // start with center pixel
	filteredPixelColor = m[4].rgb;

        // search left
        if (m[3].a < threshold)
        {
                filteredPixelColor += m[3].rgb;
                count++; 
        }
        // search right
        if (m[5].a < threshold)
        {
                filteredPixelColor += m[5].rgb;
                count++; 
        }
        // search above
        if (m[1].a < threshold)
        {
                filteredPixelColor += m[1].rgb;
                count++; 
        }
        // search below
        if (m[7].a < threshold)
        {
                filteredPixelColor += m[7].rgb;
                count++; 
        }

        // search upper-left
        if (m[0].a < threshold)
        {
                filteredPixelColor += m[0].rgb;
                count++; 
        }
        // search upper-right
        if (m[2].a < threshold)
        {
                filteredPixelColor += m[2].rgb;
                count++; 
        }
        // search lower-left
        if (m[6].a < threshold)
        {
                filteredPixelColor += m[6].rgb;
                count++; 
        }
        // search lower-right
        if (m[8].a < threshold)
        {
                filteredPixelColor += m[8].rgb;
                count++; 
        }

        filteredPixelColor /= float(count);

        if (uOneOverSampleCounter < 1.0)
	        filteredPixelColor = mix(filteredPixelColor, centerPixel.rgb, clamp(centerPixel.a, 0.0, 1.0));

        filteredPixelColor *= uOneOverSampleCounter;

        filteredPixelColor = ReinhardToneMapping(filteredPixelColor);
        //filteredPixelColor = OptimizedCineonToneMapping(filteredPixelColor);
        //filteredPixelColor = ACESFilmicToneMapping(filteredPixelColor);

        pc_fragColor = clamp(vec4( pow(filteredPixelColor, vec3(0.4545)), 1.0 ), 0.0, 1.0);
}



        /* // 5x5 kernel (good for full screen resolutions (pixelRatio = 1))
        vec4 m[25];

        // startwith center pixel
        filteredPixelColor = m[12].rgb;
        // search left
        if (m[11].a < threshold)
        {
                filteredPixelColor += m[11].rgb;
                count++; 
                if (m[10].a < threshold)
                {
                        filteredPixelColor += m[10].rgb;
                        count++; 
                }
                if (m[5].a < threshold)
                {
                        filteredPixelColor += m[5].rgb;
                        count++; 
                }
        }
        // search right
        if (m[13].a < threshold)
        {
                filteredPixelColor += m[13].rgb;
                count++; 
                if (m[14].a < threshold)
                {
                        filteredPixelColor += m[14].rgb;
                        count++; 
                }
                if (m[19].a < threshold)
                {
                        filteredPixelColor += m[19].rgb;
                        count++; 
                }
        }
        // search above
        if (m[7].a < threshold)
        {
                filteredPixelColor += m[7].rgb;
                count++; 
                if (m[2].a < threshold)
                {
                        filteredPixelColor += m[2].rgb;
                        count++; 
                }
                if (m[3].a < threshold)
                {
                        filteredPixelColor += m[3].rgb;
                        count++; 
                }
        }
        // search below
        if (m[17].a < threshold)
        {
                filteredPixelColor += m[17].rgb;
                count++; 
                if (m[22].a < threshold)
                {
                        filteredPixelColor += m[22].rgb;
                        count++; 
                }
                if (m[21].a < threshold)
                {
                        filteredPixelColor += m[21].rgb;
                        count++; 
                }
        }

        // search upper-left
        if (m[6].a < threshold)
        {
                filteredPixelColor += m[6].rgb;
                count++; 
                if (m[0].a < threshold)
                {
                        filteredPixelColor += m[0].rgb;
                        count++; 
                }
                if (m[1].a < threshold)
                {
                        filteredPixelColor += m[1].rgb;
                        count++; 
                }
        }
        // search upper-right
        if (m[8].a < threshold)
        {
                filteredPixelColor += m[8].rgb;
                count++; 
                if (m[4].a < threshold)
                {
                        filteredPixelColor += m[4].rgb;
                        count++; 
                }
                if (m[9].a < threshold)
                {
                        filteredPixelColor += m[9].rgb;
                        count++; 
                }
        }
        // search lower-left
        if (m[16].a < threshold)
        {
                filteredPixelColor += m[16].rgb;
                count++; 
                if (m[15].a < threshold)
                {
                        filteredPixelColor += m[15].rgb;
                        count++; 
                }
                if (m[20].a < threshold)
                {
                        filteredPixelColor += m[20].rgb;
                        count++; 
                }
        }
        // search lower-right
        if (m[18].a < threshold)
        {
                filteredPixelColor += m[18].rgb;
                count++; 
                if (m[23].a < threshold)
                {
                        filteredPixelColor += m[23].rgb;
                        count++; 
                }
                if (m[24].a < threshold)
                {
                        filteredPixelColor += m[24].rgb;
                        count++; 
                }
        }
        filteredPixelColor /= float(count); */
