extends Node

@onready var button = $Button

func play_start():
	button.event_name = "event:/start"
	button.play_one_shot()
