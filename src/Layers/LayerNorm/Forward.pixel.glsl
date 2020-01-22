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
	Layer normalization ---> 

	Paper: https://arxiv.org/pdf/1607.06450.pdf

	Calculates the mean and variance of the neurons, normalizes the input 
	and transforms is back using trainable parameters to model space.
*/

// Define constants
#define TEX_INPUT 0
#define TEX_MEANVARIANCE 1
#define TEX_WEIGHTS 2

#define EPSILON 1e-08

uniform int uUseMovingAverage;

layout (location = 0) out float fragNeuron;
layout (location = 1) out float fragXhat;
void main()
{
	ivec2 xy = ivec2(gl_FragCoord.xy);

	vec4 meanvar = texelFetch(sTD2DInputs[TEX_MEANVARIANCE], ivec2(xy.x, 0), 0);

	float x = texelFetch(sTD2DInputs[TEX_INPUT], xy, 0).x;
	float xhat = (x-meanvar.x)*inversesqrt(meanvar.y + EPSILON);

	float w = texelFetch(sTD2DInputs[TEX_WEIGHTS], ivec2(0, xy.y), 0).r; // weights, gamma 
	float b = texelFetch(sTD2DInputs[TEX_WEIGHTS], ivec2(1, xy.y), 0).r; // bias, beta

	fragNeuron = w*xhat + b;
	fragXhat = xhat;
}