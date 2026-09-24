extends CanvasLayer

@onready var waypoint: Marker2D = $Waypoint
@onready var waypointBL: Sprite2D = $Waypoint/bottomleft
@onready var waypointBR: Sprite2D = $Waypoint/bottomright
@onready var waypointB: Sprite2D = $Waypoint/bottom
@onready var waypointL: Sprite2D = $Waypoint/left
@onready var waypointR: Sprite2D = $Waypoint/right
@onready var waypointTL: Sprite2D = $Waypoint/topleft
@onready var waypointTR: Sprite2D = $Waypoint/topright
@onready var waypointT: Sprite2D = $Waypoint/top


#@onready var viewport_size = get_viewport().size
#const top = WAYPOINT_MARGIN
#const left = WAYPOINT_MARGIN
#@onready var right = viewport_size.x - WAYPOINT_MARGIN + 3
#@onready var bottom = viewport_size.y - WAYPOINT_MARGIN + 2
const WAYPOINT_MARGIN := 96.0
var waypoint_target = null

#@onready var max_dimension = max(viewport_size.x, viewport_size.y)

func _process(delta: float) -> void:
	if not $CountDownLabel.visible:
		_waypointer()
	else:
		waypoint.hide()

func _waypointer():
	if waypoint_target == null:
		waypoint.hide()
		return
	
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * waypoint_target
	var safe := get_viewport().get_visible_rect().grow(-WAYPOINT_MARGIN)
	#var center = safe.get_center()
	 
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
	#print(waypoint.position)
	#print(right)
	#print(bottom)

func update_ready(message):
	$CountDownLabel.text = message
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

func update_timer(time):
	$TimeLabel.text = str(time)
	if time <= 10:
		$TimeLabel.add_theme_color_override("font_color", Color(255, 0, 0))
		$TimeLabel.add_theme_color_override("font_outline_color", Color(255, 255, 255))
	else:
		$TimeLabel.add_theme_color_override("font_color", Color(255, 255, 255))
		$TimeLabel.add_theme_color_override("font_outline_color", Color(0, 0, 0))

func update_score(score):
	$ScoreLabel.text = str(score)

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

func set_waypoint(pos) -> void:
	waypoint_target = pos
