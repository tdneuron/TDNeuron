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
    
    Computes the gradient with respect to the input
*/
#define TEX_KERNELS 0
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

#if TD_NUM_3D_INPUTS > 1
    int minibatchSample = uTDCurrentDepth / uInputMaps;
    int smpl = xy.x;

    if (uConv2d > 0) {
        xy -= uPadding + uKernelSize - 1;
    } else {
        xy.y -= uPadding + uKernelSize - 1;
    }

    float activation = 0;
    int iterations = uKernelSize * ((1-uConv2d) + uKernelSize*uConv2d);
    for (int z = 0; z < uKernels; z++) {
        for (int iter = 0; iter < iterations; iter++) {
            int x = int(uConv2d > 0?iter/uKernelSize:iter), y = iter % uKernelSize;
            ivec2 rotatedKernelXY = (uConv2d > 0?ivec2(vec2(uKernelSize - x - 1, uKernelSize - y - 1 + z*uKernelSize)):ivec2(uKernelSize - x - 1,z));
            ivec2 gradientXY = (uConv2d > 0?ivec2(floor(xy/uStride)+vec2(x,y)):ivec2(smpl,xy.y*uStride+x));

            float kernel = texelFetch(sTD3DInputs[TEX_KERNELS], ivec3(rotatedKernelXY, int(uConv2d > 0?uTDCurrentDepth % uInputMaps:uTDCurrentDepth)), 0).x;
            float gradient = texelFetch(sTD3DInputs[TEX_GRADIENT], ivec3(gradientXY, z + uConv2d * minibatchSample * uKernels), 0).x;
            activation += kernel * gradient;
        }
    }
    fragNeuron = activation;
#else
    fragNeuron = 0;
#endif
}