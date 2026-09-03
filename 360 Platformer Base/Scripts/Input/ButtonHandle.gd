class_name ButtonHandle

var internalButtonName: String
var isPressed: bool
var isHeld: bool
var isReleased: bool
var frameDuration: float
var physicsStartFrame: float

func _init(buttonName: String):
	internalButtonName = buttonName

func updateButton():
	isReleased = false
	if Input.is_action_pressed(internalButtonName):
		if physicsStartFrame == -1:
			physicsStartFrame = FrameCount.physicsFrame
		isPressed = (physicsStartFrame == FrameCount.physicsFrame)
		isHeld = true
		frameDuration += 1
	if physicsStartFrame != FrameCount.physicsFrame:
		isPressed = false

func updateButtonRelease():
	isReleased = false
	if isHeld && !Input.is_action_pressed(internalButtonName) && physicsStartFrame < FrameCount.physicsFrame:
		frameDuration = 0
		isPressed = false
		isHeld = false
		isReleased = true
		physicsStartFrame = -1
	elif !isHeld && !Input.is_action_pressed(internalButtonName):
		isReleased = false
		physicsStartFrame = -1
