## WHAT HAS BEEN CHANGED
## - @onready var so that we only call the process once instead of a million times
## - reordered and grouped all the functions
## - added remove_ghosts to free the memory properly
## - formatted functions and variable names to snake case accordingly
## - placed typed variable ":=" for every variable initialized
## - placed comments to processes that needed it
## WHAT NEEDS TO BE CHANGED 
## - generally should not directly find children by using $parent/child.function()
## - gameoverbruh function in PLAYER should be a signal what was i on bruh
## - check your own written code cause im having trouble wrapping my head around some of it
## - add documentation comments for function 
##   - ## function does A B C or smth
##     func function():
## OTHER THINGS
## - please read the comments with double # comments. apparently this is for documentation?
 
extends Node2D

var playerPast_scene := preload("res://Players/playerPast.tscn")
var artifact_scene := preload("res://gameElements/artifact.tscn")
var portal_texture := preload("res://assets/portals/Portal.tscn")
var portal_light_texture := preload("res://assets/Lights/PointLightGradient.tres")


@onready var player := $player
@onready var hud := $HUD
@onready var round_timer := $RoundTimer
@onready var count_down := $CountDown
@onready var gameovertimer := $gameovertimer
@onready var white_flash := $ColorRect
@onready var spawns := [
	$playerspawns/playerspawn.position,
	$playerspawns/playerspawn2.position,
	$playerspawns/playerspawn3.position,
	$playerspawns/playerspawn4.position,
	$playerspawns/playerspawn5.position,
	$playerspawns/playerspawn6.position
]
##------------------------------------------------------------------------------
## I DONT KNOW WHAT THESE VARIABLE TYPES SHOULD BE 
##------------------------------------------------------------------------------
var portal_sprite
var portal_visual
var portal_sound
var visited_spawns = []
var futures = []
var past_players = []

var time := 0
var score := 0
var count := 0
var round_number := 0
var gameovertime := 0
var gameoverseq_started := false

const TIME_FOR_ONE_ROUND := 30
const COUNTDOWN_TIME := 2
##------------------------------------------------------------------------------
## Artifact position should NOT be stored here. a new scene for maps 
## specifcally should be made that holds these position in the future
##------------------------------------------------------------------------------
const ARTIFACTS = [
	[Vector2(192, 1997), "pot1", 175], 
	[Vector2(192, 1677), "pot2", 175], 
	[Vector2(768, 1037), "pot2", 175],
	[Vector2(704, 1805), "pot1", 175], 
	[Vector2(1472, 1101), "pot2", 175], # new room / N
	[Vector2(1280, 1933), "chisato", 300], # famous paintings / Central
	[Vector2(1472, 1933), "purpleguy", 300], 
	[Vector2(1664, 1933), "shark", 300],
	[Vector2(2240, 1613), "sword1", 300], # war relics / NE
	[Vector2(2624, 1357), "sword2", 300], 
	[Vector2(2304, 2061), "statue1", 200], # statues / SE
	[Vector2(2560, 973), "statue2", 200], # new room / E
	[Vector2(1472, 2445), "freddy", 450] # great hall / S
]

signal rewind

func _ready() -> void:
	randomize()
	# Connect
	player.score_earned.connect(_on_score_added)
	player.exit_point_reached.connect(_on_exit_reached)
	player.spotted.connect(_on_spotted)
	
	# place artifacts
	for artifact in ARTIFACTS:
		add_artifact(artifact[0], artifact[1], artifact[2])
	
	# place portal
	place_portal()
	
	new_round()

func new_round() -> void:
	$player/playerSounds.play_reset_sound()
	# reset round to a default round start state
	round_number += 1
	time = TIME_FOR_ONE_ROUND
	count = COUNTDOWN_TIME
	player.set_physics_process(false)
	hud.update_score(score)
	hud.update_timer(time)
	round_timer.stop()
	rewind.emit()
	
	#ghost players intializer
	if player.record.size() > 1:
		futures.append(player.record)
	spawn_ghosts()
	create_player_path()
	
	# setplayer's invincibility to true
	player.set_invincible(true)
##------------------------------------------------------------------------------
## objective updating logic should be on HUD
##------------------------------------------------------------------------------
	if round_number == 1:
		hud.update_objective(1)
		hud.update_ready("Steal an artifact and escape.")
	elif round_number > 1:
		hud.update_objective(2)
		hud.update_ready("Avoid your past selves.")
	$HUD/CountDownLabel.show()
	
	# start the countdown at the start of the round
	count_down.start()

func game_over() -> void:
	remove_ghosts()
	frame_whole_map()
	# undo the flash / probably shouldnt be here or smth i dunno
	create_tween().tween_property(white_flash, "color:a", 0.0, 0.5)
	player.set_physics_process(false)
	round_timer.stop()
##------------------------------------------------------------------------------
## HUD logic should be in HUD and not main
##------------------------------------------------------------------------------
	$HUD/TimeLabel.hide()
	$HUD/ObjectiveLabel.hide()
	$HUD/ObjectiveLabel2.hide()
	$HUD/CountDownLabel.hide()
	player.gameoverbruh()
	hud.update_ready("Space Time Continuum\nCollapse.")
	$HUD/CountDownLabel.show()
	rewind.emit()
	if player.record.size() > 1:
		futures.append(player.record)
	spawn_ghosts()
	gameovertimer.start()

func place_portal():
	var portal_light := PointLight2D.new()
	portal_light.texture = portal_light_texture
	portal_light.scale = Vector2(3.0, 3.0)
	portal_sprite = Node2D.new()
	portal_visual = portal_texture.instantiate()
	portal_visual.play()
	portal_sound = FmodEventEmitter2D.new()
	portal_sound.event_guid = "{80400fb2-5f5e-42e2-8ab0-655f1d08d1d8}"
	portal_sound.autoplay = true
	portal_visual.add_child(portal_light)
	portal_sprite.add_child(portal_visual)
	portal_sprite.add_child(portal_visual)
	add_child(portal_sprite)
	start_float_on_portal() 

func add_artifact(pos: Vector2, sprite_name: String, points=200) -> void:
	var artifact := artifact_scene.instantiate()
	artifact.initialize_data(pos, sprite_name, points)
	add_child(artifact)

func create_player_path() -> void:
	var randi1 := randi_range(1, spawns.size())
	var randi2 := randi_range(1, spawns.size())
	
	while randi1 == randi2:
		randi2 = randi_range(1, spawns.size())
		
	player.start(spawns[randi1 - 1])
	player.set_exit_point(spawns[randi2 - 1])
	
	# spawn portal @ exit point
	portal_sprite.global_position = spawns[randi2 - 1]
	hud.set_waypoint(spawns[randi2 - 1])
	
	var data := {
		"s": randi2 - 1
	}
	
	print("exit point set to position {s}".format(data))

func spawn_ghosts() -> void:
	if futures:
		for past in futures:
			var past_player_instance := playerPast_scene.instantiate()
			add_child(past_player_instance)
			past_player_instance.position = past[0]
			past_player_instance.set_movement(past.slice(1))
			past_player_instance.set_physics_process(false)
			past_players.append(past_player_instance)
			past_player_instance.spotted.connect(_on_spotted)

func remove_ghosts() -> void:
	for ghost in past_players:
		if is_instance_valid(ghost):
			if ghost.is_inside_tree():
				remove_child(ghost)
			ghost.queue_free()
	past_players.clear()

func start_float_on_portal() -> void:
	var t := create_tween().set_loops()
	t.tween_property(portal_visual, "position", Vector2(0, -25), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(portal_visual, "position", Vector2(0, 0), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func frame_whole_map() -> void:
	var cam: Camera2D = $player/Camera2D
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

func frame_killer(observer) -> void:
	var cam: Camera2D = $player/Camera2D
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

##------------------------------------------------------------------------------
## There has to be a better way to do all of these timers bruh
## and do not tell me making a timer is going to take 4 hours
##------------------------------------------------------------------------------
func _on_count_down_timeout() -> void:
	if count == 0:
		$HUD/CountDownLabel.hide()
		hud.update_timer(time)
		hud.update_score(score)
		$player/ParticleEffect.show()
		$player/ParticleEffect.play("default")
		player.set_physics_process(true)
		for p in past_players:
			if is_instance_valid(p):
				p.set_physics_process(true)
		round_timer.start()
	else:
		count -= 1
		count_down.start()

func _on_round_timer_timeout() -> void:
	if time <= 0:
		game_over()
	elif time == TIME_FOR_ONE_ROUND - 3: 
		player.set_invincible(false)
		for p in past_players:
			if is_instance_valid(p):
				p.set_invincible(false)
		$player/ParticleEffect.hide()
		$player/ParticleEffect.stop()
		time -= 1
		round_timer.start()
		hud.update_timer(time)
	else:
		time -= 1
		round_timer.start()
		hud.update_timer(time)

func _on_gameovertimer_timeout() -> void:
	if gameovertime == 2:
		for p in past_players:
			if is_instance_valid(p):
				p.set_physics_process(true)
	if gameovertime == 3:
		$HUD/RestartLabel.show()
	if gameovertime < 5:
		gameovertime += 1
		gameovertimer.start()

func _on_score_added(points) -> void:
	score += points
	hud.update_score(score)
	
func _on_exit_reached() -> void:
	remove_ghosts()
	new_round()

func _on_spotted(observer, target) -> void:
	if observer != player and target != player:
		return                                    
	if gameoverseq_started:
		return                               
	gameoverseq_started = true
	
	# set all the physics off
	player.set_physics_process(false)
	for p in past_players:
		if is_instance_valid(p):
			p.set_physics_process(false)
	
	# zoom the camera onto the killer
	frame_killer(observer)
	round_timer.stop()
	
	#create the white flash
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(white_flash, "color:a", 1.0, 2.5)
	await get_tree().create_timer(3).timeout
	
	#game is over
	game_over()

##------------------------------------------------------------------------------
## redo inputs for resetting and quitting
##------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if gameovertime > 0: 
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				get_tree().change_scene_to_file("res://UI/main_menu.tscn")
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
