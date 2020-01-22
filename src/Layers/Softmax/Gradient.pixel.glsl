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
	Softmax (backprop) <---
	
	Computes the backprogragation of the softmax function
	S(i) = gradient * S(i)*(kroneckerDelta - S(j))
*/

#define TEX_OUTPUT 0
#define TEX_GRADIENT 1

out float fragGradient;
void main()
{
	vec2 uv = vUV.st;
	vec2 res = uTDOutputInfo.res.zw;
	ivec2 xy = ivec2(uv * res);

	int neurons = int(res.y);
	float local = 0;
	float Si = texelFetch(sTD2DInputs[TEX_OUTPUT], xy, 0).x;
	for (int i = 0; i < neurons; i++) {
		float gradient = texelFetch(sTD2DInputs[TEX_GRADIENT], ivec2(xy.x, i), 0).x;
		float Sj = texelFetch(sTD2DInputs[TEX_OUTPUT], ivec2(xy.x, i), 0).x;
		
		int kroneckerDelta = int(i == xy.y);
		local += gradient * Si*(kroneckerDelta - Sj);
	}

	fragGradient = local;
}