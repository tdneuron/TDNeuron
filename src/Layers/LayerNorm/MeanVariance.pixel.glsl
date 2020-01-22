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
    Calculates the variance of the input and mean.
*/

#define TEX_INPUT 0
#define TEX_MEAN 1

// Set the compute space
layout (location = 0) out vec2 fragData;

void main()
{
	ivec2 xy = ivec2(gl_FragCoord.xy); // Fetch current shader instance
	vec2 res = uTDOutputInfo.res.zw; // Size of weight (input neurons, output neurons)

	float mean = texelFetch(sTD2DInputs[TEX_MEAN], ivec2(xy.x, 0), 0).x;
    float mean2 = mean*mean;

    float variance = 0;
    int neurons = int(uTD2DInfos[TEX_INPUT].res.w);
    for (int i = 0; i < neurons; i++) {
        float x = texelFetch(sTD2DInputs[TEX_INPUT], ivec2(xy.x, i), 0).x;
        variance += x*x - 2*mean*x + mean2;
    }
    fragData = vec2(mean, variance/float(neurons));
}