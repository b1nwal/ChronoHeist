extends CanvasLayer

# waypoint images
@onready var waypoint : Marker2D = $Waypoint
@onready var waypointBL : Sprite2D = $Waypoint/bottomleft
@onready var waypointBR : Sprite2D = $Waypoint/bottomright
@onready var waypointB : Sprite2D = $Waypoint/bottom
@onready var waypointL : Sprite2D = $Waypoint/left
@onready var waypointR : Sprite2D = $Waypoint/right
@onready var waypointTL : Sprite2D = $Waypoint/topleft
@onready var waypointTR : Sprite2D = $Waypoint/topright
@onready var waypointT : Sprite2D = $Waypoint/top

@onready var artifact_waypoint : Marker2D = $ArtifactWaypoint

@onready var top_timer : Label = $TopTimer
@onready var score_label : Label = $ScoreLabel
@onready var main_middle_label : Label = $MainMiddleLabel

const WAYPOINT_MARGIN := 96.0
var portal_waypoint_target = null
var artifact_waypoint_target : Vector2 

func _process(delta: float) -> void:
	_portal_waypointer()
	_artifact_waypointer()

func _portal_waypointer():
	if portal_waypoint_target == null:
		waypoint.hide()
		return
	
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * portal_waypoint_target
	var safe := get_viewport().get_visible_rect().grow(-WAYPOINT_MARGIN)
	 
	if safe.has_point(screen_pos):
		waypoint.hide()
		return
	
	waypoint.show()
	waypoint.position = screen_pos.clamp(safe.position, safe.end)
	
	var p := waypoint.position
	var on_left   := p.x <= safe.position.x
	var on_right  := p.x >= safe.end.x
	var on_top    := p.y <= safe.position.y
	var on_bottom := p.y >= safe.end.y
	
	for s in waypoint.get_children():
		s.hide()
	if on_top and on_left:       waypointTL.show()
	elif on_top and on_right:    waypointTR.show()
	elif on_bottom and on_left:  waypointBL.show()
	elif on_bottom and on_right: waypointBR.show()
	elif on_left:                waypointL.show()
	elif on_right:               waypointR.show()
	elif on_top:                 waypointT.show()
	else:                        waypointB.show()

func _artifact_waypointer():
	if artifact_waypoint_target == null:
		artifact_waypoint.hide()
		return
	#var viewport_dimensions : Vector2 = get_viewport().get_visible_rect().size
	#var screen_pos: Vector2 = get_viewport().get_canvas_transform() * artifact_waypoint_target
	#var screen_center : Vector2 = viewport_dimensions / 2
	#artifact_waypoint.show()
	#artifact_waypoint.position = screen_center.clamp(screen_center.position, screen_center.end)
	

func set_artifact_waypoint(pos : Vector2) -> void:
	artifact_waypoint_target = pos



func update_ready(message):
	main_middle_label.text = message
	if message.contains("Space"):
		$CountDownLabel.add_theme_font_size_override("font_size", 100)
		$CountDownLabel.add_theme_color_override("font_color", Color(0, 0, 0))
		$CountDownLabel.add_theme_color_override("font_outline_color", Color(255, 255, 255))
	elif message.contains("Avoid"):
		$CountDownLabel.add_theme_font_size_override("font_size", 85)
		$CountDownLabel.add_theme_color_override("font_color", Color(255, 0, 0))
		$CountDownLabel.add_theme_color_override("font_outline_color", Color(255, 255, 255))
	else:
		$CountDownLabel.add_theme_font_size_override("font_size", 75)
		$CountDownLabel.add_theme_color_override("font_color", Color(255, 255, 255))
		$CountDownLabel.add_theme_color_override("font_outline_color", Color(0, 0, 0))

func update_timer(time : float):
	top_timer.text = str("%.2f" % time)
	if time <= 10:
		top_timer.add_theme_color_override("font_color", Color(255, 0, 0))
		top_timer.add_theme_color_override("font_outline_color", Color(255, 255, 255))
	else:
		top_timer.add_theme_color_override("font_color", Color(255, 255, 255))
		top_timer.add_theme_color_override("font_outline_color", Color(0, 0, 0))

func update_score(score : int):
	score_label.text = str(score)

func update_objective(objective):
	if objective == 1:
		$ObjectiveLabel2.hide()
		$ObjectiveLabel.text = "Steal an artifact and escape through the portal."
	elif objective == 2:
		$ObjectiveLabel.text = "Steal an artifact and escape through the portal."
		$ObjectiveLabel2.show()
		$ObjectiveLabel2.text = "Avoid your past selves."
	else:
		$ObjectiveLabel.text = "the objective label is cooked what did you do"

func set_waypoint(pos : Vector2) -> void:
	portal_waypoint_target = pos

func _on_player_proximal_to_artifact(truth) -> void:
	$E_Indicator.visible = truth;
