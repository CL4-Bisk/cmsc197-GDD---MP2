extends GDScript
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
		handler.charm_zone.set_deferred("disabled", false)
		
		var s = (handler.charm_zone.shape as CircleShape2D)
		var duration = handler.life_force / handler.charm_zone_growth_spd
		s.radius = 0.0
		t = handler.get_tree().create_tween()
		t.tween_property(s, "radius", handler.life_force, duration).set_trans(Tween.TRANS_LINEAR)
		return ""
	
	func update(_delta: float) -> String:
		if not handler.lustful: handler.spd_mult = 0.5
		if Input.is_action_just_released(&"charm"): return &"pop"
		return ""
	
	func end() -> String:
		if handler.state_machine.stack.is_empty(): handler.state_machine.change(&"normal")
		handler.charm_zone.set_deferred("disabled", true)
		if t and t.is_running(): t.kill()
		(handler.charm_zone.shape as CircleShape2D).radius = handler.life_force
		return ""

class Feeding extends GameState:
	var handler : Player
	var feeding_target : NPC
	var t: Tween
	
	func _init() -> void:
		state_name = &"feed"
	
	func start() -> String:
		handler.censor.show()
		handler.spd_mult = 0
		handler.hit_box.set_deferred(&"disabled", true)
		handler.nav2d.avoidance_enabled = false
		
		var x = handler.find_nearest()
		
		if not x or handler.level < x.npc_level:
			print("player level not high")
			handler.state_machine.back()
			return &"repeat"
		
		if x:
			feeding_target = x
			feeding_target.offender = handler
			
			t = handler.create_tween()
			t.tween_property(handler, "global_position", feeding_target.global_position, 0.1)
		
			feeding_target.state_machine.change(&"struggle")
			
		return ""
	
	func begin() -> String:
		if feeding_target: return ""
		return &"repeat"
		
	func update(delta: float) -> String:
		
		if not is_instance_valid(feeding_target):
			return &"pop"
		
		var suck_power = feeding_target.drain_rate * delta \
							* (2 if handler.lustful else 1)
		
		feeding_target.life_force -= suck_power
		handler.life_force += suck_power
		
		if Input.is_action_just_pressed(&"feed"): 
			feeding_target.state_machine.back()
			return &"pop"
		if feeding_target.life_force <= 0: 
			handler.state_machine.back()
			handler.state_machine.change(&"lust")
			return ""
		if t and t.is_running(): return ""
		handler.global_position = feeding_target.global_position
		return ""
	
	func finish() -> void:
		for i in handler.level_threshold.keys().slice(handler.level-1, -1):
			print(handler.level)
			if handler.level_threshold.get(i) <= handler.life_force - handler.AURA_SIZE: 
				handler.level = i + 1
		
		handler.censor.hide()
		if handler.state_machine.stack.is_empty(): handler.state_machine.change(&"normal")
		handler.nav2d.avoidance_enabled = true
		handler.hit_box.set_deferred("disabled", false)

class Lustful extends GameState:
	var handler : Player
	
	func _init() -> void:
		state_name = &"lust"
	
	func start() -> String:
		handler.spd_mult = 2.0
		handler.lustful = true
		handler.status = &"_demon"
		handler.demon_timer.start()
		return ""
	
	func update(_delta: float) -> String:
		if Input.is_action_just_pressed(&"charm"): 
			return &"charm"
		return ""

class Subjugated extends GameState:
	var handler : Player
	
	func _init() -> void:
		state_name = &"dead"
	
	func start() -> String:
		handler.spd_mult = 0.0
		handler.anim.play(&"dead")
		return ""

class Hit extends GameState:
	var handler : Player
	
	func _init() -> void: state_name = &"hit"
	
	func begin() -> String:
		handler.anim.play(&"hit")
		handler.anim.animation_finished.connect(
			func(_x): handler.state_machine.back()
		)
		return ""
	
	func finish() -> void:
		handler.lives -= 1
		if handler.lives <= 0:
			handler.player_dead.emit()
			handler.state_machine.change(&"dead")
			return
		handler.state_machine.change(&"normal")
