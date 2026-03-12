extends PanelContainer

@export var perk_name: String = "Perk Name"
@export var perk_description: String = "Perk Description"

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

func _ready() -> void:
	name_label.text = perk_name
	description_label.text = perk_description

func apply(fish: CharacterBody2D) -> void:
	pass  # override in child scenes
