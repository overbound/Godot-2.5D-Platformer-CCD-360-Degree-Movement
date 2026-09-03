class_name ActionableInput

var buttonInputs: Array
var axisInput: AxisHandle
var axisDirection: int
var action: ActionParent

func _init(action: ActionParent, buttonInputs: Array, axisInput: AxisHandle, axisDirection: int):
	self.action = action
	self.buttonInputs = buttonInputs
	self.axisInput = axisInput
	self.axisDirection = axisDirection
