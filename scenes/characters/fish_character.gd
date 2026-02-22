extends Node2D

@export var max_launch_force: float = 350.0
@export var max_drag_distance: float = 100.0

@onready var body = $Body
@onready var head = $Head
@onready var tail = $Tail

@export var max_bend_angle: float = 25.0

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if body.global_position.distance_to(get_global_mouse_position()) < 60:
				is_dragging = true
				drag_start = get_global_mouse_position()
		else:
			if is_dragging:
				launch()
				is_dragging = false
				queue_redraw()

func launch():
	var drag_vector = drag_start - get_global_mouse_position()
	drag_vector = drag_vector.limit_length(max_drag_distance)
	var force = drag_vector * (max_launch_force / max_drag_distance)
	
	# Reset all segments before launch
	for segment in [tail, body, head]:
		segment.linear_velocity = Vector2.ZERO
		segment.angular_velocity = 0.0
	
	# Apply force to all segments so they launch together
	body.apply_central_impulse(force)
	head.apply_central_impulse(force)
	tail.apply_central_impulse(force)
	
	# Random spin on each segment for ragdoll effect
	tail.apply_torque_impulse(randf_range(-30000, 30000))
	body.apply_torque_impulse(randf_range(-10000, 10000))
	head.apply_torque_impulse(randf_range(-30000, 30000))

func _draw():
	if is_dragging:
		var drag_vector = drag_start - get_global_mouse_position()
		drag_vector = drag_vector.limit_length(max_drag_distance)
		draw_line(
			to_local(drag_start),
			to_local(drag_start - drag_vector),
			Color.RED, 2
		)
		

func _physics_process(_delta):
	if is_dragging:
		queue_redraw()
	enforce_angle_limits()

func enforce_angle_limits():
	var soft_limit = max_bend_angle * 0.7  # starts correcting at 70% of max angle
	
	var head_relative_angle = rad_to_deg(head.rotation - body.rotation)
	if abs(head_relative_angle) > soft_limit:
		var correction_strength = remap(abs(head_relative_angle), soft_limit, max_bend_angle, 0.0, 1.0)
		head.angular_velocity = lerp(head.angular_velocity, body.angular_velocity, correction_strength)
	if abs(head_relative_angle) > max_bend_angle:
		head.rotation = body.rotation + deg_to_rad(sign(head_relative_angle) * max_bend_angle)
		head.angular_velocity = body.angular_velocity

	var tail_relative_angle = rad_to_deg(tail.rotation - body.rotation)
	if abs(tail_relative_angle) > soft_limit:
		var correction_strength = remap(abs(tail_relative_angle), soft_limit, max_bend_angle, 0.0, 1.0)
		tail.angular_velocity = lerp(tail.angular_velocity, body.angular_velocity, correction_strength)
	if abs(tail_relative_angle) > max_bend_angle:
		tail.rotation = body.rotation + deg_to_rad(sign(tail_relative_angle) * max_bend_angle)
		tail.angular_velocity = body.angular_velocity
		
func _process(_delta):
	enforce_angle_limits()
