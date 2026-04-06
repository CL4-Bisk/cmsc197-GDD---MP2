extends Node
class_name Stage

@onready var player: Player = $Player
@onready var access_zones: Area2D = $AccessZones
@onready var base_map: NavigationRegion2D = $Map/BaseMap

@export var npc_scene : PackedScene
@export var max_npcs: int = 10
@export var spawn_interval: float = 1.0 # Seconds between spawns

var current_npc_count: int = 0
var spawn_timer: Timer

func _ready() -> void:
	# Set up a timer to handle the "gradual" part
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if current_npc_count < max_npcs:
		spawn_npc()
	else:
		spawn_timer.stop()

func pick_access_point() -> Vector2:
	var point = access_zones.get_children().pick_random()
	var pos = point.global_position
	var dim = point.shape.size/2
	
	return Vector2(
		randf_range(pos.x - dim.x, pos.x + dim.x),
		randf_range(pos.y - dim.y, pos.y + dim.y))

func spawn_npc() -> void:
	var n = npc_scene.instantiate() as NPC
	n.tree_exited.connect(func(): current_npc_count -= 1; spawn_timer.start())
	n.global_position = pick_access_point()
	add_child(n)
	current_npc_count += 1
	n.stage = self
	n.nav2d.target_position = NavigationServer2D.region_get_random_point(base_map.get_rid(), 1, true)
	n.start_state(&"enter")
