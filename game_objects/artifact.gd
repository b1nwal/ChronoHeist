class_name Artifact
extends Node2D

@onready var particles := $GPUParticles2D
@onready var stand := $Stand
@onready var artifact := $artifactsprite
@export var empty_stand_texture : CompressedTexture2D 
@export var artifact_texture : CompressedTexture2D
@export var mini_artifact_texture : CompressedTexture2D
@export var points : int
var is_collected : bool = false 
var point_value : int 

# Initialize stand textures
func _ready() -> void:
	stand.texture = empty_stand_texture
	artifact.texture = artifact_texture
	_start_float()

# returns true if the artifact was successfully collected. returns false if you cant interact.
func interact() -> bool:
	if is_collected:
		return false
	else:
		is_collected = true
		particles.restart()
		artifact.hide()
		return true 

# returns texture of the mini version of the artifact for the player to hold
func get_mini_artifact() -> CompressedTexture2D:
	return mini_artifact_texture

# return the amount of points you should receive for the artifact
func get_points() -> int:
	return points

# make the artifact move up and down
func _start_float() -> void:
	var t := create_tween().set_loops()
	t.tween_property(artifact, "position", Vector2(0, -100), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(artifact, "position", Vector2(0, -112), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
