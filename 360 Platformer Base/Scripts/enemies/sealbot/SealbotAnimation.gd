class_name SealbotAnimation
extends AnimationHandler

var animationIdle: AnimationSet
var spriteTexture: Texture2D

func _init(newActor: EnemiesParent):
	actor = newActor
	spriteTexture = load("res://sprites/enemies/sealbot.png")
	animationIdle = AnimationSet.new(false, false, 0, actor.sprite, 1, 0, Callable(self, "idleSpeed"), spriteTexture)
	currentAnimation = animationIdle

func idleSpeed(frame: int = 0) -> float:
	return 60.0
