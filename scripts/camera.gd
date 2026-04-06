extends Camera2D
class_name Camera

@export var target: Node2D
@export var max_distance: float = 100.0
var zoom_distance : float

func _init() -> void:
	zoom_distance = max_distance

func _process(delta: float) -> void:
	if target:
		var mouse_pos = get_global_mouse_position()
		var target_pos = (target.global_position + mouse_pos) / 2.0
		
		
		var distance = target.global_position.distance_to(target_pos)
		if distance > zoom_distance:
			target_pos = target.global_position + (target_pos - target.global_position).normalized() * zoom_distance
		
		global_position = global_position.lerp(target_pos, position_smoothing_speed * delta)
