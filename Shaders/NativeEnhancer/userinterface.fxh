/*
    Description : 'NATIVENHANCER' Film Emulation for Reshade https://reshade.me/
    Author      : dddfault
    License     : MIT, Copyright © 2022 dddfault

    User Interface Parameter file.

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
#define KATEGORI  "Guide (Read-Me)"
#define TERTUTUP  false

    MP_TEXT(readme,
      "Welcome to NATIVENHANCER!                                                    \n"
      "This is short guidance how to use this shader.                             \n\n"

  		"NATIVENHANCER  is a film emulation shader using color-lookup table           \n"
  		"and lot of simplistic and basic methods to achieve a film looks.             \n"
  		"NATIVENHANCER have some of visual film imperfection effect such as           \n"
      "film halaition, lens diffusion, film breath, gate weave and film grain     \n\n"

      "To activate those effects, go to preprocessor settings under NATIVENHANCER   \n"
      "user parameters. Scroll it down till you find \"Preprocessor Definitions\"   \n"
      "all of those effect will be listed there, change the value from 0 to 1 to    \n"
      "activate the effect.                                                       \n\n",
      0)

#undef KATEGORI
#undef TERTUTUP

#define TERTUTUP  true
#define KATEGORI  "Pre - Color Grading"
    MP_BOOL(flatColor,
      "Flat Color",
      "Enable flat color for better color grading (fake)",
      null, 0, false)

    MP_INT_S(kelvinTemp,
      "Color Temperature (K)",
      "Color temperature in Kelvin value.\n\n"
      "Lower value  = Warmer color tone    \n"
      "Higher value = Colder color tone",
      null, 0, 1000, 40000, 1, 6500)

    MP_FLOAT_S(lumaPresevation,
      "Color Temperature Luminance Preservation",
      null, null, 0, 0.0, 1.0, 0.01, 1.0)

    MP_FLOAT_S(kelvinMix,
      "Color Temperature Mix",
      "Mixture or blending intensity with Original color.\n\n"
      "Lower value  = Original color tone                  \n"
      "Higher value = Full color temperature tone blend",
      null, 0, 0.0, 1.0, 0.01, 1.0)

    MP_FLOAT_S(filmSatLimit,
      "Color Saturation Limit",
      "Limit overall color saturation to prevent over-saturation.\n\n"
      "Lower value  = Limited saturation (Zero goes black n White) \n"
      "Higher value = Original color",
      null, 0, 0.0, 1.0, 0.01, 1.0)

    MP_FLOAT_S(filmExposure,
      "Exposure / Highlight Adjustment",
      "Adjustment control for exposure or highlight color tone.\n\n"
      "Lower value  = Squashed highlight tone\n"
      "Higher value = Boosted highlight tone",
      null, 0, -2.0, 2.0, 0.001, 0.0);

    MP_FLOAT_S(filmGamma,
      "Gamma / Midtone Adjustment",
      "Adjustment control for midtone (between highlight and shadow).\n\n"
      "Lower value  = Darker midtone color\n"
      "Higher value = Brighter midtone color",
      null, 0, 0.0, 2.0, 0.001, 1.0)

    MP_FLOAT_S(filmContrast,
      "Contrast / Shadow Adjustment",
      "Adjustment control for contrast or shadow color tone.\n\n"
      "Lower value  = Darker shadow color tone\n"
      "Higher value = Brighter shadow color tone",
      null, 0, 0.33, 3.00, 0.001, 1.0)

    MP_FLOAT_S(filmBrightness,
      "Brightness Adjustment",
      "Adjustment control for overall screen / color brightness.\n\n"
      "Lower value  = Less brightness / more darker tone\n"
      "Higher value = More brighter overall color tone",
      null, 0, 0.0, 2.0, 0.001, 1.0)

    MP_FLOAT_S(filmSaturation,
      "Color Saturation Adjustment",
      "Adjustment control for overall color saturation.\n\n"
      "Lower value  = Desaturated color tone (Zero goes black n White)\n"
      "Higher value = More Saturation on the color tone",
      null, 0, 0.0, 2.0, 0.001, 1.0)
#undef KATEGORI

#define KATEGORI  "Film Color Lookup Table"
    MP_COLOR(inBlack,
      "LUT Black In Level",
      null, null, 0, float3(0.0, 0.0, 0.0))

    MP_COLOR(inWhite,
      "LUT White In Level",
      null, null, 0, float3(1.0, 1.0, 1.0))

    MP_COLOR(outBlack,
      "LUT Black Out Level",
      null, null, 0, float3(0.0, 0.0, 0.0))

    MP_COLOR(outWhite,
      "LUT White Out Level",
      null, null, 0, float3(1.0, 1.0, 1.0))

    MP_FLOAT_S(inGamma,
      "LUT Gamma / Midtone Level",
      null, null, 0, 0.0, 5.0, 0.001, 1.0)

    MP_FLOAT_S(filmLUTMixLuma,
      "LUT Luminance Blending",
      null, null, 0, 0.0, 1.0, 0.001, 1.0)

    MP_FLOAT_S(filmLUTMixChroma,
      "LUT Chromatic Blending",
      null, null, 0, 0.0, 1.0, 0.001, 1.0)

    MP_FLOAT_S(filmLUTIntensity,
      "LUT Overall Intensity",
      null, null, 0, 0.0, 1.0, 0.001, 1.0)

    MP_COMBO(filmLUTSelector,
      "LUT Selection",
      null, null,
      "Agfa Optima 100II\0"
      "Agfa Portrait XPS 160\0"
      "Agfa RSX50II\0"
      "Agfa RSX200II\0"
      "Agfa Scala 200\0"
      "Agfa Ultra 50\0"
      "Agfa Ultra 100\0"
      "Agfa Vista 400 NT\0"
      "Agfa Vista 800 NT\0"
      "Fuji 160C\0"
      "Fuji 160S\0"
      "Fuji 400H\0"
      "Fuji 800Z\0"
      "Fuji Astia 100F\0"
      "Fuji Fortia SP\0"
      "Fuji Neopan 400 NT\0"
      "Fuji Neopan 1600\0"
      "Fuji Provia 100F\0"
      "Fuji Provia 400X\0"
      "Fuji Sensia 100\0"
      "Fuji Superia 100\0"
      "Fuji Superia 400\0"
      "Fuji t64\0"
      "Fuji Velvia 50\0"
      "Fuji Velvia 100\0"
      "Ilford Delta 3200\0"
      "Ilford HP5\0"
      "Ilford Pan F Plas 50\0"
      "Kodak BW400CN NT\0"
      "Kodak E100G\0"
      "Kodak E100VS\0"
      "Kodak E200\0"
      "Kodak Ektachrome 64\0"
      "Kodak Ektar 25\0"
      "Kodak Elite 50II\0"
      "Kodak Elite Chrome 160t\0"
      "Kodak Max 800 NT\0"
      "Kodak Plus-X 125\0"
      "Kodak Portra 100t\0"
      "Kodak Portra 160\0"
      "Kodak Portra 400\0"
      "Kodak Portra 800\0"
      "Kodak Royal Gold 400 NT\0"
      "Kodak T-Max 3200\0"
      "Kodak Tri-X 320\0"
      "Kodak UltraMax 400 NT\0"
      "Kodak UltraMax 800 NT\0"
      "Polaroid PX-70\0"
      "Polaroid PX-70 Cold\0"
      "Polaroid PX-70 Warm\0"
      "Polaroid PX-100UV Cold\0"
      "Polaroid PX-100UV Warm\0"
      "Polaroid PX-680\0"
      "Polaroid PX-680 Cold\0"
      "Polaroid PX-680 Warm\0"
      "Time-Zero Polaroid\0", 0, 0, 56, 2)
#undef KATEGORI

#if(FILMFX_1_HALATION)
#define KATEGORI  "Film FX : Halation"
    MP_FLOAT_S(halationEdgeDetail,
      "Halation Edge Curve",
      "Edge Detail (Affected on Intensity).\n\n"
      "Lower value  = More pronounce detail\n"
      "Higher value = Less pronounce detail",
      null, 0, 1.0, 5.0, 0.001, 2.000)

    MP_FLOAT_S(halationEdgeIntensity,
      "Halation Edge Intensity",
      "Edge Intensity.\n\n"
      "Lower value  = Less detail edge\n"
      "Higher value = More intense edge",
      null, 0, 0.0, 3.0, 0.001, 0.100)

    MP_FLOAT_S(halationBlurWidth,
      "Halation Blur Width",
      "Halation blur width adjustment.\n\n"
      "Lower value  = Narrow blur effect\n"
      "Higher value = Wider blur effect",
      null, 0, 1.0, 5.0, 0.001, 2.000)

    MP_FLOAT_S(halationOpacity,
      "Halation Opacity",
      null, null, 0, 0.0, 1.0, 0.001, 0.850)
      
    MP_FLOAT_S(halationIntensity,
      "Halation Intensity",
      null, null, 0, 0.0, 3.0, 0.001, 1.150)

    MP_COLOR(halationTint,
      "Halation Color Tint",
      null, null, 0, float3(0.941f, 0.597f, 0.042f))
    
    MP_COMBO(halationDebug,
      "Halation Debugging Mode",
      null, null,
      "Default\0"
      "Edge Detection\0"
      "Blending\0", 0, 0, 3, 0)
#undef KATEGORI
#endif

#if(FILMFX_2_DIFFUSION)
#define KATEGORI  "Film FX : Diffusion"
    MP_FLOAT_S(diffusionBlurWidth,
      "Diffusion Blur Width.",
      "Diffusion blur width adjustment.\n\n"
      "Lower value  = Narrow blur effect\n"
      "Higher value = Wider blur effect",
      null, 0, 2.0, 16.0, 0.01, 4.0)

    MP_FLOAT_S(diffusionOpacity,
      "Diffusion Opacity",
      null, null, 0, 0.0, 1.0, 0.01, 0.75)

    MP_COMBO(diffusionBlendMode,
      "Diffusion Blend Mode",
      null, null,
      "Lighten (Diffusion)\0"
      "Screen (Bloom)\0"
      "Default (Debug)\0",
      0, 0, 3, 0)
#undef KATEGORI
#endif


#if(FILMFX_3_BREATH)
#define KATEGORI  "Film FX : Breath"
    MP_INT_S(filmBreathFramerate,
      "Breath Framerate",
      "Matching breathing animation to specific framerate.\n\n"
      "Zero means using current frame rate.",
      null, 0, 0, 144, 1, 24)

    MP_FLOAT2_S(filmBreathBrightness,
      "Breath Brightness",
      "Minimum and maximum value of overall brightness breath.\n\n"
      "Left (X) - Minimum value\n"
      "Right (Y) - Maximum value",
      null, 0, 0.0, 1.5, 0.001, float2(0.985, 1.000))
    
    MP_FLOAT2_S(filmBreathMidtone,
      "Breath Midtone",
      "Minimun and maximum value of midtone breath.\n\n"
      "Left (X) - Minimum value\n"
      "Right (Y) - Maximum value",
      null, 0, 0.0, 1.5, 0.001, float2(0.985, 1.000))

    MP_FLOAT2_S(filmBreathSaturation,
      "Breath Saturation",
      "Minimun and maximum value of saturation breath.\n\n"
      "Left (X) - Minimum value\n"
      "Right (Y) - Maximum value",
      null, 0, 0.0, 1.5, 0.001, float2(0.920, 1.000))
#undef KATEGORI
#endif

#if(FILMFX_4_GATE_WEAVE)
#define KATEGORI  "Film FX : Gate Weave"
    MP_INT_S(filmGateWeaveFramerate,
      "Gate Weave Framerate",
      "Matching weave animation to specific framerate.\n\n"
      "Zero means using current frame rate.",
      null,
      0, 0, 144, 1, 24)
    
    MP_FLOAT2_S(filmGateWeaveOffset,
      "Gate Weave Offsets",
      "Screen coordinate offset value.",
      null, 0, 0.0, 1.0, 0.001, float2(0.000, 0.080))
#undef KATEGORI
#endif

#if(FILMFX_5_FILM_GRAIN)
#define KATEGORI  "Film FX : Film Grain"
    MP_COMBO(filmGrainMotion,
      "Grain Motion",
      "Enable film grain motion.\n"
      "Disable this if you want static grain.",
      null,
      "Disabled\0Enabled\0", 0, 0, 2, 1)
    
    MP_INT_S(filmGrainFramerate,
      "Grain Framerate Motion",
      "Matching grain motion to specific framerate.\n\n"
      "Zero means using current frame rate.",
      null, 0, 0, 144, 1, 24)

    MP_FLOAT_S(filmGrainSeed,
      "Grain Pattern Adjust (for still noise)",
      null, null,
      0, 1.0, 2.0, 0.001, 1.0)
    
    MP_FLOAT_S(filmGrainColor,
      "Grain Color Amount",
      null, null,
      0, 0.0, 1.0, 0.001, 1.0)
    
    MP_FLOAT_S(filmGrainIntensity,
      "Grain Intensity",
      null, null,
      0, 0.0, 1.0, 0.001, 0.25)
    
    MP_FLOAT_S(filmGrainHighlight,
      "Grain Highlights Intensity",
      null, null,
      0, 0.0, 1.0, 0.001, 1.00)

    MP_FLOAT_S(filmGrainShadow,
      "Grain Shadows Intensity",
      null, null,
      0, 0.0, 1.0, 0.001, 1.00)
    
    MP_BOOL(use_negnoise,
      "Use Negative Noise (highlights)",
      null, null, 0, false)
    
    MP_FLOAT_S(filmGrainSize,
      "Grain Size",
      null, null,
      0, 1.35, 3.50, 0.01, 1.45)
    
    MP_FLOAT_S(filmGrainBlur,
     "Grain Smoothness",
      null, null,
      0, 0.0, 1.0, 0.001, 0.5)
    
    MP_FLOAT_S(filmGrainResolution,
      "Film Grain Resolution",
      "Film grain resolution size applied to final image (this affected to blurriness)",
      null,
      0, 0.1, 1.0, 0.001, 0.5)
#undef KATEGORI
#endif

#undef TERTUTUP
#undef KATEGORISASI