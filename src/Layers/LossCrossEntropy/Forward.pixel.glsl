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
	Cross entropy (forward) --->

	Calculates the cross entropy of the samples
*/

#define TEX_PREDICTION 0
#define TEX_GROUNDTRUTH 1

#define EPSILON 1e-11

out float fragNeuron;
void main()
{
	vec2 uv = vUV.st;
	vec2 res = uTDOutputInfo.res.zw;
	ivec2 xy = ivec2(uv * res);

	int samples = int(uTD2DInfos[TEX_GROUNDTRUTH].res.z); // Fetch amount of samples		
	int neurons = int(uTD2DInfos[TEX_PREDICTION].res.w); // Fetch amount of neurons
	float cost = 0.0;

	for (int i = 0; i < neurons; i++) {
		float yhat = texelFetch(sTD2DInputs[TEX_PREDICTION], ivec2(xy.x, i), 0).x;
		float y = texelFetch(sTD2DInputs[TEX_GROUNDTRUTH], ivec2(xy.x, i), 0).x;

		// Clamping with epsilon to make sure no log(0) occurs
		cost +=  y*log(max(yhat,EPSILON)) + (1-y)*log(max(1-yhat, EPSILON));
	}
	fragNeuron = -cost/samples;
}