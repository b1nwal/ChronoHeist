extends Node2D

@onready var artifact_node := $map/artifacts
var artifact_list = []
var randi : int
var target_artifact : Node2D

func _ready() -> void:
	randomize()
	for artifact in artifact_node.get_children():
		artifact.is_collected = true
		artifact.artifact.hide()
		artifact_list.append(artifact)
	randi = randi_range(0, artifact_list.size() - 1)
	target_artifact = artifact_list[randi]
	target_artifact.is_collected = false
	target_artifact.artifact.show()
	
