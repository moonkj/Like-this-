package com.likethis.likethis.camera

/// B&W 렌더링 OpenGL ES 2.0 셰이더
object MFBWShader {

    val VERTEX_SHADER = """
        attribute vec4 aPosition;
        attribute vec2 aTexCoord;
        varying vec2 vTexCoord;
        void main() {
            gl_Position = aPosition;
            vTexCoord = aTexCoord;
        }
    """.trimIndent()

    /// B&W 채널 믹서 + Grain + Vignette 통합 Fragment Shader
    val FRAGMENT_SHADER = """
        precision mediump float;
        uniform sampler2D uTexture;
        varying vec2 vTexCoord;

        uniform float uGrain;           // 0.0 ~ 1.0
        uniform float uContrast;        // -1.0 ~ 1.0
        uniform float uExposure;        // -1.0 ~ 1.0
        uniform float uVignette;        // 0.0 ~ 1.0
        uniform float uLightLeak;       // 0.0 ~ 1.0
        uniform float uTime;            // 노이즈 시드용
        uniform float uLUTIntensity;    // 0.0 ~ 1.0 (필터 강도)

        // 의사 난수 생성 (Grain용)
        float rand(vec2 co) {
            return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main() {
            vec4 color = texture2D(uTexture, vTexCoord);

            // 1. B&W 변환: 채널 믹서 (Luminance 가중치)
            float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));

            // 2. Exposure 보정
            lum = lum + uExposure * 0.5;

            // 3. Contrast 조절 (S-curve 근사)
            lum = 0.5 + (lum - 0.5) * (1.0 + uContrast * 0.8);

            // 4. Grain (강도를 lutIntensity로 스케일)
            float noise = rand(vTexCoord + vec2(uTime, uTime)) - 0.5;
            lum = lum + noise * uGrain * uLUTIntensity * 0.15;

            // 5. Vignette (강도를 lutIntensity로 스케일)
            vec2 center = vTexCoord - vec2(0.5);
            float dist = length(center);
            float vignetteMask = 1.0 - smoothstep(0.4, 0.9, dist) * uVignette * uLUTIntensity * 1.5;
            lum = lum * vignetteMask;

            // 6. 컬러 → B&W 블렌드: 0%=원본 컬러, ~50%=완전 B&W
            float bwMix = clamp(uLUTIntensity * 2.0, 0.0, 1.0);
            vec3 result = mix(color.rgb, vec3(lum), bwMix);

            // 7. Light Leak (강도를 lutIntensity로 스케일)
            if (uLightLeak > 0.001) {
                float leakDist = length(vTexCoord - vec2(0.0, 1.0));
                float leak = max(0.0, 1.0 - leakDist / 0.8) * uLightLeak * uLUTIntensity * 0.5;
                result = min(vec3(1.0), result + leak);
            }

            result = clamp(result, 0.0, 1.0);
            gl_FragColor = vec4(result, color.a);
        }
    """.trimIndent()

    /// LUT 적용 Fragment Shader (별도 패스)
    val LUT_FRAGMENT_SHADER = """
        precision mediump float;
        uniform sampler2D uTexture;
        uniform sampler2D uLUTTexture;
        uniform float uLUTIntensity;
        uniform float uLUTSize;
        varying vec2 vTexCoord;

        vec3 applyLUT(vec3 color) {
            float blueIdx = color.b * (uLUTSize - 1.0);
            float blueFloor = floor(blueIdx);
            float blueFrac = blueIdx - blueFloor;

            float xOffset = 1.0 / uLUTSize;
            float yOffset = 1.0 / uLUTSize;

            // Trilinear interpolation (단순화: bilinear)
            vec2 uv1 = vec2(
                (color.r + blueFloor * uLUTSize) / (uLUTSize * uLUTSize),
                color.g
            );
            vec2 uv2 = vec2(
                (color.r + (blueFloor + 1.0) * uLUTSize) / (uLUTSize * uLUTSize),
                color.g
            );

            vec3 sample1 = texture2D(uLUTTexture, uv1).rgb;
            vec3 sample2 = texture2D(uLUTTexture, uv2).rgb;
            return mix(sample1, sample2, blueFrac);
        }

        void main() {
            vec4 color = texture2D(uTexture, vTexCoord);
            float lum = color.r;
            vec3 bwColor = vec3(lum);

            vec3 lutColor = applyLUT(bwColor);
            // 메인 셰이더 출력(color.rgb)을 기준으로 블렌드 → 0%=패스스루, 100%=LUT 톤 적용
            vec3 result = mix(color.rgb, lutColor, uLUTIntensity);

            gl_FragColor = vec4(result, color.a);
        }
    """.trimIndent()
}
