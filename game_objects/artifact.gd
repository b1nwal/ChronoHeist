class_name Artifact
extends Node2D

# artifact's sprite child node

@onready var particles = $GPUParticles2D
const TEXTURE_STAND_EMPTY = preload("res://assets/artifacts/artifact_stand_empty.png")
var collected # boolean: is the artifact collected?
var treasure_sprite_name
var point_value = 200

# null creates an empty stand. otherwise please input a string or else my code explodes
func initialize_data(pos: Vector2, sprite_name = null, points = 200):
	
	var sprite = $Sprite2D
	
	collected = false
	position = pos
	point_value = points
	
	sprite.texture = TEXTURE_STAND_EMPTY
	if sprite_name == null:
		collected = true
		$artifactsprite.hide()
		
	
	else:
		treasure_sprite_name = sprite_name
		
		var data = {
			"sprite_name": sprite_name
		}
		
		$artifactsprite.texture = load("res://assets/artifacts/artifact_item_{sprite_name}.png".format(data))
		$artifactsprite.show()
		_start_float()
# returns true if the artifact was successfully collected. returns false if you cant interact.
func interact() -> bool:
	
	var sprite = $Sprite2D
	
	if collected:
		return false
		
	else:
		collected = true
		particles.restart()
		$artifactsprite.hide()
		return true 
		
# returns the name of the artifact to render on player 
func get_sprite_name() -> String:
	return treasure_sprite_name

# make the artifact move up and down
func _start_float() -> void:
	var t := create_tween().set_loops()
	t.tween_property($artifactsprite, "position", Vector2(32, -88), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property($artifactsprite, "position", Vector2(32, -112), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
