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
	def __init__(self, ownerComp):
		self.ownerComp = ownerComp
		self.playButton = op("buttonMomentary2")
		self.epochStepButton = op("Info/Add1")
		self.minibatchStepButton = op("Info/Add")
		self.minibatchLockButton = op("Info/buttonToggle1")

	def Pause(self):
		op.TDNeuron.op("Control").par.Train = False
		self.playButton.par.Value0 = False

	def Play(self):
		op.TDNeuron.op("Control").par.Train = True
		self.playButton.par.Value0 = True

	def StepMinibatch(self):
		op.TDNeuron.op("Control").par.Nextminibatch.pulse()

	def StepEpoch(self):
		op.TDNeuron.op("Control").par.Nextepoch.pulse()

	def LockMinibatch(self, lock):
		op.TDNeuron.op("Control").par.Lockminibatch = lock

	def Reset(self):
		op.TDNeuron.op("Control").par.Reset.pulse()

	def Rebuild(self):
		op.TDNeuron.op("Model").par.Build.pulse()

	def ToggleToolbar(self, toggle):
		if toggle:
			p = ui.panes.current
			if ui.panes['TDNeuronToolbar'] == None:
				tp = p.splitTop()
				tp.ratio = 0.85
				tp.owner = op.TDNeuron.op("Model/Toolbar")
				tp.name = "TDNeuronToolbar"
				tp.changeType(PaneType.PANEL)
		elif ui.panes['TDNeuronToolbar'] != None:
			ui.panes['TDNeuronToolbar'].close()

	def FloatingCopy(self, toggle):
		if toggle:
			self.ownerComp.openViewer(unique=True)
		else:
			self.ownerComp.closeViewer()
