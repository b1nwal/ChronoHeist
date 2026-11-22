extends Node2D

@onready var portal_visual : AnimatedSprite2D = $PortalVisual

func _ready():
	portal_visual.play()
	var t := create_tween().set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(portal_visual, "position:y", -25.0, 1.5)
	t.tween_property(portal_visual, "position:y", 0.0, 1.5)
