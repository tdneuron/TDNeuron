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

	Calculates the gradient of the cross entropy with respect to the input
*/

#define TEX_INPUT 0
#define TEX_GROUNDTRUTH 1

#define EPSILON 1e-11

out float fragGradient;

void main()
{
	vec2 uv = vUV.st;
	vec2 res = uTDOutputInfo.res.zw;
	ivec2 xy = ivec2(uv * res);

	float samples = uTD2DInfos[TEX_INPUT].res.z; // Fetch amount of samples
	// Clamping with epsilon to make sure no division by 0 occurs
	float prediction = texelFetch(sTD2DInputs[TEX_INPUT], xy, 0).x;
	float groundTruth = texelFetch(sTD2DInputs[TEX_GROUNDTRUTH], xy, 0).x;

	float gradient = -groundTruth/max(prediction,EPSILON) + (1-groundTruth)/max(1-prediction, EPSILON);
	fragGradient = gradient/samples;
}