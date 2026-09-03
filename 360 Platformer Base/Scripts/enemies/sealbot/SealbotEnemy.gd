class_name SealbotEnemy
extends EnemiesParent

var sealbotActionPatrol: EnemyActionParent

@export var startDirection: int = -1

func _ready():
	animation = SealbotAnimation.new(self)
	sealbotActionPatrol = SealbotActionPatrol.new(self)
	direction = startDirection
	groundOffset = 3.5
	currentAction = sealbotActionPatrol
	currentAction.beginAction()
