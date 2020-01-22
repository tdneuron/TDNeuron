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
	Texture3D slice select and grid viewer
*/

uniform int uShowGrid;
uniform int uIndex;
uniform ivec2 uResolution;
uniform float uIntensity;
uniform int uChannel;
uniform vec3 uColorPos;
uniform vec3 uColorNeg;

out vec4 fragColor;
void main()
{
	vec2 uv = vUV.st;

	vec3 uvp = vec3(0);
	if (uShowGrid > 0) {
		vec2 res = uTDOutputInfo.res.zw;
		uv.y = 1-uv.y; // Reverse order

		ivec2 xy = ivec2(uv * res);
		ivec2 gridXY = ivec2(floor(uv * uResolution));
		int depthIndex = gridXY.x + gridXY.y*uResolution.x;

		uv.y = 1-uv.y; // Flipping back to make proper local UVs
		vec2 localUV = fract(uv * uResolution);
#if TD_NUM_3D_INPUTS > 0
		uvp = vec3(localUV, (depthIndex+0.5)/uTD3DInfos[0].depth.y);
	} else {
		uvp = vec3(uv, (uIndex+0.5)*uTD3DInfos[0].depth.x);
	}
    vec4 color = texture(sTD3DInputs[0], uvp);
#else
	}
    vec4 color = texture(sTD2DInputs[0], uv);
#endif

	if (uChannel > 0) {
		float v = color.r*float(uChannel == 1)+color.g*float(uChannel == 2)+color.b*float(uChannel == 3)+color.a*float(uChannel == 4);
		color = vec4(max(v,0)*uColorPos + max(-v,0)*uColorNeg, 1);
	}
    fragColor = TDOutputSwizzle(color * uIntensity);
}