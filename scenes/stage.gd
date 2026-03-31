extends Node
class_name Stage

@onready var player: Player = $Player
@onready var access_zones: Area2D = $AccessZones
@export var npc : Dictionary[Node2D, int]
