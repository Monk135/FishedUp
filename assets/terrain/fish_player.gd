extends Node2D

# ── Config ──────────────────────────────────────────────────────────────────
@export var device_id: int = 0          # -1 = keyboard, 0+ = joypad
@export var turn_speed: float = 180.0   # degrees/sec
@export var thrust_force: float = 400.0
@export var max_speed: float = 350.0
@export var damping: float = 0.92       # per-frame velocity multiplier (no gravity feel)
@export var segment_distance: float = 28.0  # distance between segment anchors
@export var segment_lag: float = 0.18   # how "loose" the chain is (0=rigid, 1=very loose)

# ── State ────────────────────────────────────────────────────────────────────
var velocity: Vector2 = Vector2.ZERO
var is_piercing: bool = false           # bill is currently stuck in someone
var pierce_joint: Node = null           # the PinJoint2D linking us to victim
var pierce_victim: Node2D = null
var player_color: Color = Color.WHITE

# Segment positions (world-space anchor points for drawing/child positioning)
# Order: [bill_tip, head, body, tail]
var segment_positions: Array[Vector2] = []
var head_angle: float = 0.0             # radians, direction fish faces

# ── Node refs ────────────────────────────────────────────────────────────────
@onready var bill_area: Area2D = $BillArea
@onready var body_collision: Area2D = $BodyArea
@onready var bill_visual: Node2D = $BillVisual
@onready var head_visual: Node2D = $HeadVisual
@onready var body_visual: Node2D = $BodyVisual
@onready var tail_visual: Node2D = $TailVisual

# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Initialise segment positions behind the spawn point
	segment_positions.resize(4)
	for i in 4:
		segment_positions[i] = global_position - Vector2(i * segment_distance, 0)

	bill_area.body_entered.connect(_on_bill_hit)
	bill_area.area_entered.connect(_on_bill_hit_area)

func setup(color: Color, device: int) -> void:
	player_color = color
	device_id = device
	# Tint all visuals
	for child in get_children():
		if child is Polygon2D or child.has_method("set_color"):
			child.modulate = color

# ──────────────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	var input := _get_input()
	_handle_movement(input, delta)
	_update_segments(delta)
	_update_visuals()

	# Unstick if pulling back hard enough
	if is_piercing and input.y < -0.6:
		_unstick()

func _get_input() -> Vector2:
	if device_id == -1:
		# Keyboard fallback
		var x := Input.get_axis("ui_left", "ui_right")
		var y := Input.get_axis("ui_up", "ui_down")
		return Vector2(x, y)
	else:
		var x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
		var y := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
		# dead zone
		var v := Vector2(x, y)
		if v.length() < 0.15:
			return Vector2.ZERO
		return v

func _handle_movement(input: Vector2, delta: float) -> void:
	if is_piercing:
		# While stuck, can only struggle (reduced control)
		# Reverse pull is handled above; damp velocity
		velocity *= 0.88
		global_position += velocity * delta
		return

	# Tank turning: left stick X rotates head
	if abs(input.x) > 0.1:
		head_angle += deg_to_rad(turn_speed * input.x * delta)

	# Forward thrust: left stick Y (negative = forward in screen space)
	var thrust_dir := Vector2(cos(head_angle), sin(head_angle))
	if abs(input.y) > 0.1:
		velocity += thrust_dir * (-input.y) * thrust_force * delta

	velocity = velocity.limit_length(max_speed)
	velocity *= damping

	global_position += velocity * delta

func _update_segments(delta: float) -> void:
	# Head always sits at our position, facing head_angle
	segment_positions[1] = global_position

	# Bill is rigidly in front of head
	var forward := Vector2(cos(head_angle), sin(head_angle))
	segment_positions[0] = global_position + forward * segment_distance

	# Body and tail follow with lag (verlet-style chain)
	for i in range(2, 4):
		var target := segment_positions[i - 1]
		var current := segment_positions[i]
		var diff := current - target
		if diff.length() > segment_distance:
			segment_positions[i] = target + diff.normalized() * segment_distance
		else:
			# Smooth follow
			segment_positions[i] = current.lerp(
				target - diff.normalized() * segment_distance,
				segment_lag
			)

func _update_visuals() -> void:
	# Position each visual node at its segment anchor
	bill_visual.global_position = segment_positions[0]
	head_visual.global_position = segment_positions[1]
	body_visual.global_position = segment_positions[2]
	tail_visual.global_position = segment_positions[3]

	# Rotate segments to face the next segment
	bill_visual.rotation = head_angle
	head_visual.rotation = _angle_between(segment_positions[1], segment_positions[0])
	body_visual.rotation = _angle_between(segment_positions[2], segment_positions[1])
	tail_visual.rotation = _angle_between(segment_positions[3], segment_positions[2])

	# Move bill collision area to bill tip
	bill_area.global_position = segment_positions[0]
	bill_area.rotation = head_angle

func _angle_between(from: Vector2, to: Vector2) -> float:
	return (to - from).angle()

# ── Piercing ──────────────────────────────────────────────────────────────────
func _on_bill_hit(body: Node) -> void:
	if is_piercing:
		return
	if not body.is_in_group("fish_body"):
		return
	var victim_fish: Node2D = body.get_parent()
	if victim_fish == self:
		return
	_stick_to(victim_fish)

func _on_bill_hit_area(area: Area2D) -> void:
	if is_piercing:
		return
	if not area.is_in_group("fish_body_area"):
		return
	var victim_fish: Node2D = area.get_parent()
	if victim_fish == self:
		return
	_stick_to(victim_fish)

func _stick_to(victim: Node2D) -> void:
	is_piercing = true
	pierce_victim = victim

	# Transfer momentum: push victim with our velocity
	if victim.has_method("receive_impact"):
		victim.receive_impact(velocity * 0.7)

	# Create a PinJoint2D linking us
	var joint := PinJoint2D.new()
	get_tree().root.add_child(joint)
	joint.global_position = segment_positions[0]  # bill tip
	joint.node_a = get_path()
	joint.node_b = victim.get_path()
	joint.softness = 0.5
	pierce_joint = joint

	print("Fish %d pierced fish!" % device_id)

func _unstick() -> void:
	is_piercing = false
	pierce_victim = null
	if pierce_joint and is_instance_valid(pierce_joint):
		pierce_joint.queue_free()
	pierce_joint = null

func receive_impact(impulse: Vector2) -> void:
	velocity += impulse
	velocity = velocity.limit_length(max_speed * 1.5)  # allow brief overspeed on hit
