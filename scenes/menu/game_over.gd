extends Node2D

func _ready() -> void:
	%Restart.pressed.connect(_on_restart_pressed)
	%MainMenu.pressed.connect(_on_main_menu_pressed)
	%Quit.pressed.connect(_on_quit_pressed)

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stages/base.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
