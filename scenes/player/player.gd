extends CharacterBody2D
class_name Succubus

@onready var state_machine: GameStateMachine = $StateMachine
@onready var charm_zone: CollisionShape2D = $CharmZone/Zone
@onready var feed_zone: Area2D = $FeedZone

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: CollisionShape2D = $HitBox

@export var move_speed : float = 250.0
@export var charm_power : float = 1.0
@export var charm_zone_growth_spd : float = 50.0

@export var life_force : float = 40.0
@export var total_life_force : float = 40.0

var is_mouse_inside : bool = false
var spd_mult : float = 1.0

func _ready() -> void:
	state_machine.handler = self
	
	state_machine.register_state("normal", SucccubiStates.Normal)
	state_machine.register_state("charm", SucccubiStates.Charming)
	state_machine.register_state("feed", SucccubiStates.Feeding)
	state_machine.register_state("lust", SucccubiStates.Lustful)
	state_machine.register_state("dead", SucccubiStates.Subjugated)
	
	state_machine.change("normal")
	state_machine._process_pending()

func _physics_process(_delta: float) -> void:
	match state_machine.current().state_name:
		"feed", "dead":
			velocity = Vector2.ZERO
		_:
			move_to_mouse()
	(charm_zone.shape as CircleShape2D).radius = life_force
	move_and_slide()
	animate_me()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("feed") and \
	state_machine.current().state_name != "feed" and \
	feed_zone.has_overlapping_bodies():
		state_machine.change("feed")

func move_to_mouse() -> void:
	if state_machine.current() is SucccubiStates.Feeding: return
	var mouse_pos = get_global_mouse_position()
	var dir = global_position.direction_to(mouse_pos)
	sprite.flip_h = dir.x < 0
	if not is_mouse_inside: 
		velocity = dir * move_speed * spd_mult
	else:
		velocity = Vector2.ZERO

func find_nearest() -> Node2D:
	var bodies := feed_zone.get_overlapping_bodies()
	var nearest : Node2D = null
	var min_dis = INF
	
	for body in bodies:
		if not body.is_in_group("npc") and body == self: continue
		
		var distance = global_position.distance_to(body.global_position)
		if distance < min_dis:
			min_dis = distance
			nearest = body
		
	return nearest

func mouse_detect(toggle: bool) -> void:
	is_mouse_inside = toggle

func animate_me() -> void:
	match state_machine.current().state_name:
		"feed":
			anim.play("feed")
		_:
			if velocity.length() > 0:
				anim.play("run")
			else:
				anim.play("idle")

func _on_charm(body: Node2D, entered: bool) -> void:
	if body is NPC:
		var npc = (body as NPC)
		npc.receive_charm(charm_power if entered else 0.0)
