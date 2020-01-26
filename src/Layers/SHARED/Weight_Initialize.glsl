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

#define PI 3.1415926536

#define INIT_RANDOM 0 // Uniformly random initialization
#define INIT_GAUSS 1 // Gaussian random initialization
#define INIT_XAVIER 2 // Distribution based on xavier (http://proceedings.mlr.press/v9/glorot10a/glorot10a.pdf)
#define INIT_CONSTANT 3 // Sets weights to a constant value for all neurons

uniform vec4 uWeightInit; // Weight initialization (min, max, type (gaussian, xavier), xavier parameter)
uniform float uBiasInit; // Bias initialization (commonly 0, 1 in LSTMs)
uniform int uSeed; // Random seed to generate the weights

// Create unsigned random values with a seed
float Hash(vec3 st) { return fract(sin(dot(st, vec3(12.9898, 78.233,543.63466))) * 43578.5453); }
#define STD(x) sqrt(-2*log(x+1e-08))*sin(x*2*PI)

float InitializeWeight(ivec3 xyz)
{
	vec2 res = uTDOutputInfo.res.zw;
	int initializationType = int(uWeightInit.z);
	int inputNeurons = int(res.x - 1);
	int outputNeurons = int(res.y);
	ivec2 xy = xyz.xy;
	int depth = xyz.z;
	bool bias = (xy.x == inputNeurons);

	/////////////////////////////////////////////////////////
	// INITIALIZE WEIGHTS to XAVIER, CONSTANT or RANDOM modes
	//////////////////////////////////////////////////////////

	float weight = 0.0; 
	float r = Hash(vec3(xy / res, depth) - uSeed);
	if (initializationType == INIT_RANDOM) {
		weight = r*(uWeightInit.y - uWeightInit.x) + uWeightInit.x;
	} else if (initializationType == INIT_GAUSS) {
		weight = STD(r)*(uWeightInit.y - uWeightInit.x)*0.5;
	} else if (initializationType == INIT_CONSTANT) {
		weight = (uWeightInit.x + uWeightInit.y)*0.5; // Take the average of the boundaries
	} else if (initializationType == INIT_XAVIER) {
		weight = (r*2.0-1.0)*sqrt(6./(inputNeurons+outputNeurons));
	}
	
	// Check if pixel is weight or bias and output accordingly
	return (!bias ? weight : uBiasInit);
}
