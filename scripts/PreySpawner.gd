extends Node2D

@export var prey_scene: PackedScene
@export var enemy_succubus_scene: PackedScene
@export var gang_scene: PackedScene

@export var max_prey: int = 2
@export var max_rivals: int = 2
@export var max_gangs: int = 2
@export var base_spawn_interval: float = 10.0

@onready var container: Node2D = get_parent().get_node("Container")
	
var spawn_timer: Timer
var active: bool = false

const PREY_CONFIGS: Array = [
	{ "type": "civilian",  "resist": 1.0, "flee_speed": 140.0 },
	{ "type": "guarded",   "resist": 2.0, "flee_speed": 170.0 },
	{ "type": "rival_prey","resist": 1.5, "flee_speed": 160.0 },
]

# How many rivals/gangs allowed per level
const LEVEL_ENEMY_COUNTS: Array = [
	{ "rivals": 1, "gangs": 0 },  # level 1
	{ "rivals": 1, "gangs": 1 },  # level 2
	{ "rivals": 2, "gangs": 1 },  # level 3
	{ "rivals": 2, "gangs": 2 },  # level 4+
]

func _ready() -> void:
	GameData.level_changed.connect(_on_level_changed)

func start_spawning() -> void:
	active = true
	spawn_timer = Timer.new()
	spawn_timer.wait_time = base_spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_tick)
	add_child(spawn_timer)
	# Seed the map on start
	_initial_spawn()

func stop_spawning() -> void:
	active = false
	if spawn_timer:
		spawn_timer.stop()

func _initial_spawn() -> void:
	for i in 6:
		_spawn_prey()
	
	_spawn_rival()
	_spawn_gang()

func _on_spawn_tick() -> void:
	if not active:
		return

	var prey_count: int = 0
	var rival_count: int = 0
	var gang_count: int = 0

	for n in container.get_children():
		if n.is_in_group("prey"):
			prey_count += 1
		elif n.is_in_group("enemy_succubus"):
			rival_count += 1
		elif n.is_in_group("gang"):
			gang_count += 1

	var lvl_idx: int = min(GameData.level - 1, LEVEL_ENEMY_COUNTS.size() - 1)
	var cfg: Dictionary = LEVEL_ENEMY_COUNTS[lvl_idx]

	if prey_count < max_prey:
		_spawn_prey()
	if rival_count < cfg["rivals"]:
		_spawn_rival()
	if gang_count < cfg["gangs"]:
		_spawn_gang()

func _spawn_prey() -> void:
	if not prey_scene:
		push_error("PreySpawner: prey_scene not assigned!")
		return

	# Pick config weighted by level
	var available_types := mini(GameData.level, PREY_CONFIGS.size())
	var cfg: Dictionary = PREY_CONFIGS[randi() % available_types]

	var prey: Prey = prey_scene.instantiate()
	prey.prey_type     = cfg["type"]
	prey.resist_strength = cfg["resist"]
	prey.flee_speed    = cfg["flee_speed"]
	prey.global_position = _random_spawn_position()
	container.add_child(prey)

func _spawn_rival() -> void:
	if not enemy_succubus_scene:
		push_error("PreySpawner: enemy_succubus_scene not assigned!")
		return
	var rival: EnemySuccubus = enemy_succubus_scene.instantiate()
	
	# Scale rival power with level
	rival.power = 10.0 + (GameData.level * 3.0)
	rival.global_position = _random_spawn_position()
	container.add_child(rival)

func _spawn_gang() -> void:
	if not gang_scene:
		push_error("PreySpawner: gang_scene not assigned!")
		return
	var gang: Gang = gang_scene.instantiate()
	gang.member_count    = 2 + GameData.level
	gang.power_per_member = 4.0 + (GameData.level * 1.5)
	gang.global_position = _random_spawn_position()
	container.add_child(gang)


func _random_spawn_position() -> Vector2:
	var vp := get_viewport_rect()
	# Spawn away from screen center so player isn't immediately swarmed
	var edge := randi() % 4
	match edge:
		0:
			return Vector2(randf_range(50, vp.size.x - 50), 50)              # top
		1:
			return Vector2(randf_range(50, vp.size.x - 50), vp.size.y - 50)  # bottom
		2:
			return Vector2(50, randf_range(50, vp.size.y - 50))               # left
		_:
			return Vector2(vp.size.x - 50, randf_range(50, vp.size.y - 50))  # right


func _on_level_changed(new_level: int) -> void:
	# Speed up spawns as levels increase
	if spawn_timer:
		spawn_timer.wait_time = max(base_spawn_interval - (new_level * 0.2), 1.0)
