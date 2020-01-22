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
	Generates and optimizes 1D or 2D kernels used for convolutional layers
*/

#define TEX_UPDATE 0
#define TEX_INIT 1

uniform int uIteration; // Current iteration (epoch*MinibatchSize + minibatch)
uniform int uReset; // Reset all weights
uniform int uUpdate; // Samples from update texture to add to the weights
uniform int uInitialSnap; // When set, initial weights are loaded

#include <Weight_Initialize>
#include <Weight_Optimize>

// Set the compute space
layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

void main()
{
	ivec2 xy = ivec2(gl_GlobalInvocationID.xy); // Fetch current shader instance
	vec2 res = uTDOutputInfo.res.zw; // Size of weight (input neurons, output neurons)
	int depth = int(uTDOutputInfo.depth.y);
	ivec3 xyz = ivec3(xy, gl_GlobalInvocationID.z-1);

	if (xy.x >= res.x || xy.y >= res.y) { // In case we have more instances than pixels, return
		return;
	}

	if (xyz.z >= depth) {
		return;
	}

	// Determine if current pixel corresponds to bias
	bool bias = (xy.x == res.x - 1);

	// Initialize variables to store weights and optimization values
	float weight = 0, velocity = 0, rmsprop = 0;


	//////////////////////////////
	// RESET OR UPDATE
	//////////////////////////////

	if (uInitialSnap > 0) {
		#if TD_NUM_3D_INPUTS > 1
			vec4 data = texelFetch(sTD3DInputs[TEX_INIT], xyz, 0);
		#else
			vec4 data = texelFetch(sTD2DInputs[0], xy, 0);
		#endif
		weight = data.x;
		velocity = data.y;
		rmsprop = data.z;
	} else if (uReset > 0) { 
		weight = InitializeWeight(xyz);
			// In this case we leave velocity and rmsprop values to 0
	} else {
		vec3 currentWeight = imageLoad(sTDComputeOutputs[0], xyz).rgb;
		weight = currentWeight.r; // weight is stored in the 'r' channel
		velocity = currentWeight.g; // Velocity and rmsprop are saved in the 'g' and 'b' channels
		rmsprop = currentWeight.b;  // of the weight map.
	}

	//////////////////////////////
	// UPDATE VALUES STAGE
	//////////////////////////////

	#if TD_NUM_3D_INPUTS > 0
	if (uUpdate > 0) { // If the update flag is on, we need to fetch the input
		float weightUpdate = texelFetch(sTD3DInputs[TEX_UPDATE], xyz, 0).x;
		weight = Optimize(weightUpdate, weight, velocity, rmsprop, !bias);
	}
	#endif

	// Store our data
    imageStore(sTDComputeOutputs[0], xyz, vec4(weight,velocity,rmsprop,0));
}