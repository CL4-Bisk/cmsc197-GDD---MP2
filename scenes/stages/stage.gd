extends Node
class_name Stage

@onready var player: Player = $Player
@onready var ui: UI = $UI
@onready var access_zones: Area2D = $AccessZones
@onready var base_map: NavigationRegion2D = $Map/BaseMap
@onready var cam: Camera = $Camera2D
@onready var spawn_timer: Timer = $SpawnTimer

@export var npc_scenes : Dictionary[int, PackedScene]
@export var max_npcs: int = 10

var current_npc_count: int = 0
var game_started : bool = false

func _process(delta: float) -> void:
	var level = player.level
	ui.level.text = str(level) if level < 5 else "MAX"
	ui.lifeforce.text = str(snappedf(player.lifeforce - player.AURA_SIZE, 0.1))
	ui.charm.text = str(snappedf(player.charm_power.get(level), 0.1)) 
	ui.hint.text = str(player.level_threshold.get(level)) if level < 5 else "N/A"
	ui.lives.text = str(player.lives)

func _ready() -> void:
	player.set_process(false)

func _on_spawn_timer_timeout() -> void:
	if current_npc_count < max_npcs: spawn_npc()
	else: spawn_timer.stop()

func pick_access_point() -> Vector2:
	var point = access_zones.get_children().pick_random()
	var pos = point.global_position
	var dim = point.shape.size/2
	
	return Vector2(
		randf_range(pos.x - dim.x, pos.x + dim.x),
		randf_range(pos.y - dim.y, pos.y + dim.y))

func spawn_npc() -> void:
	var x = randi_range(0, player.level-1)
	var n = npc_scenes.get(x).instantiate()
	n.tree_exited.connect(func(): current_npc_count -= 1; spawn_timer.start())
	n.global_position = pick_access_point()
	add_child(n)
	current_npc_count += 1
	if player.lifeforce > n.lifeforce:
		n.lifeforce += player.lifeforce - player.AURA_SIZE
	n.stage = self
	n.nav2d.target_position = NavigationServer2D.region_get_random_point(base_map.get_rid(), 1, true)
	n.start_state(&"enter")

func zoom(enabled: bool) -> void:
	if enabled:
		cam.zoom = Vector2(4, 4)
		cam.zoom_distance = 0
	else:
		cam.zoom = Vector2(2, 2)
		cam.zoom_distance = cam.max_distance
	
func _on_player_dead() -> void:
	zoom(true)
	ui.game_over_screen.show()

func new_game() -> void:
	get_tree().reload_current_scene()

func start_game() -> void:
	player.set_process(true)
	player.game_started = true
	spawn_timer.start()
