class_name SealbotActionPatrol
extends EnemyActionParent

const PATROL_SPEED: float = 0.15
const WALL_CHECK_DIST: float = 20.0
const EDGE_CHECK_DIST: float = 8.0

func beginAction():
	enemy.velocity = Vector3.ZERO
	enemy.groundSpeed = 0
	enemy.animation.changeAnimation(enemy.animation.animationIdle)
	enemy.animation.setAnimationDirectionX(enemy.direction)

func action():
	enemy.groundSpeed = enemy.direction * PATROL_SPEED
	if enemy.landed:
		if hitWall() and atCliff():
			enemy.direction *= -1
			enemy.animation.setAnimationDirectionX(enemy.direction)
			enemy.groundSpeed = enemy.direction * PATROL_SPEED
		enemy.groundMovement()
	else:
		enemy.airMovement()

func hitWall() -> bool:
	var spaceState = enemy.get_world_3d().direct_space_state
	var from = enemy.global_position + Vector3(0, 1.0, 0)
	var to = from + Vector3(enemy.direction * WALL_CHECK_DIST, 0, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	var result = spaceState.intersect_ray(query)
	if result.is_empty():
		return false
	var n = result.get("normal", Vector3.ZERO)
	return abs(n.x) > 0.5 and abs(n.y) < 0.5

func atCliff() -> bool:
	var spaceState = enemy.get_world_3d().direct_space_state
	var from = enemy.global_position + Vector3(enemy.direction * EDGE_CHECK_DIST, 0, 0)
	var to = from + Vector3(0, -200.0, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	return spaceState.intersect_ray(query).is_empty()

func endAction():
	enemy.velocity = Vector3.ZERO
	enemy.groundSpeed = 0
