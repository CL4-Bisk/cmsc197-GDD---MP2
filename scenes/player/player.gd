extends CharacterBody2D
class_name Player

signal player_dead
signal feeding_start
signal feeding_stop

var game_started : bool = false

const AURA_SIZE : int = 40.0
const STARVATION_DURATION: float = 10.0
const STARVATION_THRESHOLD: float = 0.0
@onready var state_machine: StateMachine = $StateMachine
@onready var charm_zone: CollisionShape2D = $Charm/Zone
@onready var feed_zone: Area2D = $Feed
@onready var check: RayCast2D = $Check
@onready var demon_timer: Timer = $DemonTimer
@onready var invul_timer: Timer = $IFrameTimer
@onready var censor: ColorRect = $Censor
@onready var charm_aura: CPUParticles2D = $CharmAura
@onready var starve_timer: Timer = $StarveTimer

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var nav2d: NavigationObstacle2D = $Nav2D
@onready var hit_box: CollisionShape2D = $HitBox

@onready var status_ind: Label = $Status

@export var move_speed : float = 250.0
@export var charm_power : Dictionary[int, float] = {
	1: 1.0,
	2: 2.5,
	3: 5.0,
	4: 8,
	5: 12
}
@export var charm_zone_growth_spd : float = 50.0

@export var lifeforce : float = 40.0
@export var lives : int = 5
@export var level_threshold : Dictionary[int, float]
@export var popup_text : PackedScene

var level : int = 5
var status = ""
var lustful : bool = false
var is_mouse_inside : bool = false
var spd_mult : float = 1.0
var is_starving : bool = false

func _ready() -> void:
	state_machine.handler = self
	state_machine.register_state(&"normal", SucccubiStates.Normal)
	state_machine.register_state(&"charm", SucccubiStates.Charming)
	state_machine.register_state(&"feed", SucccubiStates.Feeding)
	state_machine.register_state(&"lust", SucccubiStates.Lustful)
	state_machine.register_state(&"dead", SucccubiStates.Subjugated)
	state_machine.register_state(&"hit", SucccubiStates.Hit)

	starve_timer.wait_time = 0.1
	starve_timer.timeout.connect(_on_starve_timer_tick)

	state_machine.change(&"normal")
	state_machine._process_pending()

func _physics_process(_delta: float) -> void:
	if not game_started: return
	var is_pressing_mouse = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	#print(state_machine.stack.map(func(x): return x.state_name))
	match state_machine.current().state_name:
		&"feed", &"dead", &"hit":
			velocity = Vector2.ZERO
		_:
			anim.speed_scale = spd_mult
			move_to_mouse(is_pressing_mouse)
	(charm_zone.shape as CircleShape2D).radius = lifeforce
	move_and_slide()

	check_starvation()

	print("player level: ", level)
	print("life force count: ", lifeforce - AURA_SIZE)
	if is_starving:
		status_ind.text = "HuNgRy"
	elif lives < 3:
		status_ind.text = "HoRt"
	else:
		status_ind.text = "healty"

func check_starvation() -> void:
	if lifeforce <= STARVATION_THRESHOLD and not is_starving:
		is_starving = true
		starve_timer.start()
	if lifeforce > STARVATION_THRESHOLD and is_starving:
		is_starving = false
		starve_timer.stop()

func _on_starve_timer_tick() -> void:
	lifeforce -= (lifeforce + AURA_SIZE) * 0.1
	if lifeforce <= -AURA_SIZE:
		starve_timer.stop()
		player_dead.emit()
		state_machine.change(&"dead")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"feed") and \
	state_machine.current().state_name != &"feed" and \
	feed_zone.has_overlapping_bodies():
		state_machine.change(&"feed")

func generate_text(text: String) -> void:
	var p = popup_text.instantiate()
	p.text = text
	add_child(p)
	await p.finished
	p.queue_free()

func move_to_mouse(is_pressed : bool) -> void:
	if state_machine.current() is SucccubiStates.Feeding: return

	var mouse_pos = get_global_mouse_position()
	var dir = global_position.direction_to(mouse_pos)
	sprite.flip_h = dir.x < 0

	if is_mouse_inside or not is_pressed:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
		anim.play(&"idle" + status)
		return

	var look_distance = 60.0
	var stop = 20.0

	check.target_position = dir * look_distance
	check.force_raycast_update()

	var spd_mod = 1.0

	if check.is_colliding():
		var dis_to_wall = global_position.distance_to(check.get_collision_point())
		if dis_to_wall <= stop:
			velocity = velocity.lerp(Vector2.ZERO, 0.4)
			anim.play(&"idle" + status)
			return

		spd_mod = clamp((dis_to_wall - stop)/ look_distance, 0, 1.0)

	velocity = velocity.lerp(dir * move_speed * spd_mult * spd_mod, 0.1)
	anim.play(&"run" + status)

func find_nearest() -> Node2D:
	var bodies := feed_zone.get_overlapping_bodies()
	var nearest : Node2D = null
	var min_dis = INF

	for body in bodies:
		if not body.is_in_group(&"npc") and body == self and self.lifeforce > 0: continue
		
		var distance = global_position.distance_to(body.global_position)
		if distance < min_dis:
			min_dis = distance
			nearest = body

	return nearest

func invul(toggle: bool) -> void:
	if lives <= 0: return
	set_collision_layer_value(1, !toggle)
	sprite.modulate.a = 0.5 if toggle else 1.0

func mouse_detect(toggle: bool) -> void:
	is_mouse_inside = toggle

func _on_charm(body: Node2D, entered: bool) -> void:
	if body is NPC:
		var npc = (body as NPC)
		npc.receive_charm(charm_power.get(level) if entered else 0.0)

func end_demon_time() -> void:
	lustful = false
	status = ""
	state_machine.refresh()
	if state_machine.current().state_name == &"lust":
		state_machine.back()
		state_machine.change(&"normal")

func hit() -> void:
	if lustful: return
	state_machine.change(&"hit")

func _on_player_dead() -> void:
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/menu/game_over.tscn")

func stop_starve() -> void:
	is_starving = false
	starve_timer.stop()
