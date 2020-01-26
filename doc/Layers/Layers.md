## Layers
---

There are 3 types of data that may flow through a model:

1. **Neurons**: Floating point numbers in fully connected layers
1. **1D**: 1D Convolutional data, such as audio
1. **2D**: 2D Convolutional data, such as images

Here we present an overview of all the layers available in TDNeuron:

### Linear Layer
---
- **Input**: Data/Neurons
- **Trainable**: Yes

Performs a linear function `y = WX + b`, which is a dot product between the input data and a set of weights, pluse the biases. It outputs N "neurons". 

### Activation layer
---
- **Input**: Neurons, 1D or 2D
- **Trainable**: No

Converts the input signal to a non-linear one, using a so-called 'activation' function. The following activation functions are currently implemented:

- Sigmoid
- Tanh
- RELU
- Leaky RELU
- Swish
- Softplus

Since its operation is uniform over all input data points it will work with any input, including convolutional data.
See "Introduction to machine learning - chapter 05: Activation functions" for more detailed info.

### Convolution layer
---
- **Input**: 1D or 2D
- **Trainable**: yes

Performs convolutional filters to the input. The filters have a defined size and are tipically called "kernels". Depending on how the kernels fit over the input data, a certain 'padding' and 'stride' values are required which define the offset and hop size of the kernels. The filters move along the input data horizontally and vertically, computing the dot product of the weights and the input pluse the biases.

### Pool layer
---
- **Input**: 1D or 2D
- **Trainable**: No

Performs a max or a mean average function over the input data. These operations are applied to a set of groups in the input data. The output is a value for each one of this groups. The operation has the effect of reducing dimensionality of input data, meaning how many neurons we have, and in doing so creates invariance. Invariance means how robust the model is to small perturbations of the data. 

### Flatten layer
---
- **Input**: 1D or 2D
- **Trainable**: No

Collapses the spatial dimensions of the input data into flat array of values.

### Add layer
---
- **Input**: neurons
- **Trainable**: No

Adds the given two inputs element-wise.

### Multiply layer
---
- **Input**: neurons
- **Trainable**: No

Multiplies the two given inputs element-wise.

### Concat layer
---
- **Input**: neurons
- **Trainable**: No

Concatenates the two given inputs into a single output.

### Layer normalization
---
- **Input**: neurons
- **Trainable**: yes

Calcualtes the mean and variance of the data, normalizes the input and transforms it back, using trainable parameters to model space.

### Softmax layer
---
- **Input**: neurons
- **Trainable**: No

Applies the softmax function: `exp(x)/sum(exp(x))` to the input. It outputs the probability distribution of N different classes in the input. The probability range will be from 0 to 1.

### LossMAE layer
---
- **Input**: neurons
- **Trainable**: No

Takes the absolute value of the difference between the prediction and ground truth.

### LossMSE layer
---
- **Input**: neurons
- **Trainable**: No

Takes the squared difference between the prediction and ground truth. 

### LossHuber layer
---
- **Input**: neurons
- **Trainable**: No

Takes the absolute value and the squared difference between the prediction and ground truth over some delta.

### LossCrossEntropy layer
---
- **Input**: neurons
- **Trainable**: No

Used for classification problems where the output of the model is a discrete value. The loss function expects input features summed up to one, since it models a probability distribution.

