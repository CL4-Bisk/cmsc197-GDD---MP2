extends RefCounted
class_name NPCStates

class Idle extends GameState:
	var handler : NPC
	
	func _init() -> void:
		state_name = "idle"
	
	func begin() -> String:
		handler.state_machine.refresh()
		
		handler.sensitive.set_collision_mask_value(3, true)
		handler.anim.play("idle")
		handler.idle_timer.start(handler.wait_time + randf_range(-2, 2))
		
		handler.path.clear_points()
		handler.velocity = Vector2.ZERO
		
		return ""
	
	func end() -> String:
		handler.idle_timer.stop()
		return ""

class Wander extends GameState:
	var handler : NPC
	var destination : Vector2
	
	func _init() -> void:
		state_name = "wander"
	
	func begin() -> String:
		handler.sensitive.set_collision_mask_value(3, false)
		destination = handler.global_position + handler.pick_destination()
		return ""
	
	func update(_delta: float) -> String:
		handler.move_towards(destination)
		if handler.global_position.distance_to(destination) < 30:
			return "pop"
		return ""
	
	func end() -> String:
		return "repeat"

class Flee extends GameState:
	var handler : NPC
	var destination : Vector2
	var zones : Array[Area2D]
	
	func _init() -> void:
		state_name = "flee"
	
	func _find_safe_point() -> Vector2:
		var att = 0
		var radius = handler.c_zone.shape.radius * handler.scale.x
		
		while att < 50:
			var offset = handler.pick_destination(handler.wander_zone.shape.radius, handler.offender.global_position)
			var potential_d = handler.global_position + offset
			
			var is_safe = not Geometry2D.is_point_in_circle(handler.offender.global_position, potential_d, radius)
			
			if is_safe:
				return potential_d
			att += 1
		return handler.global_position + (handler.global_position - handler.offender.global_position)
	
	func start() -> String:
		zones.append(handler.comfort)
		handler.toggle_zones(false, zones)
		handler.spd_mult = 1.5
		return ""
	
	func begin() -> String:
		handler.sensitive.set_collision_mask_value(3, false)
		if handler.offender is Succubus:
			handler.modify_vigilance(2.5)
			handler.update_indicators()
		
		destination = _find_safe_point()
		return ""
	
	func update(_delta: float) -> String:
		handler.move_towards(destination)
		if handler.global_position.distance_to(destination) < 50:
			return "pop"
		return ""
	
	func finish() -> void:
		handler.spd_mult = 1.0
		handler.toggle_zones(true, zones)
		if handler.sensitive.overlaps_body(handler.offender):
			handler.flee_from(handler.offender)
		
		if handler.state_machine.stack.is_empty():
			handler.state_machine.change("idle")

class Chase extends GameState:
	var handler : NPC
	var destination : Vector2

	func _init() -> void:
		state_name = "chase"
	
	func _find_approachable_distance() -> Vector2:
		var att = 0
		var radius = handler.d_zone.shape.radius * handler.scale.x
		
		while att < 40:
			var offset = handler.pick_destination(radius, handler.target.global_position, false)
			var potential_d = handler.global_position + offset
			
			var in_range = Geometry2D.is_point_in_circle(handler.target.global_position, potential_d, handler.c_zone.shape.radius)
			
			if in_range:
				return potential_d
			att += 1
		return handler.global_position + (handler.target.global_position - handler.global_position)
	
	func start() -> String:
		destination = _find_approachable_distance()
		return ""
	
	func update(_delta: float) -> String:
		if handler.global_position.distance_to(destination) < 50:
			return "pop"
		
		match handler.behavior:
			NPC.Behavior.CHARMED: destination = handler.target.global_position
		handler.move_towards(destination)
		
		return ""
	
	func end() -> String:
		handler.path.clear_points()
		handler.velocity = Vector2.ZERO
		return ""

class Struggle extends GameState:
	var handler : NPC
	var destination : Vector2
	
	func _init() -> void:
		state_name = "struggle"
	
	func _distance() -> Vector2:
		var radius = handler.c_zone.shape.radius * handler.scale.x
		var offset = handler.pick_destination(radius)
		return handler.global_position + offset
	
	func start() -> String:
		handler.toggle_zones(false, handler.sensitive)
		handler.spd_mult = 0.75
		
		handler.anim.play("struggle")
		destination = _distance()
		
		handler.set_collision_mask_value(1, false)
		return ""
	
	func update(delta: float) -> String:
		if handler.global_position.distance_to(destination) < 50:
			destination = _distance()
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
	
	func _init() -> void:
		state_name = "husk"
	
	func begin() -> String:
		handler.spd_mult = 0.5
		handler.state_machine.refresh()
		var zones = [handler.sensitive, handler.comfort, handler.detection]
		handler.toggle_zones(false, zones)
		
		handler.velocity = Vector2.ZERO
		handler.modulate.a = 0.5
		handler.set_collision_layer_value(3, false)
		return ""
		
