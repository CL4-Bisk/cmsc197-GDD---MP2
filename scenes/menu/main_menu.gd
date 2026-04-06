extends Node2D

func _ready() -> void:
	$Start.pressed.connect(_on_start_pressed)
	$Quit.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stages/base.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
