extends "res://scripts/Perks/perk_card.gd"

func _ready() -> void:
	perk_name = "Side Armor"
	perk_description = "Add armored plates to the side of your fish"
	border_color = Color(0.642, 0.65, 0.632, 1.0)
	super._ready()  # call parent _ready to apply the name/description to labels

func apply(fish: CharacterBody2D) -> void:
	print("applying armor perk")
	fish.has_side_armor = true
	fish.armor_area.monitoring = true
	fish.armor_area.monitorable = true
	fish.armor_visual.visible = true
