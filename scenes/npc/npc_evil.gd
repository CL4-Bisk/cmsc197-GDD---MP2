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

func play_scream_sound() -> void:
	var x = randi_range(0, 2)
	var stream_to_play = audio_scenes.get(x)
	
	print("Trying to play sound ID: ", x)
	
	if audio == null:
		print("ERROR: AudioStreamPlayer node not found!")
		return
		
	if stream_to_play:
		audio.stream = stream_to_play
		audio.play()
		print("Audio node 'playing' status: ", audio.playing)
	else:
		print("ERROR: Stream not found in dictionary for ID: ", x)

func _process(_delta):
	# Add 'audio != null' to prevent the crash
	if audio != null and audio.playing:
		if lifeforce <= 0 or Input.is_action_just_pressed("feed"):
			audio.stop()
	elif audio == null:
		push_error("ScreamPlayer node is missing on: " + name)
