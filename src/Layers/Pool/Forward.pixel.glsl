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

uniform int uKernelSize;
uniform int uType;
uniform int uStride;
uniform int uPadding;
uniform int uConv2d;

out float fragNeuron;
void main()
{
    vec2 uv = vUV.st;
    vec2 res = uTDOutputInfo.res.zw;
    ivec2 xy = ivec2(uv * res);
    float currentDepth = uTDCurrentDepth;
    float maxNeuron = -1e8, totalNeuron = 0;
    
    int iterations = uKernelSize * ((1-uConv2d) + uKernelSize*uConv2d);
    xy -= uPadding*ivec2(uConv2d, 1);
    for (int iter = 0; iter < iterations; iter++) {
        int x = int(iter/uKernelSize), y = iter % uKernelSize;
        ivec2 inputXY = (uConv2d > 0?xy*uStride+ivec2(x,y):ivec2(xy.x, xy.y*uStride+iter));
#if TD_NUM_3D_INPUTS > 0
        float neuronInput = texelFetch(sTD3DInputs[TEX_INPUT], ivec3(inputXY, currentDepth), 0).x;
#else
        float neuronInput = texelFetch(sTD2DInputs[TEX_INPUT], ivec2(inputXY), 0).x;
#endif
        totalNeuron += neuronInput;
        maxNeuron = max(maxNeuron, neuronInput);
    }
    totalNeuron /= iterations;
    fragNeuron = mix(maxNeuron, totalNeuron, uType);
}