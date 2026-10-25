class_name Ability
extends Node

var cooldown : float = 5.0
var cooldown_left : float = 0.0
@onready var player: Player = get_parent()

func _physics_process(delta):
	cooldown_left = maxf(0.0, cooldown_left - delta)

func activate():
	return

func tryactivate():
	if cooldown_left > 0:
		print("on cooldown")
		return
	cooldown_left = cooldown
	activate()
