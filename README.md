# TDNeuron

Welcome to our repository. Here you will find material on how to use the TDNeuron system to implement machine learning within [Derivative's TouchDesigner](https://www.derivative.ca/)

## Why use TDNeuron?

There are several deep learning libraries and frameworks available today. Why yet another one, such as TDNeuron? Here are some of the reasons why we think that TDNeuron is a fruitful endeavour.

## Education

TDNeuron was created initially out of our desire to self-learn the rudiments of machine learning. We believe that the best way to fully understand a concept is to build it from scratch. By making our code open-source and enriching it with comments, tutorials and documention, we are trying to open the world of machine learning for the novice 'regular' user, though still keeping the doors open to allow for those curious to dive deep into the mathematics and core concepts.

## Visual modelling

The modelling interface of TDNeuron is completely TouchDesigner-based. It uses the regular controls and the same patching mechanisms, like those one uses when creating a regular network. In addition, the 'nodes' in the model show extended realtime information about the data flowing through the layer. This gives great insights on what the machine is actually learning at any given time or for bug-fixing. Since TouchDesigner is a visually oriented programming environment, there is no need to code a single letter in order to build a deep learning model.

## GPU powered

Most calculations of the deep Learning layers can be done in parallel. TDNeuron uses GLSL (pixel and compute) shaders, to achieve the best possible performance.

## Extended built-in layers

The following deep learning layers are currently implemented:

*   Linear
*   Activation (sigmoid, tanh, relu, lrelu, swish, softplus)
*   Multiply, Add, Concat, Split
*   Convolution (1d and 2d)
*   Pool (maximum and average)
*   Flatten
*   Loss (MAE, MSE, Huber, CrossEntropy)
*   Softmax
*   Layer normalization

We have made sure that TDNeuron is as modular as possible, which makes it easy to implement new layers if needed.

## TouchDesigner native

Since TDNeuron is fully build from scratch in TouchDesigner, with its own custom-made shaders and UI, everything is native to the program. There are no libraries to import and nothing new to learn outside the scope of TD. This allows you to quickly prototype models without leaving the comfort of your favourite software and to train them and share them with your colleagues, fit to function in your real-time projects.

## Commercial licenses available

TDNeuron is released under a *Creative Commons Non-commercial* license. If you want to use TDNeuron in commercial projects, please contact [licenses@tdneuron.com](mailto:licenses@tdneuron.com) for specific licenses.

## Final words

![something](someimage.jpg)

To get you started with, we offer you with this repository a gentle introduction to how the framework is implemented. We are assuming that you are already proficient with TouchDesigner and that know the basics of GLSL and shaders. 

We believe that knowledge should be shared. We hope that TDNeuron can help others in their first steps in machine learning. We look forward to learn from you as well and to see how far we can take this platform. 
