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

class Output:
	def __init__(self, ownerComp):
		self.ownerComp = ownerComp
		self.opTextureSelect = op("Texture3DSelect")
		self.opLossFunctions = op.TDNeuron.op("Engine/Predictions/LossFunctions")
		self.opDataTypes = op("DataTypes")
		self.opUI = op("UI")
		self.opModule = op.TDNeuron.op("Module")

	def UpdateViewer(self):
		self.opTextureSelect.par.Top = self.getTopPath()
		self.opTextureSelect.cook(force=True)

	def OnView(self, changeOp):
		o = changeOp
		o.viewer = True
		o.par.Showdata = not o.par.Showdata

		if o.par.Showdata:
			self.UpdateViewer()

	def OnCustomOutput(self):
		o = self.getModule("Output")

		try:
			o.par.Prediction = op.TDNeuron.op(ops[int(parent().par.Datatype)])
		except:
			pass

		try:
			o.par.Type = int(parent().par.Datatype)
		except:
			pass

		parent().par.opviewer = "./Layer" if not parent().par.Showcustomoutput else o

	def OnOpenCustomViewer(self, par):
		p = ui.panes.createFloating(type=PaneType.PANEL, name="Output", maxWidth=1024, maxHeight=1024)
		p.owner = self.getModule("Output")

	def OnWireChange(self, changeOp):
		try:
			connectedOp = changeOp.inputs[0]
			name = connectedOp.parent().name
			path = self.opLossFunctions[name, "path"]
			op.TDNeuron.op("Engine/Predictions").par.Predictionlayer = path.row-1
		except:
			pass

	def getTopPath(self):
		data = self.ownerComp.par.Datatype.eval()
		dataType = self.opDataTypes[data,"top"]
		dataRoot = op.TDNeuron.op("Engine").path

		path = None
		if op(dataRoot) and dataType != None:
			path = op(dataRoot).path+"/"+dataType

		return path

	def getModule(operator=None):
		if self.opModule.par.Custommodule and op(self.opModule.par.Custommodulecomp):
			m = op(self.opModule.par.Custommodulecomp)
		else:
			m = self.opModule.op("Module")

		if operator:
			m = m.op(operator)
		return m