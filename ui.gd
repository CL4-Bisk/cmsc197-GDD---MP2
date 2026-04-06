extends CanvasLayer
class_name UI

signal new_game
signal start_game

@onready var title_screen: MarginContainer = $TitleScreen

@onready var game_info: MarginContainer = $GameInfo
@onready var lifeforce: Label = $GameInfo/VBoxContainer/H1/Value
@onready var level: Label = $GameInfo/VBoxContainer/H2/Value
@onready var charm: Label = $GameInfo/VBoxContainer/H3/Value
@onready var hint: Label = $GameInfo/VBoxContainer/H4/Value
@onready var lives: Label = $GameInfo/VBoxContainer/H5/Value

@onready var game_over_screen: MarginContainer = $GameOverScreen
@onready var button: Button = $GameOverScreen/VBox/Button
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	audio.play()

func start_game_pressed() -> void:
	audio.stream = preload("res://assets/audio/stagemusic.wav")
	audio.play()
	title_screen.hide()
	game_info.show()
	start_game.emit()

func new_game_pressed() -> void:
	game_over_screen.hide()
	new_game.emit()
