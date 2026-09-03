class_name RogEnemy
extends EnemiesParent

var jumping = false
var rogActionIdle: EnemyActionParent
var rogActionHop: EnemyActionParent
var hopDelayCount: int = 0

func _ready():
	animation = RogAnimation.new(self)
	rogActionIdle = RogActionIdle.new(self)
	rogActionHop = RogActionHop.new(self)
	currentAction = rogActionIdle
	direction = -1

func _afterMovement():
	if not landed:
		return
	horizontalCollision = collisionHorizontal()
	if !horizontalCollision.is_empty():
		groundSpeed = 0
		turnAround()
	var edgeResult = checkEdge()
	if edgeResult.is_empty():
		turnAround()
	else:
		turning = false
