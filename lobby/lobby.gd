extends Node2D

@onready var selectors : Array[Node] = $LevelSelect.get_children()
@onready var player := $Player
@onready var level_indicator := $LevelIndicator

func _ready() -> void:
	level_indicator.hide()

func _process(delta: float) -> void:
	level_indicator.hide()
	for selector in selectors:
		check_collisions(selector)
	
func check_collisions(selector: Node) -> void:
	if player.global_position.distance_squared_to(selector.global_position) < 4086:
		level_indicator.text = "PRESS E TO ENTER " + selector.get_meta("name")
		if Input.is_key_pressed(KEY_E):
			get_tree().change_scene_to_packed(selector.get_meta("scene"))
		level_indicator.show()

	
	
