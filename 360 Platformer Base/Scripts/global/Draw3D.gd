extends Node

func line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE) -> MeshInstance3D:
	var meshInstance := MeshInstance3D.new()
	var immediateMesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	meshInstance.mesh = immediateMesh
	meshInstance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	immediateMesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediateMesh.surface_add_vertex(pos1)
	immediateMesh.surface_add_vertex(pos2)
	immediateMesh.surface_end()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	get_tree().get_root().add_child(meshInstance)
	return meshInstance

func point(pos: Vector3, radius = 0.05, color = Color.WHITE_SMOKE) -> MeshInstance3D:
	var meshInstance := MeshInstance3D.new()
	var sphereMesh := SphereMesh.new()
	var material := ORMMaterial3D.new()
	meshInstance.mesh = sphereMesh
	meshInstance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	meshInstance.position = pos
	sphereMesh.radius = radius
	sphereMesh.height = radius * 2
	sphereMesh.material = material
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	get_tree().get_root().add_child(meshInstance)
	return meshInstance
