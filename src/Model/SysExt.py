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

class Sys:
	def __init__(self, ownerComp):
		self.ownerComp = ownerComp
		self.opModule = op.TDNeuron.op("Module")
		self.opModel = op.TDNeuron.op("Model")
		self.opEngine = op.TDNeuron.op("Engine")
		self.opSession = op.TDNeuron.op("Session")
		self.opLayers = op.TDNeuron.op("Layers")
		self.opTemplates = ownerComp.op("Templates")
		self.opMergeChops = ownerComp.op("opfindMergeChops")
		self.nodes = []
		self.nodeNames = []
		self.flows = {}

	###############
	# PUBLIC
	###############

	def Build(self):
		"""
		Rebuilds the sessionDATs by processing the current model.
		Looping through the inputs starting from the loss functions.
		"""

		self.flows = {}
		self.nodes = []
		self.nodeNames = []
		
		# clear current session
		self.clearSession()

		# Set basic info like name, version, module.
		self.setInfo()

		# Find flow from loss functions backwards
		index = 1
		lossFunctions = self.opModel.op("Cost/opfindLoss").col('name')[1:]
		for f in lossFunctions:
			index = self.processFlow(index, 0, self.opModel.op(f))
		
		index = 0
		self.lastNodeY = 0
		self.processed = []

		# Build new session
		for flowIndex in sorted(self.flows, key=lambda k: len(self.flows[k]), reverse=True):
			self.flows[flowIndex].reverse()
			index = self.buildFlow(index, flowIndex)

		# Switch off dirty-flag since we just generated the model
		self.opModel.par.Dirty = False

	def Destroy(self):
		self.destroyExistingModel(self.opModel)

	def Load(self):
		"""
		Load the current session and creates a connected model
		"""
		session = self.opSession.Get()

		try:
			n = self.createLayers(self.opModel, session['Layers'])
		except Exception as e:
			print('Could not create model due exception: ',e)

	def ToggleSystemNodes(self):
		"""
		This method shows or hides the system nodes 'toolbar' and 'sys'
		"""
		exposed = self.opModel.op("Sys").expose
		self.opModel.op("Toolbar").expose = not exposed
		self.opModel.op("Sys").expose = not exposed

	def OnDelete(self, operatorName):
		# recopy template node when system nodes get deleted		
		self.opModel.copy(self.opTemplates.op(operatorName))
		o = self.ownerComp.op("sortDesignX")
		if (operatorName in ["Output", "Cost"]):
			self.opModel.op(operatorName).nodeX = o[o.numRows-1,"nodeX"]

		self.ownerComp.op("Scripts/exec"+operatorName).cook(force=True)

	def OnModelUpdate(self):
		for i in range(1, self.opMergeChops.numRows):
			op(self.opMergeChops[i,0]).cook(force=True)

	def OnRename(self, operatorName, newName):
		# permit renaming of system nodes
		self.opModel.op(newName).name = operatorName

	def UpdateColors(self, default=False):
		c = ui.colors
		if default:
			c["parms.bind.fg"] = (0.77, 0.7, 1.0)
			c["parms.bind.bg"] = (0.192, 0.19, 0.2)
		else:
			c["parms.bind.fg"] = c["parms.field.numeric.fg"]
			c["parms.bind.bg"] = c["parms.field.numeric.bg"]

	###############
	# PRIVATE
	###############

	def buildFlow(self, index, flowIndex):
		parentIndex = -1
		# loop thru all nodes in flow
		for nodeIndex in self.flows[flowIndex]:
			if nodeIndex in self.processed:
				parentIndex = nodeIndex
				continue
			self.processed.append(nodeIndex)

			self.nodes[nodeIndex]["index"] = index
			if parentIndex >= 0:
				if not self.buildNode(nodeIndex, parentIndex):
					index -= 1
			index += 1
			parentIndex = nodeIndex

		return index

	def setInfo(self):
		self.opSession.op("Model")["Name",1] = self.opModel.par.Name 
		self.opSession.op("Model")["Author",1] = self.opModel.par.Author
		self.opSession.op("Model")["Version",1] = "{}.{}.{}".format(self.opModel.par.Version1, self.opModel.par.Version2, self.opModel.par.Version3)
		self.opSession.op("Model")["Module",1] = self.opModule.par.Module

		m = self.opSession.op("Module")
		m.clear()
		parameters = self.getParameters(self.opModule.op("Module"), ["Config"])
		for p in parameters.items():
			m.appendRow([p[0], p[1]])

		m = self.opSession.op("Global")
		parameters = self.getParameters(self.opEngine, ["Parameters"])
		for p in parameters.items():
			try:
				m[p[0],1] = p[1]
			except:
				pass

	def clearSession(self):
		self.opSession.op("Layers").clear(keepFirstRow=True)
		parameterDats = self.opSession.findChildren(type=tableDAT, name="Parameters*")
		for d in parameterDats:
			d.clear(keepFirstRow=True)

	def buildNode(self, nodeIndex, parentIndex):

		index = self.nodes[nodeIndex]["index"]
		nodeName = self.nodes[nodeIndex]["node"].name
		nodeX = self.nodes[nodeIndex]["node"].nodeX
		nodeY = self.nodes[nodeIndex]["node"].nodeY
		nodeType = self.nodes[nodeIndex]["type"]
		parameters = self.nodes[nodeIndex]["parameters"]

		if nodeType == None:
			return False

		o = self.opSession.op("Layers")
		if index == 1:
			o.clear(keepFirstRow=True)
		o.appendRow([nodeName, nodeType, self.nodes[parentIndex]["index"], nodeX, nodeY])
		o.cook()

		if len(parameters) == 0:
			return True

		opName = "Parameters"+nodeType
		o = self.opSession.op(opName)
		if o == None:
			o = self.opSession.CreateParametersDat(opName, list(parameters.keys()))

		o.appendRow([index] + list(parameters.values()))
		o.cook()
		return True

	def processFlow(self, flowIndex, nodeIndex, node):
		nodeType = self.nodeType(node)
		index = len(self.nodes)

		if node.name not in self.nodeNames:
			self.nodeNames.append(node.name)
			self.nodes.append(self.processType(nodeType, node))
		else:
			index = self.nodeNames.index(node.name)

		if flowIndex not in self.flows:
			self.flows[flowIndex] = []

		self.flows[flowIndex].append(index)

		for j in range(0, len(node.inputs)):
			self.processFlow(flowIndex, nodeIndex + 1, node.inputs[j].parent())
			flowIndex = (flowIndex << 2) + nodeIndex
			nodeIndex = -1
		return flowIndex

	def getParameters(self, node, pages=["Parameters"]):
		parameters = {}
		for i in range(0, len(node.customPars)):
			if node.customPars[i].page not in pages:
				continue 
			if node.customPars[i].isToggle:
				v = int(node.customPars[i].val)
			elif node.customPars[i].isMenu and len(node.customPars[i].menuNames) > 0:
				val = node.customPars[i].eval()
				v = node.customPars[i].menuNames[int(val)-1] if val.isdigit() else val
			else: 
				v = node.customPars[i].eval()

			parameters[node.customPars[i].name] = v
		return parameters

	def processType(self, nodeType, node):
		nodeObject = {"node": node, "type": nodeType, "parameters": {}}
		if nodeType == None:
			return nodeObject

		if len(node.inputs) > 1:
			inputOp = node.inputs[1].parent()
			inputOpName = inputOp.name
			nodeObject["parameters"]["Layer"] = inputOpName
			nodeObject["parameters"]["Top"] = inputOpName

		nodeObject['parameters'] = self.getParameters(node)
		return nodeObject

	def nodeType(self, node):
		return op(node.par.clone).dock.name if node.par.clone else None

	def destroyExistingModel(self, target):
		try:
			for t in target.findChildren(tags=["UI"]):
				t.destroy() 
		except Exception as e:
		 	print('Destruction skipped due: ', e)

	def findLayerChildren(self):
		children = {}
		layers = self.opSession.op("Layers")
		numLayers = layers.numRows - 1

		# loop through all layers
		for i in range(numLayers):
			# save the indices of all layers that have children
			parentIndex = int(layers[i+1, 'Parent'])
			if parentIndex not in children:
				children[parentIndex] = []
			children[parentIndex].append(i)
		return children

	def createLayers(self, target, parameters):
		layers = self.opSession.op("Layers")
		numLayers = layers.numRows-1
		nodes = [target.op("Input")]
		children = self.findLayerChildren()
		index = 1
		# splitted = 0
		positions = []
		for i in range(numLayers):

			nodeName = layers[i+1, 'LayerName']
			parentIndex = layers[i+1, 'Parent']

			try:
				nodeX = int(layers[i+1, 'NodeX'])
				nodeY = int(layers[i+1, 'NodeY'])
			except:
				nodeX = index*200
				nodeY = 0

			# Skip if no parent supplied
			if (parentIndex == ""):
				continue
			parentIndex = int(parentIndex)
			
			nodeType = str(layers[i+1, 'LayerType'])
			nodes = self.createLayer(index, target, nodes, name=nodeName, type=nodeType, parentIndex=parentIndex, parameters=parameters[i], nodeX=nodeX, nodeY=nodeY)
			index += 1

		self.moveCostAndOutput()
		return nodes		

	def moveCostAndOutput(self):
		o = self.ownerComp.op("sortDesignX")
		x = o[o.numRows-1,"nodeX"]
		if str(o[o.numRows-1,"name"]) not in ["Output", "Cost"]:
			x += 200
		self.opModel.op("Output").nodeX = x
		self.opModel.op("Cost").nodeX = x

	def createLayer(self, index, target, nodes, name="", type="", parentIndex="", parameters=[], nodeX=0, nodeY=0):
		# Skip if no parent supplied
		if (parentIndex == "" or not self.opLayers.op(type)):
			return nodes
		# Create nodes in target with right name and position
	
		n = target.copy(self.opLayers.op("UI"+type))
		n.par.clone = self.opLayers.op("UI"+type)
		n.par.externaltox = ""
		n.showCustomOnly = True
		n.name = name
		n.nodeX = nodeX
		n.nodeY = nodeY

		self.setParameters(index, n, parameters)
		nodes.append(n)	

		if (parentIndex < index):
			parentNode = nodes[parentIndex]
			self.connectLayer(nodes, index, parentIndex)
			n.cook(force=True)

		return nodes

	def setParameters(self, index, node, parameters):
		for k in parameters:
			try:
				getattr(node.par, k).mode = ParMode.CONSTANT
				exec('node.par.{} = "{}"'.format(k, parameters[k]))
			except Exception as e:
				pass


	def connectLayer(self, nodes, index, parentIndex):
		if index >= len(nodes):
			return
			
		currentNode = nodes[index]
		if parentIndex < len(nodes):
			nodes[parentIndex].outputConnectors[0].connect(currentNode.inputConnectors[0])
