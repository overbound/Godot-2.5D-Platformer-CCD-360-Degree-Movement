class_name AnimationHandler

var actor
var currentAnimation: AnimationSet
var currentReverse: bool = false
var currentSubFrame: float = 0
var currentFrame: float
var fps: float = 60
var isFrozenOnFrame: bool
var freezeFrameLength: int
var frozenFrame: int

func calculateCurrentFrame():
	var animFps = currentAnimation.animationSpeed.call(int(currentFrame))
	var frameDelay = fpsToFrameDelay(animFps)
	var physicsFrame = FrameCount.physicsFrame

	if isFrozenOnFrame && frozenFrame + freezeFrameLength > physicsFrame:
		return
	elif isFrozenOnFrame:
		isFrozenOnFrame = false
		frozenFrame = -1
		freezeFrameLength = -1
		currentSubFrame = frameDelay

	currentSubFrame += 1

	if currentSubFrame > frameDelay && currentReverse:
		currentFrame -= 1
		currentSubFrame = 0
		if currentFrame <= 0:
			if currentAnimation.toLoop:
				currentFrame = 0
				currentReverse = false
			else:
				currentAnimation.isAnimationEnded = true

	if currentSubFrame > frameDelay && !currentReverse:
		currentFrame += 1
		currentSubFrame = 0
		if currentFrame >= currentAnimation.numberOfFrames:
			if currentAnimation.toLoop:
				currentFrame = currentAnimation.loopFrame - currentAnimation.startFrame
			else:
				currentFrame = currentAnimation.numberOfFrames - 1
				currentAnimation.isAnimationEnded = true
				if currentAnimation.toReverse:
					currentReverse = true

func fpsToFrameDelay(targetFps: float) -> int:
	if targetFps <= 0:
		return 60
	return int(60.0 / targetFps) - 1

func calculateCurrentRotation(rotationDegrees):
	if actor.sprite != null:
		actor.sprite.rotation.z = deg_to_rad(rotationDegrees)

func replaceCurrentAnimationFrame():
	if currentAnimation.isAnimationEnded == false:
		actor.sprite.frame = currentFrame + currentAnimation.startFrame

func changeAnimation(newAnimation: AnimationSet):
	currentAnimation = newAnimation
	currentFrame = 0
	currentSubFrame = 0
	currentAnimation.isAnimationEnded = false
	actor.sprite.texture = currentAnimation.texture

func setAnimationDirectionX(x):
	if x == 0:
		return
	actor.spriteParent.scale.x = abs(actor.spriteParent.scale.x) * x

func setAnimationDirectionY(y):
	actor.sprite.flip_v = (y == -1)

func freezeFrame(shouldFreeze: bool, frameLength: int):
	isFrozenOnFrame = shouldFreeze
	freezeFrameLength = frameLength
	frozenFrame = FrameCount.physicsFrame
