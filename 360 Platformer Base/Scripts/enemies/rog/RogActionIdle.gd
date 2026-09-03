class_name RogActionIdle
extends EnemyActionParent

func beginAction():
	setAnimationIdle()
	enemy.hopDelayCount = 60
	enemy.groundSpeed = 0
	enemy.velocity = Vector3.ZERO

func action():
	if enemy.animation.currentAnimation != enemy.animation.animationIdle:
		setAnimationIdle()

	if enemy.landed:
		enemy.groundMovement()
		if enemy.hopDelayCount == 0:
			enemy.changeState(enemy.rogActionHop)
		else:
			enemy.hopDelayCount -= 1
	else:
		enemy.airMovement()

func setAnimationIdle():
	enemy.animation.changeAnimation(enemy.animation.animationIdle)
