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
	Derivative of activation function <--- 

	Performs gPrime(Z): the derivative of the activation part of gradient descent
	in backward propagation
*/

#define TEX_FORWARD_IN 0
#define TEX_FORWARD_OUT 1
#define TEX_GRADIENT 2

#define ACTIVATION_LINEAR 0
#define ACTIVATION_SIGMOID 1
#define ACTIVATION_TANH 2
#define ACTIVATION_RELU 3
#define ACTIVATION_LRELU 4
#define ACTIVATION_SWISH 5
#define ACTIVATION_SOFTPLUS 6

uniform float uActivationFunction;
uniform float uLeakyness;

// Define derivatives calculation functions
#define Sigmoid(x) 		(1/(1+exp(-x)))
#define dSigmoid(z) 	(z*(1.0-z))
#define dTanh(z) 		(1.0-z*z)
#define dRelu(z,l) 		(mix(l,1.0,step(0.0,z)))
#define dSwish(x,y) 	(y+Sigmoid(x)*(1.0-y))
#define dSoftplus(z)	(exp(z)/(1+exp(z)))

float CalculateLocalGradient(float layerInput, float layerOutput) 
{
	float localGradient = 0;
	if (uActivationFunction == ACTIVATION_LINEAR) {
		localGradient = 1;
	} else if(uActivationFunction == ACTIVATION_SIGMOID) {
		localGradient = dSigmoid(layerOutput);
	} else if (uActivationFunction == ACTIVATION_TANH) {
		localGradient = dTanh(layerOutput);
	} else if (uActivationFunction == ACTIVATION_RELU || uActivationFunction == ACTIVATION_LRELU) {
		localGradient = dRelu(layerInput, uLeakyness*int(uActivationFunction == ACTIVATION_LRELU));
	} else if (uActivationFunction == ACTIVATION_SWISH) {
		localGradient = dSwish(layerInput, layerOutput);
	} else if (uActivationFunction == ACTIVATION_SOFTPLUS) {
		localGradient = dSoftplus(layerInput);
	}
	return localGradient;
}

out float fragNeuron;

void main()
{
    vec2 uv = vUV.st;
    
    vec2 res = uTDOutputInfo.res.zw; // Get total width and height
	ivec2 xy = ivec2(uv * res); // Get coordinate in pixel value

  	// Grab input value
#if TD_NUM_3D_INPUTS > 0
	int d = uTDCurrentDepth;
    float gradient = texelFetch(sTD3DInputs[TEX_GRADIENT], ivec3(xy, d), 0).r;
    float layerInput = texelFetch(sTD3DInputs[TEX_FORWARD_IN], ivec3(xy, d), 0).r;
    float layerOutput = texelFetch(sTD3DInputs[TEX_FORWARD_OUT], ivec3(xy, d), 0).r;
#else  	
    float gradient = texelFetch(sTD2DInputs[TEX_GRADIENT], xy, 0).r;
    float layerInput = texelFetch(sTD2DInputs[TEX_FORWARD_IN], xy, 0).r;
    float layerOutput = texelFetch(sTD2DInputs[TEX_FORWARD_OUT], xy, 0).r;
#endif
 
 	float localGradient = 0;
	localGradient = CalculateLocalGradient(layerInput, layerOutput);

    // Ouput gradient flow (chain rule)
    fragNeuron = localGradient * gradient;
}