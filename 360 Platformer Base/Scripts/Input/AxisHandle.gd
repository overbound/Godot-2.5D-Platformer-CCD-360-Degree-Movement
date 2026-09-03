class_name AxisHandle

var internalNegativeAxis: String
var internalPositiveAxis: String
var isPressed: bool
var isHeld: bool
var isReleased: bool
var frameDuration: float
var direction: int = 0
var deadZone: float = 0.05
var position: float

func _init(negativeAxis: String, positiveAxis: String):
	internalNegativeAxis = negativeAxis
	internalPositiveAxis = positiveAxis

func updateAxis():
	position = Input.get_axis(internalNegativeAxis, internalPositiveAxis)
	if abs(position) > deadZone:
		isPressed = (frameDuration == 0)
		isHeld = true
		frameDuration += 1
		direction = sign(position)
		isReleased = false

func updateAxisRelease():
	var axisPosition: float = Input.get_axis(internalNegativeAxis, internalPositiveAxis)
	if isHeld && abs(axisPosition) <= deadZone:
		frameDuration = 0
		direction = 0
		isPressed = false
		isHeld = false
		isReleased = true
		position = 0
	elif !isHeld && abs(axisPosition) <= deadZone:
		isReleased = false
