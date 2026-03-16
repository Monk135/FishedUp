extends CharacterBody2D

@export var player_id: int = 1
@export var joypad_id: int = -1  # -1 = keyboard, 0+ = joypad

var _prev_space_pressed: bool = false

var original_modulate: Color = Color.WHITE

var last_hit_by: int = -99  # device_id of last attacker

var segment_prev_positions: Array[Vector2] = []

@export var damage_bonus: float = 0.0

@export var is_preview: bool = false

var hit_flash_timer: float = 0.0
@export var hit_flash_duration: float = 0.2
var player_color: Color = Color.WHITE
@export var initial_angle_degrees: float = 0.0

@export var turn_speed: float = 10.0
@export var thrust_force: float = 1400
@export var passive_thrust: float = 400
@export var max_speed: float = 2800.0
@export var damping: float = 0.98
@export var segment_distance: float = 1
@export var segment_lag: float = 0.5

@export var dash_force: float = 1000.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 2.0

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false

var _last_input: Vector2 = Vector2.ZERO

@export var wall_side_strength: float = 0.01

@onready var physics_shape: CollisionShape2D = $PhysicsShape
@onready var bill_area: Area2D = $BillArea
@onready var head_area: Area2D = $HeadArea
@onready var body_area: Area2D = $BodyArea
@onready var tail_area: Area2D = $TailArea

@export var angular_damping: float = 0.99
@export var max_rotation_speed: float = 1.0  # degrees per second

@export var max_health: float = 100.0
@export var invulnerability_duration: float = 0.5
@export var initial_damage: float = 20.0
@export var knockback_force: float = 600.0

@export var health: float = 100.0
var invulnerable_timer: float = 0.0

var _prev_a_pressed: bool = false

@onready var health_bar: ProgressBar = $HealthBar

@onready var wall_feeler: RayCast2D = $WallFeeler
@onready var wall_feeler_left: RayCast2D = $WallFeelerLeft
@onready var wall_feeler_right: RayCast2D = $WallFeelerRight

var angular_velocity: float = 0.0

var head_angle: float = 0.0
var segment_positions: Array[Vector2] = []
var segment_angles: Array[float] = []

var corner_escape_direction: float = 0.0

@onready var bill_visual: Polygon2D = $BillVisual
@onready var head_visual: Polygon2D = $HeadVisual
@onready var body_visual: Polygon2D = $BodyVisual
@onready var tail_visual: Polygon2D = $TailVisual

var _first_wall_hit: String = ""

var idle_wave_timer: float = 0.0
var idle_wave_direction: float = 1.0

var _dash_was_on_cooldown: bool = false
var _outline_flash_timer: float = 0.0
@export var dash_ready_flash_duration: float = 0.05



func _ready() -> void:
	segment_positions.resize(4)
	segment_prev_positions.resize(4)
	segment_angles.resize(4)
	for i in 4:
		segment_positions[i] = global_position + Vector2(-i * segment_distance, 0)
		segment_prev_positions[i] = segment_positions[i]
	bill_area.add_to_group("bill")
	head_area.add_to_group("hittable")
	body_area.add_to_group("hittable")
	tail_area.add_to_group("hittable")
	add_to_group("fish")
	
	bill_area.area_entered.connect(_on_bill_area_entered)
	
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_behind_parent = true
	
	print(Input.get_connected_joypads())
	head_angle = deg_to_rad(initial_angle_degrees)
	
	original_modulate = modulate

func _on_bill_area_entered(area: Area2D) -> void:
	if area.is_in_group("hittable"):
		var other_fish: Node = area.get_parent()
		if other_fish == self:
			return
		var impact_speed := velocity.length()
		var knockback_dir: Vector2 = (other_fish.global_position - global_position).normalized()
		
		other_fish.velocity += knockback_dir * knockback_force
		other_fish.take_hit(impact_speed, knockback_dir, joypad_id, damage_bonus)
		velocity -= knockback_dir * knockback_force * 0.8

	elif area.is_in_group("bill"):
		var other_fish: Node = area.get_parent()
		if other_fish == self:
			return
		var push_dir: Vector2 = (global_position - other_fish.global_position).normalized()
		velocity += push_dir * knockback_force
		other_fish.velocity += -push_dir * knockback_force

func die() -> void:
	if last_hit_by != -99:
		GameState.add_kill(last_hit_by)
		print("kill awarded to device: ", last_hit_by, " scores: ", GameState.scores)
	get_parent().on_fish_died()
	queue_free()

func take_hit(impact_speed: float, _knockback_dir: Vector2, attacker_id: int, attacker_damage_bonus: float = 0.0) -> void:
	if invulnerable_timer > 0.0:
		return
	var damage: float = initial_damage + attacker_damage_bonus
	health -= damage
	invulnerable_timer = invulnerability_duration
	health_bar.value = health
	hit_flash_timer = hit_flash_duration
	_flash_red()

	if health <= 0.0:
		die()

func refresh_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta: float) -> void:
	if is_preview:
		return
	var input := _get_input()
	_last_input = input
	#global_position += velocity * delta
	_handle_movement(input, delta)
	_update_chain()
	_update_visuals()
	_handle_wall_anticipation(delta)
	
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
	
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			_reset_color()
			
	if _dash_was_on_cooldown and dash_cooldown_timer <= 0.0:
		_outline_flash_timer = dash_ready_flash_duration
		_flash_white()
	_dash_was_on_cooldown = dash_cooldown_timer > 0.0

	if _outline_flash_timer > 0.0:
		_outline_flash_timer -= delta
		if _outline_flash_timer <= 0.0:
			_reset_color()

func _handle_wall_anticipation(_delta: float) -> void:
	if _last_input.length() < 0.15:
		return
	for feeler in [wall_feeler, wall_feeler_left, wall_feeler_right]:
		feeler.global_position = segment_positions[0]
		feeler.force_raycast_update()
	
	wall_feeler.global_rotation = head_angle
	wall_feeler_left.global_rotation = head_angle - deg_to_rad(45)
	wall_feeler_right.global_rotation = head_angle + deg_to_rad(45)

	
	var center_hit := wall_feeler.is_colliding()
	var left_hit := wall_feeler_left.is_colliding()
	var right_hit := wall_feeler_right.is_colliding()
	
	# All rays hit = stuck in corner, pick a random escape direction
	#if center_hit and left_hit and right_hit:
		#if corner_escape_direction == 0.0:
			#corner_escape_direction = [-1.0, 1.0].pick_random()
		#angular_velocity += corner_escape_direction * 0.02
		#return
	
	var total_push: float = 0.0
	
	#if center_hit:
		#var normal := wall_feeler.get_collision_normal()
		#var tangent := Vector2(-normal.y, normal.x)
		#if tangent.dot(Vector2(cos(head_angle), sin(head_angle))) < 0:
			#tangent = -tangent
		#total_push += angle_difference(head_angle, tangent.angle()) * 0.1

	if left_hit:
		var distance := wall_feeler_left.get_collision_point().distance_to(segment_positions[0])
		var proximity : float = 1.0 - clamp(distance / 150.0, 0.0, 1.0)
		total_push += clamp(proximity * wall_side_strength, 0.0, 0.04)
	
	if right_hit:
		var distance := wall_feeler_right.get_collision_point().distance_to(segment_positions[0])
		var proximity : float = 1.0 - clamp(distance / 150.0, 0.0, 1.0)
		total_push -= clamp(proximity * wall_side_strength, 0.0, 0.04)  # right wall = push left

	var is_turning: bool = abs(_last_input.x) > 0.1
	if not is_turning:
		total_push *= 0.02

	angular_velocity += total_push *0.5
	
func _get_input() -> Vector2:
	if joypad_id >= 0:
		return Vector2(
			Input.get_joy_axis(joypad_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(joypad_id, JOY_AXIS_LEFT_Y)
		)
	match joypad_id:
		-1:  # WASD
			return Vector2(
				Input.get_axis("move_left_p1", "move_right_p1"),
				Input.get_axis("move_up_p1", "move_down_p1")
			)
		-2:  # IJKL
			return Vector2(
				Input.get_axis("move_left_p2", "move_right_p2"),
				Input.get_axis("move_up_p2", "move_down_p2")
			)
		-3:  # Arrow keys
			return Vector2(
				Input.get_axis("move_left_p3", "move_right_p3"),
				Input.get_axis("move_up_p3", "move_down_p3")
			)
		-4:  # TFGH
			return Vector2(
				Input.get_axis("move_left_p4", "move_right_p4"),
				Input.get_axis("move_up_p4", "move_down_p4")
			)
	return Vector2.ZERO

func _flash_red() -> void:
	modulate = Color.RED
func _flash_white() -> void:
	modulate = Color(3.0, 3.0, 3.0, 1.0)
func _reset_color() -> void:
	modulate = original_modulate

func _handle_joypad_movement(input: Vector2, delta: float) -> void:
	if input.length() > 0.15:
		var target_angle := input.angle()
		var angle_diff: float = angle_difference(head_angle, target_angle)
		angular_velocity += angle_diff * turn_speed * 0.1 * delta

	var a_pressed: bool = Input.is_joy_button_pressed(joypad_id, JOY_BUTTON_A)
	var a_just_pressed: bool = a_pressed and not _prev_a_pressed
	_prev_a_pressed = a_pressed

	if a_just_pressed and dash_cooldown_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		var forward := Vector2(cos(head_angle), sin(head_angle))
		velocity += forward * dash_force

	var forward := Vector2(cos(head_angle), sin(head_angle))
	var thrust := passive_thrust
	if input.length() > 0.15:
		thrust += thrust_force

	velocity += forward * thrust * delta

	angular_velocity *= angular_damping
	angular_velocity = clamp(angular_velocity, deg_to_rad(-max_rotation_speed), deg_to_rad(max_rotation_speed))
	head_angle += angular_velocity

	velocity = velocity.limit_length(max_speed)
	velocity *= damping
	move_and_slide()

func _handle_movement(input: Vector2, delta: float) -> void:
	
	if joypad_id >= 0:
		_handle_joypad_movement(input, delta)
		return
	
	var space_pressed: bool = false
	match joypad_id:
		-1: space_pressed = Input.is_key_pressed(KEY_SPACE)
		-2: space_pressed = Input.is_key_pressed(KEY_ENTER)
		-3: space_pressed = Input.is_key_pressed(KEY_SHIFT)
		-4: space_pressed = Input.is_key_pressed(KEY_B)

	var space_just_pressed: bool = space_pressed and not _prev_space_pressed
	_prev_space_pressed = space_pressed

	if space_just_pressed and dash_cooldown_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		var forward := Vector2(cos(head_angle), sin(head_angle))
		velocity += forward * dash_force
	
	
	
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
	
	

	move_and_slide()
		
func _update_chain() -> void:
	segment_positions[1] = global_position
	segment_angles[1] = head_angle
	segment_positions[0] = global_position + Vector2(cos(head_angle), sin(head_angle)) * segment_distance
	segment_angles[0] = head_angle

	# Body and tail: verlet integration + distance constraint
	for i in range(2, 4):
		# Inertia: continue in same direction as last frame
		var inertia := segment_positions[i] - segment_prev_positions[i]
		segment_prev_positions[i] = segment_positions[i]
		segment_positions[i] += inertia * 0.5  # 0.8 = how much inertia carries over

		# Distance constraint: pull back to correct distance from parent
		var parent_pos := segment_positions[i - 1]
		var parent_angle := segment_angles[i - 1]
		var target := parent_pos - Vector2(cos(parent_angle), sin(parent_angle)) * segment_distance
		var diff := segment_positions[i] - target
		if diff.length() > segment_distance * 0.5:
			segment_positions[i] = target + diff.normalized() * segment_distance * 0.5

		# Angle from actual position
		var desired_angle := (parent_pos - segment_positions[i]).angle()
		segment_angles[i] = lerp_angle(segment_angles[i], desired_angle, 0.3)

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
	
	physics_shape.global_position = segment_positions[1]
	physics_shape.global_rotation = segment_angles[1] + PI / 2
