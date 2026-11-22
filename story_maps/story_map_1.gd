extends Node2D

var playerPast_scene := preload("uid://ds72i60gi80dp")

@onready var round_timer := $map/RoundTimer
@onready var hud := $HUD
@onready var player := $Player
@onready var artifact_nodes := $map/artifacts
@onready var spawn_nodes := $map/playerspawns
@onready var portal := $Portal

var spawns : Array[Marker2D]
var artifacts : Array[Artifact]
var futures : Array[Array]
var past_players : Array[PastPlayer]
var target_artifact : Node2D
var player_spawn : Vector2
var portal_position : Vector2
var score : int
var game_over_sequence_started : bool = false
var round_number : int = 0
var white_flash : ColorRect = ColorRect.new()

# initializes the game at the very beginning
func _ready() -> void:
	randomize()
	_initialize_spawns()
	_new_round()

# _process function. handles anything that requires checks over the course of the round
func _process(delta: float) -> void:
	hud.update_timer(round_timer.time_left)
	if round_timer.time_left < 27:
		_set_invincibility(false)

# calls all the functions in order to start a new round
func _new_round() -> void:
	player.get_node("playerSounds").play_reset_sound()
	round_number += 1
	round_timer.start()
	round_timer.paused = true
	_place_portal()
	_spawn_ghosts()
	_create_player_path()
	_set_physics_process(false)
	_set_invincibility(true)
	await get_tree().create_timer(3).timeout
	_set_physics_process(true)
	round_timer.paused = false

#place spawns into array and pick a random one
func _initialize_spawns():
	for spawn in spawn_nodes.get_children():
		spawns.append(spawn)
	player_spawn = spawns[randi_range(0, spawns.size() - 1)].position

# ends the game and runs the final sequence
func _game_over():
	game_over_sequence_started = true
	round_timer.paused = true
	await get_tree().create_timer(3).timeout
	frame_whole_map()
	while game_over_sequence_started:
		_remove_ghosts()
		_spawn_ghosts()
		_set_invincibility(true)
		_set_physics_process(false)
		await get_tree().create_timer(3).timeout
		_set_physics_process(true)
		await get_tree().create_timer(30).timeout

# randomly places a portal that is not the player spawn
func _place_portal() -> void:
	portal_position = spawns[randi_range(0, spawns.size() - 1)].position
	while portal_position == player_spawn:
		portal_position = spawns[randi_range(0, spawns.size() - 1)].position
	portal.position = portal_position

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
	for past_player in past_players:
		if is_instance_valid(past_player):
			past_player.set_invincible(status)

# takes boolean. sets the physics process of players and ghosts to true or false
func _set_physics_process(status : bool) -> void:
	player.set_physics_process(status)
	for past_player in past_players:
		if is_instance_valid(past_player):
			past_player.set_physics_process(status)

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
	if game_over_sequence_started:
		return
	frame_killer(observer)
	_game_over()

# when the timer runs out, start the game over sequence
func _on_round_timer_timeout() -> void:
	frame_killer(player)
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
	create_tween().tween_property(white_flash, "color:a", 0.0, 2.5)
	create_tween().tween_property($map/mapdimmer, "color", Color("939aa9"), 2.5)
	

func frame_killer(observer) -> void:
	_set_physics_process(false)
	white_flash.position = Vector2(-5000, 0)
	white_flash.size = Vector2(10000, 10000)
	white_flash.color = Color(1, 1, 1, 0)
	white_flash.z_index = 21
	observer.z_index = 22
	player.z_index = 23
	add_child(white_flash)
	create_tween().tween_property(white_flash, "color:a", 1.0, 2.5)
	create_tween().tween_property($map/mapdimmer, "color", Color("ffffff"), 2.5)
	var cam: Camera2D = $Player/Camera2D
	cam.set_process(false)
	var killer_position : Vector2 = observer.position
##------------------------------------------------------------------------------
## map bg should be big enough that camera size does not need to be reset
##------------------------------------------------------------------------------
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	
	# tween camera to zoom in on player
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(cam, "global_position", killer_position, 1.5)
	t.tween_property(cam, "zoom", Vector2(2.7, 2.7), 1.5)
	
func _unhandled_input(event: InputEvent) -> void:
	if game_over_sequence_started == true:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				get_tree().change_scene_to_file("uid://7elayt2y1mgn")
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
