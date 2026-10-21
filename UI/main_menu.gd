extends Control

const GAME_SCENE = preload("res://main/main.tscn")
@onready var music = MainAudio.get_node("Music")
@onready var UI_audio = MainAudio.get_node("UI")

func _ready():
	music.hold_intro()
	music.play()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			music.release_intro()
			UI_audio.play_start()
			get_tree().change_scene_to_packed(GAME_SCENE)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
