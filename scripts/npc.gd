extends CharacterBody2D
class_name NPC

enum Behavior {
	SWAYED,
	NORMAL,
	FLEE,
	CHASE,
	IDLE
}

@export var npc_size: float = 1.0
@export var speed: float = 100.0
@export var score_value: int = 10
@export var behavior: Behavior = Behavior.NORMAL

@onready var sprite: Sprite2D = $Sprite2D
@onready var screen_notifier = $VisibleOnScreenNotifier2D

var direction: Vector2 = Vector2.LEFT

func _ready() -> void:
	add_to_group("npc")
	screen_notifier.screen_exited.connect(_on_screen_exited)
	
	var vp := get_viewport_rect()
	if randf() > 0.5:
		global_position = Vector2(vp.size.x + 50, randf_range(50, vp.size.y - 50))
		direction = Vector2.LEFT
	else:
		global_position = Vector2(-50, randf_range(50, vp.size.y - 50))
		direction = Vector2.RIGHT
	
	sprite.flip_h = direction.x < 0
	move_and_slide()

func _flee_from_player() -> void:
	

func _chase_player() -> void:
	

func _swayed_from_player() -> void:
	

func get_eaten() -> void:
	queue_free()

func _on_screen_exited() -> void:
	queue_free()
