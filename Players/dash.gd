class_name Dash
extends Ability

func _init():
	cooldown = 5.0
	uses = 2

func activate():
	player.f_applied = 90000
	print("dashed")
