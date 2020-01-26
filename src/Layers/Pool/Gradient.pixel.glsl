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

#define TEX_INPUT 0
#define TEX_GRADIENT 1

#define TYPE_MAX 0
#define TYPE_AVERAGE 1

uniform int uType;
uniform int uStride;
uniform int uKernelSize;
uniform int uPadding;
uniform int uConv2d;

out float fragNeuron;

void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value

#if TD_NUM_3D_INPUTS > 1
	float maxNeuron = -1e8, totalNeuron = 0;
	float currentDepth = uTDCurrentDepth;

	ivec2 gradientXY = ivec2((xy - uPadding)/uStride);
	if (uConv2d == 0) {
		gradientXY.x = xy.x;
	}
	float gradient = texelFetch(sTD3DInputs[TEX_GRADIENT], ivec3(gradientXY, currentDepth), 0).x;

	int isMax = 0;
	ivec2 p = ivec2(floor(xy/uStride)*uStride - uPadding);
	int index = int(floor(xy.y/uStride)*uStride - uPadding);

    int iterations = uKernelSize * ((1-uConv2d) + uKernelSize*uConv2d);
    for (int iter = 0; iter < iterations; iter++) {
        int x = int(iter/uKernelSize), y = iter % uKernelSize;
        ivec2 inputXY = (uConv2d > 0?p+ivec2(x,y):ivec2(xy.x, p.y+iter));
       	float neuronInput = texelFetch(sTD3DInputs[TEX_INPUT], ivec3(inputXY, currentDepth), 0).x;
       	totalNeuron += neuronInput;
        if (neuronInput > maxNeuron) {
	       	maxNeuron = max(maxNeuron, neuronInput);
    	   	isMax = (uConv2d > 0?int(p.x+x == xy.x && p.y+y == xy.y):int(p.y+x == xy.y));
        }
    }
	fragNeuron = mix(isMax, 1.0/(iterations), uType) * gradient;
#else
	fragNeuron = 0;
#endif
}