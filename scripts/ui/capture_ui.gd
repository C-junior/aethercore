## CaptureUI - Post-battle spirit capture selection
## Shows defeated enemies and lets player choose one to purify/capture.
class_name CaptureUI
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when player selects a spirit to capture
signal spirit_captured(spirit_data: SpiritData)

## Emitted when player skips capture
signal capture_skipped


# =============================================================================
# NODES
# =============================================================================

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var spirits_container: HBoxContainer = $SpiritsContainer
@onready var skip_button: Button = $SkipButton


# =============================================================================
# STATE
# =============================================================================

## Defeated spirits available for capture
var defeated_spirits: Array[SpiritData] = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	visible = false
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Show the capture UI with defeated spirits
## @param spirits: Array of SpiritData from defeated enemies
func show_capture_options(spirits: Array[SpiritData]) -> void:
	defeated_spirits = spirits
	
	# Clear existing options
	for child in spirits_container.get_children():
		child.queue_free()
	
	# Create option buttons for each spirit
	for spirit in spirits:
		var option := _create_spirit_option(spirit)
		spirits_container.add_child(option)
	
	# Update text
	if title_label:
		title_label.text = "✨ VICTORY! ✨"
	
	if subtitle_label:
		subtitle_label.text = "Choose a spirit to purify and capture:"
	
	visible = true


## Hide the capture UI
func hide_capture() -> void:
	visible = false
	defeated_spirits.clear()


# =============================================================================
# UI CREATION
# =============================================================================

func _create_spirit_option(spirit_data: SpiritData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 220)
	
	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.2, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.3, 0.7, 1.0)  # Purple for purification theme
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Purify label
	var purify_label := Label.new()
	purify_label.text = "🔮 PURIFY"
	purify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purify_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	vbox.add_child(purify_label)
	
	# Portrait
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(80, 80)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if spirit_data.portrait:
		portrait.texture = spirit_data.portrait
	vbox.add_child(portrait)
	
	# Name
	var name_label := Label.new()
	name_label.text = spirit_data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	# Element
	var element_label := Label.new()
	element_label.text = _get_element_text(spirit_data.element)
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(element_label)
	
	# Stats hint
	var stats_label := Label.new()
	stats_label.text = "HP: %d | ATK: %d" % [spirit_data.base_hp, spirit_data.base_attack]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(stats_label)
	
	# Capture button
	var capture_btn := Button.new()
	capture_btn.text = "Capture"
	capture_btn.pressed.connect(_on_spirit_selected.bind(spirit_data))
	vbox.add_child(capture_btn)
	
	return panel


func _get_element_text(element: Enums.Element) -> String:
	match element:
		Enums.Element.FIRE: return "🔥 Fire"
		Enums.Element.WATER: return "💧 Water"
		Enums.Element.EARTH: return "🪨 Earth"
		Enums.Element.AIR: return "💨 Air"
		Enums.Element.NATURE: return "🌿 Nature"
	return "⚪ Neutral"


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_spirit_selected(spirit_data: SpiritData) -> void:
	spirit_captured.emit(spirit_data)
	hide_capture()


func _on_skip_pressed() -> void:
	capture_skipped.emit()
	hide_capture()
