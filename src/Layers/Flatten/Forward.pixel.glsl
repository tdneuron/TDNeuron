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

#define TEX_INPUT 0

uniform int uConv2d;

out float fragNeuron;
void main()
{
    vec2 uv = vUV.st;
    vec2 res = uTDOutputInfo.res.zw;
#if TD_NUM_3D_INPUTS == 1
    ivec2 xy = ivec2(res * uv);
    vec2 inputRes = uTD3DInfos[TEX_INPUT].res.zw;
    int mapSize = int(inputRes.x);
    int mapSize2 = mapSize*mapSize;
    int inputMaps = int(uTD3DInfos[TEX_INPUT].depth.y);

    ivec3 xyz = ivec3(xy.x, xy.y % int(inputRes.y), xy.y / inputRes.y);
	if (uConv2d > 0) {
    	int o = xy.y % mapSize2;
    	xyz = ivec3(o % mapSize, o / mapSize, xy.y / mapSize2 + res.y / mapSize2 * xy.x);
    }
    fragNeuron = texelFetch(sTD3DInputs[TEX_INPUT], xyz, 0).x;
#else
    fragNeuron = 0;
#endif
}