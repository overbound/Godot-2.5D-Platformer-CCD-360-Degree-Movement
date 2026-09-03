class_name ActionRun
extends ActionParent

func beginAction():
	player.physics.landed = true

func action():
	if player.physics.landed:
		handleGroundMovement()
	else:
		handleAirMovement()

func handleAirMovement():
	var inputDir = InputHandler.xAxis1.direction
	if inputDir != 0:
		player.physics.direction = inputDir
	if inputDir == -1 && player.physics.velocity.x > -player.physics.maxGroundSpeed:
		player.physics.velocity.x -= player.physics.airAcceleration
	elif inputDir == 1 && player.physics.velocity.x < player.physics.maxGroundSpeed:
		player.physics.velocity.x += player.physics.airAcceleration

	if player.physics.relativeAngle != 0.0:
		var step = 6.0 * player.physics.direction
		var newAngle = fmod(player.physics.relativeAngle - step + 360.0, 360.0)
		if player.physics.direction == 1 and newAngle > player.physics.relativeAngle:
			newAngle = 0.0
		elif player.physics.direction == -1 and newAngle < player.physics.relativeAngle:
			newAngle = 0.0
		player.physics.relativeAngle = newAngle

	var airSpeed = abs(player.physics.velocity.x)
	if airSpeed == 0:
		setAnimationIdle()
	elif airSpeed < player.physics.maxGroundSpeed:
		setAnimationRun()
	else:
		setAnimationHover()

	setDirection()

func handleGroundMovement():
	if InputHandler.xAxis1.isHeld:
		var axisStrength = abs(InputHandler.xAxis1.position)
		var hc = player.physics.horizontalCollisions
		var px = player.position.x

		if (InputHandler.xAxis1.direction == -1 && hc == null) || \
			InputHandler.xAxis1.direction == -1 && hc != null && hc.position.x > px:
			if player.physics.groundSpeed > 0:
				player.physics.groundSpeed -= player.physics.deceleration
			else:
				player.physics.groundSpeed -= player.physics.acceleration * axisStrength
				var maxSpeed = -player.physics.maxGroundSpeed * axisStrength
				if player.physics.groundSpeed <= maxSpeed:
					player.physics.groundSpeed = maxSpeed

		if (InputHandler.xAxis1.direction == 1 && hc == null) || \
			InputHandler.xAxis1.direction == 1 && hc != null && hc.position.x < px:
			if player.physics.groundSpeed < 0:
				player.physics.groundSpeed += player.physics.deceleration
			else:
				player.physics.groundSpeed += player.physics.acceleration * axisStrength
				var maxSpeed = player.physics.maxGroundSpeed * axisStrength
				if player.physics.groundSpeed >= maxSpeed:
					player.physics.groundSpeed = maxSpeed
	else:
		player.physics.groundSpeed -= min(abs(player.physics.groundSpeed), player.physics.friction) * sign(player.physics.groundSpeed)

	if InputHandler.yAxis1.isHeld && InputHandler.yAxis1.direction == 1 && player.physics.isOnOneWayPlatform:
		player.physics.startDropThrough()
		return

	if InputHandler.buttonJump.isPressed:
		player.bufferedAction = player.actionJump

	setGroundAnimation()

	if InputHandler.xAxis1.isHeld and player.physics.groundMode == PlayerPhysics.SurfaceMode.FLOOR:
		player.physics.direction = InputHandler.xAxis1.direction
		setDirection()

func setGroundAnimation():
	var hc = player.physics.horizontalCollisions
	var px = player.position.x

	if player.physics.groundSpeed == 0:
		if InputHandler.yAxis1.isHeld && InputHandler.yAxis1.direction == -1:
			setAnimationLookUp()
		elif InputHandler.yAxis1.isHeld && InputHandler.yAxis1.direction == 1:
			setAnimationCrouch()
		elif InputHandler.xAxis1.isHeld && InputHandler.xAxis1.direction == 1 && hc != null && hc.position.x > px:
			setAnimationPush()
		elif InputHandler.xAxis1.isHeld && InputHandler.xAxis1.direction == -1 && hc != null && hc.position.x < px:
			setAnimationPush()
		else:
			setAnimationIdle()
	elif abs(player.physics.groundSpeed) < player.physics.maxGroundSpeed:
		setAnimationRun()
	else:
		setAnimationHover()

func setDirection():
	player.playerAnimation.setAnimationDirectionX(player.physics.direction)

func setAnimationHover():
	if player.playerAnimation.animationHover != player.playerAnimation.currentAnimation:
		player.playerAnimation.changeAnimation(player.playerAnimation.animationHover)

func setAnimationRun():
	if player.playerAnimation.animationRun != player.playerAnimation.currentAnimation:
		player.playerAnimation.changeAnimation(player.playerAnimation.animationRun)

func setAnimationIdle():
	if player.playerAnimation.animationIdle != player.playerAnimation.currentAnimation:
		player.playerAnimation.changeAnimation(player.playerAnimation.animationIdle)

func setAnimationPush():
	if player.playerAnimation.animationPush != player.playerAnimation.currentAnimation:
		player.playerAnimation.changeAnimation(player.playerAnimation.animationPush)

func setAnimationLookUp():
	if player.playerAnimation.animationLookUp != player.playerAnimation.currentAnimation:
		player.playerAnimation.changeAnimation(player.playerAnimation.animationLookUp)

func setAnimationCrouch():
	if player.playerAnimation.animationCrouch != player.playerAnimation.currentAnimation:
		player.playerAnimation.changeAnimation(player.playerAnimation.animationCrouch)
