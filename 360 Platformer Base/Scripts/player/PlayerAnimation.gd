class_name PlayerAnimation
extends AnimationHandler

var animationRun: AnimationSet
var animationHover: AnimationSet
var animationJump: AnimationSet
var animationIdle: AnimationSet
var animationCrouch: AnimationSet
var animationLookUp: AnimationSet
var animationPush: AnimationSet

var spriteTexture: CompressedTexture2D

func _init(newActor: Player):
	actor = newActor
	spriteTexture = load("res://icon.svg")

	animationHover = AnimationSet.new(true, false, 0, null, 1, 0, Callable(self, "hoverSpeed"), spriteTexture)
	animationRun = AnimationSet.new(true, false, 0, null, 1, 0, Callable(self, "runSpeed"), spriteTexture)
	animationJump = AnimationSet.new(true, false, 0, null, 1, 0, Callable(self, "jumpSpeed"), spriteTexture)
	animationIdle = AnimationSet.new(true, false, 0, null, 1, 0, Callable(self, "idleSpeed"), spriteTexture)
	animationLookUp = AnimationSet.new(true, false, 0, null, 1, 0, Callable(self, "lookUpSpeed"), spriteTexture)
	animationCrouch = AnimationSet.new(true, false, 0, null, 1, 0, Callable(self, "crouchSpeed"), spriteTexture)
	animationPush = AnimationSet.new(true, false, 0, null, 1, 0, Callable(self, "pushSpeed"), spriteTexture)

	currentAnimation = animationRun

func runSpeed(_frame: int = 0):
	var speedRatio = abs(actor.physics.groundSpeed) / actor.physics.maxGroundSpeed
	return max(lerp(8.0, 20.0, speedRatio), 2.0)

func hoverSpeed(_frame: int = 0): return 15.0
func jumpSpeed(_frame: int = 0): return 15.0
func idleSpeed(_frame: int = 0): return 6.0
func pushSpeed(_frame: int = 0): return 4.0
func lookUpSpeed(_frame: int = 0): return 6.0
func crouchSpeed(_frame: int = 0): return 6.0

func calculateCurrentRotation(rotationDegrees):
	if actor.isDying:
		return
	if actor.get_node_or_null("SpriteParent/Sprite"):
		var spr = actor.get_node("SpriteParent/Sprite")
		var normalized = fmod(rotationDegrees + 180, 360) - 180
		spr.rotation.z = deg_to_rad(normalized * actor.physics.direction)
