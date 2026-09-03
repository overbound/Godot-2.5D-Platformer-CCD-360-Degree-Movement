class_name ActionParent

var player

func _init(newPlayer: Player):
	player = newPlayer

func beginAction():
	pass

func action():
	pass

func endAction():
	pass

func canPerform():
	return true

func canEnd():
	return true

func postPhysics() -> void:
	pass

func physicsSkip() -> bool:
	return false
