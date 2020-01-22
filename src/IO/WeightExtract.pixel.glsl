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

#define TEX_MODEL 0

uniform int uLayer;

ivec2 IndexToXY(int index)
{
	vec2 res = uTD2DInfos[TEX_MODEL].res.zw;
	return ivec2(index % int(res.x), index / res.x);
}

vec4 Tex(int index)
{
	return texelFetch(sTD2DInputs[TEX_MODEL], IndexToXY(index), 0);
}

out vec4 fragData;
void main()
{
	vec2 uv = vUV.st;
	vec2 res = uTDOutputInfo.res.zw;
	ivec2 xy = ivec2(uv * res);
	int index = xy.x + xy.y*int(res.x);

	vec4 data = Tex(0);
	int layers = int(data.x + data.y);
	if (uLayer >= layers) {
		fragData = vec4(0);
		return;
	}

	int layer = uLayer;
	data = Tex(layer+1);
	int offset = int(data.a);

	if (uTDOutputInfo.depth.y > 1) {
		offset += int(uTDCurrentDepth * res.x*res.y);
	}

	fragData = Tex(index + offset + layers + 1);
}
