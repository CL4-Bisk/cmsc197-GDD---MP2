extends CharacterBody2D
class_name NPC

@onready var state_machine: GameStateMachine = $StateMachine
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: CollisionShape2D = $HitBox
@onready var wander_zone: CollisionShape2D = $Wander/WanderZone

@onready var idle_timer: Timer = $IdleTimer
@onready var tick_rate: Timer = $TickRate
@onready var vigilance_ind: Label = $VigilanceInd
@onready var life_force_ind: Label = $LifeForceInd

@onready var detection: Area2D = $Detection
@onready var d_zone: CollisionShape2D = $Detection/Zone
@onready var comfort: Area2D = $Comfort
@onready var c_zone: CollisionShape2D = $Comfort/Zone
@onready var sensitive: Area2D = $Sensitive
@onready var check: RayCast2D = $Check

@export_category("Dynamic Parameters")
@export var move_speed : float = 100.0
@export var life_force : float = 10.0
@export var vigilance : float = 15
var reduc_rate : float = 0

@export_category("Fixed Parameters")
@export var wait_time : float = 4.0

enum Behavior {
	CHARMED,	# reduction amount is havled
	DULLED,		# 1/3
	SOBER,		# 1/4
	ALERT,		# 1/5
	ALARMED,	# 1/10
	TERRIFIED,	# 1/20
	DRAINED, 
}
@export var behavior : Behavior
@export var mult : Dictionary[Behavior, Vector2] = {
	Behavior.CHARMED: Vector2(2, 0),
	Behavior.DULLED: Vector2(1, 15),
	Behavior.SOBER: Vector2(1/1.5, 50),
	Behavior.ALERT: Vector2(1.0/2, 75),
	Behavior.ALARMED: Vector2(1.0/3, 99),
	Behavior.TERRIFIED: Vector2(1.0/5, 100),
}

func _ready() -> void:
	update_indicators()
	
	state_machine.handler = self
	
	state_machine.register_state("idle", NPCStates.Idle)
	state_machine.register_state("wander", NPCStates.Wander)
	state_machine.register_state("flee", NPCStates.Flee)
	state_machine.register_state("struggle", NPCStates.Struggle)
	state_machine.register_state("chase", NPCStates.Chase)
	state_machine.register_state("husk", NPCStates.Husk)
	
	state_machine.change("idle")
	state_machine._process_pending()

var spd_mult : float = 1.0
var offender : Node2D
var target : Node2D

func _physics_process(_delta: float) -> void:
	move_and_slide()
	print(state_machine.stack.map(func(x): return x.state_name))
	
	if state_machine.current() and state_machine.current().state_name == "struggle": return
	if velocity.length() <= 1: anim.play("idle")
	else: anim.play("run")

func toggle_zones(enabled: bool, ... zones: Array) -> void:
	for z in zones:
		if z is not Area2D: continue
		z.monitoring = enabled

func _is_path_clear(destination: Vector2) -> bool:
	check.target_position = destination
	check.force_raycast_update()
	return not check.is_colliding()

func pick_destination(
	max_distance: float,
	min_distance: float = 0.0,
	target_pos: Vector2 = Vector2.ZERO,
	flee: bool = true) -> Vector2:
	
	var angle : float = randf() * TAU
	if target_pos:
		var dir = (target_pos - global_position).angle()
		if flee: dir += PI
		angle = dir + randf_range(-PI/4, PI/4)
	var distance = ((max_distance - min_distance) * sqrt(randf())) + min_distance
	var offset = Vector2.from_angle(angle) * distance
	return offset if _is_path_clear(offset) else pick_destination(max_distance, min_distance, target_pos, flee)

func modify_vigilance(amount: float) -> void:
	vigilance = max(0, vigilance + amount)
	for i in mult.keys():
		var comparison = mult[i].y
		
		if vigilance <= comparison:
			behavior = i
			break
	update_indicators()

func update_indicators() -> void:
	vigilance_ind.text = str(ceili(vigilance))
	life_force_ind.text = str(ceili(life_force))

func move_towards(target_pos: Vector2) -> void:
	var dis := global_position.distance_to(target_pos)
	var dir := global_position.direction_to(target_pos)
	
	var arrival_mult = clamp(dis / 100.0, 0, 1.0)
	
	check.target_position = to_local(target_pos)
	var tar_vel = dir * move_speed * spd_mult * arrival_mult
	velocity = velocity.lerp(tar_vel, 0.1)
	sprite.flip_h = dir.x < 0

func receive_charm(amount: float) -> void:
	reduc_rate = amount * mult[behavior].x * 2
	if amount > 0:
		tick_rate.start()
	else:
		tick_rate.stop()

func initiate_chase(body: Node2D) -> void:
	target = body
	
	var top = state_machine.current().state_name
	match top:
		"chase":
			state_machine.current().start()
		"struggle", "flee", "husk":
			return
		_:
			state_machine.change("chase")

func flee_from(body: Node2D) -> void:
	if body == self: return
	offender = body
	var top = state_machine.current()
	if not top: return
	
	# check if already fleeing
	match top.state_name:
		"flee": top.begin()
		"husk", "struggle": return
		_:
			state_machine.clear()
			state_machine.change("flee")

func reduce_vigilance() -> void:
	modify_vigilance(-(2 * reduc_rate))

func _finish_idling() -> void:
	match behavior:
		var n when n <= Behavior.DULLED:
			if target == null : return
			if detection.overlaps_body(target) and not comfort.overlaps_body(target):
				state_machine.change("chase")
				return
		
	state_machine.change("wander")

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		match behavior:
			Behavior.TERRIFIED: flee_from(body)
			var n when n <= Behavior.DULLED: initiate_chase(body)

func _on_comfort_body_exited(body: Node2D) -> void:
	if body is Player:
		match behavior:
			var n when n <= Behavior.DULLED: initiate_chase(body)
