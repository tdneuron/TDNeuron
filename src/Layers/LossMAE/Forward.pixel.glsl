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
	MAE (forward) -->

	Calculates the mean absolute error of the samples
*/

#define TEX_PREDICTION 0
#define TEX_GROUNDTRUTH 1

out float fragNeuron;
void main()
{
	vec2 uv = vUV.st;
	vec2 res = uTDOutputInfo.res.zw;
	ivec2 xy = ivec2(uv * res);

	float loss = 0.0;
#if TD_NUM_3D_INPUTS > 0
	int samples = int(uTD3DInfos[TEX_GROUNDTRUTH].res.z); // Fetch amount of samples		
	int neurons = int(uTD3DInfos[TEX_PREDICTION].res.w); // Fetch amount of neurons
	for (int x = 0; x < neurons; x++) {
		for (int y = 0; y < neurons; y++) {
			float groundTruth = texelFetch(sTD3DInputs[TEX_GROUNDTRUTH], ivec3(x, y, uTDCurrentDepth), 0).x;
			float prediction = texelFetch(sTD3DInputs[TEX_PREDICTION], ivec3(x, y, uTDCurrentDepth), 0).x;
			loss += abs(groundTruth - prediction);
		}
	}
#else
	int samples = int(uTD2DInfos[TEX_GROUNDTRUTH].res.z); // Fetch amount of samples		
	int neurons = int(uTD2DInfos[TEX_PREDICTION].res.w); // Fetch amount of neurons
	for (int i = 0; i < neurons; i++) {
		float groundTruth = texelFetch(sTD2DInputs[TEX_GROUNDTRUTH], ivec2(xy.x, i), 0).x;
		float prediction = texelFetch(sTD2DInputs[TEX_PREDICTION], ivec2(xy.x, i), 0).x;
		loss += abs(groundTruth - prediction);
	}
#endif		
	fragNeuron = loss/samples;
}