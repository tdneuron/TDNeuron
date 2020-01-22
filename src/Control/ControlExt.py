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

class Control:
	"""
	
	This module is in charge of controlling the the training process.
	This is achieved by usage of a timerChop that advances "iterations"
	In TDNeuron, a frame constitues an iteration.
	"""
	def __init__(self, ownerComp):
		self.ownerComp 			= ownerComp
		self.opTrainable 		= op('select_TrainableLayers')
		self.opMaxMinibatches 	= op('MaxMinibatches')
		self.opModel 			= op.TDNeuron.op("Engine")
		self.opLog 				= op.TDNeuron.op("Log")
		self.opCachePrediction	= op.TDNeuron.op("Engine/cache_TestPrediction")
		self.opCacheCost		= op.TDNeuron.op("Engine/cache_TestCost")
		self.opCount 			= op("count")
		self.epochsSinceStart 	= 0

	def Train(self, toggle):
		# self.opTimer.par.play = toggle
		if toggle:
			self.epochsSinceStart = 0
			# self.opTimer.par.start.pulse()

	def Test(self):
		training = self.ownerComp.par.Train.eval()
		if training: 
			self.ownerComp.par.Train = False
		testing = self.opModel.par.Testing.eval()

		self.opModel.par.Testing = True
		self.opModel.cook(force=True)
		self.opCachePrediction.par.activepulse.pulse()
		self.opCachePrediction.par.prefillpulse.pulse()
		self.opCacheCost.par.activepulse.pulse()
		self.opCacheCost.par.prefillpulse.pulse()
		
		if not testing:
			self.opModel.par.Testing = False

		if training:
			self.ownerComp.par.Train = True

	def NextEpoch(self):
		self.ownerComp.par.Currentepoch += 1

		miniBatches = max(int(self.opMaxMinibatches[0]), 1)
		iteration = self.ownerComp.par.Currentepoch * miniBatches + self.ownerComp.par.Currentminibatch
		self.opCount.par.resetvalue = iteration
		self.opCount.par.reset.pulse()
		self.ownerComp.par.Train = False

	def NextMinibatch(self):
		newBatch = self.ownerComp.par.Currentminibatch+1
		miniBatches = int(self.opMaxMinibatches[0])
		if newBatch >= miniBatches:
			self.ownerComp.par.Currentepoch += 1 
		self.ownerComp.par.Currentminibatch = newBatch % miniBatches

		iteration = self.ownerComp.par.Currentepoch * miniBatches + self.ownerComp.par.Currentminibatch
		self.opCount.par.resetvalue = iteration
		self.opCount.par.reset.pulse()

		self.ownerComp.par.Train = False

	def Update(self, minibatch, epoch):
		if minibatch < 0 and epoch < 0:
			return

		miniBatches = max(int(self.opMaxMinibatches[0]), 1)
		iteration = epoch * miniBatches + minibatch
		for i in range(self.opTrainable.numRows):
			n = self.opModel.op(self.opTrainable[i, 0])
			try:
				n.par.Iteration = iteration
				n.par.Update.pulse()
			except:
				pass

		currentBatch = iteration % miniBatches
		self.ownerComp.par.Currentepoch = iteration / miniBatches
		self.ownerComp.par.Currentminibatch = currentBatch

		if currentBatch == 0:
			self.opLog.par.Updateepoch.pulse()				
			self.epochsSinceStart += 1
			if self.ownerComp.par.Testafterepoch > 0 and self.epochsSinceStart % int(self.ownerComp.par.Testafterepoch.val) == 0:
				self.Test()

		self.opLog.par.Update.pulse()

	def SetEpoch(self, epoch):
		self.ownerComp.par.Currentepoch = epoch
		
		miniBatches = max(int(self.opMaxMinibatches[0]), 1)
		iteration = self.ownerComp.par.Currentepoch * miniBatches + self.ownerComp.par.Currentminibatch
		self.opCount.par.resetvalue = iteration
		self.opCount.par.reset.pulse()

	def Reset(self):
		self.ownerComp.par.Currentepoch = 0
		self.ownerComp.par.Currentminibatch = 0
		self.opCount.par.resetvalue = 0
		self.opCount.par.reset.pulse()

		model = op.TDNeuron.op("Model")
		if model.par.Dirty == True:
			self.Build()
		else:
			for i in range(self.opTrainable.numRows):
				n = self.opModel.op(self.opTrainable[i, 0])
				n.par.Iteration = 0
				n.par.Reset = 1
				self.opLog.par.Reset.pulse()
				run('op("'+n.path+'").par.Reset = 0', delayFrames=1)

	def Build(self):
		model = op.TDNeuron.op("Model")
		model.par.Build.pulse()
		model.par.Dirty = False
		run('op("'+self.ownerComp.path+'").Reset()', delayFrames=1)
