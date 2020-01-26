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
#define TEX_GRADIENT 0

uniform int uConv2d;

out float fragNeuron;

void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value

#if TD_NUM_2D_INPUTS == 1
	int minibatchSize = int(uTD2DInfos[TEX_GRADIENT].res.z);
    int maps = int(uTDOutputInfo.depth.y / minibatchSize);
    int d = uTDCurrentDepth % maps;

    int index = (uConv2d > 0?int(xy.x + xy.y*res.y + (uTDCurrentDepth % maps)*res.y*res.y):int(xy.y + (uTDCurrentDepth * res.y)));
    ivec2 gradientXY = ivec2((uConv2d > 0?uTDCurrentDepth / maps:xy.x), index);
    fragNeuron = texelFetch(sTD2DInputs[TEX_GRADIENT], gradientXY, 0).x;
#else
    fragNeuron = 0;
#endif
}