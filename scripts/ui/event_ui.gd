## EventUI - Displays random event encounters with choices
## Presents narrative text and multiple choice buttons with outcomes.
class_name EventUI
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

signal event_completed(choice_index: int)


# =============================================================================
# STATE
# =============================================================================

var current_event: EventData = null
var event_pool: Array[EventData] = []
var used_one_time_events: Array[String] = []


# =============================================================================
# NODES
# =============================================================================

var panel: PanelContainer
var icon_label: Label
var title_label: Label
var description_label: Label
var choices_container: VBoxContainer
var outcome_label: Label


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_load_event_pool()
	_setup_ui()
	visible = false


func _load_event_pool() -> void:
	var events_dir: String = "res://resources/events/"
	var dir := DirAccess.open(events_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path: String = events_dir + file_name
				var event: EventData = load(path) as EventData
				if event:
					event_pool.append(event)
					print("[EventUI] Loaded event: %s" % event.title)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	print("[EventUI] Loaded %d events" % event_pool.size())


func _setup_ui() -> void:
	# Main panel
	panel = PanelContainer.new()
	panel.name = "EventPanel"
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.5, 0.35, 0.6, 1.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# Center the panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(550, 450)
	panel.position = Vector2(-275, -225)
	
	# Content margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Icon
	icon_label = Label.new()
	icon_label.text = "❓"
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)
	
	# Title
	title_label = Label.new()
	title_label.text = "EVENT TITLE"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Description
	description_label = Label.new()
	description_label.text = "Event description goes here..."
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(description_label)
	
	# Choices container
	choices_container = VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 10)
	vbox.add_child(choices_container)
	
	# Outcome label (hidden initially)
	outcome_label = Label.new()
	outcome_label.text = ""
	outcome_label.add_theme_font_size_override("font_size", 14)
	outcome_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.7))
	outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome_label.visible = false
	vbox.add_child(outcome_label)


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func show_random_event() -> void:
	var event: EventData = _pick_random_event()
	if event:
		show_event(event)
	else:
		# No event available, complete immediately with no-op
		push_warning("[EventUI] No events available for current act!")
		event_completed.emit(-1)


func show_event(event: EventData) -> void:
	current_event = event
	
	# Update UI
	icon_label.text = event.icon
	title_label.text = event.title
	description_label.text = event.description
	description_label.visible = true
	outcome_label.visible = false
	
	# Clear and rebuild choices
	for child in choices_container.get_children():
		child.queue_free()
	
	for i in event.choices.size():
		var choice_button := Button.new()
		choice_button.text = event.get_choice_text(i)
		choice_button.add_theme_font_size_override("font_size", 14)
		choice_button.custom_minimum_size = Vector2(0, 45)
		choice_button.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(choice_button)
	
	visible = true


func hide_event() -> void:
	visible = false
	current_event = null


# =============================================================================
# EVENT SELECTION
# =============================================================================

func _pick_random_event() -> EventData:
	var current_act: int = GameManager.current_act
	var available: Array[EventData] = []
	var total_weight: float = 0.0
	
	for event in event_pool:
		# Check act requirements
		if current_act < event.min_act or current_act > event.max_act:
			continue
		
		# Check one-time events
		if event.one_time and event.id in used_one_time_events:
			continue
		
		available.append(event)
		total_weight += event.weight
	
	if available.is_empty():
		return null
	
	# Weighted random selection
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	
	for event in available:
		cumulative += event.weight
		if roll <= cumulative:
			return event
	
	return available.back()


# =============================================================================
# CHOICE HANDLING
# =============================================================================

func _on_choice_pressed(choice_index: int) -> void:
	if not current_event or choice_index >= current_event.choices.size():
		return
	
	# Get effects
	var effects: Dictionary = current_event.get_choice_effects(choice_index)
	
	# Apply effects
	_apply_effects(effects)
	
	# Mark one-time event as used
	if current_event.one_time:
		used_one_time_events.append(current_event.id)
	
	# Show outcome
	outcome_label.text = current_event.get_outcome_text(choice_index)
	outcome_label.visible = true
	description_label.visible = false
	
	# Hide choice buttons
	for child in choices_container.get_children():
		child.visible = false
	
	# Wait and complete
	await get_tree().create_timer(2.0).timeout
	event_completed.emit(choice_index)
	hide_event()


func _apply_effects(effects: Dictionary) -> void:
	# Gold
	if effects.has("gold"):
		var gold_change: int = effects["gold"]
		GameManager.gold += gold_change
		print("[EventUI] Gold change: %+d" % gold_change)
	
	# XP to all spirits
	if effects.has("xp"):
		var xp_amount: int = effects["xp"]
		for spirit in GameManager.owned_spirits:
			var spirit_data: SpiritData = spirit as SpiritData
			if spirit_data:
				spirit_data.add_xp(xp_amount)
		print("[EventUI] XP awarded to all spirits: %d" % xp_amount)
	
	# Heal spirits
	if effects.has("heal_percent"):
		var heal_pct: float = effects["heal_percent"]
		print("[EventUI] Healing spirits by %d%%" % int(heal_pct * 100))
		# Note: Actual healing happens on Spirit nodes at battle start
	
	# Damage spirits
	if effects.has("damage_percent"):
		var damage_pct: float = effects["damage_percent"]
		print("[EventUI] Damaging spirits by %d%%" % int(damage_pct * 100))
		# Note: Actual damage happens on Spirit nodes at battle start
	
	# Give item
	if effects.has("item_id"):
		var item_id: String = effects["item_id"]
		var item_path: String = "res://resources/items/%s.tres" % item_id
		if ResourceLoader.exists(item_path):
			var item: Resource = load(item_path)
			if item:
				GameManager.add_item_to_inventory(item)
				print("[EventUI] Item granted: %s" % item_id)
	
	# Give random spirit
	if effects.has("spirit_element"):
		var element: int = effects["spirit_element"]
		var spirit: Resource = GameManager.get_spirit_by_element(element as Enums.Element)
		if spirit:
			var spirit_copy := (spirit as SpiritData).duplicate_spirit()
			GameManager.owned_spirits.append(spirit_copy)
			print("[EventUI] Spirit granted: %s" % spirit_copy.display_name)
	
	# Remove spirit
	if effects.has("remove_spirit") and effects["remove_spirit"]:
		# Remove a random bench spirit (not on grid)
		var bench_spirits: Array = []
		for spirit in GameManager.owned_spirits:
			if spirit and spirit not in GameManager.grid_spirits:
				bench_spirits.append(spirit)
		
		if bench_spirits.size() > 0:
			var to_remove: Resource = bench_spirits.pick_random()
			GameManager.owned_spirits.erase(to_remove)
			print("[EventUI] Spirit sacrificed: %s" % to_remove.get("display_name"))
		else:
			# No bench spirits, sacrifice from grid
			for i in range(GameManager.grid_spirits.size() - 1, -1, -1):
				if GameManager.grid_spirits[i]:
					var sacrificed: Resource = GameManager.grid_spirits[i]
					GameManager.grid_spirits[i] = null
					GameManager.owned_spirits.erase(sacrificed)
					print("[EventUI] Grid spirit sacrificed: %s" % sacrificed.get("display_name"))
					break


# =============================================================================
# RUN MANAGEMENT
# =============================================================================

func reset_for_new_run() -> void:
	used_one_time_events.clear()
