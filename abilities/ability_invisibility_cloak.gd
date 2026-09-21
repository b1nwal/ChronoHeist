class_name AbilityInvisiblityCloak
extends Ability

func _init():
	ability_name = "invisibility cloak"
	cooldown_time = 3
	uses = 2

func _on_cast(player: Node):
	player.set_invincible(true)
	player.hide()
	await player.get_tree().create_timer(3.0).timeout
	player.set_invincible(false)
	player.show()
	
	
