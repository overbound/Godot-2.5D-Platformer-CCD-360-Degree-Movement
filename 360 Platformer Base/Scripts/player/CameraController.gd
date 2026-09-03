class_name CameraController
extends Node

var camera: Camera3D
var player: Player

var cameraZOffset: float = 76.0
var deadZoneHalfWidth: float = 1.25
var deadZoneHalfHeight: float = 1.0

var anchor: Vector2 = Vector2.ZERO
var initialized: bool = false
var prevPlayerX: float = 0.0

var lookaheadSpeedThreshold: float = 1.5
var lookaheadDistance: float = 20.0
var lookaheadStep: float = 0.625
var speedShiftOffset: float = 0.0

var limitLeft: float = -INF
var limitRight: float = INF
var limitTop: float = INF
var limitBottom: float = -INF

var noise: FastNoiseLite
var shakeIntensity: float = 0.0
var shakeTimer: float = 0.0
var shakeDuration: float = 0.0
var noiseTime: float = 0.0

var entranceActive: bool = false
var entranceHeight: float = 0.0
var entranceTimer: float = 0.0
var entranceDuration: float = 0.0

func _init(newPlayer: Player = null, targetCamera: Camera3D = null):
	if newPlayer:
		player = newPlayer
	if targetCamera:
		camera = targetCamera

func setup(targetCamera: Camera3D):
	camera = targetCamera
	if camera == null:
		push_warning("CameraController: received null Camera3D")
		return
	camera.top_level = true
	anchor = Vector2(player.global_position.x, player.global_position.y)
	prevPlayerX = player.global_position.x
	snapCamera()
	initialized = true
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 4.0
	call_deferred("printInitialLimits")

func _physics_process(delta):
	if not initialized:
		return
	updateLimits()
	updateAnchor()
	updateSpeedShift(delta)
	clampAnchorToLimits()
	applyCameraPosition(delta)

func updateAnchor():
	var px = player.global_position.x
	var py = player.global_position.y
	if px < anchor.x - deadZoneHalfWidth:
		anchor.x = px + deadZoneHalfWidth
	elif px > anchor.x + deadZoneHalfWidth:
		anchor.x = px - deadZoneHalfWidth
	if py < anchor.y - deadZoneHalfHeight:
		anchor.y = py + deadZoneHalfHeight
	elif py > anchor.y + deadZoneHalfHeight:
		anchor.y = py - deadZoneHalfHeight

func updateSpeedShift(_delta: float):
	var currentX: float = player.global_position.x
	var spd: float = absf(currentX - prevPlayerX)
	var targetOffset: float = 0.0
	if spd >= lookaheadSpeedThreshold:
		var moveDir: float = signf(currentX - prevPlayerX)
		if moveDir == 0.0:
			moveDir = player.physics.direction
		targetOffset = moveDir * lookaheadDistance
	speedShiftOffset = move_toward(speedShiftOffset, targetOffset, lookaheadStep)
	prevPlayerX = currentX

func clampAnchorToLimits():
	var halfH = getVisibleHalfHeight()
	var halfW = halfH * camera.get_viewport().get_visible_rect().size.x \
				/ camera.get_viewport().get_visible_rect().size.y
	var clampedLeft = limitLeft + halfW
	var clampedRight = limitRight - halfW
	var clampedBot = limitBottom + halfH
	var clampedTop = limitTop - halfH
	if clampedLeft > clampedRight:
		anchor.x = (limitLeft + limitRight) * 0.5
	else:
		anchor.x = clampf(anchor.x, clampedLeft, clampedRight)
	if clampedBot > clampedTop:
		anchor.y = (limitBottom + limitTop) * 0.5
	else:
		anchor.y = clampf(anchor.y, clampedBot, clampedTop)

func getVisibleHalfHeight() -> float:
	var dist = cameraZOffset
	return tan(deg_to_rad(camera.fov * 0.5)) * dist

func applyCameraPosition(delta: float):
	var halfH := getVisibleHalfHeight()
	var halfW := halfH * camera.get_viewport().get_visible_rect().size.x \
				/ camera.get_viewport().get_visible_rect().size.y
	var insetLeft := limitLeft + halfW
	var insetRight := limitRight - halfW
	var rawX := anchor.x + speedShiftOffset
	var finalX: float
	if insetLeft > insetRight:
		finalX = (limitLeft + limitRight) * 0.5
	else:
		finalX = clampf(rawX, insetLeft, insetRight)
	var targetPos = Vector3(finalX, anchor.y, player.global_position.z + cameraZOffset)

	if entranceActive:
		entranceTimer += delta
		var t = clampf(entranceTimer / entranceDuration, 0.0, 1.0)
		var eased = 1.0 - pow(1.0 - t, 3.0)
		targetPos.y += entranceHeight * (1.0 - eased)
		if t >= 1.0:
			entranceActive = false

	camera.global_position = camera.global_position.lerp(targetPos, 12.0 * delta)

	if shakeTimer > 0:
		shakeTimer -= delta
		noiseTime += delta * 60.0
		var t = shakeTimer / shakeDuration if shakeDuration > 0 else 0.0
		var currentIntensity = shakeIntensity * t
		var offsetX = noise.get_noise_2d(noiseTime, 0.0) * currentIntensity
		var offsetY = noise.get_noise_2d(0.0, noiseTime) * currentIntensity
		camera.global_position += Vector3(offsetX, offsetY, 0.0)
	else:
		shakeIntensity = 0.0

func snapCamera():
	if camera:
		camera.global_position = Vector3(anchor.x, anchor.y, player.global_position.z + cameraZOffset)

func printInitialLimits():
	updateLimits()
	var zones = get_tree().get_nodes_in_group("camera_limit_zones")
	for zone in zones:
		var aabb = zone.getTriggerAabb()

func updateLimits():
	var zones = get_tree().get_nodes_in_group("camera_limit_zones")
	if zones.is_empty():
		return
	var px := player.global_position.x
	var py := player.global_position.y
	var pz := player.global_position.z
	var playerZones: Array = []
	for zone in zones:
		if zone.triggerContains(px, py, pz):
			playerZones.append(zone)
	if playerZones.is_empty():
		return
	var best: CameraLimitZone = null
	var bestPriority: int = -2147483648
	var bestWidth: float = INF
	for zone in playerZones:
		var w: float = zone.limitRight - zone.limitLeft
		if best == null or zone.zonePriority > bestPriority or (zone.zonePriority == bestPriority and w < bestWidth):
			best = zone
			bestPriority = zone.zonePriority
			bestWidth = w
	var first := true
	for zone in zones:
		if zone == best or zonesOverlap(best, zone):
			if first:
				limitLeft = zone.limitLeft
				limitRight = zone.limitRight
				limitTop = zone.limitTop
				limitBottom = zone.limitBottom
				first = false
			else:
				limitLeft = minf(limitLeft, zone.limitLeft)
				limitRight = maxf(limitRight, zone.limitRight)
				limitTop = maxf(limitTop, zone.limitTop)
				limitBottom = minf(limitBottom, zone.limitBottom)

func zonesOverlap(a: CameraLimitZone, b: CameraLimitZone) -> bool:
	return a.limitLeft < b.limitRight and a.limitRight > b.limitLeft \
	   and a.limitBottom < b.limitTop and a.limitTop > b.limitBottom

func startShake(intensity: float, duration: float):
	if intensity > shakeIntensity:
		shakeIntensity = intensity
	if duration > shakeTimer:
		shakeTimer = duration
		shakeDuration = duration

func testShake():
	startShake(0.5, 1.0)

func startEntrance(heightOffset: float = 120.0, duration: float = 10.0):
	entranceActive = true
	entranceHeight = heightOffset
	entranceTimer = 0.0
	entranceDuration = duration
