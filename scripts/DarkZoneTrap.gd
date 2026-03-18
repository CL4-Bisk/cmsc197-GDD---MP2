extends Area2D

@export var lure_strength: float = 0.5
@export var lifetime: float = 15.0
@export var radius: float = 80.0

var elapsed: float = 0.0

func _ready() -> void:
	#body_entered.connect(_on_body_entered)
	# Visual pulse using tween
	var tween := create_tween().set_loops()
	tween.tween_property($Sprite2D, "modulate:a", 0.3, 0.8)
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.8)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
	# Tick seduction on any prey inside
	for body in get_overlapping_bodies():
		if body.is_in_group("prey"):
			body.seduction_meter += lure_strength * delta * GameData.seduction_strength
			if body.seduction_meter >= 1.0:
				body._become_charmed()
