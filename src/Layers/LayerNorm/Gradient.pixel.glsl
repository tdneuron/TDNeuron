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
    Layer normalization (backprop) <--- 

    Computes the partial derivative of the layer normalization with respect 
    to the input x.
*/

#define TEX_WEIGHTS 0
#define TEX_MEAN 1
#define TEX_XHAT 2
#define TEX_GRADIENT 3

#define EPSILON 1e-08

out float fragNeuron;

void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value
    int neurons = int(res.y);

    float gamma = texelFetch(sTD2DInputs[TEX_WEIGHTS], ivec2(0, xy.y), 0).r; // weights, gamma 
    float sumGradient = 0, sumXhat = 0;
    float gradient = 0, xhat = 0;
    for (int i = 0; i < neurons; i++) {
        float g = texelFetch(sTD2DInputs[TEX_GRADIENT], ivec2(xy.x, i), 0).r;
        float x = texelFetch(sTD2DInputs[TEX_XHAT], ivec2(xy.x, i), 0).r;
        sumGradient += g*gamma;
        sumXhat += g*gamma*x;
        if (i == xy.y) {
            gradient = g*gamma;
            xhat = x;
        }
    }
    float variance = texelFetch(sTD2DInputs[TEX_MEAN], ivec2(xy.x, 0), 0).y;
    float demon = sqrt(variance + EPSILON)*neurons;

    fragNeuron = (gradient*neurons-sumGradient-sumXhat*xhat) / demon;
}