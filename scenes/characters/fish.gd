extends RigidBody2D

@export var max_launch_force: float = 2000.0
@export var max_drag_distance: float = 200.0

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if global_position.distance_to(get_global_mouse_position()) < 60:
				is_dragging = true
				drag_start = get_global_mouse_position()
		else:
			if is_dragging:
				launch()
				is_dragging = false
				queue_redraw()  # force clear the line

func launch():
	var drag_vector = drag_start - get_global_mouse_position()
	drag_vector = drag_vector.limit_length(max_drag_distance)
	var force = drag_vector * (max_launch_force / max_drag_distance)
	linear_velocity = Vector2.ZERO  # reset velocity before each launch
	angular_velocity = 0.0
	apply_central_impulse(force)
	apply_torque_impulse(randf_range(-50000, 50000))  # random spin on launch

func _draw():
	if is_dragging:
		var drag_vector = drag_start - get_global_mouse_position()
		drag_vector = drag_vector.limit_length(max_drag_distance)
		draw_line(Vector2.ZERO, to_local(drag_start - drag_vector) - to_local(global_position), Color.RED, 2)

func _physics_process(_delta):
	if is_dragging:
		queue_redraw()
