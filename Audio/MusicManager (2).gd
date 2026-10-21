extends Node

@onready var music = $Music

func switch():
	music.event_guid = "" 
	# nothing for now
	
func play():
	music.play()
	
func stop():
	music.stop()
	
func hold_intro():
	music.set_parameter("in_intro", "true")

func release_intro():
	music.set_parameter("in_intro", "false")
