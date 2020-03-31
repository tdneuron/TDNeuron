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

#define EPSILON 1e-11

#define OPTIMIZER_SGD 0 // vanilla stochastic gradient descent
#define OPTIMIZER_MOMENTUM 1 // stochastic gradient descent with momentum
#define OPTIMIZER_RMSPROP 2 // Root mean square prpop
#define OPTIMIZER_ADAGRAD 3 // Like rmsprop but worse
#define OPTIMIZER_ADAM 4 // Adam optimizer (SGD-momentum with RMSProp)

#define REGULARIZATION_NONE 0
#define REGULARIZATION_L1 1 // L1 regularization penalty. Penalties the weights using abs(weight)
#define REGULARIZATION_L2 2 // L2 regularization penalty. Penalties the weights using squared distance (weight*weight)

uniform float uLearningRate; // The speed the weight gets updated
uniform int uOptimizer; // Type of optimizer (SGD, RMSProp, Adam)
uniform int uGradientAscent; // 1 when ascending gradient instead of descending
uniform float uMomentumFactor; // Amount of momentum (0 is normal SGD)
uniform float uRMSPropFactor; // Amount of RMSProp
uniform vec2 uRegularization; // Type and amount of regularization

float Optimize(float weightUpdate, float weight, inout float velocity, inout float rmsprop, bool regulate)
{
	if (uOptimizer == OPTIMIZER_SGD) {
		// Default stochastic gradient descent. Dont do anything with the weight update
		weightUpdate = weightUpdate;

	} else if (uOptimizer == OPTIMIZER_MOMENTUM) {
		// Calculate the velocity of the weight update and use that instead.
		velocity = uMomentumFactor * velocity + weightUpdate;
		weightUpdate = velocity;

	} else if (uOptimizer == OPTIMIZER_ADAGRAD) { 
		// Calculate the squared weight update and divide by the step
		// This might saturate too quickly, better use RMSProp
		rmsprop += weightUpdate*weightUpdate; // Reusing rmsprop buffer
		weightUpdate = weightUpdate / (sqrt(rmsprop) + EPSILON);

	} else if (uOptimizer == OPTIMIZER_RMSPROP) {
		// Fixes the saturation problem of ADAGRAD by introducing a decay variable
		rmsprop = uRMSPropFactor * rmsprop + (1-uRMSPropFactor)*weightUpdate*weightUpdate;
		weightUpdate = weightUpdate / (sqrt(rmsprop) + EPSILON);

	} else if (uOptimizer == OPTIMIZER_ADAM) {
		// Best of both worlds, uses SGD momentum with RMSProp
		velocity = uMomentumFactor * velocity + (1-uMomentumFactor)*weightUpdate;
		rmsprop = uRMSPropFactor * rmsprop + (1-uRMSPropFactor)*weightUpdate*weightUpdate;

		// Bias correction, need to account for the first few epochs.
		float velocityUnbiased = velocity/(1-pow(uMomentumFactor, uIteration));
		float rmspropUnbiased = rmsprop/(1-pow(uRMSPropFactor, uIteration));

		weightUpdate = velocityUnbiased / (sqrt(rmspropUnbiased) + EPSILON);
	}
		
	/////////////////////////////////////////////////////////
	// L1/L2 REGULARIZATION STEP 
	/////////////////////////////////////////////////////////

	// Add regularization penality in case set
	if (regulate && uRegularization.x != REGULARIZATION_NONE) {
		weightUpdate += uRegularization.y * (uRegularization.x == REGULARIZATION_L2 ? weight:sign(weight));
	}
		
	//////////////////////////////
	// UPDATE WEIGHTS
	//////////////////////////////
	return weight + sign(uGradientAscent - 0.5) * uLearningRate * weightUpdate; // Decrease the weight 
}
