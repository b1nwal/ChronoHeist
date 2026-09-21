extends Player

var record_index = 0
var v_vec

func _ready() -> void:
	#print(speed)
	get_tree().current_scene.connect("rewind",_on_rewind)
	
func _on_rewind() -> void:
	
	queue_free()
	
func set_movement(_record: Array) -> void:
	record = _record
	
func _obtain_v_vec():
	record_index += 1
	if record_index > record.size() - 2:
		queue_free()
	return record[record_index]
