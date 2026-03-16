extends Node2D

@onready var score_label: Label = $ScoreLabel

var current_perks: Array = []
var current_player_index: int = 0  # which player is currently picking
var hovered_card: int = 1          # start on middle card
var selection_order: Array = []    # device_ids in pick order
@onready var cards: Array = [$Card0, $Card1, $Card2]
var selected_cards: Dictionary = {}  # device_id : card_index

func _ready() -> void:
	var text := "SCORES\n\n"
	var sorted := GameState.get_sorted_scores()
	for device_id in sorted:
		var score: int = GameState.scores[device_id]
		text += "Player %d : %d\n" % [device_id + 1, score]
	score_label.text = text
	
	selection_order = GameState.get_sorted_scores()
	print("selection order: ", selection_order)
	_highlight_card(hovered_card)
	_deal_cards()

func _deal_cards() -> void:
	var perk_paths := PerkRegistry.get_random_perks(3)
	current_perks.clear()
	
	for i in 3:
		# Remove old card if present
		if cards[i].get_child_count() > 0:
			cards[i].get_child(0).queue_free()
		
		# Instance new perk card
		var perk_scene: PackedScene = load(perk_paths[i])
		var perk_instance = perk_scene.instantiate()
		perk_instance.set_meta("perk_path", perk_paths[i])
		cards[i].add_child(perk_instance)
		current_perks.append(perk_instance)

func _highlight_card(index: int) -> void:
	for i in cards.size():
		var scale := Vector2(1.2, 1.2) if i == index else Vector2(1.0, 1.0)
		cards[i].scale = scale

func _input(event: InputEvent) -> void:
	if selection_order.is_empty() or current_player_index >= selection_order.size():
		return
	var current_device: int = selection_order[current_player_index]
	
	if event is InputEventKey and event.pressed and not event.echo:
		# Only keyboard player can control if it's their turn
		if current_device == -1:
			if event.keycode == KEY_A:
				hovered_card = max(0, hovered_card - 1)
				_highlight_card(hovered_card)
			if event.keycode == KEY_D:
				hovered_card = min(cards.size() - 1, hovered_card + 1)
				_highlight_card(hovered_card)
			if event.keycode == KEY_SPACE:
				_select_card(current_device)

	if event is InputEventJoypadButton and event.pressed:
		# Only the current player's controller can act
		if event.device == current_device:
			if event.button_index == JOY_BUTTON_DPAD_LEFT:
				hovered_card = max(0, hovered_card - 1)
				_highlight_card(hovered_card)
			if event.button_index == JOY_BUTTON_DPAD_RIGHT:
				hovered_card = min(cards.size() - 1, hovered_card + 1)
				_highlight_card(hovered_card)
			if event.button_index == JOY_BUTTON_A:
				_select_card(current_device)

func _select_card(device_id: int) -> void:
	print("selecting card for device: ", device_id, " card index: ", hovered_card)
	print("selection order: ", selection_order)
	print("current player index: ", current_player_index)
	selected_cards[device_id] = hovered_card
	var chosen_perk = current_perks[hovered_card]
	print("scene_file_path: ", chosen_perk.scene_file_path)
	PlayerData.pending_perks[device_id] = chosen_perk.perk_name
	print("player ", device_id, " selected: ", chosen_perk.perk_name)
	current_player_index += 1
	hovered_card = 1
	PlayerData.pending_perks[device_id] = chosen_perk.get_meta("perk_path")
	_highlight_card(hovered_card)
	_deal_cards()  # new cards for next player
	
	if current_player_index >= selection_order.size():
		_continue()

func _continue() -> void:
	get_tree().change_scene_to_file("res://scenes/Gym_OLI.tscn")
