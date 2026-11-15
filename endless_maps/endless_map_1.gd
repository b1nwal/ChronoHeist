extends Node2D
##endless mode. one artifact spawns randomly each round. see how far you can get
#this also mainly just revamps the code for main map. i want to see opinions and know if its better or wor
#currently, no round timer
var playerPast_scene := preload("uid://ds72i60gi80dp")

@onready var hud := $HUD
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
var futures = []
var past_players = []
var target_artifact : Node2D
var player_spawn : Vector2
var portal_position : Vector2
var score : int
var gameoverseq_started := false

# initializes the game at the very beginning
func _ready() -> void:
	randomize()
	# generate random spawn
	player_spawn = spawns[randi_range(0, spawns.size() - 1)].position
	_new_round()

# calls all the functions in order to start a new round
func _new_round() -> void:
	_place_artifact()
	_place_portal()
	_spawn_ghosts()
	_create_player_path()
	_set_invincibility(true)
	await get_tree().create_timer(3).timeout
	_set_invincibility(false)

# ends the game and runs the final sequence
func _game_over():
	frame_whole_map()
	await get_tree().create_timer(3).timeout
	_spawn_ghosts()

# randomly chooses an artifact to collect
func _place_artifact():
	for artifact in artifact_node.get_children():
		artifact.is_collected = true
		artifact.artifact.hide()
		artifact_list.append(artifact)
	var randi_artifact : int = randi_range(0, artifact_list.size() - 1)
	target_artifact = artifact_list[randi_artifact]
	target_artifact.is_collected = false
	target_artifact.artifact.show()

# randomly places a portal
func _place_portal() -> void:
	portal_position = spawns[randi_range(0, spawns.size() - 1)].position
	var portal_light := PointLight2D.new()
	portal.play("default")
	portal.position = portal_position
	var t := create_tween().set_loops()

# spawns a player and sets and exit point
func _create_player_path() -> void:
	player.start(player_spawn)
	player.set_exit_point(portal_position)
	hud.set_waypoint(portal_position)

# adds the previous player record and the spanws the ghosts
func _spawn_ghosts() -> void:
	if player.record.size() > 1:
		futures.append(player.record)
	if futures:
		for past in futures:
			var past_player_instance := playerPast_scene.instantiate()
			add_child(past_player_instance)
			past_player_instance.position = past[0]
			past_player_instance.set_movement(past.slice(1))
			#past_player_instance.set_physics_process(false)
			past_players.append(past_player_instance)
			past_player_instance.spotted.connect(_on_spotted)

# removes all ghosts
func _remove_ghosts() -> void:
	for ghost in past_players:
		if is_instance_valid(ghost):
			if ghost.is_inside_tree():
				remove_child(ghost)
			ghost.queue_free()
	past_players.clear()

# takes boolean. sets the invincibility of players and ghosts to true or false
func _set_invincibility(status : bool) -> void:
	player.set_invincible(status)
	for p in past_players:
		p.set_invincible(status)

# remove ghosts, randomize portal position, starts new round
func _on_exit_reached() -> void:
	_remove_ghosts()
	player_spawn = portal_position
	_new_round()

# adds new score
func _on_score_added(points) -> void:
	score += points
	hud.update_score(score)

# if you are spotted run the game over function
func _on_spotted(observer, target) -> void:
	if observer != player and target != player:
		return                                    
	if gameoverseq_started:
		return                               
	gameoverseq_started = true
	
	player.set_physics_process(false)
	_remove_ghosts()
	_game_over()





# frame the entire map. would like to change this code. 
func frame_whole_map() -> void:
	var cam: Camera2D = $Player/Camera2D
	cam.set_process(false)
	player.hide()
	var map_size := Vector2(3008, 2816)
	var map_center := Vector2(1504, 1408)
	var vp := get_viewport_rect().size
	var z: float = min(vp.x / map_size.x, vp.y / map_size.y)
##------------------------------------------------------------------------------
	## map bg should be big enough that camera size does not need to be reset---
##------------------------------------------------------------------------------
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	
	# tween camera to zoom out onto the map
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(cam, "global_position", map_center, 1.5)
	t.tween_property(cam, "zoom", Vector2(z, z), 1.5)
