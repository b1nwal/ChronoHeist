extends Node2D

@onready var player := $Player
@onready var artifact_node := $map/artifacts
@onready var portal := $Portal
@onready var spawns := [
	$map/playerspawns/playerspawn,
	$map/playerspawns/playerspawn2,
	$map/playerspawns/playerspawn3,
	$map/playerspawns/playerspawn4,
	$map/playerspawns/playerspawn5,
	$map/playerspawns/playerspawn6
]

var artifact_list = []
var target_artifact : Node2D

func _ready() -> void:
	randomize()
	_new_round()
	player.exit_point_reached.connect(_on_exit_reached)

func _new_round() -> void:
	_place_artifact()
	_place_portal()

#randomly chooses an artifact to collect
func _place_artifact():
	for artifact in artifact_node.get_children():
		artifact.is_collected = true
		artifact.artifact.hide()
		artifact_list.append(artifact)
	var randi_artifact : int = randi_range(0, artifact_list.size() - 1)
	target_artifact = artifact_list[randi_artifact]
	target_artifact.is_collected = false
	target_artifact.artifact.show()

#randomly places a portal
func _place_portal() -> void:
	var randi_portal_position : int = randi_range(0, spawns.size() - 1)
	var portal_light := PointLight2D.new()
	portal.play("default")
	portal.position = spawns[randi_portal_position].position
	
func _on_exit_reached() -> void:
	#remove_ghosts()
	print("end")
	_new_round()
