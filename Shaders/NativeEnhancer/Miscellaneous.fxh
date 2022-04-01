/*
    Description : Miscellaneous Helper File for NATIVENHANCER
    Author      : dddfault
    License     : MIT, Copyright © 2022 dddfault
                  MIT, Copyright © 2022 prod80

    Additional credits
    - Color space convertion function by prod80
      (https://github.com/prod80/prod80-ReShade-Repository)
    - Fit Fill image function by Otis_Inf
    - Gaussian Blur and Box blur by Marty McFly
    - Sobel Filter by Jeroen Baert
    - Gaussian Blur by TambakoJaguar
    - Simple and Fast Gaussian Blur by existical

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
    //// DEFINES ///////////////////////////////////////////////////////////////
    uniform float timer < source = "timer"; >;
    uniform float framecount < source = "framecount"; >;

    // SRGB <--> CIELAB CONVERSIONS
    // Reference white D65
    #define reference_white         float3(0.95047, 1.0, 1.08883)

    // Source
    // http://www.brucelindbloom.com/index.html?Eqn_RGB_to_XYZ.html
    #define K_val                   float(24389.0 / 27.0)
    #define E_val                   float(216.0 / 24389.0)

    #define lumaCoeff               float3(0.212656, 0.715158, 0.072186)
    #define filmTileSizeXY          64
    #define filmTileAmount          filmTileSizeXY
    #define filmLUTAmount           56
    #define PI                      3.14159265359
    #define DOUBLE_PI               2 * PI

    // Otis' Fit Fill Image
    #define aspekRasio              (float(BUFFER_WIDTH)/float(BUFFER_HEIGHT))
    #define wideRasio               1.77777777778 //Widescreen (16:9) Aspect Ratio
    #define idealRatio              float2(float(BUFFER_HEIGHT) * 1.61803399, float(BUFFER_WIDTH) / 1.61803399) //x. width, y. height
    #define sourceCoord             float4(float(BUFFER_WIDTH)/idealRatio.x, 1.0, idealRatio.x/float(BUFFER_WIDTH), 1.0)
    #define fitTex(tex)             float2((tex.x * sourceCoord.x) - ((1.0-sourceCoord.z)/2.0), (tex.y * sourceCoord.y) - ((1.0-sourceCoord.w)/2.0))

    // Noise texture definitions
    #define permTexSize             256
    #define permONE                 1.0f / 256.0f
    #define permHALF                0.5f * permONE

    // Blending functions
    float4 opacityValue(float4 base, float opacity)    {return lerp(0, base, opacity);}
    float4 alphaBlend(float4 base, float4 blend)       {return lerp(base, blend, blend.a);}
    float3 saturation(float3 base, float sat)          {return lerp(dot(base, lumaCoeff), base, sat);}
    float3 fillValue(float3 base, float fill)          {return pow(abs(base), lerp(1, 0, fill));}

    // Texcoord flip
    float2 normalCoord(float2 coord)                   {return float2(coord.x, coord.y);}
    float2 flippedCoord(float2 coord)                  {return float2(1.0-coord.x, coord.y);}

    //// GENERAL FUNCTIONS /////////////////////////////////////////////////////

    // Framerate Seed function by Fu-Bama
    float framerateSeed(float framerate)
    {
      float  randSeed;
      randSeed     = framerate == 0 ? framecount : floor(timer * 0.001 * framerate);
      randSeed    %= 10000;
      return randSeed;
    }

    float gauss(float x, float e)
    { return exp(-pow(x, 2.)/e); }

    float simpleNoiseGen(float p)
    { return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }

    // Levels function by prod80
    float3 levels(float3 color, float3 blackin, float3 whitein, float gamma, float3 outblack, float3 outwhite)
    {
       float3 ret       = saturate( color.xyz - blackin.xyz ) / max( whitein.xyz - blackin.xyz, 0.000001f );
       ret.xyz          = pow( ret.xyz, gamma );
       ret.xyz          = ret.xyz * saturate( outwhite.xyz - outblack.xyz ) + outblack.xyz;
       return ret;
    }

    float fade(float t)
    {
      return t * t * t * ( t * ( t * 6.0 - 15.0 ) + 10.0 );
    }

    float2 coordRot(float2 tc, float angle)
    {
      float rotX = ((tc.x * 2.0 - 1.0) * ReShade::AspectRatio * cos(angle)) - ((tc.y * 2.0 - 1.0) * sin(angle));
      float rotY = ((tc.y * 2.0 - 1.0) * cos(angle)) + ((tc.x * 2.0 - 1.0) * ReShade::AspectRatio * sin(angle));
      rotX = ((rotX / ReShade::AspectRatio) * 0.5 + 0.5);
      rotY = rotY * 0.5 + 0.5;

      return float2(rotX, rotY);
    }

    float2 rotateUV(float2 coord, float rotation)
    {
      return float2(
      cos(radians(rotation)) * (coord.x - 0.5) + sin(radians(rotation)) * (coord.y - 0.5) + 0.5,
      cos(radians(rotation)) * (coord.y - 0.5) - sin(radians(rotation)) * (coord.x - 0.5) + 0.5);
    }

    float2 rotateUV2(float2 coord, int rotation)
    {
      return float2(
      cos(radians(45*rotation)) * (coord.x - 0.5) + sin(radians(45*rotation)) * (coord.y - 0.5) + 0.5,
      cos(radians(45*rotation)) * (coord.y - 0.5) - sin(radians(45*rotation)) * (coord.x - 0.5) + 0.5);
    }

    // Clipping check function by CeeJay.dk
    float3 clipCheck(float3 color)
    {
      float3 clipped_colors;
      clipped_colors = any(color > saturate(color)) // any colors whiter than white?
      ? float3(1.0, 0.0, 0.0)
      : color;
      clipped_colors = all(color > saturate(color)) // all colors whiter than white?
      ? float3(1.0, 1.0, 0.0)
      : clipped_colors;
      clipped_colors = any(color < saturate(color)) // any colors blacker than black?
      ? float3(0.0, 0.0, 1.0)
      : clipped_colors;
      clipped_colors = all(color < saturate(color)) // all colors blacker than black?
      ? float3(0.0, 1.0, 1.0)
      : clipped_colors;
      color = clipped_colors;
      return color;
    }
    //// BLURRING FUNCTIONS ////////////////////////////////////////////////////
    float3 radialBlur(float2 uv, float rad_amount)
    {
      float4 color;
      float b  = 0;
      for (int i = 1; i <= 32; i++)
      {
        uv    -= b;
        uv    *= 1.0+(rad_amount * 0.01);
        b      = (1-(1*pow(abs(1.0+(rad_amount * 0.01)), i))) / 2;
        uv    += b;
        color += tex2Dlod(ReShade::BackBuffer, float4(uv.x, uv.y, 10, 10));
      }
      color = color / 32;
      return color.rgb;
    }

    float4 boxBlur(sampler2D BackBuffer, float2 texcoord, float bluramount)
    {
      float4 blurcolor = 0.0;
      float2 blurmult = ReShade::PixelSize * bluramount;

      float weights[6] = { 1.0, 0.833, 0.666, 0.499, 0.332, 0.165};
      for (float x = -5; x <= 5; x++) {
        for (float y = -5; y <= 5; y++) {
          float2 offset = float2(x, y);
          float offsetweight = weights[abs(int(x))] * weights[abs(int(y))];
          blurcolor.rgb += tex2D(BackBuffer, texcoord + offset.xy * blurmult).rgb * offsetweight;
          blurcolor.a += offsetweight;
        }
      }
      return float4(blurcolor.rgb / blurcolor.a, 1.0);
    }

    float4 fastBoxBlur(sampler2D BackBuffer, float2 texcoord, float bluramount)
    {
      float4 blurcolor = 0.0;
      float2 blurmult = ReShade::PixelSize * bluramount;
      float weights[3] = { 1.0,0.75,0.5 };
      for (float x = -2; x <= 2; x++) {
        for (float y = -2; y <= 2; y++) {
          float2 offset = float2(x, y);
          float offsetweight = weights[abs(int(x))] * weights[abs(int(y))];
          blurcolor.rgb += tex2D(BackBuffer, texcoord + offset.xy * blurmult).rgb * offsetweight;
          blurcolor.a += offsetweight;
        }
      }
      return float4(blurcolor.rgb / blurcolor.a, 1.0);
    }

    float4 gaussBlur(float2 coord, sampler tex, float mult, float lodlevel, bool isBlurVert)
    {
      float4 sum = 0;
      float2 axis = (isBlurVert) ? float2(0, 1) : float2(1, 0);
      float  weight[11] = {
        0.082607, 0.080977,
        0.076276, 0.069041,
        0.060049, 0.050187,
        0.040306, 0.031105,
        0.023066, 0.016436,
        0.011254};

      for(int i=-10; i < 11; i++)
      {
        float currweight = weight[abs(i)];
        sum	+= tex2Dlod(tex, float4(coord.xy + axis.xy * (float)i * ReShade::PixelSize * mult,0,lodlevel)) * currweight;
      }
      return sum;
    }

    float4 fastGaussBlur(sampler2D samplerColor, float2 uvCoord, float gaussSize, float gaussQuality, float gaussIteration)
    {
      float4 color;
      float2 radius, coord;

      radius = gaussSize / ReShade::ScreenSize.xy;
      coord  = uvCoord.xy / ReShade::ScreenSize.xy;
      for(float d = 0.0; d < DOUBLE_PI; d += DOUBLE_PI / gaussIteration) {
        for(float i = 1.0 / gaussQuality; i <= 1.0; i += 1.0 / gaussQuality) {
        color += tex2Dlod(samplerColor, float4(uvCoord + float2(cos(d), sin(d)) * radius * i, 0, gaussQuality));
        }
      }

      color /= gaussQuality * gaussIteration;
      return color;
    }

    // TambakoJaguar https://www.shadertoy.com/view/XstGWB
    float4 fastGaussBlurVert(sampler2D tex, float2 coord, float gaussQuality, int gaussSize)
    {
      float4    color = 0.0;
      const int nBlur = 2 * gaussSize + 1;
      for(int i = 0; i < nBlur; i++)
      {
        float i2   = gaussQuality * float(i - gaussSize);
        float2 pos = coord.xy + float2(0.0, i2 / ReShade::ScreenSize.y);
        float gss  = gauss(i2, float(20 * gaussSize));
        color.rgb += gss * tex2D(tex, pos).rgb;
        color.a   += gss;
      }
      color.rgb /= color.a;
      return color;
    }

    float4 fastGaussBlurHorz(sampler2D tex, float2 coord, float gaussQuality, int gaussSize)
    {
      float4 color    = 0.0;
      const int nBlur = 2 * gaussSize + 1;
      for(int i = 0; i < nBlur; i++)
      {
        float i2   = gaussQuality * float(i - gaussSize);
        float2 pos = coord.xy + float2(i2 / ReShade::ScreenSize.x, 0.0);
        float gss  = gauss(i2, float(20 * gaussSize));
        color.rgb += gss * tex2D(tex, pos).rgb;
        color.a   += gss;
      }
      color.rgb /= color.a;
      return color;
    }

    //// SOBEL FILTER //////////////////////////////////////////////////////////
    float intensity(sampler2D tex, float2 coord, float2 xy_step)
    {
      float3 color = tex2D(tex, coord + xy_step).rgb;
      return sqrt((color.x * color.x) + (color.y * color.y) + (color.z * color.z));
    }

    //sobelFilter(sobelWidth / ReShade::ScreenSize.x, sobelWidth / ReShade::ScreenSize.y, texcoord.xy, sobelDetail, sobelMultiplier);
    float3 sobelFilter(sampler2D tex, float stepx, float stepy, float2 center, float sobelDetail, float sobelMultiplier)
    {
      float tleft   = intensity(tex, center, float2(-stepx,  stepy));
      float left    = intensity(tex, center, float2(-stepx,      0));
      float bleft   = intensity(tex, center, float2(-stepx, -stepy));
      float top     = intensity(tex, center, float2(     0,  stepy));
      float bottom  = intensity(tex, center, float2(     0, -stepy));
      float tright  = intensity(tex, center, float2( stepx,  stepy));
      float right   = intensity(tex, center, float2( stepx,      0));
      float bright  = intensity(tex, center, float2( stepx, -stepy));

      float x =  tleft + 2.0 * left + bleft  - tright - 2.0 * right  - bright;
      float y = -tleft - 2.0 * top  - tright + bleft  + 2.0 * bottom + bright;

      float color = pow(sqrt((x*x) + (y*y)), sobelDetail) * sobelMultiplier;
      return float3(color, color, color);
    }

    //// COLOR SPACE AND CONVERSIONS ///////////////////////////////////////////
    // Color temperature
    float3 KelvinToRGB(in float k)
    {
      float3 ret;
      float kelvin     = clamp( k, 1000.0f, 40000.0f ) / 100.0f;
      if( kelvin <= 66.0f )
      {
        ret.r        = 1.0f;
        ret.g        = saturate( 0.39008157876901960784f * log( kelvin ) - 0.63184144378862745098f );
      }
      else
      {
        float t      = max( kelvin - 60.0f, 0.0f );
        ret.r        = saturate( 1.29293618606274509804f * pow( t, -0.1332047592f ));
        ret.g        = saturate( 1.12989086089529411765f * pow( t, -0.0755148492f ));
      }
      if( kelvin >= 66.0f )
      ret.b        = 1.0f;
      else if( kelvin < 19.0f )
      ret.b        = 0.0f;
      else
      ret.b        = saturate( 0.54320678911019607843f * log( kelvin - 10.0f ) - 1.19625408914f );
      return ret;
    }

    // collected from
    // http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
    float3 rgb2hsv(float3 c)
    {
      float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
      float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
      float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

      float d = q.x - min(q.w, q.y);
      float e = 1.0e-10;
      return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    float3 hsv2rgb(float3 c)
    {
      float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
      float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
      return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    float3 hueslider(float3 base, float hue_value)
    {
      base.rgb = rgb2hsv(base.rgb);
      base.r   = frac((hue_value  * 0.005) + base.r);
      base.rgb = hsv2rgb(base.rgb);
      return base.rgb;
    }

    float3 HUEToRGB(in float H)
    {
      return saturate( float3( abs( H * 6.0f - 3.0f ) - 1.0f,
      2.0f - abs( H * 6.0f - 2.0f ),
      2.0f - abs( H * 6.0f - 4.0f )));
    }

    float3 RGBToHCV(in float3 RGB)
    {
      // Based on work by Sam Hocevar and Emil Persson
      float4 P         = (RGB.g < RGB.b ) ? float4(RGB.bg, -1.0f, 2.0f/3.0f) : float4(RGB.gb, 0.0f, -1.0f/3.0f);
      float4 Q1        = (RGB.r < P.x ) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
      float C          = Q1.x - min(Q1.w, Q1.y);
      float H          = abs((Q1.w - Q1.y) / (6.0f * C + 0.000001f) + Q1.z);
      return float3(H, C, Q1.x);
    }

    float3 RGBToHSL(in float3 RGB)
    {
      RGB.xyz          = max(RGB.xyz, 0.000001f);
      float3 HCV       = RGBToHCV(RGB);
      float L          = HCV.z - HCV.y * 0.5f;
      float S          = HCV.y / (1.0f - abs(L * 2.0f - 1.0f) + 0.000001f);
      return float3(HCV.x, S, L);
    }

    float3 HSLToRGB(in float3 HSL)
    {
      float3 RGB       = HUEToRGB(HSL.x);
      float C          = (1.0f - abs(2.0f * HSL.z - 1.0f)) * HSL.y;
      return (RGB - 0.5f) * C + HSL.z;
    }

    float3 pd80_xyz_to_lab(float3 c)
    {
      // .xyz output contains .lab
      float3 w       = c / reference_white;
      float3 v;
      v.x            = (w.x >  E_val) ? pow(abs(w.x), 1.0 / 3.0) : (K_val * w.x + 16.0) / 116.0;
      v.y            = (w.y >  E_val) ? pow(abs(w.y), 1.0 / 3.0) : (K_val * w.y + 16.0) / 116.0;
      v.z            = (w.z >  E_val) ? pow(abs(w.z), 1.0 / 3.0) : (K_val * w.z + 16.0) / 116.0;
      return float3(116.0 * v.y - 16.0,
                     500.0 * (v.x - v.y),
                     200.0 * (v.y - v.z));
    }

    float3 pd80_lab_to_xyz(float3 c)
    {
      float3 v;
      v.y            = (c.x + 16.0) / 116.0;
      v.x            = c.y / 500.0 + v.y;
      v.z            = v.y - c.z / 200.0;
      return float3((v.x * v.x * v.x > E_val) ? v.x * v.x * v.x : (116.0 * v.x - 16.0) / K_val,
                    (c.x > K_val * E_val) ? v.y * v.y * v.y : c.x / K_val,
                    (v.z * v.z * v.z > E_val) ? v.z * v.z * v.z : (116.0 * v.z - 16.0) / K_val) *
                    reference_white;
    }

    float3 pd80_srgb_to_xyz(float3 c)
    {
      // Source: http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
      // sRGB to XYZ (D65) - Standard sRGB reference white ( 0.95047, 1.0, 1.08883 )
      const float3x3 mat = float3x3(
      0.4124564, 0.3575761, 0.1804375,
      0.2126729, 0.7151522, 0.0721750,
      0.0193339, 0.1191920, 0.9503041
      );
      return mul(mat, c);
    }

    float3 pd80_xyz_to_srgb(float3 c)
    {
      // Source: http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
      // XYZ to sRGB (D65) - Standard sRGB reference white ( 0.95047, 1.0, 1.08883 )
      const float3x3 mat = float3x3(
      3.2404542,-1.5371385,-0.4985314,
     -0.9692660, 1.8760108, 0.0415560,
      0.0556434,-0.2040259, 1.0572252
      );
      return mul(mat, c);
    }

    // Maximum value in LAB, B channel is pure blue with 107.8602... divide by 108 to get 0..1 range values
    // Maximum value in LAB, L channel is pure white with 100
    float3 pd80_srgb_to_lab(float3 c)
    {
      float3 lab = pd80_srgb_to_xyz(c);
      lab        = pd80_xyz_to_lab(lab);
      return lab / float3( 100.0, 108.0, 108.0 );
    }

    float3 pd80_lab_to_srgb(float3 c)
    {
      float3 rgb = pd80_lab_to_xyz(c * float3(100.0, 108.0, 108.0));
      rgb        = pd80_xyz_to_srgb(max(min(rgb, reference_white), 0.0));
      return saturate(rgb);
    }

    float3 def0_xyz_to_lms(float3 c)
    {
      // Source: https://en.wikipedia.org/wiki/LMS_color_space
      const float3x3 mat = float3x3(
      1.94735469, -1.41445123, -0.36476327,
      0.68990272,  0.34832189,  0.0,
      0.0,         0.0,         1.93485343
      );
      return mul(mat, c);
    }

    float3 def0_lms_to_xyz(float3 c)
    {
      // Source: https://en.wikipedia.org/wiki/LMS_color_space
      const float3x3 mat = float3x3(
       0.210576, 0.855098, -0.0396983,
      -0.417076, 1.17726,   0.0786283,
       0.0,      0.0,       0.516835
      );
      return mul(mat, c);
    }
