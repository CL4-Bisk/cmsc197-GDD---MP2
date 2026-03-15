extends Node

signal power_changed(new_power: float)
signal level_changed(new_level: int)
signal score_changed(new_score: int)
signal prey_consumed(prey_type: String)
signal rival_defeated(enemy: Node)
signal game_over

var power: float = 10.0          # dominance stat — replaces fish size
var level: int = 1
var score: int = 0
var charm_radius: float = 120.0  # grows with level
var seduction_strength: float = 1.0  # affects how fast seduction meter fills

const POWER_PER_PREY: float = 1.5
const POWER_PER_RIVAL: float = 8.0
const LEVEL_POWER_THRESHOLDS: Array[float] = [0, 15, 35, 65, 110, 180]

func add_power(amount: float) -> void:
	power += amount
	power_changed.emit(power)
	_check_level_up()

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func consume_prey(prey_type: String) -> void:
	prey_consumed.emit(prey_type)
	match prey_type:
		"civilian": add_power(POWER_PER_PREY);      add_score(100)
		"guarded":  add_power(POWER_PER_PREY * 1.5); add_score(250)
		"rival_prey": add_power(POWER_PER_PREY * 2); add_score(400)

func defeat_rival(enemy: Node) -> void:
	rival_defeated.emit(enemy)
	add_power(POWER_PER_RIVAL)
	add_score(1000)

func _check_level_up() -> void:
	var next_idx := mini(level, LEVEL_POWER_THRESHOLDS.size() - 1)
	if power >= LEVEL_POWER_THRESHOLDS[next_idx]:
		level += 1
		charm_radius += 20.0
		seduction_strength += 0.25
		level_changed.emit(level)

func reset() -> void:
	power = 10.0
	level = 1
	score = 0
	charm_radius = 120.0
	seduction_strength = 1.0
