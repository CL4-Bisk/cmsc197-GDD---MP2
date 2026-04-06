extends Control

@onready var level_label : Label = $Level
@onready var xp_bar     : ProgressBar = $EXP
@onready var xp_label   : Label = $EXPlabel   # optional

# Called by the player (or any autoload) whenever XP/level changes
func update_player_ui(exp: int, lvl: int) -> void:
	level_label.text = "Lv. %d" % lvl
	xp_label.text = "XP: %d" % exp

	var xp_needed = max(1, $Player._get_xp_for_next_level())
	xp_bar.max_value = xp_needed
	xp_bar.value = exp % xp_needed

func play_level_up() -> void:
	$LevelUpLabel.visible = true
	$LevelUpLabel.modulate = Color.YELLOW
	$LevelUpLabel.text = "LEVEL UP!"
	$LevelUpLabel.set_process_callback(func(_delta):
		$LevelUpLabel.modulate = Color(Color(1,1,1,1) - _delta)
		if $LevelUpLabel.modulate.a <= 0:
			$LevelUpLabel.visible = false
			$LevelUpLabel.set_process_callback(null)
)
