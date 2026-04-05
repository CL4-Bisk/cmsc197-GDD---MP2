extends GDScript
class_name NPCStates

class Idle extends GameState:
	var handler : NPC
	var timer : SceneTreeTimer
	func _init() -> void: state_name = &"idle"
	
	func threat_detected(body: Node2D) -> void:
		handler.offender = body
		handler.state_machine.change(&"flee")
	
	func interest_detected(body: Node2D) -> void:
		handler.target = body
		handler.state_machine.change(&"chase")
	
	func begin() -> String:
		handler.state_machine.refresh()
		handler.sensitive.set_collision_mask_value(3, true)
		handler.anim.play(&"idle")
		
		handler.nav2d.target_position = handler.global_position
		
		timer = handler.get_tree().create_timer(
			handler.wait_time + randf_range(-2, 2)
		)
		timer.timeout.connect(_idle_finished)
		return ""
	
	func _idle_finished() -> void:
		match handler.behavior:
			var n when n <= NPC.Behavior.DULLED:
				if handler.target != null:
					if handler.detection.overlaps_body(handler.target) and \
					not handler.comfort.overlaps_body(handler.target):
						handler.state_machine.change(&"chase")
						return
		if (randf() < 0.1):
			handler.state_machine.change(&"exit")
			return
		handler.state_machine.change(&"wander")
	
	func update(_delta: float) -> String:
		match handler.behavior:
			NPC.Behavior.TERRIFIED: handler.state_machine.change(&"exit")
			NPC.Behavior.ALARMED:
				if handler.detection.overlaps_body(handler.offender):
					if handler.offender is Player:
						threat_detected(handler.offender)
		
		handler.velocity = Vector2.ZERO
		return ""
	
	func end() -> String:
		timer.timeout.disconnect(_idle_finished)
		return ""

class Wander extends GameState:
	var handler : NPC
	func _init() -> void: state_name = &"wander"
	
	func threat_detected(body: Node2D) -> void:
		handler.state_machine.back()
		handler.offender = body
		handler.state_machine.change(&"flee")
	
	func interest_detected(body: Node2D) -> void:
		handler.state_machine.back()
		handler.target = body
		handler.state_machine.change(&"chase")
	
	func begin() -> String:
		handler.anim.play(&"run")
		handler.sensitive.set_collision_mask_value(3, false)
		var o = handler.d_zone.shape.radius * handler.scale.x
		handler.nav2d.target_position = handler.pick_destination(50, o)
		return ""
	
	func update(_delta: float) -> String:
		if handler.nav2d.is_navigation_finished(): return &"pop"
		return ""

class Flee extends GameState:
	var handler : NPC
	func _init() -> void: state_name = &"flee"
	
	func threat_detected(body: Node2D) -> void:
		handler.offender = body
		begin()
	
	func _find_safe_point() -> Vector2:
		var o = handler.d_zone.shape.radius * handler.scale.x
		var i = handler.c_zone.shape.radius * handler.scale.x
		var t = handler.offender.global_position
		
		for a in range(50):
			var potential_destination = handler.pick_destination(50, o, i, t)
			
			var is_safe = not Geometry2D.is_point_in_circle(t, potential_destination, i)
			
			if is_safe: return potential_destination
		return handler.global_position + (handler.global_position - t)
	
	func begin() -> String:
		handler.anim.play(&"flee")
		handler.toggle_zones(false, handler.comfort)
		handler.spd_mult = 1.5
		handler.sensitive.set_collision_mask_value(3, false)
		if handler.offender is Player: handler.modify_vigilance(2.5)
		handler.nav2d.target_position = _find_safe_point()
		return ""
	
	func update(_delta: float) -> String:
		if handler.nav2d.is_navigation_finished(): return &"pop"
		return ""
	
	func finish() -> void:
		handler.spd_mult = 1.0
		handler.toggle_zones(true, handler.comfort)

class Chase extends GameState:
	var handler : NPC
	func _init() -> void: state_name = &"chase"
	
	func threat_detected(body: Node2D) -> void:
		handler.state_machine.back()
		handler.offender = body
		handler.state_machine.change(&"flee")
	
	func interest_detected(body: Node2D) -> void:
		if handler.behavior == NPC.Behavior.CHARMED: return
		handler.target = body
		start()

	func _find_approachable_distance() -> Vector2:
		var o = handler.c_zone.shape.radius * handler.scale.x
		var t = handler.target.global_position
		
		for a in range(50):
			var potential_destination = handler.pick_destination(50, o, 0, t, false)
			var in_range = Geometry2D.is_point_in_circle(t, potential_destination, o)
			if in_range: return potential_destination
		return handler.global_position + (handler.target.global_position - handler.global_position)
	
	func start() -> String:
		handler.nav2d.target_position = _find_approachable_distance()
		return ""
	
	func update(_delta: float) -> String:
		if handler.nav2d.is_navigation_finished(): return &"pop"
		if handler.behavior == NPC.Behavior.CHARMED: handler.nav2d.target_position = handler.target.global_position
		return ""

class Struggle extends GameState:
	var handler : NPC
	func _init() -> void: state_name = &"struggle"
	
	func _distance() -> Vector2:
		var radius = handler.c_zone.shape.radius * handler.scale.x
		return handler.pick_destination(50, radius)
	
	func start() -> String:
		handler.toggle_zones(false, handler.sensitive, handler.sighting)
		handler.spd_mult = 0.75
		handler.anim.play("flee")
		handler.nav2d.target_position = _distance()
		handler.set_collision_mask_value(1, false)
		return ""
	
	func update(delta: float) -> String:
		if handler.nav2d.is_navigation_finished(): handler.nav2d.target_position = _distance()
		handler.life_force -= handler.drain_rate * delta
		handler.update_indicators()
		if handler.life_force <= 0:
			handler.state_machine.refresh()
			return &"husk"
		return ""
	
	func finish() -> void:
		handler.spd_mult = 1.0
		handler.toggle_zones(true, handler.sensitive, handler.sighting)

class Husk extends GameState:
	var handler : NPC
	func _init() -> void: state_name = &"husk"
	
	func start() -> String:
		handler.spd_mult = 0.3
		handler.state_machine.refresh()
		handler.toggle_zones(false, handler.sensitive, handler.comfort, handler.detection)
		
		handler.nav2d.set_avoidance_mask_value(1, false)
		handler.nav2d.set_avoidance_mask_value(2, false)
		handler.nav2d.target_position = handler.global_position
		handler.behavior = NPC.Behavior.DRAINED
		
		handler.velocity = Vector2.ZERO
		handler.set_spd(100)
		handler.modulate.a = 0.5
		handler.set_collision_layer_value(3, false)
		handler.set_collision_mask_value(2, false)
		handler.state_machine.change(&"exit")
		return "repeat"

class Enter extends GameState:
	var handler : NPC
	func _init() -> void: state_name = &"enter"
	
	func threat_detected(body: Node2D) -> void:
		handler.state_machine.back()
		handler.offender = body
		handler.state_machine.change(&"flee")
	
	func interest_detected(body: Node2D) -> void:
		handler.state_machine.back()
		handler.target = body
		handler.state_machine.change(&"chase")
	
	func start() -> String:
		handler.set_spd(handler.move_speed)
		handler.nav2d.set_navigation_layer_value(3, true)
		handler.nav2d.set_navigation_layer_value(1, false)
		handler.anim.play(&"run")
		return ""
	
	func update(_delta: float) -> String:
		if handler.nav2d.is_navigation_finished(): return &"pop"
		return ""
	
	func end() -> String:
		handler.nav2d.set_navigation_layer_value(1, true)
		handler.nav2d.set_navigation_layer_value(3, false)
		return ""

class Exit extends GameState:
	var handler : NPC
	func _init() -> void: state_name = &"exit"
	
	func threat_detected(body: Node2D) -> void:
		handler.state_machine.back()
		handler.offender = body
		handler.state_machine.change(&"flee")
	
	func interest_detected(body: Node2D) -> void:
		handler.state_machine.back()
		handler.target = body
		handler.state_machine.change(&"chase")
	
	func start() -> String:
		handler.nav2d.target_position = handler.stage.pick_access_point()
		handler.nav2d.set_navigation_layer_value(3, true)
		handler.nav2d.set_navigation_layer_value(1, false)
		match handler.behavior:
			NPC.Behavior.DRAINED: handler.anim.play(&"husk")
			NPC.Behavior.TERRIFIED: handler.anim.play(&"flee")
			_: handler.anim.play(&"run")
		return ""
		
	func update(_delta: float) -> String:
		if handler.nav2d.is_navigation_finished(): handler.queue_free()
		return ""
	
	func finish() -> void:
		handler.nav2d.set_navigation_layer_value(1, true)
		handler.nav2d.set_navigation_layer_value(3, false)
