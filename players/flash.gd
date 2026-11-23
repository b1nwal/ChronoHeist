class_name Flash
extends Ability

func _init():
	cooldown = 10.0
	uses = 2
	
func activate():
	#player.f_applied = 500
	print("flashed")
