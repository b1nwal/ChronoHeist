extends Node

@onready var player = get_parent();

@onready var step_delay = get_meta("delay") 

var footstep_timer: Timer
var time_sound_running = false;

func _ready():
	timer_ready()
 
func _process(delta):
	play_walk_sound()
	#print(calc_ramp_delay())
	
func play_walk_sound(): #tempporary
	if (!player.is_physics_processing()):
		footstep_timer.stop()
	elif !player.velocity.is_zero_approx():
		if footstep_timer.is_stopped():
			footstep_timer.start()
	else: 
		footstep_timer.stop()
		

func play_delay_async(emitter: FmodEventEmitter2D, delay):
	emitter.play()
	await get_tree().create_timer(delay).timeout
	
func timer_ready():
	footstep_timer = Timer.new()
	footstep_timer.one_shot = false
	footstep_timer.wait_time = step_delay
	add_child(footstep_timer)
	footstep_timer.timeout.connect(_on_footstep_timer_timeout)
#
func _on_footstep_timer_timeout():
	$footsteps.play()
	
func play_artifact_sound():
	$artifact.play()
	
func play_death_sound():
	print("OW")
	
func play_reset_sound():
	$rewind.play_one_shot()
