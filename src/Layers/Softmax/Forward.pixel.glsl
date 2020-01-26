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
	Softmax function ---> 

	Calculates the softmax of the neurons
*/

// Define constants
#define TEX_INPUT 0
#define TEX_MAXIMA  1

#define EPSILON 1e-11

out float fragNeuron;
void main()
{
	vec2 uv = vUV.st;
	vec2 res = uTDOutputInfo.res.zw;
	ivec2 xy = ivec2(uv * res);

	float e = 0;
	float ev = 0;
	int neurons = int(uTD2DInfos[TEX_INPUT].res.w);
	float m = texelFetch(sTD2DInputs[TEX_MAXIMA], ivec2(xy.x, 0), 0).x;
	for (int i = 0; i < neurons; i++) {
		float p = texelFetch(sTD2DInputs[TEX_INPUT], ivec2(xy.x, i), 0).x;
		p -= m; // Shift weights so that maximum number is 0
		float v = exp(p);
		ev += v;
		if (i == xy.y) {
			e = v;
		}
	}
	fragNeuron = e/ev;
}
