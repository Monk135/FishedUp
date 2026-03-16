extends "res://scripts/Perks/perk_card.gd"

func _ready() -> void:
	perk_name = "Health Increase"
	perk_description = "Increases Health by 50%"
	border_color = Color(0.0, 0.627, 0.21, 1.0)
	super._ready()  # call parent _ready to apply the name/description to labels

func apply(fish: CharacterBody2D) -> void:
	fish.max_health *= 1.5
	fish.health *= 1.5
	fish.refresh_health_bar()
#UI doesnt represent correct health
