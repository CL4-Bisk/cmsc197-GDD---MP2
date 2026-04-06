extends NPC
class_name NPCEvil

@onready var hit: Area2D = $Hit

func _ready() -> void:
	modify_vigilance(0)
	state_machine.handler = self
	state_machine.register_state(&"idle", NPCStates.AggroIdle)
	state_machine.register_state(&"wander", NPCStates.Wander)
	state_machine.register_state(&"struggle", NPCStates.Struggle)
	state_machine.register_state(&"threat", NPCStates.AggroChase)
	state_machine.register_state(&"follow", NPCStates.Chase)
	state_machine.register_state(&"attack", NPCStates.Attack)
	state_machine.register_state(&"husk", NPCStates.Husk)
	state_machine.register_state(&"enter", NPCStates.Enter)
	state_machine.register_state(&"exit", NPCStates.Exit)

func _on_attack(body: Node2D) -> void:
	body.hit()

func _on_detection_body_entered(body: Node2D) -> void:
	if body == self: return
	var current_state = state_machine.current()
	if body is Player:
		if behavior < Behavior.DULLED: 
			if current_state.has_method(&"interest_detected"):
				current_state.interest_detected(body)
		else:
			if current_state.has_method(&"threat_detected"):
				current_state.threat_detected(body)

func _on_sensitive_body_entered(body: Node2D) -> void:
	if body == self: return
	if body is Player:
		if behavior != Behavior.CHARMED:
			state_machine.change(&"attack")
