extends Node
class_name GameStateMachine

var handler

var stack : Array[GameState]
var pending : Array = []
var state_registry : Dictionary = {}
var memory : Dictionary

func register_state(_name: String, state_class: GDScript) -> void:
	state_registry[_name] = state_class

func change(state_name: String) -> void:
	pending.append(state_name)

func back() -> void:
	pending.append(&"pop")

func clear() -> void:
	pending.append(&"clear")

func refresh() -> void:
	stack = [stack[-1]]

func current() -> GameState:
	return stack.back() if stack else null

func _process(delta: float) -> void:
	if stack.is_empty(): return
	
	var state : GameState = stack.back()
	var repeat := false
	
	# START
	if not state.started:
		state.started = true
		if state.start() == &"repeat":
			repeat = true
	
	# BEGIN
	if not repeat and not state.processed:
		state.processed = true
		if state.begin() == &"repeat":
			repeat = true
	
	# UPDATED
	if not repeat:
		var transition = state.update(delta)
		if transition != "" and transition != &"repeat":
			change(transition)
		elif transition == &"repeat":
			repeat = true
	
	# END
	if not pending.is_empty() and state.processed:
		state.processed = false
		state.end()
	
	_process_pending()

func _pop(s: GameState):
	s.end()
	s.finish()

func _process_pending() -> void:
	for transition: Variant in pending:
		match transition:
			&"pop":
				if stack.size() > 0:
					_pop(stack.pop_back())
			&"clear":
				while stack.size() > 0:
					_pop(stack.pop_back())
			_:
				var new_state: GameState = state_registry[transition].new()
				if &"handler" in new_state:
					new_state.handler = self.handler
				new_state.state_name = transition
				stack.append(new_state)
	#print(stack.map(func(x): return x.state_name))
	pending.clear()

func _draw_stack() -> void:
	var start_idx := stack.size() - 1
	while start_idx > 0 and stack[start_idx].transparent:
		start_idx -= 1
	
	for i: int in range(start_idx, stack.size()):
		stack[i].draw(get_tree().root)
