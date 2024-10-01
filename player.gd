extends CharacterBody3D

@onready var playerModel = $playerMesh
@onready var camera = $RemoteTransform3D

var debugMode = false

var playerHealth = 100.0
var playerHealthMax = 100.0
var playerHealthCooldown = 0.0
var playerHealthCooldownMax = 2.0
var playerHealthRegen = 0.1

var playerStamina = 100.0
var playerStaminaMax = 100.0
var playerStamCooldown = 0.0
var playerStamCooldownMax = 2.0
var playerStamRegen = 10.0

var playerMana = 100.0
var playerManaMax = 100.0
var playerManaCooldown = 0.0
var playerManaCooldownMax = 5.0
var playerManaRegen = 2.0

var playerZoomLevel = 3
var playerSpeed = 60.0
var playerSprintMult = 1.67
var playerJumpImpulse = 7.0
var playerSprintStamDrain = 5.0
var playerJumpStamDrain = 10.0
var playerAttackCooldown = 0.0
var playerAttackCooldownMax = 0.5
var playerCanAttack = true
var playerSpellCooldown = 0.0
var playerSpellCooldownMax = 1.0
var playerCanCast = true
var playerLight = false
var playerDblJumpManaDrain = 16.7
var playerDblJumpLateralMult = 4.0


func _healthChange(amount):
	playerHealth += amount
	if playerHealth <= 0.0:
		playerHealth = 0.0
		print("YOU DIED")
	elif playerHealth > playerHealthMax:
		playerHealth = playerHealthMax
	if amount < 0.0:
		playerHealthCooldown = playerHealthCooldownMax


func _staminaChange(amount):
	playerStamina += amount
	if playerStamina < 0.0:
		playerStamina = 0.0
	elif playerStamina > playerStaminaMax:
		playerStamina = playerStaminaMax
	if amount < 0.0:
		playerStamCooldown = playerStamCooldownMax


func _manaChange(amount):
	playerMana += amount
	if playerMana < 0.0:
		playerMana = 0.0
	elif playerMana > playerManaMax:
		playerMana = playerManaMax
	if amount < 0.0:
		playerManaCooldown = playerManaCooldownMax
		playerSpellCooldown = playerSpellCooldownMax
		playerCanCast = false


func _tickCooldowns(delta):
	if playerHealthCooldown > 0.0:
		playerHealthCooldown -= delta
	else:
		_healthChange(playerHealthRegen * delta)
	if playerStamCooldown > 0.0:
		playerStamCooldown -= delta
	else:
		_staminaChange(playerStamRegen * delta)
	if playerManaCooldown > 0.0:
		playerManaCooldown -= delta
	else:
		_manaChange(playerManaRegen * delta)
	if playerSpellCooldown > 0.0:
		playerSpellCooldown -= delta
	else:
		playerCanCast = true

func _zoomIn():
	if playerZoomLevel < 5:
		playerZoomLevel += 1
		if playerZoomLevel == 5 and not debugMode:
			playerZoomLevel = 4
	_zoomCamera()

func _zoomOut():
	if playerZoomLevel > 1:
		playerZoomLevel -= 1
		if playerZoomLevel == 1 and not debugMode:
			playerZoomLevel = 2
	_zoomCamera()

func _zoomCamera():
	match playerZoomLevel:
		1:
			camera.position.y = 25.0
			camera.position.z = -6.67
		2:
			camera.position.y = 20.0
			camera.position.z = -5.33
		3:
			camera.position.y = 15.0
			camera.position.z = -4.0
		4:
			camera.position.y = 10.0
			camera.position.z = -2.67
		5:
			camera.position.y = 5.0
			camera.position.z = -1.33

func _activateLight():
	$playerSpotlight.spot_range = 32.0
	$playerSpotlight.spot_angle = 85.0
	$playerSpotlight.set_color("ffffff")

func _deactivateLight():
	$playerSpotlight.spot_range = 8.0
	$playerSpotlight.spot_angle = 60.0
	$playerSpotlight.set_color("808080")

func _physics_process(delta):
	var moveDir = Vector3(0.0, 0.0, 0.0)
	var drag = $"..".dragBase
	var doubleJumped = false
	
	if Input.is_action_just_pressed("debug"):
		debugMode = !debugMode
	
	if Input.is_action_just_pressed("zoom_in"):
		_zoomIn()
	if Input.is_action_just_pressed("zoom_out"):
		_zoomOut()
	
	if is_on_floor():
		if Input.is_action_pressed("move_up"):
			moveDir.z = 1.0
		if Input.is_action_pressed("move_down"):
			moveDir.z = -1.0
		if Input.is_action_pressed("move_left"):
			moveDir.x = 1.0
		if Input.is_action_pressed("move_right"):
			moveDir.x = -1.0
		if Input.is_action_just_pressed("jump") and playerStamina > 0.0:
			if playerStamina >= playerJumpStamDrain:
				moveDir.y = 1.0
			else:
				moveDir.y = playerStamina / playerJumpStamDrain
			_staminaChange(-playerJumpStamDrain)
	else:
		drag = $"..".dragAir
		if Input.is_action_just_pressed("jump") and playerCanCast and playerMana > 0.0 and debugMode:
			if playerMana >= playerDblJumpManaDrain:
				moveDir.y = 1.0
			else:
				moveDir.y = playerMana / playerDblJumpManaDrain
			_manaChange(-playerDblJumpManaDrain)
			doubleJumped = true
			if Input.is_action_pressed("move_up"):
				moveDir.z = 1.0
			if Input.is_action_pressed("move_down"):
				moveDir.z = -1.0
			if Input.is_action_pressed("move_left"):
				moveDir.x = 1.0
			if Input.is_action_pressed("move_right"):
				moveDir.x = -1.0
		else:
			moveDir.y = -1.0
	
	if playerCanAttack:
		pass

	var moveActual = Vector3(moveDir.x, 0.0, moveDir.z).normalized()
	
	if moveActual != Vector3.ZERO:
		playerModel.basis.x = moveActual.rotated(Vector3.UP, PI/2.0)
		playerModel.basis.y = Vector3(0, 1, 0)
		playerModel.basis.z = moveActual.normalized()
	
	if doubleJumped:
		moveActual.x *= playerSpeed * delta * playerDblJumpLateralMult
		moveActual.z *= playerSpeed * delta * playerDblJumpLateralMult
	else:
		moveActual.x *= playerSpeed * delta
		moveActual.z *= playerSpeed * delta
	
	if moveDir.y > 0.0:
		moveActual.y = moveDir.y * playerJumpImpulse
	elif moveDir.y < 0.0:
		moveActual.y = -($"..".gravity * delta)

	if Input.is_action_pressed("sprint") and playerStamina > 0.0 and (moveActual.length() > 0.0):
		moveActual.x *= playerSprintMult
		moveActual.z *= playerSprintMult
		_staminaChange(-(delta * playerSprintStamDrain))
	
	velocity.x = velocity.x * (1.0 - drag) + moveActual.x
	velocity.y += moveActual.y
	velocity.z = velocity.z * (1.0 - drag) + moveActual.z
	
	move_and_slide()
	
	if Input.is_action_just_pressed("light"):
		playerLight = !playerLight
		if playerLight:
			_activateLight()
		else:
			_deactivateLight()
	if playerLight:
		_manaChange(-delta)
		if playerMana <= 1.0:
			_deactivateLight()
			playerLight = false
		
		
	_tickCooldowns(delta)
	
	if debugMode:	#supercharge regen rates by pressing `
		_tickCooldowns(delta * 80)
