extends Player
class_name PastPlayer

var record_index = 0

func _ready() -> void:
	get_tree().current_scene.connect("rewind",_on_rewind)
	
func _on_rewind() -> void:
	
	queue_free()
	
func set_movement(_record: Array) -> void:
	record = _record

func artifact_inrange() -> Array[Node2D]:
	return [];

func _obtain_v_vec():
	record_index += 1
	if record_index > record.size() - 2:
		queue_free()
	return record[record_index]
