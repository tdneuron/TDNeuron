"""__________________________________________________________________

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
____________________________________________________________________"""

class Engine:
	"""
	This class is in charge of grabbing the properties specified
	in the Session node and generating Train and Test models.
	"""
	def __init__(self, ownerComp):
		self.ownerComp 		= ownerComp
		self.session 		= op.TDNeuron.op('Session')
		self.layers			= op.TDNeuron.op('Session/Layers')
		self.yOffsets		= {}
		self.currentYOffset = 0
		self.costFunctions  = 0

	###############
	# PUBLIC
	###############

	def CreateModel(self):
		session = self.session.Get(True)
		parameters = session['Layers']
		pos = (self.ownerComp.nodeX, self.ownerComp.nodeY - 175)
		color = (0.3,0,0)
	
		try:
			self.destroyExistingModel(self.ownerComp)
			n = self.createLayers(self.ownerComp, parameters)
		except Exception as e:
			print('Could not create model due exception: ',e)

	def DestroyModel(self):
		self.destroyExistingModel(self.ownerComp)

	###############
	# PRIVATE
	###############

	def destroyExistingModel(self, target):
		self.yOffsets		= {}
		self.currentYOffset = 0
		self.costFunctions  = 0

		try:
			for t in target.findChildren(tags=["Layer"]):
				t.destroy() 
		except Exception as e:
		 	print('Destruction skipped due: ', e)

	def createLayer(self, index, target, nodes, name="", type="", parentIndex="", parameters=[]):
		# Skip if no parent supplied
		if (parentIndex == "" or not op.Layers.op(type)):
			return nodes
		# Create nodes in target with right name and position
		n = target.copy(op.Layers.op(type))
		n.par.clone = op.Layers.op(type)
			
		if parentIndex < index-1:
			self.currentYOffset	= parentIndex

		# Set each node characteristics
		self.setProperties(n, name)
		self.setParameters(index, n, parameters)
		self.linkParameters(n)
		nodes.append(n)	

		if (parentIndex < index):
			parentNode = nodes[parentIndex]
			self.connectLayer(nodes, index, parentIndex)

		return nodes

	def createLayers(self, target, parameters):
		numLayers = self.layers.numRows - 1
		nodes = [target.op("Input")]
		children = self.findLayerChildren()
		index = 1
		splitted = 0
		positions = []
		for i in range(numLayers):

			nodeName = self.layers[i+1, 'LayerName']
			parentIndex = self.layers[i+1, 'Parent']

			# Skip if no parent supplied
			if (parentIndex == ""):
				continue
			parentIndex = int(parentIndex)

			# Check if layer has multiple children, in that case we need to add a splitter.
			if i in children and len(children[i]) > 1:
				nodes = self.splitLayer(index, target, nodes, parentIndex + splitted, children[i])

				# Keep track of the amount of splits, to manage the indices
				splitted += 1
				parentIndex = index
				index += 1
			else:
				parentIndex += splitted
			
			nodeType = str(self.layers[i+1, 'LayerType'])
			nodes = self.createLayer(index, target, nodes, name=nodeName, type=nodeType, parentIndex=parentIndex, parameters=parameters[i])

			if nodeType[:4] == "Cost":
				nodes = self.configCost(nodes, index, parameters=parameters[i])
			index += 1

		return nodes

	def configCost(self, nodes, index, parameters=[]):
		try:
			nodes[index].par.Index = self.costFunctions
			self.costFunctions += 1
			#nodes[index].par.Groundtruthtop = parameters["Groundtruth"] if "Groundtruth" in parameters else "Groundtruth"
		except:
			pass
		return nodes

	def findLayerChildren(self):
		children = {}
		numLayers = self.layers.numRows - 1

		# loop through all layers
		for i in range(numLayers):
			# save the indices of all layers that have children
			parentIndex = int(self.layers[i+1, 'Parent'])
			if parentIndex not in children:
				children[parentIndex] = []
			children[parentIndex].append(i)
		return children

	def splitLayer(self, index, target, nodes, parentIndex, children):			
		nodes = self.createLayer(index, target, nodes, name="Split"+str(index), type="Split", parentIndex=parentIndex)
		
		# Setting the child parameters of the splitter
		for j in range(1,len(children)):
			setattr(nodes[index].par, 'Childlayer{}'.format(j), self.layers[children[j]+1,'LayerName'])

		return nodes

	def connectLayer(self, nodes, index, parentIndex):
		if index >= len(nodes):
			return
			
		currentNode = nodes[index]
		if parentIndex < len(nodes):
			nodes[parentIndex].outputConnectors[0].connect(currentNode.inputConnectors[0])
		if parentIndex > 0 and len(nodes[parentIndex].inputs) < 2:
			currentNode.outputConnectors[1].connect(nodes[parentIndex].inputConnectors[1])

		# Ugly hack to connect gradients of splitted layers
		try:
			l = currentNode.par.Layer
			run("op('"+currentNode.path+"').outputConnectors[1].connect(op(str(op('"+currentNode.path+"').par.Layer)).inputConnectors[1])", delayFrames=1)
		except:
			pass

	def setProperties(self, node, name):
		node.name 	= name

		self.yOffsets[self.currentYOffset] = int(self.yOffsets[self.currentYOffset]) if self.currentYOffset in self.yOffsets else 0
		self.yOffsets[self.currentYOffset] += 1

		node.nodeX 	= (self.yOffsets[self.currentYOffset] - 1) * 500
		node.nodeY 	= self.currentYOffset*-200
		self.currentYOffset += 1

	def setParameters(self, index, node, parameters):
		# make sure seed is unique per layer
		try:
			node.par.Seed += self.ownerComp.par.Seed + index
		except:
			pass

		for k in parameters:
			try:
				getattr(node.par, k).mode = ParMode.CONSTANT
				exec('node.par.{} = "{}"'.format(k, parameters[k]))
			except Exception as e:
				pass

		# Set learningrate reference in case parameter exists
		try:
			node.par.Learningrate.expr = "op.TDNeuron.op('Control').par.Learningrate"
		except:
			pass


	def linkParameters(self, node):
		for k in node.customPars:
			if k.mode != ParMode.EXPRESSION:
				continue

			try:
				par = getattr(op.TDNeuron.op("Engine").par, k.name)
				k.expr = "op.TDNeuron.op('Engine').par."+k.name
				k.mode = ParMode.EXPRESSION
			except:
				pass
