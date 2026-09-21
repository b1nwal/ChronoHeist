class_name AbilityInvisiblityCloak
extends Ability

func _init():
	ability_name = "invisibility cloak"
	cooldown_time = 3
	uses = 2

func _on_cast(player: Node):
	print("invisibility cloak cast")
