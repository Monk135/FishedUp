extends "res://scripts/Perks/perk_card.gd"

func _ready() -> void:
	perk_name = "Big Bill"
	perk_description = "Increases Bill Lenght"
	border_color = Color(1.0, 0.624, 0.942, 1.0)
	super._ready()  # call parent _ready to apply the name/description to labels

func apply(fish: CharacterBody2D) -> void:
	fish.bill_length_multiplier += 0.5
	fish.get_node("BillVisual").scale.x *= 1.5
	var col := fish.get_node("HurtArea/CollisionShape2D")
	col.shape = col.shape.duplicate()  # make unique copy
	var shape := col.shape as RectangleShape2D
	shape.size.x *= 2.25
