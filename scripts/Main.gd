extends Node2D

@onready var prey_spawner: Node2D = $PreySpawner
@onready var game_over_screen = $GameOverScreen
@onready var hud = $HUD
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	GameData.reset()
	GameData.game_over.connect(_on_game_over)
	prey_spawner.start_spawning()

func _on_game_over() -> void:
	prey_spawner.stop_spawning()
	game_over_screen.show()
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
