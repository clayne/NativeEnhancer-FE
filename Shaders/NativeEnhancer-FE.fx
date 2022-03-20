/*
		Description : 'NATIVENHANCER' Film Emulation for Reshade https://reshade.me/
		Author      : dddfault
		License     : MIT, Copyright © 2022 dddfault

		A simple and basic film emulation using color lookup table
		combined with various overlay textures to mimic analog film looks.

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
*/

#include "ReShade.fxh"
#include "NativeEnhancer/miscellaneous.fxh"
#include "NativeEnhancer/blendingmode.fxh"

namespace dft_nefilm
{
		//// PREPROCESSOR DEFINITIONS ////////////////////////////////////////////////
		// Enable halation, simulate glowy edges on bright spot.
		#ifndef FILMFX_1_HALATION
			#define FILMFX_1_HALATION          0
		#endif

		// Simulate hazy foggy light on screen by diffusing lights.
		#ifndef FILMFX_2_DIFFUSION
			#define FILMFX_2_DIFFUSION         0
		#endif

		// Multi layered Lens Diffusion
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

		//// USER INTERFACE PARAMETERS /////////////////////////////////////////////
		uniform uint kelvinTemp <
			ui_label    = "Color Temperature (K)";
			ui_tooltip  = "Color temperature in Kelvin value.\n\n"
			              "Lower value  = Warmer color tone\n"
			              "Higher value = Colder color tone";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 1000;
			ui_max      = 40000;
			> = 6500;

		uniform float lumaPresevation <
			ui_label    = "Luminance Preservation";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.01;
			> = 1.0;

		uniform float kelvinMix <
			ui_label    = "Color Temperature Mix";
			ui_tooltip  = "Mixture or blending intensity with Original color.\n\n"
			              "Lower value  = Original color tone\n"
			              "Higher value = Full color temperature tone blend";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.01;
			> = 1.0;

		uniform float filmSatLimit <
			ui_label    = "Color Saturation Limit";
			ui_tooltip  = "Limit overall color saturation to prevent over-saturation.\n\n"
			              "Lower value  = Limited saturation (Zero goes black n White)\n"
			              "Higher value = Original color";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.01;
			> = 1.0;

		uniform float filmExposure <
			ui_label    = "Exposure / Highlight Adjustment";
			ui_tooltip  = "Adjustment control for exposure or highlight color tone.\n\n"
			              "Lower value  = Squashed highlight tone\n"
			              "Higher value = Boosted highlight tone";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = -2.0;
			ui_max      = 2.0;
			ui_step     = 0.001;
			> = 0.0;

		uniform float filmGamma <
			ui_label    = "Gamma / Midtone Adjustment";
			ui_tooltip  = "Adjustment control for midtone (between highlight and shadow).\n\n"
			              "Lower value  = Darker midtone color\n"
			              "Higher value = Brighter midtone color";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 2.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform float filmContrast <
			ui_label    = "Contrast / Shadow Adjustment";
			ui_tooltip  = "Adjustment control for contrast or shadow color tone.\n\n"
			              "Lower value  = Darker shadow color tone\n"
			              "Higher value = Brighter shadow color tone";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 0.33;
			ui_max      = 3.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform float filmBrightness <
			ui_label    = "Brightness Adjustment";
			ui_tooltip  = "Adjustment control for overall screen / color brightness.\n\n"
			              "Lower value  = Less brightness / more darker tone\n"
			              "Higher value = More brighter overall color tone";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 2.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform float filmSaturation <
			ui_label    = "Color Saturation Adjustment";
			ui_tooltip  = "Adjustment control for overall color saturation.\n\n"
			              "Lower value  = Desaturated color tone (Zero goes black n White)\n"
			              "Higher value = More Saturation on the color tone";
			ui_category = "Pre-Color Correction";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 2.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform float3 inBlack <
			ui_label    = "LUT Black In Level";
			ui_category = "Color Lookup Table";
			ui_type     = "color";
			> = float3(0.0, 0.0, 0.0);

		uniform float3 inWhite <
			ui_label    = "LUT White In Level";
			ui_category = "Color Lookup Table";
			ui_type     = "color";
			> = float3(1.0, 1.0, 1.0);

		uniform float3 outBlack <
			ui_label    = "LUT Black Out Level";
			ui_category = "Color Lookup Table";
			ui_type     = "color";
			> = float3(0.0, 0.0, 0.0);

		uniform float3 outWhite <
			ui_label    = "LUT White Out Level";
			ui_category = "Color Lookup Table";
			ui_type     = "color";
			> = float3(1.0, 1.0, 1.0);

		uniform float inGamma <
			ui_label    = "LUT Gamma / Midtone Level";
			ui_category = "Color Lookup Table";
			ui_type     = "drag";
			ui_min      = 0.5;
			ui_max      = 10.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform float filmLUTMixLuma <
			ui_label    = "LUT Luminance Blending";
			ui_category = "Color Lookup Table";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform float filmLUTMixChroma <
			ui_label    = "LUT Chromatic Blending";
			ui_category = "Color Lookup Table";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform float filmLUTIntensity <
			ui_label    = "LUT Overall Intensity";
			ui_category = "Color Lookup Table";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.001;
			> = 1.0;

		uniform int filmLUTSelector <
			ui_label    = "LUT Selection";
			ui_category = "Color Lookup Table";
			ui_type     = "combo";
			ui_items    = "Agfa Optima 100II\0"
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
			              "Time-Zero Polaroid\0";
			ui_min      = 0;
			ui_max      = 56;
			> = 2;

		#if(FILMFX_1_HALATION)
		uniform float halationEdgeWidth <
			ui_label    = "Halation Edge Width";
			ui_tooltip  = "Edge Bias Width.\n\n"
			              "Lower value  = Thinner edge\n"
			              "Higher value = Thicker edge line";
			ui_category = "Film FX : Halation";
			ui_type     = "drag";
			ui_min      = 1.0;
			ui_max      = 5.0;
			ui_step     = 0.001;
			> = 1.000;

		uniform float halationEdgeDetail <
			ui_label    = "Halation Edge Detail";
			ui_tooltip  = "Edge Detail.\n\n"
			              "Lower value  = More pronounce detail\n"
			              "Higher value = Less detail";
			ui_category = "Film FX : Halation";
			ui_type     = "drag";
			ui_min      = 1.0;
			ui_max      = 5.0;
			ui_step     = 0.001;
			> = 2.000;

		uniform float halationEdgeIntensity <
			ui_label    = "Halation Edge Intensity";
			ui_tooltip  = "Edge Intensity.\n\n"
			              "Lower value  = Less detail edge\n"
			              "Higher value = More intense edge";
			ui_category = "Film FX : Halation";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 3.0;
			ui_step     = 0.001;
			> = 0.100;

		uniform float halationBlurWidth <
			ui_label    = "Halation Blur Width";
			ui_tooltip  = "Halation blur width adjustment.\n\n"
			              "Lower value  = Narrow blur effect\n"
			              "Higher value = Wider blur effect";
			ui_category = "Film FX : Halation";
			ui_type     = "drag";
			ui_min      = 1.0;
			ui_max      = 16.0;
			ui_step     = 0.01;
			> = 6.0;

		uniform float halationOpacity <
			ui_label    = "Halation Opacity";
			ui_category = "Film FX : Halation";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.01;
			> = 0.7;

		uniform float3 halationTint <
			ui_label    = "Halation color tint";
			ui_category = "Film FX : Halation";
			ui_type     = "color";
			> = float3( 0.946, 0.105, 0.105 );

		uniform int halationDebug <
		  ui_label    = "Halation Debugging Mode";
			ui_category = "Film FX : Halation";
			ui_type     = "combo";
			ui_items    = "Default\0"
			              "Edge Detection\0"
			              "Blending\0";
			ui_min      = 0;
			ui_max      = 3;
		> = 0;
		#endif

		#if(FILMFX_2_DIFFUSION)
		uniform float diffusionBlurWidth <
			ui_label    = "Diffusion Blur Width";
			ui_tooltip  = "Diffusion blur width adjustment.\n\n"
			              "Lower value  = Narrow blur effect\n"
			              "Higher value = Wider blur effect";
			ui_category = "Film FX : Diffusion";
			ui_type     = "drag";
			ui_min      = 2.0;
			ui_max      = 32.0;
			ui_step     = 0.01;
			> = 4.0;

		#if(FILMFX_2_HQ_DIFFUSION)
		uniform float diffusionBlurWidthHQ <
			ui_label    = "Diffusion Blur Width - HQ";
			ui_tooltip  = "HQ Diffusion blur width adjustment.\n\n"
			              "Lower value  = Narrow blur effect\n"
			              "Higher value = Wider blur effect";
			ui_category = "Film FX : Diffusion";
			ui_type     = "drag";
			ui_min      = 2.0;
			ui_max      = 32.0;
			ui_step     = 0.01;
			> = 8.0;
		#endif

		uniform int diffusionBlendMode <
			ui_label    = "Diffusion blend mode";
			ui_category = "Film FX : Diffusion";
			ui_type     = "combo";
			ui_items    = "Default\0"
			              "Darken\0"
			              "Multiply\0"
			              "Color Burn\0"
			              "Linear Dodge\0"
			              "Linear Burn\0"
			              "Lighten\0"
			              "Screen\0"
			              "Color Dodge\0"
			              "Add\0"
			              "Overlay\0"
			              "Softlight\0"
			              "Vividlight\0"
			              "Linearlight\0"
			              "Pinlight\0"
			              "Hardmix\0"
			              "Difference\0"
			              "Exclusion\0"
			              "Subtract\0"
			              "Reflect\0"
			              "Hue\0"
			              "Saturation\0"
			              "Color\0"
			              "Luminosity\0";
			ui_min      = 0;
			ui_max      = 24;
			> = 6;

		uniform float diffusionOpacity <
			ui_label    = "Diffusion Opacity";
			ui_category = "Film FX : Diffusion";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.01;
			> = 0.8;
		#endif

		#if(FILMFX_3_BREATH)
		uniform float filmBreathFramerate <
			ui_label    = "Breath Framerate";
			ui_tooltip  = "Matching breathing animation to specific framerate.\n\n"
			              "Zero means using current frame rate.";
			ui_category = "FilmFX : Breath";
			ui_type     = "drag";
			ui_min      = 0;
			ui_max      = 90;
			ui_step     = 1;
			> = 24;

		uniform float2 filmBreathBrightness <
			ui_label    = "Breath Brightness";
			ui_tooltip  = "Minimum and maximum value of overall brightness breath.\n\n"
			              "Left (X) - Minimum value\n"
			              "Right (Y) - Maximum value";
			ui_category = "FilmFX : Breath";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.5;
			ui_step     = 0.001;
			> = float2(0.985, 1.000);

		uniform float2 filmBreathMidtone <
			ui_label    = "Breath Midtone";
			ui_tooltip  = "Minimun and maximum value of midtone breath.\n\n"
			              "Left (X) - Minimum value\n"
			              "Right (Y) - Maximum value";
			ui_category = "FilmFX : Breath";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.5;
			ui_step     = 0.001;
			> = float2(0.985, 1.000);

		uniform float2 filmBreathSaturation <
			ui_label    = "Breath Saturation";
			ui_tooltip  = "Minimun and maximum value of saturation breath.\n\n"
			              "Left (X) - Minimum value\n"
			              "Right (Y) - Maximum value";
			ui_category = "FilmFX : Breath";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.5;
			ui_step     = 0.001;
			> = float2(0.920, 1.010);
		#endif

		#if(FILMFX_4_GATE_WEAVE)
		uniform float filmGateWeaveFramerate <
			ui_label    = "Gate Weave Framerate";
			ui_tooltip  = "Matching weave animation to specific framerate.\n\n"
			              "Zero means using current frame rate.";
			ui_category = "FilmFX : Gate Weave";
			ui_type     = "drag";
			ui_min      = 0;
			ui_max      = 90;
			ui_step     = 1;
			> = 24;

		uniform float2 filmGateWeaveOffset <
			ui_label    = "Gate Weave Offsets";
			ui_tooltip  = "Screen coordinate offset value.";
			ui_category = "FilmFX : Gate Weave";
			ui_type     = "drag";
			ui_min      = 0.0;
			ui_max      = 1.0;
			ui_step     = 0.001;
			> = float2(0.000, 0.080);
		#endif

		//// DEFINES ///////////////////////////////////////////////////////////////
		uniform float timer < source = "timer"; >;
		uniform float framecount < source = "framecount"; >;

		//// TEXTURES //////////////////////////////////////////////////////////////
		texture texHalationA {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};
		texture texHalationB {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};
		texture texDiffusionA {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};
		texture texDiffusionB {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;};

		texture neFilmTexture < source = "neFilmLUT.png"; >
		{
			Width  = 64 * 64;
			Height = 64 * filmLUTAmount;
		};

		//// SAMPLERS //////////////////////////////////////////////////////////////
		sampler	filmSampler {Texture = neFilmTexture;};
		sampler	halationBufferA {Texture = texHalationA;};
		sampler	halationBufferB {Texture = texHalationB;};
		sampler	diffusionBufferA {Texture = texDiffusionA;};
		sampler	diffusionBufferB {Texture = texDiffusionB;};

		//// PIXEL SHADERS /////////////////////////////////////////////////////////
		void PS_colorStore(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 halation : SV_Target0, out float4 diffusion : SV_Target1)
		{
			halation  = tex2D(ReShade::BackBuffer, texcoord.xy);
			diffusion = tex2D(ReShade::BackBuffer, texcoord.xy);
		}

		void PS_PreGrading(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
		{
			float3 kColor, oLum, blended, resHSV, resRGB;
			color        = tex2D(ReShade::BackBuffer, texcoord.xy);

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
			lutcolor     = lerp(tex2D(filmSampler, lutcoord.xy).rgb, tex2D(filmSampler, float2(lutcoord.x + texelsize.y, lutcoord.y)).rgb, lerpfact);

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
			//halation     = fastBoxBlur(color, texcoord.xy, halationBufferB, halationBlurWidth);
			halation     = fastGaussBlur(halationBufferB, texcoord.xy, halationBlurWidth, 4.0, 16.0);
			halation.rgb = (halation.rgb < 0.5 ? (2.0 * halation.rgb * halationTint) : (1.0 - 2.0 * (1.0 - halation.rgb) * (1.0 - halationTint)));

			switch(halationDebug)
	    {
				case 0: // Default
				{color.rgb = saturate(lerp(color.rgb, max(color.rgb, halation.rgb), halationOpacity));}
				break;
				case 1: // Edge detection
				{color.rgb = tex2D(halationBufferB, texcoord.xy).rgb;}
				break;
				case 2: // Halation Blending
				{color.rgb = halation.rgb;}
				break;
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
			diffusion    = gaussBlur(texcoord.xy, diffusionBufferA, diffusionBlurWidthHQ, 0, 0);
			color.rgb    = diffusion.rgb;
			color.a      = 1.0f;
		}
		#endif

		void PS_FilmFX_Diffusion2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
		{
			float4 diffusion;
			float blurWidth;
			color        = tex2D(ReShade::BackBuffer, texcoord.xy);

			#if(FILMFX_3_HQ_DIFFUSION)
				diffusion  = gaussBlur(texcoord.xy, diffusionBufferB, diffusionBlurWidthHQ, 0, 1);
			#else
				diffusion  = gaussBlur(texcoord.xy, diffusionBufferB, diffusionBlurWidth, 0, 0);
			#endif
			color.rgb    = blendingmode(diffusion.rgb, color.rgb, diffusionBlendMode, diffusionOpacity);
			color.a      = 1.0f;
		}
		#endif

		#if(FILMFX_3_BREATH)
		void PS_FilmFX_Breath(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
		{
			float4 breath;
			float  randSeed;
			breath       = tex2D(ReShade::BackBuffer, texcoord.xy);
			randSeed     = filmBreathFramerate == 0 ? framecount : floor(timer * 0.001 * filmBreathFramerate);
			randSeed    %= 10000;

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
			randSeed      = filmGateWeaveFramerate == 0 ? framecount : floor(timer * 0.001 * filmGateWeaveFramerate);
			randSeed     %= 10000;

			wCoord.xy     = texcoord.xy;
			wCoord.xy     = float2(wCoord.x + lerp(0, filmGateWeaveOffset.x/100, simpleNoiseGen(randSeed)), wCoord.y - lerp(0, filmGateWeaveOffset.y/100, simpleNoiseGen(randSeed)));
			color.rgb     = tex2D(ReShade::BackBuffer, wCoord.xy).rgb;
			color.a       = 1.0f;
		}
		#endif
}

	// TECHNIQUE //////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////
	technique FilmEmulation
	{
		pass colorStore
		{
			VertexShader   = PostProcessVS;
			PixelShader    = dft_nefilm::PS_colorStore;
			RenderTarget0  = dft_nefilm::texHalationA;
			RenderTarget1  = dft_nefilm::texDiffusionA;
		}

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
	}
