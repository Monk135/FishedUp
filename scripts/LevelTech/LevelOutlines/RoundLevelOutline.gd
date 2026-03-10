@tool
extends StaticBody2D

@export var radius: float = 500.0:
	set(value):
		radius = value
		queue_redraw()
		if Engine.is_editor_hint():
			_build_collision()

@export var segments: int = 32:
	set(value):
		segments = value
		queue_redraw()
		if Engine.is_editor_hint():
			_build_collision()

@export var line_color: Color = Color(0.2, 0.8, 1.0, 0.8):
	set(value):
		line_color = value
		queue_redraw()

var _collision_polygon: CollisionPolygon2D

func _ready() -> void:
	_build_collision()
	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array()
	for i in segments + 1:
		var angle := -i * TAU / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_polyline(points, line_color, 3.0)

func _build_collision() -> void:
	if Engine.is_editor_hint():
		return
	# Remove old segments
	for child in get_children():
		if child is StaticBody2D:
			child.queue_free()
	
	for i in segments:
		var angle_a := -i * TAU / segments
		var angle_b := -(i + 1) * TAU / segments
		var point_a := Vector2(cos(angle_a), sin(angle_a)) * radius
		var point_b := Vector2(cos(angle_b), sin(angle_b)) * radius
		
		var body := StaticBody2D.new()
		body.add_to_group("wall")
		var col := CollisionShape2D.new()
		var shape := WorldBoundaryShape2D.new()
		# Normal points inward
		var mid_angle := (angle_a + angle_b) / 2.0
		shape.normal = -Vector2(cos(mid_angle), sin(mid_angle))
		shape.distance = -radius
		col.shape = shape
		body.add_child(col)
		add_child(body)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
