class_name AnimationSet

var toLoop: bool
var toReverse: bool
var isAnimationEnded: bool
var startFrame: int
var sprite: Sprite3D
var numberOfFrames: int
var loopFrame: int
var animationSpeed: Callable
var texture: Texture

func _init(toLoop: bool, toReverse: bool, startFrame: int, sprite: Sprite3D, numberOfFrames: int,
		loopFrame: int, animationSpeed: Callable, texture: Texture):
	self.toLoop = toLoop
	self.toReverse = toReverse
	self.startFrame = startFrame
	self.sprite = sprite
	self.numberOfFrames = numberOfFrames
	self.loopFrame = loopFrame
	self.animationSpeed = animationSpeed
	self.texture = texture
	self.isAnimationEnded = false
