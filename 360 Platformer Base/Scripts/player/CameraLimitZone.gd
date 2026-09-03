class_name CameraLimitZone
extends Area3D

@export var zonePriority: int = 0
@export var alwaysActive: bool = true

var limitLeft: float = -INF
var limitRight: float = INF
var limitTop: float = INF
var limitBottom: float = -INF
var triggerZMin: float = -INF
var triggerZMax: float = INF

func _ready():
	add_to_group("camera_limit_zones")
	collision_layer = 0
	collision_mask = 0
	computeLimitsFromShape()

func computeLimitsFromShape():
	for child in get_children():
		if child is CollisionShape3D:
			var box = child.shape as BoxShape3D
			if box:
				var cx = child.global_position.x
				var cy = child.global_position.y
				var cz = child.global_position.z
				var hx = box.size.x * 0.5
				var hy = box.size.y * 0.5
				var hz = box.size.z * 0.5
				limitLeft = cx - hx
				limitRight = cx + hx
				limitBottom = cy - hy
				limitTop = cy + hy
				triggerZMin = cz - hz
				triggerZMax = cz + hz
				return
	push_warning("CameraLimitZone: No BoxShape3D child found")

func triggerContains(px: float, _py: float, pz: float) -> bool:
	if alwaysActive:
		return true
	return px >= limitLeft and px <= limitRight and pz >= triggerZMin and pz <= triggerZMax

func getTriggerAabb() -> Rect2:
	if alwaysActive:
		return Rect2(-1e9, -1e9, 2e9, 2e9)
	return Rect2(limitLeft, -1e9, limitRight - limitLeft, 2e9)
