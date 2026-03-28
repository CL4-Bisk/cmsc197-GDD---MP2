extends RefCounted
class_name NPCStates

class Idle extends GameState:
	var handler : NPC
	func _init() -> void: state_name = "idle"
	
	func begin() -> String:
		handler.state_machine.refresh()
		
		handler.sensitive.set_collision_mask_value(3, true)
		handler.anim.play("idle")
		handler.idle_timer.start(handler.wait_time + randf_range(-2, 2))
		return ""
	
	func update(_delta: float) -> String:
		handler.velocity = handler.velocity.lerp(Vector2.ZERO, 0.1)
		return ""
	
	func end() -> String:
		handler.idle_timer.stop()
		return ""

class Wander extends GameState:
	var handler : NPC
	var destination : Vector2
	func _init() -> void: state_name = "wander"
	
	func begin() -> String:
		handler.sensitive.set_collision_mask_value(3, false)
		
		var o = handler.wander_zone.shape.radius * handler.scale.x
		destination = handler.pick_destination(10, o)
		return ""
	
	func update(_delta: float) -> String:
		if handler.global_position.distance_to(destination) < 30: return "pop"
		handler.move_towards(destination)
		return ""

class Flee extends GameState:
	var handler : NPC
	var destination : Vector2
	func _init() -> void:
		state_name = "flee"
	
	func _find_safe_point() -> Vector2:
		var o = handler.wander_zone.shape.radius * handler.scale.x
		var i = handler.c_zone.shape.radius * handler.scale.x
		var t = handler.offender.global_position
		
		for a in range(50):
			var potential_destination = handler.pick_destination(10, o, i, t)
			
			var is_safe = not Geometry2D.is_point_in_circle(t, potential_destination, i)
			
			if is_safe: return potential_destination
		return handler.global_position + (handler.global_position - t)
	
	func begin() -> String:
		handler.state_machine.refresh()
		handler.toggle_zones(false, handler.comfort)
		handler.spd_mult = 1.5
		handler.sensitive.set_collision_mask_value(3, false)
		if handler.offender is Player: handler.modify_vigilance(2.5)
		destination = _find_safe_point()
		return ""
	
	func update(_delta: float) -> String:
		if handler.global_position.distance_to(destination) < 50: return "pop"
		handler.move_towards(destination)
		return ""
	
	func finish() -> void:
		handler.spd_mult = 1.0
		handler.toggle_zones(true, handler.comfort)
		if handler.sensitive.overlaps_body(handler.offender): handler.flee_from(handler.offender)
		if handler.state_machine.stack.is_empty(): handler.state_machine.change("idle")

class Chase extends GameState:
	var handler : NPC
	var destination : Vector2
	func _init() -> void: state_name = "chase"
	
	func _find_approachable_distance() -> Vector2:
		var o = handler.c_zone.shape.radius * handler.scale.x
		var t = handler.target.global_position
		
		for a in range(50):
			var potential_destination = handler.pick_destination(10, o, 0, t, false)
			var in_range = Geometry2D.is_point_in_circle(t, potential_destination, o)
			if in_range: return potential_destination
		return handler.global_position + (handler.target.global_position - handler.global_position)
	
	func start() -> String:
		handler.state_machine.refresh()
		destination = _find_approachable_distance()
		return ""
	
	func update(_delta: float) -> String:
		if handler.global_position.distance_to(destination) < 50: return "pop"
		if handler.behavior == NPC.Behavior.CHARMED: destination = handler.target.global_position
		handler.move_towards(destination)
		return ""
	
	func finish() -> void:
		if handler.state_machine.stack.is_empty(): handler.state_machine.change("idle")

class Struggle extends GameState:
	var handler : NPC
	var destination : Vector2
	func _init() -> void: state_name = "struggle"
	
	func _distance() -> Vector2:
		var radius = handler.c_zone.shape.radius * handler.scale.x
		return handler.pick_destination(10, radius)
	
	func start() -> String:
		handler.toggle_zones(false, handler.sensitive)
		handler.spd_mult = 0.75
		handler.anim.play("struggle")
		destination = _distance()
		handler.set_collision_mask_value(1, false)
		return ""
	
	func update(delta: float) -> String:
		if handler.global_position.distance_to(destination) < 50: destination = _distance()
		handler.life_force -= handler.reduc_rate * delta
		handler.update_indicators()
		if handler.life_force <= 0:
			handler.state_machine.refresh()
			return "husk"
		
		handler.move_towards(destination)
		return ""
	
	func finish() -> void:
		handler.spd_mult = 1.0
		handler.toggle_zones(true, handler.sensitive)

class Husk extends GameState:
	var handler : NPC
	func _init() -> void: state_name = "husk"
	
	func begin() -> String:
		handler.spd_mult = 0.5
		handler.state_machine.refresh()
		handler.toggle_zones(false, handler.sensitive, handler.comfort, handler.detection)
		
		handler.velocity = Vector2.ZERO
		handler.modulate.a = 0.5
		handler.set_collision_layer_value(3, false)
		return ""
		
