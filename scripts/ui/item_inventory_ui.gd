## ItemInventoryUI - Displays player's item inventory during preparation
## Players click items to select, then click spirits to equip them.
class_name ItemInventoryUI
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when an item is selected for equipping
signal item_selected(item_data: ItemData)

## Emitted when selection is cleared
signal selection_cleared


# =============================================================================
# CONFIGURATION
# =============================================================================

## Maximum item slots to display
@export var max_slots: int = 6

## Size of each item slot
@export var slot_size: Vector2 = Vector2(60, 60)


# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var title_label: Label = %TitleLabel
@onready var slots_container: HBoxContainer = %SlotsContainer


# =============================================================================
# STATE
# =============================================================================

## Currently selected item for equipping
var selected_item: ItemData = null
var selected_slot_index: int = -1


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_item_slots()
	visible = false
	
	# Connect to phase changes
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.item_equipped.connect(_on_item_equipped)


func _create_item_slots() -> void:
	# Clear existing slots
	if slots_container:
		for child in slots_container.get_children():
			child.queue_free()
	
	# Create slot panels
	for i in max_slots:
		var slot := _create_slot(i)
		slots_container.add_child(slot)


func _create_slot(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ItemSlot_%d" % index
	panel.custom_minimum_size = slot_size
	
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.5, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	
	# Content layout
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	# Item icon (emoji for now)
	var icon_label := Label.new()
	icon_label.name = "IconLabel"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(icon_label)
	
	# Item name
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1.0))
	vbox.add_child(name_label)
	
	# Make clickable
	panel.gui_input.connect(_on_slot_gui_input.bind(index))
	panel.mouse_entered.connect(_on_slot_mouse_entered.bind(index))
	panel.mouse_exited.connect(_on_slot_mouse_exited.bind(index))
	
	return panel


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Update inventory display from GameManager
func update_inventory() -> void:
	var items: Array = GameManager.item_inventory
	
	for i in max_slots:
		if i < slots_container.get_child_count():
			var slot: PanelContainer = slots_container.get_child(i)
			
			if i < items.size() and items[i] != null:
				_update_slot_visual(slot, items[i] as ItemData)
			else:
				_clear_slot_visual(slot)


## Show the inventory UI
func show_inventory() -> void:
	update_inventory()
	visible = true


## Hide the inventory UI
func hide_inventory() -> void:
	clear_selection()
	visible = false


## Clear current item selection
func clear_selection() -> void:
	if selected_slot_index >= 0 and selected_slot_index < slots_container.get_child_count():
		_reset_slot_style(selected_slot_index)
	
	selected_item = null
	selected_slot_index = -1
	selection_cleared.emit()
	EventBus.item_selected.emit(null)


# =============================================================================
# VISUAL UPDATES
# =============================================================================

func _update_slot_visual(slot: PanelContainer, item: ItemData) -> void:
	var vbox: VBoxContainer = slot.get_child(0) as VBoxContainer
	if not vbox:
		return
	
	var icon_label: Label = vbox.get_node_or_null("IconLabel")
	var name_label: Label = vbox.get_node_or_null("NameLabel")
	
	if icon_label:
		icon_label.text = item.get_icon_emoji()
	
	if name_label:
		# Truncate long names
		var display_name: String = item.display_name
		if display_name.length() > 8:
			display_name = display_name.substr(0, 7) + "…"
		name_label.text = display_name


func _clear_slot_visual(slot: PanelContainer) -> void:
	var vbox: VBoxContainer = slot.get_child(0) as VBoxContainer
	if not vbox:
		return
	
	var icon_label: Label = vbox.get_node_or_null("IconLabel")
	var name_label: Label = vbox.get_node_or_null("NameLabel")
	
	if icon_label:
		icon_label.text = ""
	
	if name_label:
		name_label.text = ""


func _reset_slot_style(slot_index: int) -> void:
	if slot_index >= slots_container.get_child_count():
		return
	
	var slot: PanelContainer = slots_container.get_child(slot_index)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.5, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)


func _highlight_slot(slot_index: int, color: Color) -> void:
	if slot_index >= slots_container.get_child_count():
		return
	
	var slot: PanelContainer = slots_container.get_child(slot_index)
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	slot.add_theme_stylebox_override("panel", style)


# =============================================================================
# INPUT HANDLERS
# =============================================================================

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var items: Array = GameManager.item_inventory
			
			if slot_index < items.size() and items[slot_index] != null:
				var item: ItemData = items[slot_index] as ItemData
				
				# Toggle selection
				if selected_item == item:
					clear_selection()
				else:
					_select_item(item, slot_index)


func _on_slot_mouse_entered(slot_index: int) -> void:
	# Hover effect (only if not selected)
	if slot_index != selected_slot_index:
		var items: Array = GameManager.item_inventory
		if slot_index < items.size() and items[slot_index] != null:
			_highlight_slot(slot_index, Color(0.6, 0.55, 0.7, 1.0))


func _on_slot_mouse_exited(slot_index: int) -> void:
	# Reset hover (only if not selected)
	if slot_index != selected_slot_index:
		_reset_slot_style(slot_index)


func _select_item(item: ItemData, slot_index: int) -> void:
	# Clear previous selection
	if selected_slot_index >= 0:
		_reset_slot_style(selected_slot_index)
	
	selected_item = item
	selected_slot_index = slot_index
	
	# Highlight selected slot
	_highlight_slot(slot_index, Color(0.9, 0.7, 0.3, 1.0))  # Gold highlight
	
	# Emit signals
	item_selected.emit(item)
	EventBus.item_selected.emit(item)
	
	print("[ItemInventoryUI] Selected item: %s" % item.display_name)


# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_phase_changed(new_phase: Enums.GamePhase, _old_phase: Enums.GamePhase) -> void:
	match new_phase:
		Enums.GamePhase.PREPARATION:
			show_inventory()
		Enums.GamePhase.BATTLE, Enums.GamePhase.MAP_SELECTION:
			hide_inventory()


func _on_item_equipped(item: Resource, _spirit: Resource) -> void:
	# Clear selection after equip
	if item == selected_item:
		clear_selection()
	
	# Refresh display
	update_inventory()
