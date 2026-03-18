class_name Gang
extends Node2D

# Player needs enough power to confront them
@export var member_count: int = 3
@export var power_per_member: float = 5.0
@export var patrol_radius: float = 150.0

var members: Array = []
var total_power: float = 0.0
var is_hostile: bool = false

func _ready() -> void:
	add_to_group("gang")
	total_power = member_count * power_per_member
	_spawn_members()

func _spawn_members() -> void:
	for i in member_count:
		var m := _create_member()
		members.append(m)
		add_child(m)

func _create_member() -> CharacterBody2D:
	var m := CharacterBody2D.new()
	# Add sprite, collision, script dynamically
	# (swap with a PackedScene for production)
	m.global_position = global_position + Vector2(randf_range(-60,60), randf_range(-60,60))
	return m

func check_player_confrontation(player_power: float) -> bool:
	return player_power > total_power

func lose_member() -> void:
	if members.is_empty():
		return
	var m: CharacterBody2D = members.pop_back() as CharacterBody2D
	m.queue_free()
	total_power -= power_per_member
	if members.is_empty():
		_gang_defeated()

func _gang_defeated() -> void:
	GameData.add_score(500 * member_count)
	GameData.add_power(power_per_member * 0.5)
	queue_free()
