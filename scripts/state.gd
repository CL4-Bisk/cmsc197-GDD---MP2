extends RefCounted
class_name GameState

var state_name : String = ""
var transparent : bool = false
var started : bool = false
var processed : bool = false

# first instantiated

func start() -> String:
	return ""

# when at top of stack
func begin() -> String:
	return ""

func update(delta: float) -> String:
	return ""

# no longer the top
func end() -> String:
	return ""

# when removed from stack
func finish() -> void:
	pass
