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
	Activation function ---> 

	Performs g(Z), the activation part of gradient descent.
*/

uniform float uActivationFunction;
uniform float uLeakyness;

// Define constants
#define TEX_INPUT 0

#define ACTIVATION_LINEAR 0
#define ACTIVATION_SIGMOID 1
#define ACTIVATION_TANH 2
#define ACTIVATION_RELU 3
#define ACTIVATION_LRELU 4
#define ACTIVATION_SWISH 5
#define ACTIVATION_SOFTPLUS 6

// Activation functions
#define sigmoid(z) 	1.0 / (1.0 + exp(-z))
#define relu(z,x) 	mix(z*x, z, step(0,z))

// Apply activation function
float ApplyActivation(float z) 
{
	float activation = 0;
	if (uActivationFunction == ACTIVATION_LINEAR) {
		activation = z;
	} else if(uActivationFunction == ACTIVATION_SIGMOID) {
		activation = sigmoid(z);
	} else if (uActivationFunction == ACTIVATION_TANH) {
		activation = tanh(z);
	} else if (uActivationFunction == ACTIVATION_RELU || uActivationFunction == ACTIVATION_LRELU) {
		activation = relu(z, uLeakyness*int(uActivationFunction == ACTIVATION_LRELU));
	} else if (uActivationFunction == ACTIVATION_SWISH) {
		activation = z*sigmoid(z);
	} else if (uActivationFunction == ACTIVATION_SOFTPLUS) {
		activation = log(1+exp(z));
	} 
	return activation;
}

out float fragNeuron;

void main()
{
	vec2 uv = vUV.st; // Get coordinate
	vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value
	
	float z = 0;
	// Apply an activation function
#if TD_NUM_3D_INPUTS == 1
	z = texelFetch(sTD3DInputs[TEX_INPUT], ivec3(xy, uTDCurrentDepth), 0).x;
#else
	z = texelFetch(sTD2DInputs[TEX_INPUT], xy, 0).x;
#endif
    fragNeuron = ApplyActivation(z);
}