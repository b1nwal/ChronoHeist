
class_name Player 
extends CharacterBody2D

@onready var speed = get_meta("speed")
@onready var animated_sprite = $Sprite2D
@onready var item_sprite = $ItemSprite2D
@onready var interaction_range = $InteractionRange
@onready var soundManager = $playerSounds
@onready var particles = $GPUParticles2D

var ability: Ability = AbilityInvisiblityCloak.new()

signal score_earned(amount)
signal exit_point_reached()
signal spotted(observer, target)

## GAME STATES
var gameoverseq := false

## PLAYER STATES
var holding_item = null
var running = false
var invincible := true
var record = [Vector2()]

## idk what this is 
var run_start
var stop_start
var exit_point

## SPOTTING
const spot_time := 0.05
var spot_timer := 0.0
var spot_fired := false

## TWEENING/MOVEMENT
var ramp_up = 300
var ramp_down = 410
var facing := Vector2.RIGHT
var f_stiffness = 0.02352
var f_damping = 0.154
var f_A = .07
var angular_velocity = 0
var angular_acceleration = 0


func gameoverbruh():
	gameoverseq = true

func _unhandled_input(event):
	if get_script() != Player:
		return

	if event.is_action_pressed("interact"):
		if !holding_item:
			interact_with_closest_artifacts()
			
	if event.is_action_pressed("ability1"):
		ability.cast(self)

func _obtain_v_vec():
	var a = Input.get_vector("move_left","move_right","move_up","move_down")
	record.append([a,position])
	return [a,position]

func _process(delta: float) -> void:
	ability.update(delta)

func _physics_process(delta: float) -> void:
	var v_vec = _obtain_v_vec()[0]
	position = _obtain_v_vec()[1]
	handle_movement(v_vec)
	handle_flashlight(delta)

	# check if distance to exit is < 64 px
	if exit_point:
		if global_position.distance_squared_to(exit_point) < 4096:
			on_exit_point_reached()

	move_and_slide()
	render_player(v_vec)
	
func handle_movement(v_vec):	
	
	

	
		 
	var e = angle_difference(v_vec.angle(), facing.angle())

	if not v_vec == Vector2.ZERO and not running:
		running = true
		run_start = Time.get_ticks_msec()
	if v_vec == Vector2.ZERO and running:
		running = false
		stop_start = Time.get_ticks_msec()
		animated_sprite.stop()
	if running:
		if angular_acceleration < 0.0174533:
			e = angle_difference(v_vec.angle() + f_A*sin((Time.get_ticks_msec() - run_start)/100), facing.angle())
		angular_acceleration = f_stiffness*e - f_damping*angular_velocity
		angular_velocity += angular_acceleration
		
		facing = facing.rotated(-angular_velocity)
		velocity = v_vec * v_tween(ramp_up, Time.get_ticks_msec() - run_start)
	if not running and not velocity == Vector2.ZERO:
		velocity = velocity.normalized() * (speed - v_tween(ramp_down * (velocity.length()/speed), Time.get_ticks_msec() - stop_start))
		
func render_player(v_vec):
	if v_vec[0] > 0:
		if particles:
			particles.emitting = true
		if holding_item:
			animated_sprite.play("walk_right_artifact")
		else:
			animated_sprite.play("walk_right")
	elif v_vec[0] < 0:
		if particles:
			particles.emitting = true
		if holding_item:
			animated_sprite.play("walk_left_artifact")
		else:
			animated_sprite.play("walk_left")
	elif v_vec[1] > 0:
		if particles:
			particles.emitting = true
		if holding_item:
			animated_sprite.play("walk_forward_artifact")
		else:
			animated_sprite.play("walk_forward")
	elif v_vec[1] < 0:
		if particles:
			particles.emitting = true
		animated_sprite.play("walk_backward")
	elif v_vec[0] == 0:
		if particles:
			particles.emitting = false
		if holding_item:
			animated_sprite.play("default_artifact")
		else:
			animated_sprite.play("default")

func set_invincible(boo):
	invincible = boo

func handle_flashlight(delta: float) -> void:
	
	$FlashLight.rotation = facing.angle()
	$Cone.rotation = facing.angle()
	
	if gameoverseq == false and invincible == false:
		var target = null
		for ray in $Cone.get_children():
			if not ray.is_colliding():
				continue
			if ray.is_colliding():
				if ray.get_collider() is Player and ray.get_collider() != self:
					target = ray.get_collider()
					break
		if target:
			spot_timer += delta
			if spot_timer >= spot_time and not spot_fired:
				spot_fired = true
				spotted.emit(self, target)
		else:
			spot_timer = max(0.0, spot_timer - delta * 2.0)
			if spot_timer == 0.0:
				spot_fired = false
	
func v_tween(ramp_time: int, x: float) -> float:
	var m = 1
	if x < ramp_time:
		m = (3*((x/ramp_time)**2) - 2*((x/ramp_time)**3))
	return m * speed

# on round start
func start(pos: Vector2):
	record = [pos,facing]
	animated_sprite.play("default")
	position = pos
	holding_item = null
	item_sprite.texture = null
	show()
	#for ray in $Cone.get_children():
		#ray.add_exception($"../raysbs")

# set the exit point for the player
func set_exit_point(point):
	exit_point = point
	
func on_exit_point_reached():
	
	if holding_item:
		score_earned.emit(holding_item.point_value)
		holding_item = null
		particles.emitting = false
	
	exit_point_reached.emit()

# interact with all the closest artifacts
func interact_with_closest_artifacts():
	var nodes_in_range: Array[Node2D] = interaction_range.get_overlapping_bodies()
	
	var artifacts = []
	
	for body in interaction_range.get_overlapping_bodies():
		var parent = body.get_parent()

		if parent is Artifact:
			artifacts.append(parent)
	
	# sort by proximity!
	artifacts.sort_custom(func(a,b):
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	
	# try interacting with all the artifacts in range in order of distance
	for artifact in artifacts:
		if artifact.interact():
			
			holding_item = artifact
			var data = {
				"name": artifact.get_sprite_name()
			}
			item_sprite.texture = load("res://assets/artifacts/artifact_item_{name}_small.png".format(data))
			soundManager.play_artifact_sound()
			break
