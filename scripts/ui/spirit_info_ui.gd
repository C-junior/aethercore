## SpiritInfoUI - Tooltip/panel showing spirit details
## Displays stats, XP progress, equipped item, and ability info.
class_name SpiritInfoUI
extends PanelContainer


# =============================================================================
# NODES
# =============================================================================

@onready var name_label: Label = $MarginContainer/VBoxContainer/HeaderContainer/NameLabel
@onready var tier_label: Label = $MarginContainer/VBoxContainer/HeaderContainer/TierLabel
@onready var element_label: Label = $MarginContainer/VBoxContainer/HeaderContainer/ElementLabel

@onready var hp_label: Label = $MarginContainer/VBoxContainer/StatsContainer/HPLabel
@onready var atk_label: Label = $MarginContainer/VBoxContainer/StatsContainer/ATKLabel
@onready var spd_label: Label = $MarginContainer/VBoxContainer/StatsContainer/SPDLabel

@onready var xp_label: Label = $MarginContainer/VBoxContainer/XPContainer/XPLabel
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/XPContainer/XPProgressBar

@onready var item_container: Control = $MarginContainer/VBoxContainer/ItemContainer
@onready var item_icon_label: Label = $MarginContainer/VBoxContainer/ItemContainer/ItemIconLabel
@onready var item_name_label: Label = $MarginContainer/VBoxContainer/ItemContainer/ItemNameLabel

@onready var ability_container: Control = $MarginContainer/VBoxContainer/AbilityContainer
@onready var ability_name_label: Label = $MarginContainer/VBoxContainer/AbilityContainer/AbilityNameLabel
@onready var ability_desc_label: Label = $MarginContainer/VBoxContainer/AbilityContainer/AbilityDescLabel


# =============================================================================
# STATE
# =============================================================================

## Currently displayed spirit
var current_spirit: SpiritData = null


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.5, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", style)


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Show info for a spirit
func show_spirit_info(spirit_data: SpiritData, screen_position: Vector2 = Vector2.ZERO) -> void:
	if not spirit_data:
		hide_info()
		return
	
	current_spirit = spirit_data
	_update_display()
	
	# Position near the given screen position
	if screen_position != Vector2.ZERO:
		_position_near(screen_position)
	
	visible = true


## Hide the info panel
func hide_info() -> void:
	current_spirit = null
	visible = false


## Update display for current spirit (call when stats change)
func refresh() -> void:
	if current_spirit:
		_update_display()


# =============================================================================
# DISPLAY UPDATE
# =============================================================================

func _update_display() -> void:
	if not current_spirit:
		return
	
	# Header
	if name_label:
		name_label.text = current_spirit.display_name
	
	if tier_label:
		tier_label.text = current_spirit.get_tier_string()
	
	if element_label:
		element_label.text = current_spirit.get_element_emoji()
	
	# Stats (show bonus in parentheses if item equipped)
	_update_stat_labels()
	
	# XP Progress
	if xp_label:
		if current_spirit.evolves_into:
			xp_label.text = "XP: %d / %d" % [current_spirit.current_xp, current_spirit.xp_to_evolve]
		else:
			xp_label.text = "XP: MAX"
	
	if xp_bar:
		xp_bar.value = current_spirit.get_xp_progress() * 100.0
		xp_bar.visible = current_spirit.evolves_into != null
	
	# Item
	_update_item_display()
	
	# Ability
	_update_ability_display()


func _update_stat_labels() -> void:
	var item: ItemData = current_spirit.held_item as ItemData if current_spirit.held_item else null
	
	# HP
	if hp_label:
		var effective_hp: int = current_spirit.get_effective_hp()
		if item and item.hp_bonus > 0:
			hp_label.text = "❤️ HP: %d (+%d)" % [effective_hp, item.hp_bonus]
			hp_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			hp_label.text = "❤️ HP: %d" % effective_hp
			hp_label.remove_theme_color_override("font_color")
	
	# ATK
	if atk_label:
		var effective_atk: int = current_spirit.get_effective_attack()
		if item and item.attack_bonus > 0:
			atk_label.text = "⚔️ ATK: %d (+%d)" % [effective_atk, item.attack_bonus]
			atk_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
		else:
			atk_label.text = "⚔️ ATK: %d" % effective_atk
			atk_label.remove_theme_color_override("font_color")
	
	# SPD
	if spd_label:
		var effective_spd: float = current_spirit.get_effective_speed()
		if item and item.speed_bonus > 0.0:
			spd_label.text = "💨 SPD: %.1f (+%.0f%%)" % [effective_spd, item.speed_bonus * 100]
			spd_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		else:
			spd_label.text = "💨 SPD: %.1f" % effective_spd
			spd_label.remove_theme_color_override("font_color")


func _update_item_display() -> void:
	if not item_container:
		return
	
	if current_spirit.held_item:
		var item: ItemData = current_spirit.held_item as ItemData
		item_container.visible = true
		
		if item_icon_label:
			item_icon_label.text = item.get_icon_emoji() if item else "📦"
		
		if item_name_label:
			item_name_label.text = item.display_name if item else "Unknown"
	else:
		item_container.visible = false


func _update_ability_display() -> void:
	if not ability_container:
		return
	
	if current_spirit.ability_name.is_empty():
		ability_container.visible = false
		return
	
	ability_container.visible = true
	
	if ability_name_label:
		ability_name_label.text = "✨ " + current_spirit.ability_name
	
	if ability_desc_label:
		ability_desc_label.text = current_spirit.ability_description


# =============================================================================
# POSITIONING
# =============================================================================

func _position_near(screen_pos: Vector2) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = size
	
	# Default: position to the right of cursor
	var target_pos: Vector2 = screen_pos + Vector2(20, 0)
	
	# Flip left if too close to right edge
	if target_pos.x + panel_size.x > viewport_size.x - 10:
		target_pos.x = screen_pos.x - panel_size.x - 20
	
	# Clamp to top/bottom edges
	target_pos.y = clampf(target_pos.y, 10, viewport_size.y - panel_size.y - 10)
	
	global_position = target_pos
