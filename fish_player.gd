extends CharacterBody2D

@export var player_id: int = 1

@export var turn_speed: float = 240.0
@export var thrust_force: float = 1200.0
@export var max_speed: float = 1200.0
@export var damping: float = 0.98
@export var segment_distance: float = 1
@export var segment_lag: float = 0.5

@onready var bill_area: Area2D = $BillArea
@onready var head_area: Area2D = $HeadArea
@onready var body_area: Area2D = $BodyArea
@onready var tail_area: Area2D = $TailArea

@onready var physics_shape: CollisionShape2D = $PhysicsShape

var head_angle: float = 0.0
var segment_positions: Array[Vector2] = []
var segment_angles: Array[float] = []

@onready var bill_visual: Polygon2D = $BillVisual
@onready var head_visual: Polygon2D = $HeadVisual
@onready var body_visual: Polygon2D = $BodyVisual
@onready var tail_visual: Polygon2D = $TailVisual


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



# already added bill_area.add_to_group("bill") above

func _on_bill_area_entered(area: Area2D) -> void:
	if area.is_in_group("hittable"):
		var other_fish: Node = area.get_parent()
		if other_fish != self:
			other_fish.die()
	
	elif area.is_in_group("bill"):
		var other_fish: Node = area.get_parent()
		if other_fish == self:
			return
		# Push both fish away from each other
		var push_dir: Vector2 = (global_position - other_fish.global_position).normalized()
		var push_strength: float = 600.0
		velocity += push_dir * push_strength
		other_fish.velocity += -push_dir * push_strength

func die() -> void:
	print("Player %d died!" % player_id)
	queue_free()

func _physics_process(delta: float) -> void:
	var input := _get_input()
	_handle_movement(input, delta)
	_update_chain()
	_update_visuals()

func _get_input() -> Vector2:
	if player_id == 1:
		return Vector2(
			Input.get_axis("move_left_p1", "move_right_p1"),
			Input.get_axis("move_up_p1", "move_down_p1")
		)
	else:
		return Vector2(
			Input.get_axis("move_left_p2", "move_right_p2"),
			Input.get_axis("move_up_p2", "move_down_p2")
		)

func _handle_movement(input: Vector2, delta: float) -> void:
	if abs(input.x) > 0.1:
		head_angle += deg_to_rad(turn_speed * input.x * delta)

	if abs(input.y) > 0.1:
		var forward := Vector2(cos(head_angle), sin(head_angle))
		velocity += forward * (-input.y) * thrust_force * delta

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
