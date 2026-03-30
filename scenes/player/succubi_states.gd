extends RefCounted
class_name SucccubiStates

class Normal extends GameState:
	var handler : Player
	
	func _init() -> void:
		state_name = &"normal"
	
	func begin() -> String:
		handler.spd_mult = 1.0
		return ""
	
	func update(_delta: float) -> String:
		if Input.is_action_just_pressed(&"charm"):
			return &"charm"
		return ""

class Charming extends GameState:
	var handler : Player
	var t : Tween
	
	func _init() -> void:
		state_name = &"charm"
	
	func begin() -> String:
		handler.spd_mult = 0.5
		handler.charm_zone.set_deferred("disabled", false)
		
		var s = (handler.charm_zone.shape as CircleShape2D)
		var duration = handler.total_life_force / handler.charm_zone_growth_spd
		s.radius = 0.0
		t = handler.get_tree().create_tween()
		t.tween_property(s, "radius", handler.total_life_force, duration).set_trans(Tween.TRANS_LINEAR)
		return ""
	
	func update(_delta: float) -> String:
		if Input.is_action_just_released(&"charm"):
			return &"pop"
		return ""
	
	func finish() -> void:
		handler.charm_zone.set_deferred("disabled", true)
		if t and t.is_running(): t.kill()
		(handler.charm_zone.shape as CircleShape2D).radius = handler.total_life_force

class Feeding extends GameState:
	var handler : Player
	var feeding_target : NPC
	var t: Tween
	
	func _init() -> void:
		state_name = &"feed"
	
	func start() -> String:
		handler.anim.play(&"feed")
		handler.state_machine.refresh()
		handler.spd_mult = 0
		handler.hit_box.set_deferred(&"disabled", true)
		
		var x = handler.find_nearest()
		if x:
			feeding_target = x
			
			feeding_target.offender = handler
			
			t = handler.create_tween()
			t.tween_property(handler, "global_position", feeding_target.global_position, 0.1)
		
			feeding_target.reduc_rate = handler.charm_power
			feeding_target.state_machine.change(&"flee")
			feeding_target.state_machine.change(&"struggle")
		return ""
	
	func begin() -> String:
		if feeding_target: return ""
		return &"repeat"
		
	func update(delta: float) -> String:
		handler.total_life_force += feeding_target.reduc_rate * delta
		handler.life_force += feeding_target.reduc_rate * delta
		
		if Input.is_action_just_pressed(&"feed"): 
			feeding_target.state_machine.back()
			return &"pop"
		if feeding_target.life_force <= 0: return &"pop"
		if t and t.is_running(): return ""
		handler.global_position = feeding_target.global_position
		return ""
	
	func finish() -> void:
		handler.state_machine.change(&"normal")
		handler.hit_box.set_deferred("disabled", false)

class Lustful extends GameState:
	var handler : Player
	
	func _init() -> void:
		state_name = &"lust"
	
	func start() -> String:
			handler.spd_mult = 2.0
			return ""

class Subjugated extends GameState:
	var handler : Player
	
	func _init() -> void:
		state_name = &"dead"
	
	func start() -> String:
		handler.spd_mult = 1.0
		return ""
