/*__________________________________________________________________

TDNeuron (c) by Tim Gerritsen and Darien Brito 
<tim@yfxlab.com> <info@darienbrito.com>

TDNeuron is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

TDNeuron is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
____________________________________________________________________*/

/*
    1D or 2D Convolution forward ---> 
    
    Computes a 1D or 2D convolution over the input
*/

#if TD_NUM_3D_INPUTS > 1
#define TEX_INPUT 0
#define TEX_KERNELS 1
#else
#define TEX_INPUT 0
#define TEX_KERNELS 0
#endif

uniform int uKernels;
uniform int uKernelSize;
uniform int uStride;
uniform int uPadding;
uniform int uConv2d;

out float fragNeuron;
void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value
    

#if TD_NUM_3D_INPUTS > 1 // Checking if input is a texture3D
    int miniBatchSize = (1-uConv2d)+uConv2d*int(uTDOutputInfo.depth.y / uKernels);
    int inputMaps = int(uTD3DInfos[TEX_INPUT].depth.y / miniBatchSize);
#else
    int inputMaps = 1;
#endif
    int outputDepth = int(uTDOutputInfo.depth.y);
    int kernels = (uConv2d > 0?uKernels:1);
    int kernelOffset = int(uTDCurrentDepth % kernels) * uKernelSize;
    int smpl = (uConv2d > 0?int(uTDCurrentDepth / kernels):xy.x);
    int kernel = uTDCurrentDepth % kernels;

    xy -= uPadding*ivec2(uConv2d, 1);
    
    float result = 0.0;

    // Set the iterations depending on if we are handing a 1d or 2d convolution (N vs NxN)
    int iterations = uKernelSize * ((1-uConv2d) + uKernelSize*uConv2d);

    for (int z = 0; z < inputMaps; z++) { // Looping through all the input maps
        for (int iter = 0; iter < iterations; iter++) {
            int x = int(uConv2d > 0?iter/uKernelSize:iter); // Setting x,y depending on 1d/2d conv
            int y = int(uConv2d > 0?(iter % uKernelSize):uTDCurrentDepth);

            float kernel = texelFetch(sTD3DInputs[TEX_KERNELS], ivec3(x, y + kernelOffset, z), 0).x;
            ivec2 inputXY = (uConv2d > 0?ivec2(xy*uStride+vec2(x,y)):ivec2(smpl, xy.y*uStride+iter));
#if TD_NUM_3D_INPUTS > 1
            float i = texelFetch(sTD3DInputs[TEX_INPUT], ivec3(inputXY, z + uConv2d*smpl*inputMaps), 0).x;
#else
            float i = texelFetch(sTD2DInputs[TEX_INPUT], ivec2(inputXY), 0).x;
#endif

            result += kernel * i;
        }
    }
    // Add bias
    result += texelFetch(sTD3DInputs[TEX_KERNELS], ivec3(uKernelSize, uTDCurrentDepth % kernels, 0), 0).x; 

    fragNeuron = result;
}