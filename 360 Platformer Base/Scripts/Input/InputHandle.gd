extends Node
class_name InputHandle

var buttonJump: ButtonHandle
var xAxis1: AxisHandle
var yAxis1: AxisHandle
var bufferedButton: ButtonHandle

func _init():
	buttonJump = ButtonHandle.new("ui_accept")
	xAxis1 = AxisHandle.new("ui_left", "ui_right")
	yAxis1 = AxisHandle.new("ui_up", "ui_down")

func _process(_delta):
	buttonJump.updateButton()
	xAxis1.updateAxis()
	yAxis1.updateAxis()
	if buttonJump.isPressed:
		bufferedButton = buttonJump

func updateButtonRelease():
	buttonJump.updateButtonRelease()
	xAxis1.updateAxisRelease()
	yAxis1.updateAxisRelease()

func getLastButtonPressed() -> ButtonHandle:
	var button = bufferedButton
	bufferedButton = null
	return button

func scrubAcceptedInputs():
	pass

func clearBufferedInput(button: ButtonHandle):
	if bufferedButton == button:
		bufferedButton = null
