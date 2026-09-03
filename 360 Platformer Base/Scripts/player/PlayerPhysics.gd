class_name PlayerPhysics

var landed:bool = false
var velocity:Vector3
var groundSpeed:float
var maxGroundSpeed:float = 8.0 / 4
var gravity:float = 0.21875 / 4
var jumpVelocity:float = 6.5 / 4
var maxYVelocity:float = 16.0 / 4
var airAcceleration:float = 0.09375 / 4
var acceleration:float = 0.046875 / 4
var deceleration:float = 0.625 / 4
var friction:float = 0.046875 / 4
var groundVector: Vector2 = Vector2.RIGHT
var relativeAngle: float:
	get: return fmod(rad_to_deg(atan2(groundVector.y, groundVector.x)) + 360.0, 360.0)
	set(v):
		var rad: float = deg_to_rad(v)
		groundVector = Vector2(cos(rad), sin(rad))
var player:Player

var landedFrame: int = -1

var direction:int = 1
var collisionBoundsOffset:float = 2
var minDistance = collisionBoundsOffset / 8

enum SurfaceMode { FLOOR = 0, CEILING = 1, RIGHT_WALL = 2, LEFT_WALL = 3 }
enum SlopeCheck { OK, AIRBORNE, FLAT }
var groundMode: int:
	get:
		if not landed:
			return SurfaceMode.FLOOR
		return findGroundMode(relativeAngle)
	set(v):
		pass

var horizontalCollisions
var shapeFacesCache:Dictionary = {}

var faceGraphCache: Dictionary = {}
var groundFaceIndex: int = -1
var groundShape = null
var groundShapeNode = null
var groundNormal: Vector3 = Vector3.UP

var isOnOneWayPlatform:bool = false
const ONE_WAY_LAYER_BIT = (1 << 11)

var dropThroughTimer:int = 0
var jumpGraceTimer:int = 0
var jumpExcludeFaceIndex: int = -1
var jumpExcludeShape = null
var jumpExcludeAdjacent: Dictionary = {}

var potentialPosition: Vector3

func _init(newPlayer:Player):
	player = newPlayer

func runPhysicsMovement() -> void:
	potentialPosition = player.position
	if dropThroughTimer > 0:
		dropThroughTimer -= 1
	if landed:
		groundMovement()
	else:
		airMovement()

func runPhysicsFinalize() -> void:
	applyBoundaryLimits()
	player.position = potentialPosition

func airMovement():
	if jumpGraceTimer > 0:
		jumpGraceTimer -= 1
	velocity.y = clampf(velocity.y - gravity, -maxYVelocity, maxYVelocity)
	var steps: int = max(1, int(ceil(velocity.length() / collisionBoundsOffset)))
	var stepVelocity: Vector3 = velocity / steps
	var feetDist: float = collisionBoundsOffset * 2
	for _i in steps:
		var savedVelocity: Vector3 = velocity
		velocity = stepVelocity
		var checkFloor: bool = stepVelocity.y <= 0 or (stepVelocity.x != 0 and jumpGraceTimer <= 0)
		if checkFloor:
			var stepFloor = collisionBelow()
			if stepFloor != null:
				var sNormal = stepFloor.get("normal")
				if sNormal.y > 0.0 and not isExcludedFace(stepFloor):
					var sDist: float = stepFloor.get("distance")
					if sDist <= feetDist + abs(stepVelocity.y) + minDistance:
						velocity = savedVelocity
						applyLanding(stepFloor, sDist, setAngle(Vector2(sNormal.x, sNormal.y)))
						potentialPosition.y += velocity.y
						potentialPosition.x += stepVelocity.x
						break
		if stepVelocity.y > 0 and collisionAbove() != null:
			velocity = savedVelocity
			velocity.y = 0.0
			savedVelocity = velocity
			stepVelocity.y = 0.0
		velocity = savedVelocity
		var stepHoriz = collisionHorizontal()
		if stepHoriz != null:
			var wNormal = stepHoriz.get("normal")
			var wAngle: float = setAngle(Vector2(wNormal.x, wNormal.y))
			var wDist: float = stepHoriz.get("distance")
			var wallSign: int = 0
			if wAngle >= 45 and wAngle < 180:
				wallSign = 1
			elif wAngle > 180 and wAngle <= 315:
				wallSign = -1
			if wallSign != 0:
				var wGroundMode: int = findGroundMode(wAngle)
				if not isExcludedFace(stepHoriz) and wGroundMode == SurfaceMode.CEILING:
					applyLanding(stepHoriz, 0.0, wAngle, true)
					velocity = savedVelocity
					calculateDownGroundSpeed()
					break
				if wDist < collisionBoundsOffset + minDistance:
					potentialPosition.x -= wallSign * (collisionBoundsOffset + minDistance - wDist)
					velocity.x = min(velocity.x, 0) if wallSign > 0 else max(velocity.x, 0)
					stepVelocity.x = 0
				else:
					var wMaxMove: float = wDist - collisionBoundsOffset - minDistance
					if stepVelocity.x * wallSign > 0:
						stepVelocity.x = clampf(stepVelocity.x, -wMaxMove, wMaxMove)
					velocity.x = stepVelocity.x * steps
		potentialPosition += stepVelocity
		applyBoundaryLimits()
		if landed:
			break

func applyLanding(collision: Dictionary, dist: float, angle: float, skipSnap: bool = false) -> void:
	relativeAngle = angle
	landed = true
	landedFrame = FrameCount.physicsFrame
	jumpExcludeFaceIndex = -1
	jumpExcludeShape = null
	jumpExcludeAdjacent.clear()
	player.airJumpsUsed = 0
	checkOneWayPlatform(collision)
	calculateDownGroundSpeed()
	if not skipSnap:
		velocity.y = -max(dist - collisionBoundsOffset * 2 + minDistance, 0.0)
	updateFaceFromCollision(collision)

func groundMovement():
	var speedLimit = maxGroundSpeed * 8.0
	groundSpeed = clampf(groundSpeed, -speedLimit, speedLimit)
	var belowCollisions = collisionBelowFallback()
	if not belowCollisions.is_empty():
		var normal: Vector3 = updateFaceIfChanged(belowCollisions)
		var previousGroundMode = groundMode
		relativeAngle = setAngle(Vector2(normal.x, normal.y))
		if groundMode != previousGroundMode:
			var recast = collisionBelow()
			if recast != null:
				belowCollisions = recast
				normal = updateFaceIfChanged(recast)
				relativeAngle = setAngle(Vector2(normal.x, normal.y))
		projectVelocityOntoGround()
		if groundMode != SurfaceMode.FLOOR and not player.lockedControls:
			var dr = sign(groundSpeed)
			if dr != 0 and dr != direction and abs(groundSpeed) > 0.01:
				direction = dr
				player.playerAnimation.setAnimationDirectionX(direction)
		checkOneWayPlatform(belowCollisions)
	else:
		if groundMode == SurfaceMode.FLOOR:
			relativeAngle = 0
		landed = false
		isOnOneWayPlatform = false
		clearFaceTracking()
	horizontalCollisions = collisionHorizontal()
	if horizontalCollisions != null:
		var hNorm = horizontalCollisions.get("normal")
		var hAngle: float = setAngle(Vector2(hNorm.x, hNorm.y))
		var hDist: float = horizontalCollisions.get("distance")
		if abs(angleDiff(hAngle, relativeAngle)) > 45:
			var maxMove = max(hDist - collisionBoundsOffset - minDistance, 0)
			var wallAxis = 0 if isFloorCeiling() else 1
			velocity[wallAxis] = clampf(velocity[wallAxis], -maxMove, maxMove)
			var wallSign: int = 1 if (hAngle > 45 and hAngle < 135) else (-1 if (hAngle > 225 and hAngle < 315) else 0)
			if wallSign != 0 and sign(groundSpeed) == wallSign:
				groundSpeed = 0
	var subSteps = max(1, int(ceil(velocity.length() / (collisionBoundsOffset * 2))))
	var stepVelocity = velocity / subSteps
	for _i in subSteps:
		if not landed:
			potentialPosition += stepVelocity
			applyBoundaryLimits()
			break
		if not moveCCD(stepVelocity):
			applyBoundaryLimits()
			break
		applyBoundaryLimits()
		if _i < subSteps - 1:
			var s = stepVelocity.length()
			stepVelocity = Vector3(groundVector.x, groundVector.y, 0) * sign(groundSpeed) * s

func collisionBelowFallback() -> Dictionary:
	var result = collisionBelow()
	if result != null:
		return result
	var savedVector := groundVector
	var savedAngle := relativeAngle
	for mode: int in [SurfaceMode.LEFT_WALL, SurfaceMode.RIGHT_WALL, SurfaceMode.CEILING, SurfaceMode.FLOOR]:
		if mode == groundMode:
			continue
		groundVector = groundVectorForMode(mode)
		result = collisionBelow()
		if result != null:
			var fallbackNormal: Vector3 = result.get("normal")
			var fallbackAngle: float = setAngle(Vector2(fallbackNormal.x, fallbackNormal.y))
			if abs(angleDiff(fallbackAngle, savedAngle)) > 120.0:
				result = null
				continue
			return result
	groundVector = savedVector
	return {}
	
func applyBoundaryLimits():
	var cc = player.cameraController
	if cc == null or not cc.initialized:
		return
	var hw = collisionBoundsOffset
	var hh = collisionBoundsOffset * 2
	if cc.limitLeft != -INF:
		if potentialPosition.x < cc.limitLeft + hw:
			potentialPosition.x = cc.limitLeft + hw
			if velocity.x < 0: velocity.x = 0
			if groundSpeed < 0: groundSpeed = 0
	if cc.limitRight != INF:
		if potentialPosition.x > cc.limitRight - hw:
			potentialPosition.x = cc.limitRight - hw
			if velocity.x > 0: velocity.x = 0
			if groundSpeed > 0: groundSpeed = 0
	if cc.limitBottom != -INF:
		if potentialPosition.y < cc.limitBottom + hh:
			potentialPosition.y = cc.limitBottom + hh
			if velocity.y < 0: velocity.y = 0
			if not landed:
				landed = true
				landedFrame = FrameCount.physicsFrame
				player.airJumpsUsed = 0
				groundSpeed = velocity.x
	if cc.limitTop != INF:
		if potentialPosition.y > cc.limitTop - hh:
			potentialPosition.y = cc.limitTop - hh
			if velocity.y > 0: velocity.y = 0

func findCollisionShapeData(collision: Dictionary) -> Array:
	var collider = collision.get("collider")
	if collider == null:
		return [null, null]
	for child in collider.get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			return [child.shape as ConcavePolygonShape3D, child]
	return [null, null]

func _edgeKey(a: int, b: int, vert_count: int) -> int:
	return min(a, b) * vert_count + max(a, b)

func buildFaceGraph(shape: ConcavePolygonShape3D) -> PackedInt32Array:
	var faces: PackedVector3Array = shapeFacesCache[shape]
	var total_verts: int = faces.size()
	var face_count: int = total_verts / 3
	var snap := Vector3(0.001, 0.001, 0.001)
	var vert_to_idx: Dictionary = {}
	var face_vert_idx: PackedInt32Array = PackedInt32Array()
	face_vert_idx.resize(total_verts)
	for i in total_verts:
		var sv: Vector3 = faces[i].snapped(snap)
		if not vert_to_idx.has(sv):
			vert_to_idx[sv] = vert_to_idx.size()
		face_vert_idx[i] = vert_to_idx[sv]
	var vert_count: int = vert_to_idx.size()
	var edge_to_faces: Dictionary = {}
	for i in face_count:
		var base: int = i * 3
		for ei in 3:
			var ek = _edgeKey(face_vert_idx[base + ei], face_vert_idx[base + (ei + 1) % 3], vert_count)
			if not edge_to_faces.has(ek): edge_to_faces[ek] = []
			edge_to_faces[ek].append(i)
	var face_edge_adj: PackedInt32Array = PackedInt32Array()
	face_edge_adj.resize(face_count * 3)
	face_edge_adj.fill(-1)
	for i in face_count:
		var base: int = i * 3
		for ei in 3:
			var ek = _edgeKey(face_vert_idx[base + ei], face_vert_idx[base + (ei + 1) % 3], vert_count)
			for adj_fi in edge_to_faces[ek]:
				if adj_fi != i:
					face_edge_adj[base + ei] = adj_fi
					break
	return face_edge_adj

func ensureFaceGraph(shape: ConcavePolygonShape3D) -> void:
	if not faceGraphCache.has(shape):
		if not shapeFacesCache.has(shape):
			shapeFacesCache[shape] = shape.get_faces()
		faceGraphCache[shape] = buildFaceGraph(shape)

func updateFaceIfChanged(collision: Dictionary) -> Vector3:
	var fi = collision.get("face_index", -1)
	var sh = findCollisionShapeData(collision)[0]
	if fi >= 0 and fi == groundFaceIndex and sh == groundShape:
		return groundNormal
	updateFaceFromCollision(collision)
	return groundNormal

func clearFaceTracking() -> void:
	groundFaceIndex = -1
	groundShape = null
	groundShapeNode = null
	groundNormal = Vector3.UP

func updateFaceFromCollision(collision: Dictionary) -> void:
	var fi = collision.get("face_index", -1)
	var data = findCollisionShapeData(collision)
	var sh = data[0]
	if fi >= 0 and sh != null:
		groundFaceIndex = fi
		groundShape = sh
		groundShapeNode = data[1]
	else:
		groundFaceIndex = -1
		groundShape = null
		groundShapeNode = null
	groundNormal = collision.get("normal", Vector3.UP)

func captureJumpExclusion() -> void:
	jumpExcludeFaceIndex = groundFaceIndex
	jumpExcludeShape = groundShape
	jumpExcludeAdjacent.clear()
	if groundShape != null and groundFaceIndex >= 0:
		var adj: PackedInt32Array = faceGraphCache.get(groundShape, PackedInt32Array())
		if not adj.is_empty():
			var base = groundFaceIndex * 3
			for ei in 3:
				var ai = adj[base + ei]
				if ai >= 0:
					jumpExcludeAdjacent[ai] = true

func isExcludedFace(collision: Dictionary) -> bool:
	if jumpGraceTimer <= 0:
		return false
	var fi = collision.get("face_index", -1)
	var sh = findCollisionShapeData(collision)[0]
	if jumpExcludeShape != null and fi >= 0 and sh != null:
		if sh == jumpExcludeShape:
			if fi == jumpExcludeFaceIndex:
				return true
			return jumpExcludeAdjacent.has(fi)
		return false
	return true

func beginJumpGrace(frames: int = 5) -> void:
	jumpGraceTimer = frames
	captureJumpExclusion()

func getWorldFaceVerts(face_index: int) -> Array:
	if groundShape == null or groundShapeNode == null:
		return []
	if not shapeFacesCache.has(groundShape):
		return []
	var faces: PackedVector3Array = shapeFacesCache[groundShape]
	var base = face_index * 3
	if base + 2 >= faces.size():
		return []
	return [
		groundShapeNode.to_global(faces[base]),
		groundShapeNode.to_global(faces[base + 1]),
		groundShapeNode.to_global(faces[base + 2])
	]

func computeFaceNormal(verts: Array) -> Vector3:
	var n = (verts[1] - verts[0]).cross(verts[2] - verts[0]).normalized()
	if n.dot(groundNormal) < 0:
		n = -n
	return n

func snapPlayerToFace(verts: Array) -> void:
	var n = computeFaceNormal(verts)
	var v0 = verts[0]
	var desired = collisionBoundsOffset * 2.0 - minDistance
	if isFloorCeiling():
		if abs(n.y) < 0.001:
			return
		var sy = v0.y - (n.x * (potentialPosition.x - v0.x)) / n.y
		potentialPosition.y = sy + desired / n.y
	else:
		if abs(n.x) < 0.001:
			return
		var sx = v0.x - (n.y * (potentialPosition.y - v0.y)) / n.x
		potentialPosition.x = sx + desired / n.x

func lineSegmentIntersectT2D(p: Vector2, d: Vector2, a: Vector2, b: Vector2) -> float:
	var s = b - a
	var denom = d.x * s.y - d.y * s.x
	if abs(denom) < 0.0001:
		return -1.0
	var diff = a - p
	var t = (diff.x * s.y - diff.y * s.x) / denom
	var u = (diff.x * d.y - diff.y * d.x) / denom
	if t < 0.001 or u < 0.0 or u > 1.0:
		return -1.0
	return t

func findFaceExit(pos: Vector3, move_vec: Vector3, verts: Array) -> Dictionary:
	var p2 = Vector2(pos.x, pos.y)
	var d2 = Vector2(move_vec.x, move_vec.y)
	if d2.length_squared() < 0.0001:
		return {}
	var e0 = Vector2(verts[0].x, verts[0].y)
	var e1 = Vector2(verts[1].x, verts[1].y)
	var e2 = Vector2(verts[2].x, verts[2].y)
	var edges = [[e0, e1], [e1, e2], [e2, e0]]
	var best_t = 1.0
	var best_edge = -1
	for i in 3:
		var t = lineSegmentIntersectT2D(p2, d2, edges[i][0], edges[i][1])
		if t >= 0.001 and t < best_t:
			best_t = t
			best_edge = i
	if best_edge < 0:
		return {}
	return {"t": best_t, "edge_idx": best_edge}

func getAdjacentFaceAcrossEdge(edge_idx: int) -> int:
	if groundShape == null or groundFaceIndex < 0:
		return -1
	var face_edge_adj: PackedInt32Array = faceGraphCache.get(groundShape, PackedInt32Array())
	if face_edge_adj.is_empty():
		return -1
	var idx: int = groundFaceIndex * 3 + edge_idx
	if idx >= face_edge_adj.size():
		return -1
	return face_edge_adj[idx]

func projectOntoFaceTangent(move_vec: Vector3, face_normal: Vector3) -> Vector3:
	var xy = Vector2(move_vec.x, move_vec.y)
	var n_xy = Vector2(face_normal.x, face_normal.y)
	var len_sq = n_xy.length_squared()
	if len_sq > 0.0001:
		xy -= n_xy * (xy.dot(n_xy) / len_sq)
	return Vector3(xy.x, xy.y, move_vec.z)

func projectVelocityOntoGround() -> void:
	velocity.x = groundVector.x * groundSpeed
	velocity.y = groundVector.y * groundSpeed

func goAirborne() -> void:
	projectVelocityOntoGround()
	groundSpeed = 0
	if groundMode == SurfaceMode.FLOOR:
		relativeAngle = 0
	landed = false
	clearFaceTracking()

func applyMiter(angle_diff: float, signed_diff: float, travel_dir: Vector3, new_normal: Vector3) -> void:
	if abs(angle_diff) <= 0.1:
		return
	var travel_tan := projectOntoFaceTangent(travel_dir, new_normal)
	var tl_len := travel_tan.length()
	if tl_len <= 0.0001:
		return
	travel_tan /= tl_len
	var mag: float = (collisionBoundsOffset * 2.0 - minDistance) * tan(deg_to_rad(abs(angle_diff) * 0.5))
	potentialPosition.x += travel_tan.x * mag * sign(signed_diff)
	potentialPosition.y += travel_tan.y * mag * sign(signed_diff)

func moveAndSnap(move_vec: Vector3) -> bool:
	potentialPosition += move_vec
	var snap = collisionBelowFallback()
	if snap.is_empty():
		goAirborne()
		return false
	var postNormal = snap.get("normal")
	if postNormal == null:
		goAirborne()
		return false
	var postAngle = setAngle(Vector2(postNormal.x, postNormal.y))
	if _checkSlopeAngle(postAngle) == SlopeCheck.AIRBORNE:
		return false
	updateFaceFromCollision(snap)
	relativeAngle = postAngle
	var snapDelta = snap.get("distance") - collisionBoundsOffset * 2 + minDistance
	var inward = Vector2(groundVector.y, -groundVector.x)
	potentialPosition.x += inward.x * snapDelta
	potentialPosition.y += inward.y * snapDelta
	projectVelocityOntoGround()
	return true

func moveCCD(move_vec: Vector3) -> bool:
	if groundFaceIndex < 0 or groundShape == null or groundShapeNode == null:
		return moveAndSnap(move_vec)
	ensureFaceGraph(groundShape)
	var remaining := move_vec
	var prev_remaining_sq := remaining.length_squared() + 1.0
	for _iter in 8:
		var rsq := remaining.length_squared()
		if rsq < 0.0001 or rsq >= prev_remaining_sq:
			break
		prev_remaining_sq = rsq
		var verts := getWorldFaceVerts(groundFaceIndex)
		if verts.is_empty():
			return moveAndSnap(remaining)
		var tangent_move := projectOntoFaceTangent(remaining, groundNormal)
		var exit := findFaceExit(potentialPosition, tangent_move, verts)
		if exit.is_empty() or exit["t"] >= 1.0:
			potentialPosition += tangent_move
			snapPlayerToFace(verts)
			break
		potentialPosition += tangent_move * exit["t"]
		var adj_face := getAdjacentFaceAcrossEdge(exit["edge_idx"])
		if adj_face < 0:
			goAirborne()
			return false
		var new_verts := getWorldFaceVerts(adj_face)
		if new_verts.is_empty():
			return moveAndSnap(tangent_move * (1.0 - exit["t"]))
		var new_normal := computeFaceNormal(new_verts)
		var new_angle := setAngle(Vector2(new_normal.x, new_normal.y))
		var angle_diff: float = angleDiff(new_angle, relativeAngle)
		match _checkSlopeAngle(new_angle):
			SlopeCheck.AIRBORNE: return false
			SlopeCheck.FLAT:
				snapPlayerToFace(new_verts)
				break
		groundFaceIndex = adj_face
		groundNormal = new_normal
		relativeAngle = new_angle
		snapPlayerToFace(new_verts)
		applyMiter(angle_diff, angle_diff * sign(groundSpeed), tangent_move, new_normal)
		remaining = projectOntoFaceTangent(tangent_move * (1.0 - exit["t"]), new_normal)
	projectVelocityOntoGround()
	return true

func _checkSlopeAngle(new_angle: float) -> int:
	if groundSpeed == 0:
		return SlopeCheck.OK
	var signed_diff = angleDiff(new_angle, relativeAngle) * sign(groundSpeed)
	if signed_diff > 60.0:
		goAirborne()
		return SlopeCheck.AIRBORNE
	if signed_diff < -60.0:
		groundSpeed = 0
		return SlopeCheck.FLAT
	return SlopeCheck.OK

func collisionBelow():
	var inward := Vector2(groundVector.y, -groundVector.x)
	var vi := velocity.x * inward.x + velocity.y * inward.y
	var length: float = (collisionBoundsOffset * 3) + max(vi, -collisionBoundsOffset)
	var mask = (1 << 1) | (1 << 2)
	if dropThroughTimer <= 0:
		mask |= ONE_WAY_LAYER_BIT
	return castRay(potentialPosition, Vector3(inward.x, inward.y, 0.0), length, mask)

func collisionAbove():
	var outward := Vector2(-groundVector.y, groundVector.x)
	var vv: float = velocity.x * outward.x + velocity.y * outward.y
	var rlen: float = collisionBoundsOffset * 2.0 + max(vv, 0.0) + minDistance
	return castRay(potentialPosition, Vector3(outward.x, outward.y, 0.0), rlen, (1 << 1) | (1 << 2))

func collisionHorizontal():
	var hMask = (1 << 1) | (1 << 2)
	var vh: float = velocity.x * groundVector.x + velocity.y * groundVector.y
	var rlen: float = abs(vh) + collisionBoundsOffset + minDistance
	var fwd := Vector3(groundVector.x, groundVector.y, 0.0)
	var resultA = castRay(potentialPosition, fwd, rlen, hMask)
	var resultB = castRay(potentialPosition, -fwd, rlen, hMask)
	if groundMode == SurfaceMode.FLOOR:
		var inward := Vector2(groundVector.y, -groundVector.x)
		var lowOrigin := Vector3(
			potentialPosition.x + inward.x * collisionBoundsOffset,
			potentialPosition.y + inward.y * collisionBoundsOffset,
			potentialPosition.z)
		resultA = _pickCloser(resultA, castRay(lowOrigin, fwd, rlen, hMask))
		resultB = _pickCloser(resultB, castRay(lowOrigin, -fwd, rlen, hMask))
	if resultA == null and resultB == null:
		return null
	if resultA == null:
		return resultB if vh <= 0 else null
	if resultB == null:
		return resultA if vh >= 0 else null
	if vh > 0:
		return resultA
	elif vh < 0:
		return resultB
	return resultA if resultA["distance"] < resultB["distance"] else resultB

func castRay(origin: Vector3, dir: Vector3, length: float, mask: int):
	var space_state = player.get_world_3d().direct_space_state
	var end = origin + dir * length
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = mask
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return null
	result["distance"] = origin.distance_to(result.get("position"))
	return result

func _pickCloser(a, b):
	if a == null: return b
	if b == null: return a
	return a if a["distance"] < b["distance"] else b

func angleDiff(a: float, b: float) -> float:
	return fmod(a - b + 540.0, 360.0) - 180.0

func setAngle(normal: Vector2) -> float:
	var angle = -rad_to_deg(normal.angle_to(Vector2(0, 1)))
	if angle < 0:
		angle += 360
	return angle

func startDropThrough():
	dropThroughTimer = 12
	landed = false
	isOnOneWayPlatform = false
	relativeAngle = 0

func checkOneWayPlatform(collisionResult):
	if collisionResult == null or collisionResult.is_empty():
		isOnOneWayPlatform = false
		return
	var collider = collisionResult.get("collider")
	if collider != null and collider is CollisionObject3D:
		isOnOneWayPlatform = (collider.get_collision_layer() & ONE_WAY_LAYER_BIT) != 0
	else:
		isOnOneWayPlatform = false

func findGroundMode(angle: float) -> int:
	angle = fmod(angle + 360, 360)
	if angle <= 45 or angle >= 315:
		return SurfaceMode.FLOOR
	elif angle < 135:
		return SurfaceMode.RIGHT_WALL
	elif angle <= 225:
		return SurfaceMode.CEILING
	else:
		return SurfaceMode.LEFT_WALL

func groundVectorForMode(mode: int) -> Vector2:
	match mode:
		SurfaceMode.FLOOR:      return Vector2.RIGHT
		SurfaceMode.CEILING:    return Vector2.LEFT
		SurfaceMode.RIGHT_WALL: return Vector2(0.0,  1.0)
		SurfaceMode.LEFT_WALL:  return Vector2(0.0, -1.0)
		_:                      return Vector2.RIGHT

func isFloorCeiling() -> bool:
	if not landed:
		return true
	return abs(groundVector.x) >= abs(groundVector.y)

func calculateDownGroundSpeed():
	groundSpeed = velocity.x * groundVector.x + velocity.y * groundVector.y
