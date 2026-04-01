extends Node
class_name Stage

@onready var player: Player = $Player
@onready var access_zones: Area2D = $AccessZones

@export var npc_scene : PackedScene
@onready var base_map: NavigationRegion2D = $Map/BaseMap

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("spawn"):
		spawn_npc()

func pick_access_point() -> Vector2:
	var point = access_zones.get_children().pick_random()
	var pos = point.global_position
	var dim = point.shape.size/2
	
	return Vector2(
		randf_range(pos.x - dim.x, pos.x + dim.x),
		randf_range(pos.y - dim.y, pos.y + dim.y))

func spawn_npc() -> void:
	var n = npc_scene.instantiate() as NPC
	n.global_position = pick_access_point()
	add_child(n)
	n.stage = self
	n.nav2d.target_position = NavigationServer2D.region_get_random_point(base_map.get_rid(), 1, true)
	n.start_state(&"enter")
