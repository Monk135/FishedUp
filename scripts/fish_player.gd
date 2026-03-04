extends CharacterBody2D

@export var player_id: int = 1
@export var joypad_id: int = -1  # -1 = keyboard, 0+ = joypad

var hit_flash_timer: float = 0.0
@export var hit_flash_duration: float = 0.2
var player_color: Color = Color.WHITE

@export var turn_speed: float = 10.0
@export var thrust_force: float = 2200.0
@export var passive_thrust: float = 600
@export var max_speed: float = 2400.0
@export var damping: float = 0.98
@export var segment_distance: float = 1
@export var segment_lag: float = 0.5

@onready var bill_area: Area2D = $BillArea
@onready var head_area: Area2D = $HeadArea
@onready var body_area: Area2D = $BodyArea
@onready var tail_area: Area2D = $TailArea

@export var angular_damping: float = 0.99
@export var max_rotation_speed: float = 1.0  # degrees per second

@export var max_health: float = 100.0
@export var invulnerability_duration: float = 1.0
@export var min_damage: float = 10.0
@export var max_damage: float = 60.0
@export var knockback_force: float = 600.0

var health: float = 100.0
var invulnerable_timer: float = 0.0

@onready var health_bar: ProgressBar = $HealthBar


var angular_velocity: float = 0.0



@onready var physics_shape: CollisionShape2D = $PhysicsShape

var head_angle: float = 0.0
var segment_positions: Array[Vector2] = []
var segment_angles: Array[float] = []

@onready var bill_visual: Polygon2D = $BillVisual
@onready var head_visual: Polygon2D = $HeadVisual
@onready var body_visual: Polygon2D = $BodyVisual
@onready var tail_visual: Polygon2D = $TailVisual

var idle_wave_timer: float = 0.0
var idle_wave_direction: float = 1.0



func _ready() -> void:
	segment_positions.resize(4)
	segment_angles.resize(4)
	for i in 4:
		segment_positions[i] = global_position + Vector2(-i * segment_distance, 0)
		segment_angles[i] = 0.0
	bill_area.add_to_group("bill")
	head_area.add_to_group("hittable")
	body_area.add_to_group("hittable")
	tail_area.add_to_group("hittable")
	
	bill_area.area_entered.connect(_on_bill_area_entered)
	
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_behind_parent = true
	
	print(Input.get_connected_joypads())



# already added bill_area.add_to_group("bill") above

func _on_bill_area_entered(area: Area2D) -> void:
	if area.is_in_group("hittable"):
		var other_fish: Node = area.get_parent()
		if other_fish == self:
			return
		var impact_speed := velocity.length()
		var knockback_dir: Vector2 = (other_fish.global_position - global_position).normalized()
		other_fish.velocity += knockback_dir * knockback_force
		other_fish.take_hit(impact_speed, knockback_dir)

	elif area.is_in_group("bill"):
		var other_fish: Node = area.get_parent()
		if other_fish == self:
			return
		var push_dir: Vector2 = (global_position - other_fish.global_position).normalized()
		velocity += push_dir * knockback_force
		other_fish.velocity += -push_dir * knockback_force

func die() -> void:
	print("Player %d died!" % player_id)
	queue_free()

func take_hit(impact_speed: float, _knockback_dir: Vector2) -> void:
	if invulnerable_timer > 0.0:
		return

	var t: float = clamp(impact_speed / max_speed, 0.0, 1.0)
	var damage: float = lerp(min_damage, max_damage, t)

	health -= damage
	invulnerable_timer = invulnerability_duration
	health_bar.value = health
	hit_flash_timer = hit_flash_duration
	_flash_red()

	if health <= 0.0:
		die()


func _physics_process(delta: float) -> void:
	var input := _get_input()
	_handle_movement(input, delta)
	_update_chain()
	_update_visuals()
	
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if hit_flash_timer <= 0.0:
		_reset_color()

func _get_input() -> Vector2:
	if joypad_id >= 0:
		return Vector2(
			Input.get_joy_axis(joypad_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(joypad_id, JOY_AXIS_LEFT_Y)
		)
	match player_id:
		1:
			return Vector2(
				Input.get_axis("move_left_p1", "move_right_p1"),
				Input.get_axis("move_up_p1", "move_down_p1")
			)
		_:
			return Vector2(
				Input.get_axis("move_left_p2", "move_right_p2"),
				Input.get_axis("move_up_p2", "move_down_p2")
			)

func _flash_red() -> void:
	for child in get_children():
		if child is Polygon2D:
			child.color = Color.RED

func _reset_color() -> void:
	for child in get_children():
		if child is Polygon2D:
			child.color = player_color

func _handle_joypad_movement(input: Vector2, delta: float) -> void:
	if input.length() > 0.15:
		var target_angle := input.angle()
		var angle_diff: float = angle_difference(head_angle, target_angle)
		# Scale force by how far off we are — prevents overshoot oscillation
		angular_velocity += angle_diff * turn_speed * 0.1 * delta

	var is_boosting: bool = Input.is_joy_button_pressed(joypad_id, JOY_BUTTON_A)
	var forward := Vector2(cos(head_angle), sin(head_angle))
	var thrust := passive_thrust
	if is_boosting:
		thrust += thrust_force
	velocity += forward * thrust * delta

	angular_velocity *= angular_damping
	angular_velocity = clamp(angular_velocity, deg_to_rad(-max_rotation_speed), deg_to_rad(max_rotation_speed))
	head_angle += angular_velocity

	velocity = velocity.limit_length(max_speed)
	velocity *= damping

	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * 0.5

func _handle_movement(input: Vector2, delta: float) -> void:
	if joypad_id >= 0:
		_handle_joypad_movement(input, delta)
		return
	
	# ... rest of your existing keyboard handling unchanged
	if abs(input.x) > 0.1:
		angular_velocity += deg_to_rad(turn_speed * input.x * delta)

	# Always thrust forward, input.y only adds extra speed (no reverse)
	var forward := Vector2(cos(head_angle), sin(head_angle))
	var thrust := passive_thrust
	if input.y < -0.1:
		thrust += thrust_force * abs(input.y)  # extra boost when pressing forward
	#if abs(input.x) > 0.1:
		#thrust += thrust_force * abs(input.y)  # extra boost when pressing forward
	velocity += forward * thrust * delta

	angular_velocity *= angular_damping
	angular_velocity = clamp(angular_velocity, deg_to_rad(-max_rotation_speed), deg_to_rad(max_rotation_speed))
	head_angle += angular_velocity

	velocity = velocity.limit_length(max_speed)
	velocity *= damping

	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * 0.5



func _update_chain() -> void:
	segment_positions[1] = global_position
	segment_angles[1] = head_angle

	segment_positions[0] = global_position + Vector2(cos(head_angle), sin(head_angle)) * segment_distance
	segment_angles[0] = head_angle

	for i in range(2, 4):
		var parent_pos: Vector2 = segment_positions[i - 1]
		var parent_angle: float = segment_angles[i - 1]
		var target_pos: Vector2 = parent_pos - Vector2(cos(parent_angle), sin(parent_angle)) * segment_distance

		segment_positions[i] = segment_positions[i].lerp(target_pos, segment_lag)

		var desired_angle: float = (parent_pos - segment_positions[i]).angle()
		segment_angles[i] = lerp_angle(segment_angles[i], desired_angle, segment_lag + 0.05)



func _update_visuals() -> void:
	bill_visual.global_position = segment_positions[0]
	head_visual.global_position = segment_positions[1]
	body_visual.global_position = segment_positions[2]
	tail_visual.global_position = segment_positions[3]

	bill_visual.rotation = segment_angles[0]
	head_visual.rotation = segment_angles[1]
	body_visual.rotation = segment_angles[2]
	tail_visual.rotation = segment_angles[3]

	bill_area.global_position = segment_positions[0]
	bill_area.rotation = segment_angles[0]
	head_area.global_position = segment_positions[1]
	head_area.rotation = segment_angles[1]
	body_area.global_position = segment_positions[2]
	body_area.rotation = segment_angles[2]
	tail_area.global_position = segment_positions[3]
	tail_area.rotation = segment_angles[3]
	
	physics_shape.global_position = segment_positions[1]  # follows the head
	physics_shape.rotation = segment_angles[1]
