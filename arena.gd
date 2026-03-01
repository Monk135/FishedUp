extends Node2D
## Simple arena: draws a rectangular play field and wraps fish at edges.

@export var arena_size: Vector2 = Vector2(800, 600)

func _ready() -> void:
	# Draw arena border via a Line2D
	var line := Line2D.new()
	line.default_color = Color(0.4, 0.8, 1.0, 0.6)
	line.width = 3.0
	var hw := arena_size.x / 2
	var hh := arena_size.y / 2
	line.points = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh), Vector2(-hw, -hh)
	])
	add_child(line)

func _process(_delta: float) -> void:
	# Wrap all fish at arena edges
	var hw := arena_size.x / 2
	var hh := arena_size.y / 2
	for fish in get_tree().get_nodes_in_group("fish"):
		var pos: Vector2 = fish.global_position
		if pos.x > hw:   pos.x = -hw
		elif pos.x < -hw: pos.x = hw
		if pos.y > hh:   pos.y = -hh
		elif pos.y < -hh: pos.y = hh
		fish.global_position = pos
