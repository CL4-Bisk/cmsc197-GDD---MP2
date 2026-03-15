extends Node
class_name Ability

signal dialogue_started(prey: Node)
signal dialogue_ended(prey: Node, success: bool)

@export var dark_zone_scene: PackedScene

var aura_active: bool = true                  # always on, handled by Player aura Area2D
var cast_cooldown: float = 0.0
var trap_cooldown: float = 0.0
const CAST_CD: float = 5.0
const TRAP_CD: float = 12.0

var dialogue_target: Node = null
var dialogue_timer: float = 0.0
const DIALOGUE_DURATION: float = 3.0        # hold near prey to complete

var player: Node2D

func _ready() -> void:
	player = get_parent()

func _process(delta: float) -> void:
	cast_cooldown = maxf(cast_cooldown - delta, 0.0)
	trap_cooldown = maxf(trap_cooldown - delta, 0.0)
	_update_dialogue(delta)

func on_prey_entered_aura(prey: Node) -> void:
	if prey.has_method("notice_player"):
		prey.notice_player()

func on_prey_in_aura_tick(prey: Node, delta: float) -> void:
	# Called each frame from Player for bodies inside aura
	if prey.state == prey.State.NOTICED or prey.state == prey.State.SEDUCED:
		prey.begin_seduction(player)

func cast_charm(targets: Array) -> void:
	if cast_cooldown > 0.0:
		return
	cast_cooldown = CAST_CD
	for prey in targets:
		if prey.is_in_group("prey"):
			prey.seduction_meter += 0.4 * GameData.seduction_strength
			if prey.seduction_meter >= 1.0:
				prey._become_charmed()

func place_dark_zone_trap(position: Vector2) -> void:
	if trap_cooldown > 0.0 or not dark_zone_scene:
		return
	trap_cooldown = TRAP_CD
	var trap := dark_zone_scene.instantiate()
	trap.global_position = position
	player.get_parent().add_child(trap)

func start_dialogue(prey: Node) -> void:
	if dialogue_target != null:
		return
	dialogue_target = prey
	dialogue_timer = 0.0
	dialogue_started.emit(prey)

func _update_dialogue(delta: float) -> void:
	if dialogue_target == null:
		return
	var dist := player.global_position.distance_to(dialogue_target.global_position)
	if dist > 80.0:
		# Player moved away — cancel
		dialogue_ended.emit(dialogue_target, false)
		dialogue_target = null
		return
	dialogue_timer += delta * GameData.seduction_strength
	dialogue_target.seduction_meter = minf(dialogue_timer / DIALOGUE_DURATION, 1.0)
	if dialogue_timer >= DIALOGUE_DURATION:
		dialogue_target._become_charmed()
		dialogue_ended.emit(dialogue_target, true)
		dialogue_target = null
