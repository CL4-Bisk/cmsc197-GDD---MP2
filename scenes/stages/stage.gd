extends Node
class_name Stage

@onready var player: Player = $Player
@onready var ui: UI = $UI
@onready var access_zones: Area2D = $AccessZones
@onready var base_map: NavigationRegion2D = $Map/BaseMap
@onready var cam: Camera = $Camera2D

@export var npc_scenes : Dictionary[int, PackedScene]
@export var max_npcs: int = 10
@export var spawn_interval: float = 2.0 # Seconds between spawns

var current_npc_count: int = 0
var spawn_timer: Timer

func _process(delta: float) -> void:
	var level = player.level
	ui.level.text = str(level) if level < 5 else "MAX"
	ui.lifeforce.text = str(snappedf(player.lifeforce - player.AURA_SIZE, 0.1))
	ui.charm.text = str(snappedf(player.charm_power.get(level), 0.1)) 
	ui.hint.text = str(player.level_threshold.get(level)) if level < 5 else "N/A"
	
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
	var x = randi_range(0, player.level)
	var n = npc_scenes.get(x).instantiate()
	n.tree_exited.connect(func(): current_npc_count -= 1; spawn_timer.start())
	n.global_position = pick_access_point()
	add_child(n)
	current_npc_count += 1
	n.stage = self
	n.nav2d.target_position = NavigationServer2D.region_get_random_point(base_map.get_rid(), 1, true)
	n.start_state(&"enter")

func _on_player_feeding_start() -> void:
	cam.zoom = Vector2(4, 4)
	cam.zoom_distance = 0

func _on_player_feeding_stop() -> void:
	cam.zoom = Vector2(2, 2)
	cam.zoom_distance = cam.max_distance
	
