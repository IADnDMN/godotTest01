extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$healthBar.value = ($"../player".playerHealth / $"../player".playerHealthMax) * 100.0
	$staminaBar.value = ($"../player".playerStamina / $"../player".playerStaminaMax) * 100.0
	$manaBar.value = ($"../player".playerMana / $"../player".playerManaMax) * 100.0

