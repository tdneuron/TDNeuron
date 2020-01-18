## Models
---

TDNeuron has a number of pre-trained models available for use. The idea is that you can also define your own and create a library of models, after you have trained them.

You may load a model by using the **Control** node. Please refer to "Getting started" to learn more about saving and loading models.

Here follows a list with all available models:

### Toy Conv2D
---

|*Version*		|*1.0.0*		|
|---		|---		|
|Epoch		|447		|
|Name		|Toy Conv2D		|
|Author		|Tim Gerritsen <tim@yfxlab.com>		|
|Seed		|0		|
|Module		|Leapmotion		|

|*Trainsetpercentage*		|*0.8999999761581421*		|
|---		|---		|
|Testsetpercentage		|0.10000000149011612		|
|Classes		|10		|
|Livetest		|0		|
|Randomizeminibatches		|1		|
|Datatype		|0		|

|*LayerName*		|*LayerType*		|*Parent*		|*NodeX*		|*NodeY*		|
|---		|---		|---		|---		|---		|
|Linear1		|Linear		|0		|200		|0		|
|Activation1		|Activation		|1		|425		|0		|
|Linear3		|Linear		|2		|625		|0		|
|Softmax1		|Softmax		|3		|825		|0		|
|LossCrossEntropy1		|LossCrossEntropy		|4		|1050		|0		|