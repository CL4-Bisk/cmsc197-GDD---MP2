extends Node2D
class_name stage

@onready var player: Player = $Player
@onready var access_zones: Area2D = $AccessZones
@export var npc : Dictionary[Node2D, int]
