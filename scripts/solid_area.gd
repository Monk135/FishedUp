extends Node2D

func _ready() -> void:
	$Area2D.add_to_group("wall")
