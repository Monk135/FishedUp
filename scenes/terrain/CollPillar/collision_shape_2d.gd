@tool
extends CollisionShape2D

@export var visual_color: Color = Color(0.2, 0.8, 1.0, 0.4):
	set(value):
		visual_color = value
		queue_redraw()

func _draw() -> void:
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var half := rect.size / 2.0
		draw_rect(Rect2(-half, rect.size), visual_color, true)

	elif shape is CircleShape2D:
		var circle := shape as CircleShape2D
		draw_circle(Vector2.ZERO, circle.radius, visual_color)

	elif shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		draw_rect(Rect2(-capsule.radius, -capsule.height / 2.0, capsule.radius * 2.0, capsule.height), visual_color, true)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
