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

class Session:
	"""
	This class is in charge of retrieve and setting the current model to 
	and from the DAT tables
	"""
	def __init__(self, ownerComp):
		self.ownerComp  = ownerComp
		self.opModel 	= op('Model')
		self.opGlobal	= op('Global')
		self.opModule 	= op('Module')
		self.opLayers 	= op('Layers')
		self.lastNodeY	= 0
		
	###############
	# PUBLIC
	###############

	def Get(self, update=False):
		"""
		This method collects the parameters for each layer and their
		general properties in the form of a dictionary. Possible keys:
		'Info' and 'Layers'
		"""
		# Updates epoch
		try:
			self.opModel["Epoch", 1] = op.TDNeuron.op("Control").par.Currentepoch.val
		except:
			pass

		# Gather general info
		info = { row[0].val : row[1].val for row in self.opModel.rows() }

		# if update:
		# 	# Update and gather module info
		# 	self.opModule.clear()
		# 	parameters = self.getParameters(op.TDNeuron.op("Module/Module"), ["Config"])
		# 	for p in parameters.items():
		# 		self.opModule.appendRow([p[0], p[1]])

		# 	# Update and gather global info
		# 	self.opGlobal.clear()
		# 	parameters = self.getParameters(op.TDNeuron.op("Engine"), ["Parameters"])
		# 	for p in parameters.items():
		# 		self.opGlobal.appendRow([p[0], p[1]])

		module = { row[0].val : row[1].val for row in self.opModule.rows() }

		engine = { row[0].val : row[1].val for row in self.opGlobal.rows() }

		# Gather layers parameters
		layers = [ { 	"Id": r, 
						"LayerName": self.opLayers[r,"LayerName"].val, 
						"LayerType": self.opLayers[r,"LayerType"].val,
						"Parent": self.opLayers[r, "Parent"].val,
						"NodeX": self.opLayers[r, "NodeX"].val,
						"NodeY": self.opLayers[r, "NodeY"].val } 
				for r in range(1, self.opLayers.numRows) ]

		types = {}
		for k,l in enumerate(layers):
			types[l["LayerType"]] = 1

			try:
				layer = op.TDNeuron.op("Model/"+str(l["LayerName"]))
				layers[k]["NodeX"] = layer.nodeX
				layers[k]["NodeY"] = layer.nodeY
			except:
				pass

		for t in types.keys():
			o = op("Parameters"+t)
			if (o):
				try:
					layers = self.addToLayersObject(layers, o)
				except:
					print("Could not add layer object: ", t)
					pass

		return {"Info": info, "Module": module, "Global": engine, "Layers": layers}

	def writeDAT(self, dat, dict):
		"""
		This method writes a dictionary to specified DAT.
		"""
		dat.setSize(dat.numRows,2)
		for k in dict.keys():
			try:
				val = dict[k]
				dat[k,1] = val
			except:
				pass

	def Set(self, model):
		"""
		This method sets the paramters for each layer and their properties
		in tables located in this COMP
		"""
		self.writeDAT(self.opModel, model["Info"])

		if "Module" in model:
			self.opModule.clear(keepFirstCol=True)
			self.writeDAT(self.opModule, model["Module"])

		if "Global" in model:
			self.opGlobal.clear(keepFirstCol=True)
			self.writeDAT(self.opGlobal, model["Global"])

		# Prepare tables
		self.opLayers.clear(keepFirstRow=True)
		self.opLayers.setSize(len(model["Layers"])+1, 5)

		parameterComps = parent().ops("Parameters*")
		pComps = {}
		for o in parameterComps:
			o.clear(keepFirstRow=True)
			pComps[o.name[10:]] = o # strip 'Parameters' from name, and use it as lookup key

		# Fill in data
		for layer in model["Layers"]:
			layerID = int(layer["Id"])
			layerType = layer["LayerType"]
			self.opLayers[layerID,"LayerName"] = layer["LayerName"]
			self.opLayers[layerID,"LayerType"] = layerType
			self.opLayers[layerID,"Parent"] = layer["Parent"]
			try:
				self.opLayers[layerID,"NodeX"] = layer["NodeX"]
				self.opLayers[layerID,"NodeY"] = layer["NodeY"]
			except:
				pass

			if layerType in pComps:
				self.updateFromLayerObject(layer, pComps[layerType])
		pass

	def CreateParametersDat(self, opName, parameters):
		self.ownerComp.create(tableDAT, opName)
		o = self.ownerComp.op(opName)
		o.nodeWidth = 1000
		o.nodeHeight = 120
		o.setSize(0,len(parameters))
		o.appendRow(["Id"] + parameters)
		o.nodeY = self.lastNodeY
		self.lastNodeY -= 150
		o.viewer = True

		return o

			
	###############
	# PRIVATE
	###############

	def addToLayersObject(self, layers, operator):
		for r in range(1, operator.numRows):
			layerID = int(operator[r,"Id"].val)
			for c in range(1, operator.numCols):
				layers[layerID-1][operator[0, c].val] = operator[r, c].val
		return layers
	
	def updateFromLayerObject(self, layer, operator):
		for c in range(1, operator.numCols):
			rowIndex = str(layer["Id"])
			colName = operator[0,c].val
			if colName in layer:
				if operator[rowIndex,0] == None:
					operator.appendRow([rowIndex])
				try:
					operator[rowIndex,colName] = layer[colName]
				except:
					pass
	
	def getParameters(self, node, pages=["Parameters"]):
		parameters = {}
		for i in range(0, len(node.customPars)):
			if node.customPars[i].page not in pages:
				continue 
			if node.customPars[i].isToggle:
				v = int(node.customPars[i].val)
			elif node.customPars[i].isMenu and len(node.customPars[i].menuNames) > 0:
				val = node.customPars[i].eval()
				v = node.customPars[i].menuNames[int(val)] if val.isdigit() else val
			else: 
				v = node.customPars[i].eval()

			parameters[node.customPars[i].name] = v
		return parameters
