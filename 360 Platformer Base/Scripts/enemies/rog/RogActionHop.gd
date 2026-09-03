class_name RogActionHop
extends EnemyActionParent

func beginAction():
	enemy.velocity.y = 0.25
	enemy.velocity.x = 0.3 * enemy.direction
	enemy.jumping = true
	enemy.landed = false
	setAnimation()
	enemy.animation.setAnimationDirectionX(enemy.direction)

func action():
	enemy.airMovement()
	if enemy.landed:
		enemy.changeState(enemy.rogActionIdle)

func setAnimation():
	enemy.animation.changeAnimation(enemy.animation.animationHop)
	enemy.animation.setAnimationDirectionX(enemy.direction)
