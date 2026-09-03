class_name ActionJump
extends ActionParent

var isJumping = false

func beginAction():
	if !player.physics.landed:
		player.airJumpsUsed += 1
	isJumping = true
	var jumpAngle = player.physics.relativeAngle
	player.physics.relativeAngle = 0
	player.physics.groundMode = PlayerPhysics.SurfaceMode.FLOOR
	player.physics.landed = false
	player.physics.beginJumpGrace(5)
	player.physics.velocity.x -= player.physics.jumpVelocity * sin(deg_to_rad(jumpAngle))
	player.physics.velocity.y += player.physics.jumpVelocity * cos(deg_to_rad(jumpAngle))
	player.playerAnimation.changeAnimation(player.playerAnimation.animationJump)

func action():
	if !InputHandler.buttonJump.isHeld && isJumping:
		if player.physics.velocity.y > 1:
			player.physics.velocity.y = 1
			isJumping = false

	var inputDir = sign(InputHandler.xAxis1.position)
	if inputDir != 0:
		player.physics.direction = inputDir
	if InputHandler.xAxis1.direction == -1 && player.physics.velocity.x > -player.physics.maxGroundSpeed:
		player.physics.velocity.x -= player.physics.airAcceleration
	elif InputHandler.xAxis1.direction == 1 && player.physics.velocity.x < player.physics.maxGroundSpeed:
		player.physics.velocity.x += player.physics.airAcceleration

func postPhysics() -> void:
	if player.physics.landed:
		player.bufferedAction = player.actionRun

func canPerform():
	if not player.physics.landed and player.airJumpsUsed >= player.maxAirJumps:
		return false
	return (player.physics.landed || player.airJumpsUsed < player.maxAirJumps)
