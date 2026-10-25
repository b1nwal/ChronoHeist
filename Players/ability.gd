class_name Ability
extends Node

# make sure you set these in the ability's _init() func
var cooldown : float 
var cooldown_left : float 
var uses : int 

@onready var player: Player = get_parent()

func _process(delta):
	cooldown_left = maxf(0.0, cooldown_left - delta)

func _physics_process(delta):
	return

func activate():
	return

func tryactivate():
	
	if uses <= 0:
		print(get_script().get_global_name() + " has no more uses")
		return
		
	if cooldown_left > 0:
		print(get_script().get_global_name() + " is on cooldown")
		return
		
	activate()
	cooldown_left = cooldown
	uses -= 1
