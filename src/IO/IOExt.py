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

import json
import os.path

class IO:
	"""
	This class is in charge of loading and saving models and its current 
	training state. 
	"""
	def __init__(self, ownerComp):
		self.ownerComp 			= ownerComp
		self.opControl			= op.TDNeuron.op("Control")
		self.opModule			= op.TDNeuron.op("Module")
		self.opEngine			= op.TDNeuron.op("Engine")

	# PUBLIC functions
	def ExportModel(self):
		"""
		Export the model to JSON and an image file
		"""
		path = self.ownerComp.par.Exportfolder
		name = self.ownerComp.par.Modelname
		if self.exportJSON(path+"/"+name+".json"):
			self.exportWeights(path+"/"+name+".exr")

	def ImportModel(self):
		"""
		Import the model from a JSON and image file
		"""		
		path = self.ownerComp.par.Importfile.val
		file = path.rsplit('.', 1)[0]

		jsonFile = file+".json"
		exrFile = file+".exr"

		if not os.path.isfile(jsonFile):
			print("JSON file not found. ({})")
			return

		elif not os.path.isfile(exrFile):
			print("EXR file not found. ({})")
			return

		success = self.importJSON(jsonFile)
		success &= self.initializeModel()

		if success:
			self.OnImported(exrFile, 0)

	def OnImported(self, exrFile, state=0):
		"""
		OnImport delayed callback to initialize the model
		"""	
		delayedFrames = 1
		if state == 0:
			op.TDNeuron.op("Model/Sys").Destroy()
			op.TDNeuron.op("Engine").DestroyModel()
		elif state == 1:
			op.TDNeuron.op("IO/Load").par.Weightsimage = exrFile
		elif state == 2:
			op.TDNeuron.op("Engine").CreateModel()
			op.TDNeuron.op("IO").par.Rebuild.pulse()
		elif state == 3:
			op.TDNeuron.op("IO/Load").par.Push.pulse()
			op.TDNeuron.op("Model/Sys").Load()
			try:
				self.initializeModel()
				# self.opControl.par.Test.pulse()
				ui.messageBox("TDNeuron", "Model loaded.", buttons=['ok'])
			except:
				ui.messageBox("TDNeuron", "Model loading failed.", buttons=['ok'])
			return
		else:
			return

		state += 1
		run('op.TDNeuron.op("IO").OnImported("'+exrFile+'", '+str(state)+')', delayFrames=delayedFrames)

	# PRIVATE functions
	def exportJSON(self, path):
		try:
			model = op.TDNeuron.op('Session').Get(True)
		except e:
			print("Error! Could not get session: ",e)
			return False

		try:			
			data = json.dumps(model, indent=2)
		except:
			print("Error! Could not convert model to JSON format.")
			return False

		if (os.path.isfile(path)):
			r = ui.messageBox("Warning", "File already exists. Overwrite?", buttons=['yes', 'no'])
			if r != 0:
				return False

		try:			
			fp = open(path,"w")
			fp.write(data)
			fp.close()
		except:
			print("Error! Could not save JSON file: "+path)
			return False

		ui.messageBox("TDNeuron", "Model saved.", buttons=['ok'])
		return True

	def exportWeights(self, path):
		op.TDNeuron.op("IO/Save/Weights").save(path)

	def importJSON(self, path):
		try:			
			fp = open(path, "r")
			data = fp.read()
			fp.close()
		except:
			print("Error! Could not read JSON file: "+path)
			return False

		try:			
			self.model = json.loads(data)
		except:
			print("Error! Could not convert JSON to model object.")
			return False

		return True

	def initializeModel(self):

		# Set current epoch
		self.opControl.SetEpoch(int(self.model["Info"]["Epoch"]))

		# Load module
		module = str(self.model["Info"]["Module"])
		if module not in self.opModule.par.Module.menuNames:
			print("Error! Input module not found: ", module)
			return False

		# Set module parameters
		if "Module" in self.model:
			self.opModule.par.Module = module
			self.opModule.cook(force=True)
			self.setParameters(self.opModule.op("Module"), self.model["Module"])

		# Set engine parameters
		if "Global" in self.model:
			self.setParameters(self.opEngine, self.model["Global"])

		# Disable test mode in case is active
		self.opEngine.par.Testing = False

		# Set session
		try:
			op.TDNeuron.op('Session').Set(self.model)
		except:
			print("Error! Could not set session.")
			return False

		return True

	def setParameters(self, o, parameters):
		for p in parameters.items():
			try:
				getattr(o.par, p[0]).val = p[1]
			except:
				pass
