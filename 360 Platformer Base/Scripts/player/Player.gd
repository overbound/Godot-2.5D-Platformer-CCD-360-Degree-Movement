class_name Player
extends Node3D

var playerAnimation: PlayerAnimation
var physics: PlayerPhysics
var action: ActionParent
var previousAction: ActionParent
var bufferedAction: ActionParent

var actionJump: ActionJump
var actionRun: ActionRun

var jumpActionableInput: ActionableInput

var airJumpsUsed: int = 0
var maxAirJumps: int = 0

var cameraController: CameraController

var isDying: bool = false

var lockedControls: bool = false
var lockedControlsTimer: float = 0.0

var spriteParent: Node3D
var sprite: Sprite3D

func _init():
	playerAnimation = PlayerAnimation.new(self)
	physics = PlayerPhysics.new(self)
	actionJump = ActionJump.new(self)
	actionRun = ActionRun.new(self)
	action = actionRun
	previousAction = actionRun
	jumpActionableInput = ActionableInput.new(actionJump, [InputHandler.buttonJump], null, 0)
	action.beginAction()

func _ready():
	spriteParent = $SpriteParent
	sprite = spriteParent.get_node("Sprite")

	var camParent = get_node_or_null("../CameraParent")
	if camParent == null:
		camParent = get_node_or_null("CameraParent")
	if camParent:
		var cam = camParent.get_node_or_null("Camera3D")
		if cam:
			cameraController = CameraController.new(self, cam)
			add_child(cameraController)
			cameraController.setup(cam)

func _process(_delta):
	playerAnimation.replaceCurrentAnimationFrame()

func _physics_process(_delta):
	var newInput = findActionableInput()
	if !action.canEnd():
		newInput = null

	if newInput != null && newInput.action.canPerform():
		action.endAction()
		previousAction = action
		action = newInput.action
		bufferedAction = null
		action.beginAction()
	elif previousAction == null || bufferedAction != null:
		if action != null:
			action.endAction()
		previousAction = action
		action = bufferedAction
		bufferedAction = null
		action.beginAction()

	playerAnimation.calculateCurrentFrame()
	playerAnimation.calculateCurrentRotation(physics.relativeAngle)

	action.action()
	if not action.physicsSkip():
		physics.runPhysicsMovement()
	physics.runPhysicsFinalize()
	action.postPhysics()

	InputHandler.updateButtonRelease()
	InputHandler.scrubAcceptedInputs()

func findActionableInput():
	var lastButton: ButtonHandle = InputHandler.getLastButtonPressed()
	if lastButton == jumpActionableInput.buttonInputs[0]:
		if jumpActionableInput.axisInput == null || \
			(jumpActionableInput.axisInput.isHeld && jumpActionableInput.axisInput.direction == jumpActionableInput.axisDirection):
			return jumpActionableInput
	return null

func setLockedControls(timer: float):
	lockedControlsTimer = timer
	lockedControls = true
