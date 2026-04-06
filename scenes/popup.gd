extends Label
class_name PopupText

signal finished
@export var duration : float = 0.2
@export var travel : float = 20.0

func _ready() -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "global_position:y", global_position.y - travel, duration)
	t.tween_property(self, "modulate:a", 0, duration)
	finished.emit()
