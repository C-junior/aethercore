## BenchUI - Displays owned spirits not currently on the battle grid
## Players click spirits to select, then click grid slot to place.
class_name BenchUI
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when a spirit is selected from bench
signal spirit_selected(spirit_data: SpiritData)

## Emitted when spirit selection is cleared
signal selection_cleared

## Emitted when mouse hovers over a spirit
signal spirit_hovered(spirit_data: SpiritData, screen_pos: Vector2)

## Emitted when mouse leaves a spirit
signal spirit_unhovered


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

## Currently selected spirit for placement
var selected_spirit: SpiritData = null
var selected_slot_index: int = -1

## Pending item to equip (from item inventory)
var pending_item: ItemData = null


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_bench_slots()
	visible = false
	
	# Connect to item selection events
	EventBus.item_selected.connect(_on_item_selected)
	EventBus.item_equipped.connect(_on_item_equipped)


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
	
	# Make clickable and hoverable
	panel.gui_input.connect(_on_slot_gui_input.bind(index))
	panel.mouse_entered.connect(_on_slot_mouse_entered.bind(index))
	panel.mouse_exited.connect(_on_slot_mouse_exited.bind(index))
	
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
			# Show held item icon if present
			var item_icon: String = ""
			if spirit_data.held_item:
				var item: ItemData = spirit_data.held_item as ItemData
				if item:
					item_icon = item.get_icon_emoji() + " "
			name_label.text = item_icon + spirit_data.display_name
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
				# If an item is pending, equip it to this spirit
				if pending_item:
					GameManager.equip_item_to_spirit(pending_item, spirit)
					return
				
				# Toggle selection
				if selected_spirit == spirit:
					# Deselect
					clear_selection()
				else:
					# Select this spirit
					select_spirit(spirit, slot_index)


func _on_slot_mouse_entered(slot_index: int) -> void:
	# Visual hover feedback (only if not selected)
	if slot_index < slots_container.get_child_count() and slot_index != selected_slot_index:
		var slot: PanelContainer = slots_container.get_child(slot_index)
		var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()
		style.border_color = Color(0.5, 0.5, 0.6, 1.0)
		slot.add_theme_stylebox_override("panel", style)
	
	# Emit hover signal for spirit info UI
	var spirit: SpiritData = bench_slots[slot_index] if slot_index < bench_slots.size() else null
	if spirit:
		var slot_node: PanelContainer = slots_container.get_child(slot_index)
		var screen_pos: Vector2 = slot_node.global_position + slot_node.size / 2
		spirit_hovered.emit(spirit, screen_pos)


func _on_slot_mouse_exited(slot_index: int) -> void:
	# Reset visual if not selected
	if slot_index < slots_container.get_child_count() and slot_index != selected_slot_index:
		_reset_slot_style(slot_index)
	
	# Emit unhover signal
	spirit_unhovered.emit()


## Select a spirit for placement
func select_spirit(spirit_data: SpiritData, slot_index: int) -> void:
	# Clear previous selection visual
	if selected_slot_index >= 0 and selected_slot_index < slots_container.get_child_count():
		_reset_slot_style(selected_slot_index)
	
	selected_spirit = spirit_data
	selected_slot_index = slot_index
	
	# Highlight selected slot
	if slot_index < slots_container.get_child_count():
		var slot: PanelContainer = slots_container.get_child(slot_index)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.3, 0.4, 0.9)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.3, 0.8, 0.3, 1.0)  # Green border for selected
		slot.add_theme_stylebox_override("panel", style)
	
	spirit_selected.emit(spirit_data)
	
	# Update title to show selected
	if title_label:
		title_label.text = "🎒 Bench - Selected: %s (click grid slot to place)" % spirit_data.display_name


## Clear selection
func clear_selection() -> void:
	if selected_slot_index >= 0 and selected_slot_index < slots_container.get_child_count():
		_reset_slot_style(selected_slot_index)
	
	selected_spirit = null
	selected_slot_index = -1
	selection_cleared.emit()
	update_bench()


func _reset_slot_style(slot_index: int) -> void:
	if slot_index >= slots_container.get_child_count():
		return
	var slot: PanelContainer = slots_container.get_child(slot_index)
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
	slot.add_theme_stylebox_override("panel", style)


## Place the selected spirit on the grid
func place_on_grid(grid_slot: int) -> void:
	if not selected_spirit:
		return
	
	# Remove from bench
	for i in bench_slots.size():
		if bench_slots[i] == selected_spirit:
			bench_slots[i] = null
			_update_slot_visual(i, null)
			break
	
	# Add to grid_spirits
	if grid_slot >= 0 and grid_slot < GameManager.grid_spirits.size():
		GameManager.grid_spirits[grid_slot] = selected_spirit
	
	# Clear selection
	clear_selection()


## Return a spirit from grid to bench
func return_to_bench(spirit_data: SpiritData, from_grid_slot: int) -> void:
	# Remove from grid
	if from_grid_slot >= 0 and from_grid_slot < GameManager.grid_spirits.size():
		GameManager.grid_spirits[from_grid_slot] = null
	
	update_bench()


# =============================================================================
# ITEM EQUIP HANDLERS
# =============================================================================

func _on_item_selected(item: Resource) -> void:
	if item:
		pending_item = item as ItemData
		# Update title to show item equip mode
		if title_label:
			title_label.text = "🎒 Bench - Click spirit to equip: %s" % pending_item.display_name
	else:
		pending_item = null
		update_bench()


func _on_item_equipped(_item: Resource, _spirit: Resource) -> void:
	# Clear pending item and refresh
	pending_item = null
	update_bench()
