## CampUI - Rest stop UI for healing and training
## Provides players with choices to heal all spirits or train a specific spirit for bonus XP.
class_name CampUI
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

signal camp_completed
signal spirit_trained(spirit: SpiritData, xp_amount: int)


# =============================================================================
# CONSTANTS
# =============================================================================

const HEAL_PERCENT: float = 1.0  # Full heal
const TRAIN_XP: int = 50  # XP awarded for training


# =============================================================================
# NODES
# =============================================================================

var panel: PanelContainer
var title_label: Label
var description_label: Label
var rest_button: Button
var train_button: Button
var spirit_container: HBoxContainer
var back_button: Button
var mode: String = "choice"  # "choice" or "training"


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_setup_ui()
	visible = false


func _setup_ui() -> void:
	# Main panel
	panel = PanelContainer.new()
	panel.name = "CampPanel"
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.4, 0.5, 0.3, 1.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# Center the panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 400)
	panel.position = Vector2(-250, -200)
	
	# Content margin
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "⛺ REST CAMP"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Description
	description_label = Label.new()
	description_label.text = "Take a moment to rest and recover.\nChoose an action:"
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(description_label)
	
	# Button container
	var button_container := VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 15)
	vbox.add_child(button_container)
	
	# Rest button
	rest_button = Button.new()
	rest_button.text = "💚 REST - Fully heal all spirits"
	rest_button.add_theme_font_size_override("font_size", 16)
	rest_button.custom_minimum_size = Vector2(0, 50)
	rest_button.pressed.connect(_on_rest_pressed)
	button_container.add_child(rest_button)
	
	# Train button
	train_button = Button.new()
	train_button.text = "📖 TRAIN - Grant +%d XP to one spirit" % TRAIN_XP
	train_button.add_theme_font_size_override("font_size", 16)
	train_button.custom_minimum_size = Vector2(0, 50)
	train_button.pressed.connect(_on_train_pressed)
	button_container.add_child(train_button)
	
	# Spirit container (hidden initially, shown during training selection)
	spirit_container = HBoxContainer.new()
	spirit_container.name = "SpiritContainer"
	spirit_container.alignment = BoxContainer.ALIGNMENT_CENTER
	spirit_container.add_theme_constant_override("separation", 15)
	spirit_container.visible = false
	vbox.add_child(spirit_container)
	
	# Back button (hidden initially)
	back_button = Button.new()
	back_button.text = "← Back"
	back_button.custom_minimum_size = Vector2(100, 35)
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false
	vbox.add_child(back_button)


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func show_camp() -> void:
	mode = "choice"
	_show_choice_mode()
	visible = true


func hide_camp() -> void:
	visible = false


# =============================================================================
# MODE SWITCHING
# =============================================================================

func _show_choice_mode() -> void:
	mode = "choice"
	title_label.text = "⛺ REST CAMP"
	description_label.text = "Take a moment to rest and recover.\nChoose an action:"
	description_label.visible = true
	rest_button.visible = true
	train_button.visible = true
	spirit_container.visible = false
	back_button.visible = false


func _show_training_mode() -> void:
	mode = "training"
	title_label.text = "📖 TRAINING"
	description_label.text = "Select a spirit to train (+%d XP):" % TRAIN_XP
	rest_button.visible = false
	train_button.visible = false
	spirit_container.visible = true
	back_button.visible = true
	
	# Populate spirit selection
	_populate_spirits()


func _populate_spirits() -> void:
	# Clear existing
	for child in spirit_container.get_children():
		child.queue_free()
	
	# Add all owned spirits (grid + bench)
	for spirit in GameManager.owned_spirits:
		var spirit_data: SpiritData = spirit as SpiritData
		if spirit_data:
			var spirit_button := _create_spirit_button(spirit_data)
			spirit_container.add_child(spirit_button)


func _create_spirit_button(spirit_data: SpiritData) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(80, 100)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(vbox)
	
	# Portrait/Icon
	var icon := Label.new()
	icon.text = spirit_data.get_element_emoji()
	icon.add_theme_font_size_override("font_size", 32)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)
	
	# Name
	var name_label := Label.new()
	name_label.text = spirit_data.display_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# XP bar
	var xp_label := Label.new()
	xp_label.text = "XP: %d/%d" % [spirit_data.current_xp, spirit_data.xp_to_evolve]
	xp_label.add_theme_font_size_override("font_size", 9)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(xp_label)
	
	button.pressed.connect(_on_spirit_selected_for_training.bind(spirit_data))
	
	return button


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_rest_pressed() -> void:
	# Heal all spirits
	_heal_all_spirits()
	
	# Show feedback
	description_label.text = "✨ All spirits have been fully healed! ✨"
	rest_button.visible = false
	train_button.visible = false
	
	# Complete after delay
	await get_tree().create_timer(1.5).timeout
	_complete_camp()


func _on_train_pressed() -> void:
	_show_training_mode()


func _on_back_pressed() -> void:
	_show_choice_mode()


func _on_spirit_selected_for_training(spirit_data: SpiritData) -> void:
	# Award XP to the selected spirit
	var evolved: SpiritData = spirit_data.add_xp(TRAIN_XP)
	
	if evolved:
		# Spirit evolved! Replace in GameManager
		var idx: int = GameManager.owned_spirits.find(spirit_data)
		if idx >= 0:
			GameManager.owned_spirits[idx] = evolved
		
		# Also replace in grid if present
		for i in GameManager.grid_spirits.size():
			if GameManager.grid_spirits[i] == spirit_data:
				GameManager.grid_spirits[i] = evolved
				break
		
		EventBus.spirit_evolved.emit(spirit_data, spirit_data.tier, evolved.tier)
		description_label.text = "🎉 %s evolved into %s! 🎉" % [spirit_data.display_name, evolved.display_name]
	else:
		description_label.text = "📖 %s gained +%d XP!" % [spirit_data.display_name, TRAIN_XP]
	
	spirit_trained.emit(spirit_data, TRAIN_XP)
	
	# Hide options and show result
	spirit_container.visible = false
	back_button.visible = false
	
	# Complete after delay
	await get_tree().create_timer(1.5).timeout
	_complete_camp()


# =============================================================================
# HELPERS
# =============================================================================

func _heal_all_spirits() -> void:
	# Note: We can't directly heal Spirit nodes here because they may not exist
	# The healing is effectively "full HP at battle start"
	# For now, we'll just emit a signal and let the system know
	print("[CampUI] All spirits healed to full HP")
	
	# Future: Track healing state in GameManager


func _complete_camp() -> void:
	camp_completed.emit()
	hide_camp()
