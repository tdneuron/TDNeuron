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
    Linear backward (derivatives of weights) <--- 
    
    Computes the partial derivatives of the dot product plus bias of two input textures: dW = dZ * a.T 
*/

#define TEX_GRADIENT 0
#define TEX_INPUT 1

out float fragNeuron;

void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value
    float z = 0.0; // The pixel to store our hand made dot product
    int inputNeurons = int(res.x - 1); // Fetch input neurons (width - bias)
    int samples = int(uTD2DInfos[TEX_INPUT].res.z); // Fetch amount of samples

    bool bias = (xy.x == inputNeurons); // Is current pixel the bias?
    for(int i = 0; i < samples; i++) {
        float x = (!bias ? texelFetch(sTD2DInputs[TEX_INPUT], ivec2(i, xy.x), 0).r : 1); // (transpose) point to right column
        float gradient = texelFetch(sTD2DInputs[TEX_GRADIENT], ivec2(i, xy.y), 0).r; // point to right row
    	z += x * gradient; 
    }

    // Output derivate of weights:
	fragNeuron = z;
}