## BenchUI - Displays owned spirits not currently on the battle grid
## Players drag spirits between bench and grid during preparation.
class_name BenchUI
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when a spirit is dragged from bench
signal spirit_drag_started(spirit_data: SpiritData, slot_index: int)

## Emitted when a spirit is dropped on a slot
signal spirit_dropped_on_grid(spirit_data: SpiritData, grid_slot: int)


# =============================================================================
# CONFIGURATION
# =============================================================================

@export var max_bench_slots: int = 8
@export var slot_size: Vector2 = Vector2(70, 90)


# =============================================================================
# NODES
# =============================================================================

@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var title_label: Label = $TitleLabel


# =============================================================================
# STATE
# =============================================================================

## Spirit slots on bench (parallel to visual slots)
var bench_slots: Array = []

## Currently dragged spirit data
var dragged_spirit: SpiritData = null
var dragged_from_slot: int = -1


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_bench_slots()
	visible = false


func _create_bench_slots() -> void:
	if not slots_container:
		return
	
	# Clear existing slots
	for child in slots_container.get_children():
		child.queue_free()
	
	bench_slots.clear()
	
	# Create slot panels
	for i in max_bench_slots:
		var slot := _create_slot(i)
		slots_container.add_child(slot)
		bench_slots.append(null)


func _create_slot(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Slot_%d" % index
	panel.custom_minimum_size = slot_size
	
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	panel.add_theme_stylebox_override("panel", style)
	
	# Content container
	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	
	# Portrait placeholder
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(50, 50)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vbox.add_child(portrait)
	
	# Name label
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)
	
	# Make clickable for drag
	panel.gui_input.connect(_on_slot_gui_input.bind(index))
	panel.mouse_entered.connect(_on_slot_mouse_entered.bind(index))
	
	return panel


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Update bench to show owned spirits not on grid
func update_bench() -> void:
	# Get spirits that are NOT on the grid
	var available_spirits: Array[SpiritData] = []
	for spirit in GameManager.owned_spirits:
		if spirit and spirit not in GameManager.grid_spirits:
			available_spirits.append(spirit as SpiritData)
	
	# Clear all slots first
	for i in max_bench_slots:
		bench_slots[i] = null
		_update_slot_visual(i, null)
	
	# Fill slots with available spirits
	for i in mini(available_spirits.size(), max_bench_slots):
		bench_slots[i] = available_spirits[i]
		_update_slot_visual(i, available_spirits[i])
	
	# Update title
	if title_label:
		title_label.text = "🎒 Bench (%d/%d)" % [available_spirits.size(), max_bench_slots]


## Show the bench
func show_bench() -> void:
	visible = true
	update_bench()


## Hide the bench
func hide_bench() -> void:
	visible = false


# =============================================================================
# VISUAL UPDATES
# =============================================================================

func _update_slot_visual(slot_index: int, spirit_data: SpiritData) -> void:
	if slot_index >= slots_container.get_child_count():
		return
	
	var slot: PanelContainer = slots_container.get_child(slot_index)
	var content: VBoxContainer = slot.get_node_or_null("Content")
	if not content:
		return
	
	var portrait: TextureRect = content.get_node_or_null("Portrait")
	var name_label: Label = content.get_node_or_null("NameLabel")
	
	if spirit_data:
		if portrait and spirit_data.portrait:
			portrait.texture = spirit_data.portrait
		if name_label:
			name_label.text = spirit_data.display_name
	else:
		if portrait:
			portrait.texture = null
		if name_label:
			name_label.text = ""


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var spirit: SpiritData = bench_slots[slot_index]
			if spirit:
				# Start drag
				dragged_spirit = spirit
				dragged_from_slot = slot_index
				spirit_drag_started.emit(spirit, slot_index)


func _on_slot_mouse_entered(slot_index: int) -> void:
	# Visual hover feedback
	if slot_index < slots_container.get_child_count():
		var slot: PanelContainer = slots_container.get_child(slot_index)
		var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()
		style.border_color = Color(0.5, 0.5, 0.6, 1.0)
		slot.add_theme_stylebox_override("panel", style)


## Place a spirit on the grid from bench
func place_on_grid(spirit_data: SpiritData, grid_slot: int) -> void:
	# Remove from bench
	for i in bench_slots.size():
		if bench_slots[i] == spirit_data:
			bench_slots[i] = null
			_update_slot_visual(i, null)
			break
	
	# Add to grid_spirits
	if grid_slot >= 0 and grid_slot < GameManager.grid_spirits.size():
		GameManager.grid_spirits[grid_slot] = spirit_data
	
	spirit_dropped_on_grid.emit(spirit_data, grid_slot)
	update_bench()


## Return a spirit from grid to bench
func return_to_bench(spirit_data: SpiritData, from_grid_slot: int) -> void:
	# Remove from grid
	if from_grid_slot >= 0 and from_grid_slot < GameManager.grid_spirits.size():
		GameManager.grid_spirits[from_grid_slot] = null
	
	update_bench()
