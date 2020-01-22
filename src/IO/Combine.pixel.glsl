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
	TODO: Needs comments
*/

#define VERSION 1

struct Weights
{
	ivec2 resolution;
	int depth;
	int offset;
};

vec3 GetResolution(int index)
{
#if TD_NUM_3D_INPUTS > 0
	return (index < TD_NUM_3D_INPUTS)?vec3(uTD3DInfos[index].res.zw,uTD3DInfos[index].depth.y):vec3(uTD2DInfos[index - TD_NUM_3D_INPUTS].res.zw, 1);
#else
	return vec3(uTD2DInfos[index].res.zw, 1);
#endif
}

Weights LoadWeights(int index)
{
	Weights w;
	vec3 res = GetResolution(index);
	w.resolution = ivec2(res.xy);
	w.depth = int(res.z);

	int total = 0;
	for (int i = 0; i < index; i++) {
		vec3 weightRes = GetResolution(i);
		total += int(weightRes.x*weightRes.y*weightRes.z);
	}
	w.offset = total;
	return w;
}

vec4 LoadData(int index)
{
	vec4 data = vec4(0);
	int total = 0;
	int inputs = TD_NUM_3D_INPUTS+TD_NUM_2D_INPUTS;
	for (int i = 0; i < inputs; i++) {
		vec3 weightRes = GetResolution(i);
		int weights = int(weightRes.x*weightRes.y*weightRes.z);
		total += weights;
		if (total > index) {
			index -= total-weights;
#if TD_NUM_3D_INPUTS > 0
			if (i < TD_NUM_3D_INPUTS) {
				int localIndex = index % int(weightRes.x*weightRes.y);
				int slice = index / int(weightRes.x*weightRes.y);
				data = texelFetch(sTD3DInputs[i], ivec3(localIndex % int(weightRes.x), localIndex / weightRes.x, slice), 0);
			} else {
#endif
				data = texelFetch(sTD2DInputs[i-TD_NUM_3D_INPUTS], ivec2(index % int(weightRes.x), index / weightRes.x), 0);
#if TD_NUM_3D_INPUTS > 0
			}
#endif
			break;
		}
	}
	return data;
}

out vec4 fragData;
void main()
{
	vec2 uv = vUV.st;
	vec2 res = uTDOutputInfo.res.zw;
	ivec2 xy = ivec2(uv * res);
	int index = xy.x + xy.y*int(res.x);

	vec4 data = vec4(0);
	int inputs = TD_NUM_2D_INPUTS + TD_NUM_3D_INPUTS;
	int headerSize = (inputs + 1);
	if (index < 1) {
		data = vec4(TD_NUM_3D_INPUTS,TD_NUM_2D_INPUTS,0,VERSION);
	} else if (index < headerSize) {
		Weights w = LoadWeights(index - 1);
		data = vec4(w.resolution, w.depth, w.offset);
	} else {
		data = LoadData(index - headerSize);
	}
	fragData = data;
}