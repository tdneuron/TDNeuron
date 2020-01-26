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
    Linear backward (derivatives) <--- 

    Computes the dot product of two input textures: dA = W.T * dZ 
*/

#define TEX_WEIGHTS 0
#define TEX_GRADIENT 1

out float fragNeuron;

void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value
    float z = 0.0; // The pixel to store our hand made dot product
    int outputNeurons = int(uTD2DInfos[TEX_WEIGHTS].res.w);

    for(int i = 0; i < outputNeurons; i++) {
    	float weight = texelFetch(sTD2DInputs[TEX_WEIGHTS], ivec2(xy.y, i), 0).r; // (transposed) point to right row
    	float gradient = texelFetch(sTD2DInputs[TEX_GRADIENT], ivec2(xy.x, i), 0).r; // point to right column
    	z += weight * gradient; 
    }

    // Output dot product
    fragNeuron = z;
    
}
