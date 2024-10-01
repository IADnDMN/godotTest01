extends CharacterBody3D

@onready var normalCast = $normalCast

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#@onready var creatureModel = $MeshInstance3D
@onready var creatureCollider = $CollisionShape3D
@onready var target = get_node("/root/world/player")

enum AI_MODE {WANDER, SEARCH, PURSUE, ATTACK}

var aiMode = AI_MODE.WANDER
var aiSearchCooldown = 0.0
var aiSearchCooldownMax = 10.0
var aiAttackSpoolup = 0.0
var aiAttackSpoolupMax = 3.0
var proximity = 2.0

func _assess_AI_mode():
	if aiMode == AI_MODE.ATTACK and target.position - position > 10:
		aiMode = AI_MODE.PURSUE
	if normalCast.is_colliding():
		if target.is_ancestor_of(normalCast.get_collider()):
			aiMode = AI_MODE.PURSUE
			if target.position - position < 10:
				aiMode = AI_MODE.ATTACK
				aiAttackSpoolup = aiAttackSpoolupMax
				print("ATTACKING!")
		elif aiMode == AI_MODE.PURSUE:
			aiMode = AI_MODE.SEARCH
			aiSearchCooldown = aiSearchCooldownMax
	else:
		aiMode = AI_MODE.SEARCH
		if aiSearchCooldown <= 0.0:
			aiMode = AI_MODE.WANDER

func _jumpAttack():
	pass	#TODO: implement jump attack

func _physics_process(delta):
	var targetPos = target.global_position
	var moveDir = Vector3(0.0, 0.0, 0.0)
	
	_assess_AI_mode()
	match aiMode:
		AI_MODE.WANDER:
			moveDir = targetPos - position
		AI_MODE.SEARCH:
			moveDir = targetPos - position
		AI_MODE.PURSUE:
			moveDir = targetPos - position
		AI_MODE.ATTACK:
			moveDir = Vector3.ZERO
			aiAttackSpoolup -= delta
			if aiAttackSpoolup <= 0.0:
				_jumpAttack()
	
	var moveActual = Vector3(moveDir.x, 0.0, moveDir.z).normalized()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	
	if moveActual != Vector3.ZERO:
		basis.x = moveActual.rotated(Vector3.UP, PI/2.0)
		basis.y = Vector3(0, 1, 0)
		basis.z = moveActual.normalized()
	
	if moveActual and is_on_floor():
		velocity.x = moveActual.x * SPEED
		velocity.z = moveActual.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, delta)
		velocity.z = move_toward(velocity.z, 0, delta)

	move_and_slide()
