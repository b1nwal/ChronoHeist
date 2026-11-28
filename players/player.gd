class_name Player 
extends CharacterBody2D

signal score_earned(amount)
signal exit_point_reached()
signal extraction_point_reached()
signal spotted(observer, target)
signal picked_up_artifact()

const PIXELS_PER_METRE = 100
const INTERACTION_INDICATOR_OFFSET := Vector2(0, -160)

@onready var speed = get_meta("speed")
@onready var mass = get_meta("Mass")
@onready var animated_sprite = $PlayerSprite
@onready var item_sprite = $ItemSprite
@onready var interaction_range = $InteractionRange
@onready var soundManager = $playerSounds
@onready var particles = $GPUParticles2D
@onready var dash = $Dash
@onready var flash = $Flash

## GAME STATES
var gameoverseq := false
var extraction_open := false

## PLAYER STATES
var holding_item = null
var holding_item_score : int
var running = false
var invincible := true
var record = [Vector2()]
var facing_direction = "forward"

## idk what this is 
var run_start
var stop_start
var exit_point
var extraction_point


## SPOTTING
const spot_time := 0.05
var spot_timer := 0.0
var spot_fired := false

## TWEENING/MOVEMENT
var lin_drag = 9
var qua_drag = .07
var f_applied = 0
var f_max = 20000
var v_mag = 0
var v_vec = Vector2.RIGHT
var i_vec = Vector2.RIGHT
var k = 4.6 # this one looks nice on desmos
var ramp_up = 300
var ramp_down = 40
var facing := Vector2.RIGHT
var f_stiffness = 0.02352
var f_damping = 0.154
var f_A = .07
var angular_velocity = 0
var angular_acceleration = 0

var interactables: Array[Node2D] = []
var current_interactable: Node2D

func gameoverbruh():
	gameoverseq = true

func _unhandled_input(event):
	if get_script() != Player:
		return
		
	if event.is_action_pressed("dash"):
		dash.tryactivate()
	if event.is_action_pressed("flash"):
		flash.tryactivate()
		
	if event.is_action_pressed("interact"):
		interact_with_closest_interactable()
			

func _obtain_v_vec():
	var a = Input.get_vector("move_left","move_right","move_up","move_down")
	record.append([a,position])
	return [a,position]

func _process(_delta: float) -> void:
	$FlashLight.rotation = facing.angle()
	$Cone.rotation = facing.angle()
	render_player(i_vec)
	_update_interaction_indicator()

func _physics_process(delta: float) -> void:
	interactables = interactables_in_range()
	i_vec = _obtain_v_vec()[0]
	position = _obtain_v_vec()[1]
	handle_movement(i_vec, delta)
	handle_flashlight(delta)
	
	# check if distance to exit is < 64 px
	if exit_point:
		if global_position.distance_squared_to(exit_point) < 4096:
			on_exit_point_reached()
			exit_point_reached.emit()
			
	if extraction_point && extraction_open:
		if global_position.distance_squared_to(extraction_point) < 4096:
			on_exit_point_reached()
			extraction_point_reached.emit()

	move_and_slide()
	_update_current_interactable()

func animate_invicibility() -> void:
	var time_elapsed_1 : = get_tree().create_timer(1.5)
	while time_elapsed_1.time_left > 0:
		await get_tree().create_timer(0.02).timeout
		animated_sprite.visible = not animated_sprite.visible
	var time_elapsed_2 : = get_tree().create_timer(1.5)
	while time_elapsed_2.time_left > 0:
		await get_tree().create_timer(0.01).timeout
		animated_sprite.visible = not animated_sprite.visible
	animated_sprite.visible = true

func handle_movement(i_vec, delta):
	var e = angle_difference(i_vec.angle(), facing.angle())
	if not i_vec == Vector2.ZERO: # if player is running
		if angular_acceleration < 0.0174533:
			e = angle_difference(v_vec.angle() + f_A*sin((Time.get_ticks_msec())/100), facing.angle())
		angular_acceleration = f_stiffness*e - f_damping*angular_velocity
		angular_velocity += angular_acceleration
		facing = facing.rotated(-angular_velocity)
		v_vec = i_vec # v_vec is always the last direction the player was moving in
		f_applied += k*(f_max - f_applied) * delta # implement F(t) = Fmax(1-e^(-kt)) as a differential equation approximated with euler's method for a per-timestep solution that does not require statefulness
	if i_vec == Vector2.ZERO: # player is not moving
		f_applied = 0 # do not apply force to character
		if abs(v_mag) < 2: # clamps velocity down when it gets really low
			v_mag = 0 # otherwise it asymptotically goes to 0 and never reaches it
	var force = f_applied - lin_drag*v_mag - qua_drag*v_mag**2 # Fnet = Fa - Drag
	var acceleration = (force * PIXELS_PER_METRE) / mass # F = ma -> a = F/m
	v_mag += acceleration * delta # integrate acceleration into velocity
	velocity = v_vec * v_mag # velocity vector
	#print(f_applied)

	
func render_player(v_vec):
	if particles:
			particles.emitting = true
	if v_vec[0] > 0:
		_render_player_helper("right")
	elif v_vec[0] < 0:
		_render_player_helper("left")
	elif v_vec[1] > 0:
		_render_player_helper("forward")
	elif v_vec[1] < 0:
		_render_player_helper("backward")
	elif v_vec[0] == 0:
		if holding_item:
			animated_sprite.play("default_"+facing_direction+"_artifact")
		else:
			animated_sprite.play("default_"+facing_direction)

func _render_player_helper(direction):
	facing_direction = direction
	if holding_item:
		animated_sprite.play("walk_"+direction+"_artifact")
	else:
		animated_sprite.play("walk_"+direction)

func set_invincible(boo):
	invincible = boo


func handle_flashlight(delta: float) -> void:
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

# on round start
func start(pos: Vector2):
	record = [pos,facing]
	animated_sprite.play("default")
	position = pos
	holding_item = null
	item_sprite.texture = null
	current_interactable = null
	show()
	#for ray in $Cone.get_children():
		#ray.add_exception($"../raysbs")

# set the exit point for the player
func set_exit_point(point):
	exit_point = point
	
func set_extraction_point(point):
	extraction_point = point
	
func set_extraction_open(boo):
	extraction_open = boo
	
func on_exit_point_reached():
	
	if holding_item:
		score_earned.emit(holding_item_score)
		holding_item_score = 0
		holding_item = null
		particles.emitting = false


func interactables_in_range() -> Array[Node2D]:
	var nearby_interactables: Array[Node2D] = []
	for body in interaction_range.get_overlapping_bodies():
		var interactable := _find_interactable_ancestor(body)
		if interactable and not nearby_interactables.has(interactable) and interactable.can_interact(self):
			nearby_interactables.append(interactable)
	nearby_interactables.sort_custom(func(a,b):
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	return nearby_interactables

func _find_interactable_ancestor(node: Node) -> Node2D:
	var current: Node = node
	while current:
		if current is Node2D and current.is_in_group("interactable"):
			return current
		current = current.get_parent()
	return null

func interact_with_closest_interactable() -> void:
	for interactable in interactables:
		if interactable.interact(self):
			interactables = interactables_in_range()
			_update_current_interactable()
			_update_interaction_indicator()
			break

func receive_artifact(artifact: Artifact) -> void:
	holding_item = artifact.get_mini_artifact()
	holding_item_score = artifact.get_points()
	item_sprite.texture = holding_item
	soundManager.play_artifact_sound()
	picked_up_artifact.emit()

func _update_current_interactable() -> void:
	if interactables.is_empty():
		current_interactable = null
		return
	current_interactable = interactables[0]

func _update_interaction_indicator() -> void:
	var indicator := get_node_or_null("InteractionIndicator") as Sprite2D
	if not indicator:
		return
	if not is_instance_valid(current_interactable):
		indicator.hide()
		return
	indicator.global_position = current_interactable.global_position + INTERACTION_INDICATOR_OFFSET
	indicator.show()
