class_name FrameCounter
extends Node

var physicsFrame: int = 0
var deltaTime: float = 0
var deltaPhysicsTime: float = 0

func _physics_process(delta):
	physicsFrame += 1
	deltaPhysicsTime = delta

func _process(delta: float) -> void:
	deltaTime = delta
