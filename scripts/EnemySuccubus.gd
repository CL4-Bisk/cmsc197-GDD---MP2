class_name EnemySuccubus
extends CharacterBody2D

enum RivalState{
	ROAM,
	LURING,
	ESCORTING,
	CONSUMING,
	STEALING,
	DEFEATED
}

@export var power: float = 12.0
@export var speed: float = 130.0
@export var charm_strength: float = 0.8
@export var territory_radius: float = 200.0

var state: RivalState = RivalState.ROAM
var current_target: Node2D = null     # prey being pursued
var player: Node2D = null

@onready var aura: Area2D = $RivalAura
@onready var territory: Area2D = $TerritoryArea   # zone control circle
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy_succubus")
	player = get_tree().get_first_node_in_group("player")
	aura.body_entered.connect(_on_aura_body_entered)

func _physics_process(delta: float) -> void:
	match state:
		RivalState.ROAM:
			_do_roam(delta)
		RivalState.LURING:
			_do_lure(delta)
		RivalState.ESCORTING:
			_do_escort(delta)
		RivalState.CONSUMING:
			pass
		RivalState.STEALING:
			_do_steal(delta)
	
	move_and_slide()

func _do_roam(_delta: float) -> void:
	# Seek nearest unclaimed prey
	var prey_list := get_tree().get_nodes_in_group("prey")
	var best: Node2D = null
	var best_dist := INF

	for p in prey_list:
		if not is_instance_valid(p):
			continue
		if p.enemy_succubus_ref != null:
			continue  # already claimed
		
		var d := global_position.distance_to(p.global_position)
		if d < best_dist:
			best_dist = d; best = p
	
	if best:
		current_target = best
		state = RivalState.LURING

func _do_lure(delta: float) -> void:
	if not is_instance_valid(current_target):
		state = RivalState.ROAM; return
	_move_toward_target(current_target.global_position)
	# Seduce the prey
	current_target.seduction_meter += charm_strength * 0.3 * delta
	if current_target.seduction_meter >= 1.0:
		current_target.claim_by_rival(self)
		state = RivalState.ESCORTING

func _do_escort(_delta: float) -> void:
	if not is_instance_valid(current_target):
		state = RivalState.ROAM
		return
	# Lead prey toward nearest secluded zone
	var zone := _find_nearest_secluded_zone()
	if zone:
		_move_toward_target(zone.global_position)
	else:
		_move_toward_target(global_position + Vector2(randf_range(-200,200), randf_range(-200,200)))

func _do_steal(_delta: float) -> void:
	# Move toward player's charmed prey and poach it
	var player_prey := _get_player_following_prey()
	if player_prey:
		current_target = player_prey
		_move_toward_target(current_target.global_position)
		var dist := global_position.distance_to(current_target.global_position)
		if dist < 40.0:
			current_target.claim_by_rival(self)
			state = RivalState.ESCORTING
	else:
		state = RivalState.ROAM

func _on_aura_body_entered(body: Node2D) -> void:
	# Detect if player's charmed prey is nearby — initiate steal
	if body.is_in_group("prey") and body.state == body.State.FOLLOWING:
		if body.enemy_succubus_ref == null:  # prey is following player
			state = RivalState.STEALING

func get_defeated_by_player() -> void:
	state = RivalState.DEFEATED
	# Release any prey being escorted
	if is_instance_valid(current_target):
		current_target.enemy_succubus_ref = null
		current_target.state = current_target.State.FLEEING
	GameData.defeat_rival(self)
	anim_defeat()

func anim_defeat() -> void:
	# Play defeat animation then remove
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _move_toward_target(target: Vector2) -> void:
	var dir := (target - global_position).normalized()
	velocity = dir * speed
	sprite.flip_h = velocity.x < 0

func _find_nearest_secluded_zone() -> Node2D:
	var zones := get_tree().get_nodes_in_group("secluded_zone")
	var best: Node2D = null
	var best_d := INF
	for z in zones:
		var d := global_position.distance_to(z.global_position)
		if d < best_d: best_d = d; best = z
	return best

func _get_player_following_prey() -> Node2D:
	var prey_list := get_tree().get_nodes_in_group("prey")
	for p in prey_list:
		if p.state == p.State.FOLLOWING and p.enemy_succubus_ref == null:
			return p
	return null
