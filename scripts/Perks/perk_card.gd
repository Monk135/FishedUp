extends PanelContainer

@export var perk_name: String = "Perk Name"
@export var perk_description: String = "Perk Description"
@export var card_image: Texture2D
@export var border_color: Color = Color.WHITE:
	set(value):
		border_color = value
		_apply_style()

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var card_image_rect: TextureRect = $VBoxContainer/CardImage

func _ready() -> void:
	name_label.text = perk_name
	description_label.text = perk_description
	if card_image:
		card_image_rect.texture = card_image
	_apply_style()

func apply(fish: CharacterBody2D) -> void:
	pass  # override in child scenes

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
