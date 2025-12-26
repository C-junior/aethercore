## SynergyUI - Displays active synergies on the left side of the screen
## Shows element icons, tier levels, and bonus descriptions.
class_name SynergyUI
extends Control


# =============================================================================
# CONSTANTS
# =============================================================================

const ENTRY_HEIGHT: int = 60
const PANEL_WIDTH: int = 200
const TIER_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6, 1.0),    # Inactive (gray)
	Color(0.7, 0.5, 0.2, 1.0),    # Tier 1 (bronze)
	Color(0.7, 0.7, 0.8, 1.0),    # Tier 2 (silver)
	Color(1.0, 0.85, 0.0, 1.0),   # Tier 3 (gold)
]


# =============================================================================
# NODES
# =============================================================================

var title_label: Label
var synergy_container: VBoxContainer
var panel: PanelContainer


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	# Initial update
	call_deferred("_update_display", {})


func _setup_ui() -> void:
	# Main panel
	panel = PanelContainer.new()
	panel.name = "SynergyPanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 200)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# Content container
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "⚔️ SYNERGIES"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Separator
	var separator := HSeparator.new()
	vbox.add_child(separator)
	
	# Synergy entries container
	synergy_container = VBoxContainer.new()
	synergy_container.name = "SynergyContainer"
	synergy_container.add_theme_constant_override("separation", 4)
	vbox.add_child(synergy_container)
	
	# Position on left side
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	position = Vector2(0, 150)


func _connect_signals() -> void:
	if is_instance_valid(SynergyManager):
		SynergyManager.synergies_changed.connect(_update_display)


# =============================================================================
# DISPLAY UPDATE
# =============================================================================

func _update_display(active_synergies: Dictionary) -> void:
	# Clear existing entries
	for child in synergy_container.get_children():
		child.queue_free()
	
	# If no synergies, show hint
	if active_synergies.is_empty():
		var hint := Label.new()
		hint.text = "Build element teams\nfor bonuses!"
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		synergy_container.add_child(hint)
		return
	
	# Create entry for each active synergy
	for element in active_synergies:
		var tier: int = active_synergies[element]
		var data: SynergyData = SynergyManager.get_synergy_for_element(element)
		if data:
			var entry := _create_synergy_entry(data, tier)
			synergy_container.add_child(entry)


func _create_synergy_entry(data: SynergyData, tier: int) -> Control:
	var entry := HBoxContainer.new()
	entry.custom_minimum_size = Vector2(0, ENTRY_HEIGHT)
	
	# Icon and tier indicator
	var icon_container := VBoxContainer.new()
	icon_container.custom_minimum_size = Vector2(40, 0)
	
	var icon := Label.new()
	icon.text = data.icon_emoji
	icon.add_theme_font_size_override("font_size", 24)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_container.add_child(icon)
	
	# Tier pips
	var tier_pips := HBoxContainer.new()
	tier_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var pip := Label.new()
		pip.text = "●" if i < tier else "○"
		pip.add_theme_font_size_override("font_size", 8)
		pip.add_theme_color_override("font_color", TIER_COLORS[tier] if i < tier else TIER_COLORS[0])
		tier_pips.add_child(pip)
	icon_container.add_child(tier_pips)
	
	entry.add_child(icon_container)
	
	# Synergy info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", TIER_COLORS[tier])
	info.add_child(name_label)
	
	var bonus_label := Label.new()
	bonus_label.text = data.get_tier_description(tier)
	bonus_label.add_theme_font_size_override("font_size", 10)
	bonus_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(bonus_label)
	
	entry.add_child(info)
	
	return entry


# =============================================================================
# VISIBILITY CONTROL
# =============================================================================

## Show the synergy panel
func show_panel() -> void:
	visible = true


## Hide the synergy panel
func hide_panel() -> void:
	visible = false


## Set panel visibility based on game phase
func update_visibility_for_phase(phase: Enums.GamePhase) -> void:
	match phase:
		Enums.GamePhase.PREPARATION, Enums.GamePhase.BATTLE:
			show_panel()
		_:
			hide_panel()
