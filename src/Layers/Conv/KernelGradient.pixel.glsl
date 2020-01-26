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
    1D or 2D Convolution backward <---
    
    Computes the gradient with respect to the kernels
*/


#define TEX_INPUT 0
#define TEX_GRADIENT 1

uniform int uKernels;
uniform int uKernelSize;
uniform int uStride;
uniform int uPadding;
uniform int uInputMaps;
uniform int uConv2d;

out float fragNeuron;

void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value

#if TD_NUM_3D_INPUTS > 0
    float z = 0;

    int samples = int(uConv2d > 0?uTD3DInfos[TEX_INPUT].depth.y / uInputMaps:uTD3DInfos[TEX_INPUT].res.z);
    int outputDepth = int(uTDOutputInfo.depth.y);

    int currentInputKernel = int(uTDCurrentDepth);
    int currentOutputKernel = int(xy.y / (uConv2d > 0?uKernelSize:1));
    int gradientIndex = TD_NUM_3D_INPUTS-1;
    int gradientSize = int(uTD3DInfos[gradientIndex].res.w);

    int iterations = gradientSize;
    if (uConv2d > 0) {
        xy.y = xy.y%gradientSize;
        iterations *= gradientSize;
    }
    for (int smpl = 0; smpl < samples; smpl++) {
        for (int iter = 0; iter < iterations; iter++) {
            int x = int(uConv2d > 0?iter/gradientSize:smpl), y = iter % gradientSize;
            float bias = (1-step(1,currentInputKernel))*(uConv2d > 0?1:1);

            float neuronGradient = texelFetch(sTD3DInputs[gradientIndex], ivec3(x, y, currentOutputKernel + uConv2d*smpl*uKernels), 0).x;
            ivec2 inputXY = (uConv2d > 0?(xy-uPadding)*uStride+ivec2(x,y):ivec2(smpl, (xy.x-uPadding)*uStride+y));
            #if TD_NUM_3D_INPUTS > 1
            float neuronInput = (xy.x < uKernelSize?texelFetch(sTD3DInputs[TEX_INPUT], ivec3(inputXY, currentInputKernel + uConv2d*smpl*uInputMaps), 0).x:bias);
            #else
            float neuronInput = (xy.x < uKernelSize?texelFetch(sTD2DInputs[0], inputXY, 0).x:bias);
            #endif
            z += neuronGradient * neuronInput;
        }
    }

    fragNeuron = z;
#else
    fragNeuron = 0;
#endif
}
