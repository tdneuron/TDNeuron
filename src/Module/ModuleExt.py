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

class Module:
	"""
	This class manages the input modules.
	"""
	def __init__(self, ownerComp):
		self.ownerComp = ownerComp
		self.modulePath = ownerComp.par.Modulepath
		self.opModule = ownerComp.op("Module")
		self.opFolder = ownerComp.op("folder_Modules")
		self.opSessionInfo = ownerComp.op("SessionInfo")
		
		self.UpdateMenuNames()

	###############
	# PUBLIC
	###############

	def Load(self, module):
		try:
			path = parent().par.Modulepath.val + "/" + str(op(self.opFolder)[module, "relpath"])
		except:
			print ("Error. Input module '"+module+"' not found.")
			return

		self.opModule.par.externaltox = path
		self.opModule.par.reinitnet.pulse()
		self.LoadModule(self.opModule)

		# parCHOP seems not to cook after insert module, so lets force cook it
		self.ownerComp.op("par1").cook(force=True)
		# if op("Module"):
		# 	o = op("Module").load(path)
		# else:
		# 	o = self.ownerComp.loadTox(path)
		# if o != None:
			# o.name = "Module"
			# o.par.parentshortcut = "Module"
			# o.nodeX = 0
			# o.nodeY = 0
			# o.showCustomOnly = True

			# self.ownerComp.op("par1").cook(force=True)
			# self.LoadModule(o)
			# self.ownerComp.op("par1").cook(force=True)
			
	def UpdateMenuNames(self):
		modules = [str(op(self.opFolder)[i,"basename"]) for i in range(1, op(self.opFolder).numRows)]
		parent().par.Module.menuNames = modules
		parent().par.Module.menuLabels = modules

	def LoadModule(self, operator):
		if not operator.op("Module") or not operator.op("Module").isDAT:
			print("'Module'-DAT table not found.")
			return

		try:
			o = operator.op("Module")
			self.ownerComp.par.Name = o['name',1] or ""
			self.ownerComp.par.Version = o['version',1] or ""
			self.ownerComp.par.Date = o['date',1] or ""
			self.ownerComp.par.Author = o['author',1] or ""
			self.ownerComp.par.Comp = operator.path
			
			operators = operator.op("Operators")
			processedTypes = []
			for i in range(1, operators.numRows):
				t = operators[i,'type']
				if t in processedTypes:
					continue
				processedTypes.append(t)
				
				if op('select_'+t):
					selectOp = op('select_'+t)
					if t == 'info':
						selectOp.par.chop = operator.path+"/"+operators[i,'path']
					else:
						selectOp.par.top = operator.path+"/"+operators[i,'path']

		except Exception as e:
			print ("Could not load module due: ", e)
			return

