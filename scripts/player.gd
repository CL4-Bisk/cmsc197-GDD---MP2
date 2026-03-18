extends CharacterBody2D

const BASE_SPEED: float = 250.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var charm_aura: Area2D = $CharmAura
@onready var charm_shape: CollisionShape2D = $CharmAura/CollisionShape2D
@onready var lure: Ability = $Ability
@onready var anim: AnimationPlayer = $AnimationPlayer

var aura_bodies: Array = []   # prey currently inside aura

func _ready() -> void:
	add_to_group("player")
	charm_aura.body_entered.connect(_on_aura_entered)
	charm_aura.body_exited.connect(_on_aura_exited)
	GameData.power_changed.connect(_on_power_changed)
	GameData.level_changed.connect(_on_level_up)
	_update_aura_radius()

func _physics_process(delta: float) -> void:
	_handle_movement()
	_tick_aura(delta)
	_handle_input()

func _handle_movement() -> void:
	var mouse := get_global_mouse_position()
	var dir := mouse - global_position
	if dir.length() > 8.0:
		velocity = dir.normalized() * BASE_SPEED
		sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	var vp := get_viewport_rect()
	global_position = global_position.clamp(Vector2.ZERO, vp.size)

func _tick_aura(delta: float) -> void:
	for body in aura_bodies:
		if is_instance_valid(body) and body.is_in_group("prey"):
			lure.on_prey_in_aura_tick(body, delta)

func _handle_input() -> void:
	# Q → Cast Charm
	if Input.is_action_just_pressed("cast_charm"):
		lure.cast_charm(aura_bodies)
	# Right-click → Place dark zone trap at mouse pos
	if Input.is_action_just_pressed("place_trap"):
		lure.place_dark_zone_trap(get_global_mouse_position())
	# E near prey → start dialogue
	if Input.is_action_just_pressed("interact"):
		var closest := _get_closest_prey(100.0)
		if closest:
			lure.start_dialogue(closest)

func _on_aura_entered(body: Node2D) -> void:
	if body.is_in_group("prey"):
		aura_bodies.append(body)
		lure.on_prey_entered_aura(body)
	elif body.is_in_group("enemy_succubus"):
		_check_rivalry_collision(body)

func _on_aura_exited(body: Node2D) -> void:
	aura_bodies.erase(body)

func _check_rivalry_collision(enemy: Node2D) -> void:
	if GameData.power > enemy.power:
		enemy.get_defeated_by_player()
	else:
		# Player is weaker — pushed back
		var knockback := (global_position - enemy.global_position).normalized() * 300
		velocity += knockback

func _on_power_changed(p: float) -> void:
	_update_aura_radius()

func _on_level_up(l: int) -> void:
	anim.play("level_up")

func _update_aura_radius() -> void:
	if charm_shape.shape is CircleShape2D:
		charm_shape.shape.radius = GameData.charm_radius

func _get_closest_prey(max_dist: float) -> Node2D:
	var closest: Node2D = null
	var best := max_dist
	for body in aura_bodies:
		if not is_instance_valid(body) or not body.is_in_group("prey"):
			continue
		var d := global_position.distance_to(body.global_position)
		if d < best:
			best = d; closest = body
	return closest
