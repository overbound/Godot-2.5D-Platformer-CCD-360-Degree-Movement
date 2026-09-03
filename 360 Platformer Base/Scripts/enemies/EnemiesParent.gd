class_name EnemiesParent
extends Node3D

@onready var spriteParent = get_node("SpriteParent")
@onready var sprite: Sprite3D = spriteParent.get_node("Sprite")
var enemy: EnemiesParent
var bufferedAction: EnemyActionParent
var previousAction: EnemyActionParent
var currentAction: EnemyActionParent
var stateTimer: float
var isInvincible: bool
var direction: int = 1
var speed: float = 1
var landed: bool = false
var rng: RandomNumberGenerator
@export var verticalHorizontalCollisionOffset: float = 0
var horizontalCollision
var turning: bool
var relativeAngle: float = 0
var animation: AnimationHandler
var playerTarget: Player

var groundSpeed: float = 0.0
var velocity: Vector3 = Vector3.ZERO
var groundVector: Vector2 = Vector2.RIGHT
var groundOffset: float = 1.0
var gravity: float = 0.05
var maxGroundSpeed: float = 2.0
var acceleration: float = 0.046875 / 4
var deceleration: float = 0.625 / 4
var friction: float = 0.046875 / 4
var maxYVelocity: float = 4.0
var jumpVelocity: float = 1.5
var collisionBoundsOffset: float = 0.25
var minDistance: float = 0.1

var offScreenCheckTimer: int = 0
var isOnScreen: bool = true
var wasOnScreen: bool = true
var lockedControlsTimer: float = 0
var lockedControls: bool = false

enum SurfaceMode { FLOOR = 0, CEILING = 1, RIGHT_WALL = 2, LEFT_WALL = 3 }

var groundMode: int:
	get:
		if not landed:
			return SurfaceMode.FLOOR
		var angle = relativeAngle
		if angle >= 315 or angle < 45:
			return SurfaceMode.FLOOR
		elif angle >= 45 and angle < 135:
			return SurfaceMode.RIGHT_WALL
		elif angle >= 135 and angle < 225:
			return SurfaceMode.CEILING
		else:
			return SurfaceMode.LEFT_WALL
	set(v):
		pass

func customInit(newEnemy: EnemiesParent):
	enemy = newEnemy
	rng = RandomNumberGenerator.new()

func destroyEnemy():
	queue_free()

func chooseRandomStateList(choices: Array):
	changeState(choices[floor(rng.randf_range(0, choices.size()))])

func setLockedControls(timer: float):
	lockedControlsTimer = timer
	lockedControls = true

func react(player: Player):
	playerTarget = player
	var dirToPlayer = sign(player.global_position.x - global_position.x)
	if dirToPlayer != 0:
		direction = dirToPlayer
		if animation:
			animation.setAnimationDirectionX(dirToPlayer)
	return true

func _process(_delta):
	animation.replaceCurrentAnimationFrame()

func _physics_process(_delta):
	offScreenCheckTimer += 1
	if offScreenCheckTimer >= 10:
		offScreenCheckTimer = 0
		var cam = get_viewport().get_camera_3d()
		if cam == null:
			isOnScreen = true
		else:
			var pos2d = cam.unproject_position(global_position)
			var vpSize = get_viewport().get_visible_rect().size
			var margin = 200.0
			isOnScreen = pos2d.x >= -margin and pos2d.x <= vpSize.x + margin and pos2d.y >= -margin and pos2d.y <= vpSize.y + margin
	if isOnScreen and not wasOnScreen:
		velocity = Vector3.ZERO
		groundSpeed = 0.0
	wasOnScreen = isOnScreen
	if not isOnScreen:
		velocity = Vector3.ZERO
		groundSpeed = 0.0
		return
	if lockedControlsTimer > 0:
		lockedControlsTimer -= 1
		if lockedControlsTimer <= 0:
			lockedControls = false
	if bufferedAction != null:
		currentAction.endAction()
		previousAction = currentAction
		currentAction = bufferedAction
		bufferedAction = null
		currentAction.beginAction()
	currentAction.action()
	animation.calculateCurrentFrame()

func setAngle(normal: Vector2) -> float:
	return fmod(rad_to_deg(atan2(normal.y, normal.x)) + 360.0, 360.0)

func findGroundMode(angle: float) -> int:
	if angle >= 315 or angle < 45:
		return SurfaceMode.FLOOR
	elif angle >= 45 and angle < 135:
		return SurfaceMode.RIGHT_WALL
	elif angle >= 135 and angle < 225:
		return SurfaceMode.CEILING
	else:
		return SurfaceMode.LEFT_WALL

func angleDiff(a: float, b: float) -> float:
	var d = fmod(a - b + 540.0, 360.0) - 180.0
	return d

func collisionBelow():
	var spaceState = get_world_3d().direct_space_state
	if spaceState == null:
		return null
	var start = position + Vector3(0, 0.5, 0)
	var endPos = position + Vector3(0, -200, 0)
	var query = PhysicsRayQueryParameters3D.create(start, endPos)
	query.collision_mask = 2
	query.collide_with_bodies = true
	var result = spaceState.intersect_ray(query)
	if !result.is_empty():
		return result
	return null

func projectVelocityOntoGround() -> void:
	velocity.x = groundVector.x * groundSpeed
	velocity.y = groundVector.y * groundSpeed

func airMovement():
	velocity.y -= gravity
	if abs(velocity.y) > maxYVelocity:
		velocity.y = maxYVelocity * sign(velocity.y)
	if velocity.y <= 0:
		var hit = _raycast(position + Vector3(0, 0.5, 0), Vector3.DOWN, 200)
		if hit != null:
			var groundY = hit.get("position").y
			var newY = position.y + velocity.y
			if newY <= groundY + groundOffset and newY > groundY - 4.0:
				position = Vector3(position.x + velocity.x, groundY + groundOffset, position.z)
				landed = true
				groundSpeed = velocity.x
				velocity = Vector3.ZERO
				_afterMovement()
				return
	position = position + velocity
	landed = false
	_afterMovement()

func groundMovement():
	var hit = collisionBelow()
	if hit == null:
		landed = false
		return
	groundVector = Vector2.RIGHT
	projectVelocityOntoGround()
	position = Vector3(position.x + velocity.x, hit.get("position").y + groundOffset, position.z)
	landed = true
	_afterMovement()

func _afterMovement():
	pass

func turnAround():
	if not turning:
		direction *= -1
		groundSpeed = abs(groundSpeed) * direction
		turning = true
		if animation:
			animation.setAnimationDirectionX(direction)

func collisionHorizontal():
	var spaceState = get_world_3d().direct_space_state
	var end = position + Vector3(4 * direction, verticalHorizontalCollisionOffset, 0)
	var query = PhysicsRayQueryParameters3D.create(
		position + Vector3(0, verticalHorizontalCollisionOffset, 0), end)
	query.collide_with_areas = true
	query.collision_mask = 2
	var result = spaceState.intersect_ray(query)
	if !result.is_empty():
		result["distance"] = position.distance_to(result.get("position"))
	return result

func checkEdge():
	var spaceState = get_world_3d().direct_space_state
	var start = Vector3(position.x + 2 * direction, position.y + 4, position.z)
	var end = start + Vector3(0, -20, 0)
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 2
	var result = spaceState.intersect_ray(query)
	return result

func _raycast(from: Vector3, dir: Vector3, dist: float):
	var spaceState = get_world_3d().direct_space_state
	if spaceState == null:
		return null
	var to = from + dir.normalized() * dist
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	query.collide_with_bodies = true
	var result = spaceState.intersect_ray(query)
	if !result.is_empty():
		result["distance"] = from.distance_to(result.get("position"))
	return result if !result.is_empty() else null

func chooseRandomStatePercentage(choice1: EnemyActionParent, choice2: EnemyActionParent, percentChoice1: int):
	var difference = 100 - percentChoice1
	var randomNum = floor(randf_range(0, 100))
	if randomNum > difference:
		changeState(choice1)
	else:
		changeState(choice2)

func changeState(newAction: EnemyActionParent):
	bufferedAction = newAction
	stateTimer = 0
