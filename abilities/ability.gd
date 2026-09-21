class_name Ability
extends Resource

var ability_name: String
var cooldown_time: float
var uses: int
var castable: bool = true
var remaining_cooldown: float = 0

func update(delta: float):
	
	if (!ability_name):
		print("plz declare an _init() and define ability_name cooldown_time uses")
	
	if (remaining_cooldown > 0):
		if (remaining_cooldown - delta < 0):
			remaining_cooldown = 0
		else:
			remaining_cooldown -= delta

# when you inherit this, replace the _on_cast function. cast will handle the 
# cooldown management!!
func cast(player: Node) -> void:
	if uses <= 0:
		print("no more uses!!!")
		return
	if (remaining_cooldown > 0):
		print("on cooldown")
		return
		
	_on_cast(player)
	uses -= 1
	remaining_cooldown = cooldown_time
	
	
	
func _on_cast(player: Node) -> void:
	pass
