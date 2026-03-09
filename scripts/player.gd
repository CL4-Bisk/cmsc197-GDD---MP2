extends CharacterBody2D
class_name Player

const SPEED: float = 250.0

signal start_game
signal player_out
signal player_levelup(level: int)
signal health_changed

@export_category("Player Values")
@export var health_max := 100
@export var stamina_max := 100
@export var power_base := 25

var screensize := Vector2.ZERO
var health : int
var is_alive := true
var level := 0
var xp := 0
var xp_per_level := 10
var power := 10

var player_condition : PlayerStatus
enum PlayerStatus {
	IDLE,
	NORMAL,
	EXPLOITED,
	DEAD
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var health_timer: Timer = $Health
@onready var stamina_timer: Timer = $Stamina
@onready var exp_timer: Timer = $Exp
@onready var eat_area: Area2D = $EatArea

func _ready() -> void:
	eat_area.body_entered.connect(_on_eat_area_body_entered)
	exp_timer.timeout.connect(gain_exp)
	health_timer.timeout.connect(func(): health = clamp(health + 0.3, 0, health_max))
	reset()

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	
	var mouse_pos := get_global_mouse_position()
	dir = (mouse_pos - global_position)
	if dir.length() > 10.0:
		velocity = dir.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
	
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	move_and_slide()
	_clamp_to_screen()

func _clamp_to_screen() -> void:
	var vp := get_viewport_rect()
	global_position.x = clamp(global_position.x, 0, vp.size.x)
	global_position.y = clamp(global_position.y, 0, vp.size.y)

func _on_eat_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("npc"):
		var npc := body as NPC
#		continuation


func can_move() -> void:
	if !is_alive: return
	player_condition = PlayerStatus.NORMAL

func reset() -> void:
	player_condition = PlayerStatus.IDLE
	collision_layer = 1
	collision_mask = 2
	
	level = 1
	xp = 0
	xp_per_level = 10
	health_max = 100
	health = health_max
	power = power_base
	
	is_alive = true
	velocity = Vector2.ZERO
	position = screensize/2
	sprite.play("idle")
	hitbox.call_deferred("set_disabled", false)

func gain_exp() -> void:
	xp += 1
	if xp >= xp_per_level:
		level = min(level + 1, 15)
		xp = 0
		xp_per_level += (5 * level)
		player_levelup.emit(level)
		exp_timer.start()
		health_max += 10
		health += 10
		power += 10
	if level >= 15: 
		exp_timer.stop()

func damage(value : float) -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.DIM_GRAY, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	health = clamp(health - value, 0, health_max)
	health_changed.emit(health, health_max)
	
	if health <= 0:
		stop()

func stop() -> void:
	if !is_alive : return
	player_condition = PlayerStatus.DEAD
	is_alive = false
	health = 0
	exp_timer.stop()
	health_timer.stop()
	#anim.play("die")
	
	velocity = Vector2.ZERO
	#bird_ded.emit() 
	#await anim.animation_finished
	#anim.play("dead")
	get_tree().create_tween().kill()

func _on_exit() -> void:
	stop()
