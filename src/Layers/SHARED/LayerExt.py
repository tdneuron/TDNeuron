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

class Layer:
	errorMessages = {
		"ERROR_NOINPUT"		: "No input found. Please connect a layer.",
		"ERROR_INVALIDTYPE"	: "Invalid dataflow input.",
		"ERROR_NOT1D"		: "Input should be 1-dimensional. Use a 'flatten' layer first.",
		"ERROR_RESOLUTION"	: "Invalid resolution. Please use different stride, kernel size or padding.",
		"ERROR_LOSS"		: "Input should be a loss function"	
	}

	def __init__(self, ownerComp):
		self.ownerComp = ownerComp
		self.layerNode = self.ownerComp.parent()
		self.opTextureSelect = op("Texture3DSelect")
		self.opDataTypes = op("in1_DataTypes")
		self.opUI = op("UI")

	def OnView(self, changeOp):
		o = changeOp
		o.viewer = True
		o.par.Showdata = not o.par.Showdata

		if o.par.Showdata:
			self.UpdateViewer()

	def UpdateViewer(self):
		try:
			name = self.ownerComp.par.Dataroot.eval()
			data = self.layerNode.par.Datatype.eval()

			dataType = self.opDataTypes[data,"top"]
			dataRoot = op.TDNeuron.op("Engine").path+("/"+name if name else "")
			if op(dataRoot) and dataType != None:
				self.opTextureSelect.par.Top = op(dataRoot).path+"/"+dataType
				self.opTextureSelect.cook(force=True)
		except:
			pass

	def OnDataTypeUpdate(self):
		names = []
		labels = [] 
		for i in range(1, self.opDataTypes.numRows):
			names.append(str(self.opDataTypes[i,'name']))
			labels.append(str(self.opDataTypes[i,'label']))

		try:
			self.layerNode.par.Datatype.menuNames = names
			self.layerNode.par.Datatype.menuLabels = labels
		except:
			pass

	def SetDirty(self):
		op.TDNeuron.op("Model").par.Dirty = True

	def Validate(self):
		error = ""
		opDataFlow = op(self.ownerComp.par.Dataflowchop)
		if opDataFlow.numChans == 0:
			error = self.errorMessages["ERROR_NOINPUT"]

		if not self.checkDatatype(opDataFlow):
			error = self.errorMessages["ERROR_NOT1D"] if self.ownerComp.par.Allowneurons.eval() else self.errorMessages["ERROR_INVALIDTYPE"]

		if self.ownerComp.par.Checkresolution.eval() and not self.checkResolution(opDataFlow):
			error = self.errorMessages["ERROR_RESOLUTION"]

		if self.ownerComp.par.Lossfunction.eval() and not self.checkLossFunction(opDataFlow):
			error = self.errorMessages["ERROR_LOSS"]

		self.layerNode.color = self.opUI.color if error == "" else (1,0,0)
		self.layerNode.comment = error
	
	def Help(self):
		name = op(self.layerNode.par.clone.eval()).name[2:]
		helpLayers = op.TDNeuron.op("Help/Layers")

		try:
			o = helpLayers.op(name)
		except:
			o = None
		p = ui.panes.createFloating(type=PaneType.NETWORKEDITOR, name="Help", maxWidth=1024, maxHeight=512)
		p.owner = helpLayers
		p.home(op=o)

	def checkDatatype(self, o):
		try:
			dataType = int(o["datatype"])
			valid = (dataType == 0 and self.ownerComp.par.Allowneurons.eval())
			valid |= (dataType == 1 and self.ownerComp.par.Allowconv1d.eval())
			valid |= (dataType == 2 and self.ownerComp.par.Allowconv2d.eval())
		except:
			valid = True
		return valid

	def checkResolution(self, o):
		res = False
		if o.numChans == 0:
			res = True
			
		try:
			res = (int(o["width"]) == int(o["width"]) and int(o["height"]) == int(o["height"]))
		except:
			res = True
		return res

	def checkLossFunction(self, o):
		isLoss = False
		if len(self.layerNode.inputs) > 0:
			isLoss = (op(self.layerNode.inputs[0].parent().par.clone).name[:6] == "UILoss")
		else:
			isLoss = True

		return isLoss
