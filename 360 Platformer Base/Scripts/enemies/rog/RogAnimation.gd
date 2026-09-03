class_name RogAnimation
extends AnimationHandler

var animationHop: AnimationSet
var animationIdle: AnimationSet
var spriteTexture

func _init(newActor: EnemiesParent):
	spriteTexture = load("res://sprites/enemies/smallrog.png")
	actor = newActor
	animationHop = AnimationSet.new(false, false, 1, actor.sprite, 5, 0, Callable(self, "hopSpeed"), spriteTexture)
	animationIdle = AnimationSet.new(true, false, 0, actor.sprite, 1, 0, Callable(self, "hopSpeed"), spriteTexture)
	currentAnimation = animationHop

func hopSpeed(frame: int = 0):
	if frame == 1:
		return 2
	else:
		return 15
