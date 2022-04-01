/*
    Description : 'NATIVENHANCER' Film Emulation for Reshade https://reshade.me/
    Author      : dddfault
    License     : MIT, Copyright © 2022 dddfault
                  MIT, Copyright © 2022 prod80

    Additional credits
    - prod80 for functions that used on this shader.
    (https://github.com/prod80/prod80-ReShade-Repository)

    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Human Readable License Summary
    You are allowed to :
    - Use, copy, modify, merge, publish, distribute, sublicense, and/or
    commercial use.

    Under the conditions :
    - The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
*/

#define KATEGORISASI
#define DMAKRO_VERSION_REQUIREMENT    1023
#define RESHADE_VERSION_REQUIREMENT   40901

#include "ReShade.fxh"
#include "dMakro.fxh"
#include "NativeEnhancer/userinterface.fxh"
#include "NativeEnhancer/miscellaneous.fxh"
#include "NativeEnhancer/blendingmode.fxh"

namespace dft_nefilm
{
    //// PREPROCESSOR DEFINITIONS ////////////////////////////////////////////////
    // Simulate glowy edges on high contrast area.
    #ifndef FILMFX_1_HALATION
        #define FILMFX_1_HALATION          0
    #endif

    // Simulate hazy foggy light diffusion on screen.
    #ifndef FILMFX_2_DIFFUSION
        #define FILMFX_2_DIFFUSION         0
    #endif

    // Multi layered Lens Diffusion (FilmFX Diffusion must be enabled)
    #ifndef FILMFX_2_HQ_DIFFUSION
        #define FILMFX_2_HQ_DIFFUSION      0
    #endif

    // Simulate film jittery-inconsistent of exposure and color effect.
    #ifndef FILMFX_3_BREATH
        #define FILMFX_3_BREATH            0
    #endif

    // Simulate film frame jitter.
    #ifndef FILMFX_4_GATE_WEAVE
        #define FILMFX_4_GATE_WEAVE        0
    #endif

    // Simulate film grain.
    #ifndef FILMFX_5_FILM_GRAIN
        #define FILMFX_5_FILM_GRAIN        0
    #endif

    //// USER INTERFACE PARAMETERS /////////////////////////////////////////////

    //// TEXTURES //////////////////////////////////////////////////////////////
    texture texHalationA  {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};
    texture texHalationB  {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};
    texture texDiffusionA {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};
    texture texDiffusionB {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};
    texture neFilmTexture < source = "neFilmLUT.png"; > {Width  = 64 * 64; Height = 64 * filmLUTAmount;};

    //// SAMPLERS //////////////////////////////////////////////////////////////
    sampler	filmLUTBuffer    {Texture = neFilmTexture;};
    sampler	halationBufferA  {Texture = texHalationA;};
    sampler	halationBufferB  {Texture = texHalationB;};
    sampler	diffusionBufferA {Texture = texDiffusionA;};
    sampler	diffusionBufferB {Texture = texDiffusionB;};

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float4 rnm(float2 tc)
    {
        float seed;

        #if(FILMFX_5_FILM_GRAIN)
          seed = filmGrainSeed;
        #else
          seed = 1.0f;
        #endif

        // A random texture generator, but you can also use a pre-computed perturbation texture
        float noise = sin(dot(tc, float2(12.9898, 78.233))) * 43758.5453;

        float noiseR = frac(noise * seed) * 2.0 - 1.0;
        float noiseG = frac(noise * 1.2154 * seed) * 2.0 - 1.0;
        float noiseB = frac(noise * 1.3453 * seed) * 2.0 - 1.0;
        float noiseA = frac(noise * 1.3647 * seed) * 2.0 - 1.0;

        return float4(noiseR, noiseG, noiseB, noiseA);
    }

    float pnoise3D(float3 p)
    {
        // Perm texture texel-size
        static const float permTexUnit = 1.0 / 256.0;
        // Half perm texture texel-size
        static const float permTexUnitHalf = 0.5 / 256.0;

        // Integer part
        // Scaled so +1 moves permTexUnit texel and offset 1/2 texel to sample texel centers
        float3 pi = permTexUnit * floor(p) + permTexUnitHalf;
        // Fractional part for interpolation
        float3 pf = frac(p);

        // Noise contributions from (x=0, y=0), z=0 and z=1
        float perm00 = rnm(pi.xy).a;
        float3 grad000 = rnm(float2(perm00, pi.z)).rgb * 4.0 - 1.0;
        float n000 = dot(grad000, pf);
        float3 grad001 = rnm(float2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
        float n001 = dot(grad001, pf - float3(0.0, 0.0, 1.0));

        // Noise contributions from (x=0, y=1), z=0 and z=1
        float perm01 = rnm(pi.xy + float2(0.0, permTexUnit)).a;
        float3 grad010 = rnm(float2(perm01, pi.z)).rgb * 4.0 - 1.0;
        float n010 = dot(grad010, pf - float3(0.0, 1.0, 0.0));
        float3 grad011 = rnm(float2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
        float n011 = dot(grad011, pf - float3(0.0, 1.0, 1.0));

        // Noise contributions from (x=1, y=0), z=0 and z=1
        float perm10 = rnm(pi.xy + float2(permTexUnit, 0.0)).a;
        float3 grad100 = rnm(float2(perm10, pi.z)).rgb * 4.0 - 1.0;
        float n100 = dot(grad100, pf - float3(1.0, 0.0, 0.0));
        float3 grad101 = rnm(float2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
        float n101 = dot(grad101, pf - float3(1.0, 0.0, 1.0));

        // Noise contributions from (x=1, y=1), z=0 and z=1
        float perm11 = rnm(pi.xy + float2(permTexUnit, permTexUnit)).a;
        float3 grad110 = rnm(float2(perm11, pi.z)).rgb * 4.0 - 1.0;
        float n110 = dot(grad110, pf - float3(1.0, 1.0, 0.0));
        float3 grad111 = rnm(float2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
        float n111 = dot(grad111, pf - float3(1.0, 1.0, 1.0));

        // Blend contributions along x
        float fade_x = pf.x * pf.x * pf.x * (pf.x * (pf.x * 6.0 - 15.0) + 10.0);
        float4 n_x = lerp(float4(n000, n001, n010, n011), float4(n100, n101, n110, n111), fade_x);

        // Blend contributions along y
        float fade_y = pf.y * pf.y * pf.y * (pf.y * (pf.y * 6.0 - 15.0) + 10.0);
        float2 n_xy = lerp(n_x.xy, n_x.zw, fade_y);

        // Blend contributions along z
        float fade_z = pf.z * pf.z * pf.z * (pf.z * (pf.z * 6.0 - 15.0) + 10.0);
        float n_xyz = lerp(n_xy.x, n_xy.y, fade_z);

        // We're done, return the final noise value.
        return n_xyz;
    }

    //// PIXEL SHADERS /////////////////////////////////////////////////////////
    void PS_colorStore(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 halation : SV_Target0, out float4 diffusion : SV_Target1)
    {
        halation.rgb  = dot(tex2D(ReShade::BackBuffer, texcoord.xy).rgb, lumaCoeff);
        halation.a = 1.0f;
        diffusion = tex2D(ReShade::BackBuffer, texcoord.xy);
    }

    void PS_PreGrading(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float3 kColor, oLum, blended, resHSV, resRGB, invColor;
        color        = tex2D(ReShade::BackBuffer, texcoord.xy);

        if (flatColor == true)
        {
          invColor   = 1 - color.rgb;
          color.rgb  = blendingmode(invColor.rgb, color.rgb, 11, 1.0);
        }

        // Color temperature by prod80
        kColor       = KelvinToRGB(kelvinTemp);
        oLum         = RGBToHSL(color.rgb);
        blended      = lerp(color.rgb, color.rgb * kColor.rgb, kelvinMix);
        resHSV       = RGBToHSL(blended.rgb); //TODO: add saturation limiter after this line
        resRGB       = HSLToRGB(float3(resHSV.xy, oLum.z));
        color.rgb    = lerp(blended.rgb, resRGB.rgb, lumaPresevation);

        // Color saturation limiter by prod80
        color.rgb    = RGBToHSL(color.rgb);
        color.g      = min(color.g, filmSatLimit); //TODO: possible to combine this function on color temperature ?
        color.rgb    = HSLToRGB(color.rgb);

        // Pre Color Correction
        color.rgb    = exp2(filmExposure * saturate(color.rgb)) * color.rgb;
        color.rgb   *= filmBrightness;
        color.rgb    = pow(abs(color.rgb), 1.0 / filmGamma);
        color.rgb	   = 0.5 + (saturate(color.rgb) - 0.5) * filmContrast;
        color.rgb    = saturation(saturate(color.rgb), filmSaturation);
        color.a      = 1.0f;
    }

    void PS_FilmEmulation(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float  lerpfact, newluma;
        float2 texelsize, newAB;
        float3 lutcoord, lutcolor, lablut, labcol;

        color        = tex2D(ReShade::BackBuffer, texcoord.xy);

        texelsize    = rcp(64);
        texelsize.x /= 64;

        lutcoord     = float3((color.rg * 64 - color.rg + 0.5) * texelsize.xy, color.b * 64 - color.b);
        lutcoord.y  /= filmLUTAmount;
        lutcoord.y  += (float(filmLUTSelector) / filmLUTAmount);

        lerpfact     = frac(lutcoord.z);
        lutcoord.x  += (lutcoord.z - lerpfact) * texelsize.y;
        lutcolor     = lerp(tex2D(filmLUTBuffer, lutcoord.xy).rgb, tex2D(filmLUTBuffer, float2(lutcoord.x + texelsize.y, lutcoord.y)).rgb, lerpfact);

        lutcolor.rgb = levels(lutcolor.rgb, saturate(inBlack.rgb), saturate(inWhite.rgb),
                       inGamma,
                       saturate(outBlack.rgb), saturate(outWhite.rgb));

        lablut       = pd80_srgb_to_lab(lutcolor.rgb);
        labcol       = pd80_srgb_to_lab(color.rgb);
        newluma      = lerp(labcol.x, lablut.x, filmLUTMixLuma);
        newAB        = lerp(labcol.yz, lablut.yz, filmLUTMixChroma);
        lutcolor.rgb = pd80_lab_to_srgb(float3(newluma, newAB));
        color.rgb    = lerp(color.rgb, saturate(lutcolor.rgb), filmLUTIntensity);
        color.a      = 1.0;
    }

    #if(FILMFX_1_HALATION)
    void PS_FilmFX_Halation1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 halation : SV_Target0)
    {
        float2 edgeUV;

        edgeUV       = float2(halationEdgeWidth / ReShade::ScreenSize.x, halationEdgeWidth / ReShade::ScreenSize.y);
        halation.rgb = sobelFilter(halationBufferA, edgeUV.x, edgeUV.y, texcoord.xy, halationEdgeDetail, halationEdgeIntensity);
        halation.a   = 1.0f;
    }

    void PS_FilmFX_Halation2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float4 halation;

        color        = tex2D(ReShade::BackBuffer, texcoord.xy);
        halation     = fastGaussBlur(halationBufferB, texcoord.xy, halationBlurWidth, 4.0, 16.0);
        halation.rgb = (halation.rgb < 0.5 ? (2.0 * halation.rgb * halationTint) : (1.0 - 2.0 * (1.0 - halation.rgb) * (1.0 - halationTint))) * halationIntensity;

        switch(halationDebug)
        {
          case 0: // Default
            {color.rgb = saturate(lerp(color.rgb, max(color.rgb, halation.rgb), halationOpacity));} break;
          case 1: // Edge detection
            {color.rgb = tex2D(halationBufferB, texcoord.xy).rgb;} break;
          case 2: // Halation Blending
            {color.rgb = halation.rgb;} break;
        }

        color.a      = 1.0f;
    }
    #endif

    #if(FILMFX_2_DIFFUSION)
    void PS_FilmFX_Diffusion1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float4 diffusion;

        color        = tex2D(ReShade::BackBuffer, texcoord.xy);
        diffusion    = gaussBlur(texcoord.xy, diffusionBufferA, diffusionBlurWidth, 0, 1);
        color.rgb    = diffusion.rgb;
        color.a      = 1.0f;
    }

    #if(FILMFX_2_HQ_DIFFUSION)
    void PS_FilmFX_DiffusionHQ1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float4 diffusion;
        diffusion    = gaussBlur(texcoord.xy, diffusionBufferB, diffusionBlurWidth, 0, 0);
        color.rgb    = diffusion.rgb;
        color.a      = 1.0f;
    }

    void PS_FilmFX_DiffusionHQ2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float4 diffusion;
        diffusion    = gaussBlur(texcoord.xy, diffusionBufferA, diffusionBlurWidthHQ, 0, 1);
        color.rgb    = diffusion.rgb;
        color.a      = 1.0f;
    }
    #endif

    void PS_FilmFX_Diffusion2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float blur;
        float4 diffusion;

        #if(FILMFX_3_HQ_DIFFUSION)
        blur         = diffusionBlurWidthHQ;
        #else
        blur         = diffusionBlurWidth;
        #endif

        color        = tex2D(ReShade::BackBuffer, texcoord.xy);
        diffusion    = gaussBlur(texcoord.xy, diffusionBufferB, blur, 0, 0);

        switch(diffusionBlendMode)
        {
          case 0: // Lighten
            {color.rgb   = saturate(lerp(color.rgb, max(color.rgb, diffusion.rgb), diffusionOpacity));} break;
          case 1: // Screen
            {color.rgb   = saturate(lerp(color.rgb, (1.0 - ((1.0 - color.rgb) * (1.0 - diffusion.rgb))), diffusionOpacity));} break;
          case 2: // Debug
            {color.rgb   = diffusion.rgb;} break;
        }
        color.a      = 1.0f;
    }
    #endif

    #if(FILMFX_3_BREATH)
    void PS_FilmFX_Breath(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float4 breath;
        float  randSeed;

        breath       = tex2D(ReShade::BackBuffer, texcoord.xy);
        randSeed     = framerateSeed(filmBreathFramerate);

        breath.rgb   *= lerp(filmBreathBrightness.x, filmBreathBrightness.y, simpleNoiseGen(randSeed));
        breath.rgb    = pow(abs(breath.rgb), 1.0 / lerp(filmBreathMidtone.x, filmBreathMidtone.y, simpleNoiseGen(randSeed)));
        breath.rgb    = saturation(saturate(breath.rgb), lerp(filmBreathSaturation.x, filmBreathSaturation.y, simpleNoiseGen(randSeed)));

        color.rgb     = breath.rgb;
        color.a       = 1.0f;
    }
    #endif

    #if(FILMFX_4_GATE_WEAVE)
    void PS_FilmFX_GateWeave(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float2 wCoord;
        float  randSeed;

        randSeed      = framerateSeed(filmGateWeaveFramerate);

        wCoord.xy     = texcoord.xy;
        wCoord.xy     = float2(wCoord.x + lerp(0, filmGateWeaveOffset.x/100, simpleNoiseGen(randSeed)), wCoord.y - lerp(0, filmGateWeaveOffset.y/100, simpleNoiseGen(randSeed)));
        color.rgb     = tex2D(ReShade::BackBuffer, wCoord.xy).rgb;
        color.a       = 1.0f;
    }
    #endif

    #if(FILMFX_5_FILM_GRAIN)
    void PS_FilmFX_FilmGrain(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        float  randc, lumin;
        float2 rotCoordR, rotCoordG, rotCoordB;
        float3 noise, negnoise;

        if( filmGrainMotion )
          randc       = framerateSeed(float(filmGrainFramerate));
        else
          randc       = filmGrainSeed;

        rotCoordR     = coordRot(texcoord.xy, randc + 1.425);
        rotCoordG     = coordRot(texcoord.xy, randc + 3.892);
        rotCoordB     = coordRot(texcoord.xy, randc + 5.835);

        noise.x       = pnoise3D(float3(rotCoordR.xy * ReShade::ScreenSize / filmGrainSize, 1));
        noise.y       = pnoise3D(float3(rotCoordG.xy * ReShade::ScreenSize / filmGrainSize, 2));
        noise.z       = pnoise3D(float3(rotCoordB.xy * ReShade::ScreenSize / filmGrainSize, 3));

        color         = tex2D(ReShade::BackBuffer, texcoord);
        lumin         = max(max(color.r, color.g), color.b);

        // Intensity
        noise.rgb    *= filmGrainIntensity;

        // Noise color
        noise.rgb     = lerp(dot(noise.rgb, lumaCoeff), noise.rgb, filmGrainColor);

        // Noise Highlight Shadows Safe
        noise.rgb     = lerp(noise.rgb * filmGrainShadow, noise.rgb * filmGrainHighlight, (lumin));
        negnoise      = -abs(noise.rgb );
        lumin        *= lumin;

        // Apply only negative noise in highlights/whites as positive will be clipped out
        // Swizzle the components of negnoise to avoid middle intensity regions of no noise ( x - x = 0 )
        negnoise.rgb  = lerp(noise.rgb, negnoise.brg * 0.5f, lumin);
        noise.rgb     = use_negnoise ? negnoise.rgb : noise.rgb;

        // Blending
        color.rgb    += noise.rgb;
        color.a       = 1.0f;
    }

    void PS_FilmFX_FilmGrain2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
    {
        color         = tex2D(ReShade::BackBuffer, texcoord);
        color         = fastBoxBlur(ReShade::BackBuffer, texcoord, lerp(0.0f, 0.5f, filmGrainBlur) * filmGrainSize / lerp(0.5, 2.0, filmGrainResolution));
		}
    #endif
}

    // TECHNIQUE //////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    technique FilmEmulation < ui_label = "NATIVENHANCER - Film Emulation"; >
    {
        pass preColorGrading
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_PreGrading;
        }

        pass mainLUT
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmEmulation;
        }

        pass colorStore
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_colorStore;
            RenderTarget0  = dft_nefilm::texHalationA;
            RenderTarget1  = dft_nefilm::texDiffusionA;
        }

        #if(FILMFX_1_HALATION)
        pass filmFXHalation1
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_Halation1;
            RenderTarget0  = dft_nefilm::texHalationB;
        }

        pass filmFXHalation2
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_Halation2;
        }
        #endif

        #if(FILMFX_2_DIFFUSION)
        pass filmFXDiffusion1
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_Diffusion1;
            RenderTarget0  = dft_nefilm::texDiffusionB;
        }

        #if(FILMFX_2_HQ_DIFFUSION)
        pass filmFXDiffusionHQ1
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_DiffusionHQ1;
            RenderTarget0  = dft_nefilm::texDiffusionA;
        }

        pass filmFXDiffusionHQ2
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_DiffusionHQ2;
            RenderTarget0  = dft_nefilm::texDiffusionB;
        }
        #endif

        pass filmFXDiffusion2
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_Diffusion2;
        }
        #endif

        #if(FILMFX_3_BREATH)
        pass filmFXBreath
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_Breath;
        }
        #endif

        #if(FILMFX_4_GATE_WEAVE)
        pass filmFXGateWeave
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_GateWeave;
        }
        #endif

        #if(FILMFX_5_FILM_GRAIN)
        pass filmFXGrain
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_FilmGrain;
        }

        pass filmFXGrain2
        {
            VertexShader   = PostProcessVS;
            PixelShader    = dft_nefilm::PS_FilmFX_FilmGrain2;
        }
        #endif
    }
