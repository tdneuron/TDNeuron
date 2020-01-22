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
    Linear forward ---> 
    
    Computes the dot product plus bias of two input textures: Z = WX + b
*/

#define TEX_INPUT 0
#define TEX_WEIGHTS 1

out float fragNeuron;
void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value
    float z = 0.0; // The pixel to store our hand made dot product
    int inputNeurons = int(uTD2DInfos[TEX_INPUT].res.w); // Amount of input neurons
    
    for(int i = 0; i < inputNeurons; i++) {
    	float a = texelFetch(sTD2DInputs[TEX_INPUT], ivec2(xy.x, i), 0).r; // point to right row
    	float w = texelFetch(sTD2DInputs[TEX_WEIGHTS], ivec2(i, xy.y), 0).r; // point to right column
    	z += a * w; 
    }

	// Add bias
	z += texelFetch(sTD2DInputs[TEX_WEIGHTS], ivec2(inputNeurons, xy.y), 0).r; // Grab bias from last column

	fragNeuron = z;
}
