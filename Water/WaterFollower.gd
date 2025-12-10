extends Node3D

@export var target : Node3D

func _process(delta: float) -> void:
	var pos = target.global_position
	pos.y = global_position.y
	global_position = pos
