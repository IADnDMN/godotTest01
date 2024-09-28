extends Node3D

@onready var torch = $torch
@export var torchChance = 0.2

# Called when the node enters the scene tree for the first time.
func _ready():
	if randf() >= torchChance:
		torch.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
