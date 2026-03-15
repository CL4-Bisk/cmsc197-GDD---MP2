class_name Prey
extends CharacterBody2D

enum State {
	WANDER,       # default: walking around city
	NOTICED,      # player is nearby, prey is aware
	SEDUCED,      # seduction meter filling
	FOLLOWING,    # fully charmed, following player
	FLEEING,      # resisted or spooked
	PANICKING,    # witnessed another prey vanish
	CONSUMED      # being processed (off-screen)
}

@export var prey_type: String = "civilian"  # civilian | guarded | rival_prey
@export var resist_strength: float = 1.0    # higher = harder to seduce
@export var flee_speed: float = 160.0
@export var wander_speed: float = 60.0
@export var follow_speed: float = 100.0

var seduction_meter: float = 0.0            # 0.0 → 1.0
const SEDUCE_FILL_RATE: float = 0.4
const SEDUCE_DECAY_RATE: float = 0.2
const SEDUCE_THRESHOLD: float = 1.0

var state: State = State.WANDER
var player_ref: Node2D = null
var enemy_succubus_ref: Node2D = null       # the succubus currently targeting this prey
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var seduction_bar: ProgressBar = $SeductionBar   # world-space UI
@onready var detection_area: Area2D = $DetectionArea      # sees dark zones / other prey vanishing

func _ready() -> void:
	add_to_group("prey")
	player_ref = get_tree().get_first_node_in_group("player")
	_pick_wander_target()

func _physics_process(delta: float) -> void:
	match state:
		State.WANDER:
			_do_wander(delta)
		State.NOTICED:
			_do_noticed(delta)
		State.SEDUCED:
			_do_seduce(delta)
		State.FOLLOWING:
			_do_follow(delta)
		State.FLEEING:
			_do_flee(delta)
		State.PANICKING:
			_do_panic(delta)
	
	seduction_bar.value = seduction_meter
	move_and_slide()

func _do_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		_pick_wander_target()
	_move_toward(wander_target, wander_speed)

func _do_noticed(delta: float) -> void:
	# Slow down, look toward player — seduction can begin passively
	seduction_meter = maxf(seduction_meter - SEDUCE_DECAY_RATE * delta, 0.0)
	_move_toward(wander_target, wander_speed * 0.4)

func _do_seduce(delta: float) -> void:
	# Called externally by LureAbility or proximity
	var fill := SEDUCE_FILL_RATE * GameData.seduction_strength / resist_strength
	seduction_meter = minf(seduction_meter + fill * delta, SEDUCE_THRESHOLD)
	if seduction_meter >= SEDUCE_THRESHOLD:
		_become_charmed()

func _do_follow(delta: float) -> void:
	if player_ref:
		_move_toward(player_ref.global_position, follow_speed)

func _do_flee(delta: float) -> void:
	if player_ref:
		var away := (global_position - player_ref.global_position).normalized()
		velocity = away * flee_speed
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)

func _do_panic(delta: float) -> void:
	# Run in random direction fast
	velocity = velocity.lerp(Vector2(randf_range(-1,1), randf_range(-1,1)).normalized() * flee_speed * 1.5, 0.05)

func notice_player() -> void:
	if state == State.WANDER:
		state = State.NOTICED

func begin_seduction(source: Node2D) -> void:
	if state in [State.WANDER, State.NOTICED]:
		state = State.SEDUCED

func resist_seduction() -> void:
	seduction_meter = 0.0
	state = State.FLEEING
	await get_tree().create_timer(3.0).timeout
	if state == State.FLEEING:
		state = State.WANDER

func _become_charmed() -> void:
	state = State.FOLLOWING
	seduction_meter = 1.0

func witness_consumption() -> void:
	# Nearby prey saw something — panic
	if state != State.FOLLOWING:
		state = State.PANICKING
		await get_tree().create_timer(5.0).timeout
		if state == State.PANICKING:
			state = State.FLEEING

func consume() -> void:
	# Called by SecludedZone when prey enters while Following
	state = State.CONSUMED
	GameData.consume_prey(prey_type)
	# Notify nearby prey
	var nearby := detection_area.get_overlapping_bodies()
	for body in nearby:
		if body.is_in_group("prey") and body != self:
			body.witness_consumption()
	queue_free()

func claim_by_rival(rival: Node2D) -> void:
	# Enemy succubus poached this prey
	enemy_succubus_ref = rival
	state = State.FOLLOWING  # now follows rival instead

func _move_toward(target: Vector2, spd: float) -> void:
	var dir := (target - global_position)
	if dir.length() > 5.0:
		velocity = dir.normalized() * spd
		sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO

func _pick_wander_target() -> void:
	var vp := get_viewport_rect()
	wander_target = Vector2(randf_range(50, vp.size.x - 50), randf_range(50, vp.size.y - 50))
	wander_timer = randf_range(3.0, 7.0)
