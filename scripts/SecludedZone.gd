class_name SecludedZone
extends Area2D

# Dark alley, rooftop, or parking garage, player leads prey here to consume
@export var zone_label: String = "Dark Alley"
@export var is_occupied: bool = false   # one use at a time

@onready var zone_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("secluded_zone")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_occupied: return
	if not body.is_in_group("prey"): return
	if body.state != body.State.FOLLOWING: return

	# Make sure the player is also in this zone
	var player := get_tree().get_first_node_in_group("player")
	if not player: return
	if not overlaps_body(player): return

	# Only player's prey — not rival's
	if body.enemy_succubus_ref != null: return

	is_occupied = true
	_trigger_consumption(body)

func _trigger_consumption(prey: Node2D) -> void:
	# Fade visual, play sound, consume
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.5)
	await tween.finished
	prey.consume()
	await get_tree().create_timer(2.0).timeout
	visual.modulate.a = 1.0
	is_occupied = false
