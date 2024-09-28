extends Node3D

@onready var torch0 = $torch0
@onready var torch1 = $torch1
@export var torchChance = 0.2

# Called when the node enters the scene tree for the first time.
func _ready():
	var rand = randf()
	if rand >= torchChance:
		torch0.queue_free()
	rand = randf()
	if rand >= torchChance:
		torch1.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
