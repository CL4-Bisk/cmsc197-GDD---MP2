extends CharacterBody2D
class_name NPC

# prelim
@onready var state_machine: StateMachine = $StateMachine
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var nav2d: NavigationAgent2D = $Nav2D
@onready var tick_rate: Timer = $TickRate

# detectors
@onready var detection: Area2D = $Detection
@onready var d_zone: CollisionShape2D = $Detection/Zone
@onready var comfort: Area2D = $Comfort
@onready var c_zone: CollisionShape2D = $Comfort/Zone
@onready var sensitive: Area2D = $Sensitive
@onready var sight: Area2D = $Sight
@onready var sighting: CollisionPolygon2D = $Sight/Sighting
@onready var check: RayCast2D = $Check
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

@export_category("NPC Parameters")
@export var move_speed : float = 50.0
@export var max_lifeforce : float = 5.0
@export var npc_level : int = 1
@export var wait_time : float = 4.0
@export var exit_chance : float = 0.1
@export var behavior : Behavior = Behavior.SOBER
enum Behavior {
	CHARMED,	# reduction amount is havled
	DULLED,		# 1/3
	SOBER,		# 1/4
	ALERT,		# 1/5
	ALARMED,	# 1/10
	TERRIFIED,	# 1/20
	DRAINED, 
}
@export var behavior_range : Dictionary[Behavior, Vector2] = {
	Behavior.CHARMED: Vector2(-1, 0),
	Behavior.DULLED: Vector2(1, 15),
	Behavior.SOBER: Vector2(15, 40),
	Behavior.ALERT: Vector2(40, 70),
	Behavior.ALARMED: Vector2(70, 99),
	Behavior.TERRIFIED: Vector2(99, 100),
}
@export var behavior_drain : Dictionary[Behavior, float] = {
	Behavior.CHARMED: 2, 
	Behavior.DULLED: 1,
	Behavior.SOBER: 1.0/2,
	Behavior.ALERT: 1.0/5,
	Behavior.ALARMED: 1.0/10,
	Behavior.TERRIFIED: 1.0/25,
}

@export var audio_scenes : Dictionary[int, AudioStream] = {
	0: preload("res://assets/audio/Man screaming - Sound effect.mp3"),
	1: preload("res://assets/audio/Man Screaming in Pain Sound Effect (HD) #meme #memes #dankmemes #soundeffects.mp3"),
	2: preload("res://assets/audio/Man screaming sound effect  what is sound_  scream 1.mp3")
}

# dynamic
var _spd : float
var _charm_rate : float = 0.0
var vigilance : float = 0.0
var spd_mult : float = 1.0
var drain_rate : float = 0.0
var lifeforce : float
var stage : Stage
var offender : Node2D
var target : Node2D

func _init() -> void:
	# randomly set a vigilance value based on starting behavior
	var ran = behavior_range.get(behavior)
	lifeforce = max_lifeforce
	vigilance = randf_range(ran.x, ran.y)

func _ready() -> void:
	nav2d.hide()
	modify_vigilance(0)
	state_machine.handler = self
	state_machine.register_state(&"idle", NPCStates.Idle)
	state_machine.register_state(&"wander", NPCStates.Wander)
	state_machine.register_state(&"threat", NPCStates.Flee)
	state_machine.register_state(&"struggle", NPCStates.Struggle)
	state_machine.register_state(&"follow", NPCStates.Chase)
	state_machine.register_state(&"husk", NPCStates.Husk)
	state_machine.register_state(&"enter", NPCStates.Enter)
	state_machine.register_state(&"exit", NPCStates.Exit)

func start_state(state_name: StringName = &"") -> void:
	state_machine.change(&"idle")
	if state_name != &"":
		state_machine.change(state_name)
	state_machine._process_pending()

func play_scream_sound() -> void:
	var x = randi_range(0, 2)
	var stream_to_play = audio_scenes.get(x)
	
	print("Trying to play sound ID: ", x)
	
	if audio == null:
		print("ERROR: AudioStreamPlayer node not found!")
		return
		
	if stream_to_play:
		audio.stream = stream_to_play
		audio.play()
		print("Audio node 'playing' status: ", audio.playing)
	else:
		print("ERROR: Stream not found in dictionary for ID: ", x)

func _process(_delta):
	if lifeforce <= 0 and audio.playing:
		audio.stop() # Stops the loop immediately when they die

func _physics_process(_delta: float) -> void:
	#print(state_machine.stack.map(func(x): return x.state_name))
	update_indicators()
	navigate()
	move_and_slide()
	if velocity.length() != 0: sprite.flip_h = velocity.x < 0
	if state_machine.current() and state_machine.current().state_name == "struggle": return

func navigate() -> void:
	var target_vel = Vector2.ZERO
	if not nav2d.is_navigation_finished():
		var next_path_pos = nav2d.get_next_path_position()
		
		check.target_position = to_local(next_path_pos)
		
		var dis := global_position.distance_to(nav2d.target_position)
		var dir := global_position.direction_to(next_path_pos)
		
		var arrival_mult = clamp(dis / 100.0, 0, 1.0)
		
		target_vel = dir * _spd * spd_mult * arrival_mult
		sight.look_at(next_path_pos)
		
	check.force_raycast_update()
	if sight.has_overlapping_bodies(): nav2d.set_velocity(target_vel)
	else: velocity = velocity.lerp(target_vel, 0.1)

func _on_nav_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if state_machine.current() == null: return
	if not sight.has_overlapping_bodies(): return
	if state_machine.current().state_name != &"idle":
		velocity = velocity.lerp(safe_velocity, 0.1)

func toggle_zones(enabled: bool, ... zones: Array) -> void:
	for z in zones:
		if z is not Area2D: continue
		z.monitoring = enabled

func _is_path_clear(destination: Vector2) -> bool:
	check.target_position = destination
	check.force_raycast_update()
	return not check.is_colliding()

func set_spd(amount: float) -> void:
	_spd = amount

func pick_destination(
	attempts: int, max_distance: float, min_distance: float = 0.0,
	target_pos: Vector2 = Vector2.ZERO, flee: bool = true) -> Vector2:
	
	# randomly set move speed to destination
	set_spd(move_speed * randf_range(0.9, 1.1))
	var angle : float = randf() * TAU
	
	if target_pos and attempts > 0:
		var dir = (target_pos - global_position).angle()
		if flee: dir += PI
		angle = dir + randf_range(-PI/4, PI/4)
	var distance = ((max_distance - min_distance) * sqrt(randf())) + min_distance
	var offset = Vector2.from_angle(angle) * distance
	var final_pos = global_position + offset
	
	var map = get_world_2d().navigation_map
	var closest = NavigationServer2D.map_get_closest_point(map, final_pos)
	
	if _is_path_clear(closest - global_position): return closest
	else: return pick_destination(attempts-1, 
			max_distance, min_distance, target_pos, flee)

func update_indicators() -> void:
	$Lifeforce.value = lifeforce
	$Lifeforce.max_value = max_lifeforce
	$Lifeforce/Value.text = str(snappedf(lifeforce, 0.1))
	$Vigilance.value = vigilance
	$Vigilance.max_value = 100
	$Vigilance/Value.text = str(ceili(vigilance))
	
	#if stage.player.level < npc_level: $LifeForceInd.modulate = Color.RED
	#else: $LifeForceInd.modulate = Color.GREEN

func modify_vigilance(amount: float) -> void:
	vigilance = clamp(vigilance + amount, 0, 100)
	if lifeforce == 0: 
		behavior = Behavior.DRAINED
		return
		
	for i in behavior_range:
		var comparison = behavior_range.get(i)
		if vigilance > comparison.x and vigilance <= comparison.y:
			drain_rate = behavior_drain.get(behavior)
			behavior = i
			return

func receive_charm(amount: float = 0.0) -> void:
	if amount > 0.0:
		_charm_rate = amount
		tick_rate.start()
	else: tick_rate.stop()

func _reduce_vigilance() -> void: modify_vigilance(-_charm_rate)

func _on_detection_body_entered(body: Node2D) -> void:
	if body == self: return
	var current_state = state_machine.current()
	if body is Player:
		match behavior:
			Behavior.TERRIFIED: state_machine.change(&"exit")
			Behavior.ALARMED:
				if current_state.has_method(&"threat_detected"):
					current_state.threat_detected(body)
			var n when n <= Behavior.DULLED: 
				if current_state.has_method(&"interest_detected"):
					current_state.interest_detected(body)

func _on_comfort_body_exited(body: Node2D) -> void:
	if body == self: return
	var current_state = state_machine.current()
	
	if body is Player:
		match behavior:
			Behavior.ALARMED:
				if current_state.has_method(&"threat_detected"):
					current_state.threat_detected(body)
			var n when n <= Behavior.DULLED: 
				if current_state.has_method(&"interest_detected"):
					current_state.interest_detected(body)

func _on_sensitive_body_entered(body: Node2D) -> void:
	if body == self: return
	var current_state = state_machine.current()
	if current_state.has_method(&"threat_detected"):
		current_state.threat_detected(body)
