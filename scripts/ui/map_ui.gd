## MapUI - Visual map display controller
## Renders the roguelike map with node selection and path visualization.
class_name MapUI
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when player selects a node to visit
signal node_selected(node: MapNode)


# =============================================================================
# NODES
# =============================================================================

@onready var background: Panel = $Background
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var path_drawer: Node2D = $ScrollContainer/MapContainer/PathDrawer
@onready var nodes_container: Control = $ScrollContainer/MapContainer/NodesContainer
@onready var act_label: Label = $ActLabel
@onready var player_marker: TextureRect = $ScrollContainer/MapContainer/PlayerMarker


# =============================================================================
# STATE
# =============================================================================

## Currently displayed map nodes
var current_nodes: Array[MapNode] = []

## Map of node ID to button reference
var node_buttons: Dictionary = {}

## Active pulse tweens (node_id -> Tween)
var pulse_tweens: Dictionary = {}

## Current player position (node ID)
var current_node_id: String = ""


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Initial state
	visible = false


# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Display the map with given nodes
## @param nodes: Array of MapNode resources
## @param current_id: ID of current player position (empty = start)
## @param act_name: Display name for the act
func display_map(nodes: Array[MapNode], current_id: String, act_name: String = "") -> void:
	current_nodes = nodes
	current_node_id = current_id
	
	# Update act label
	if act_label and not act_name.is_empty():
		act_label.text = act_name
	
	# Clear existing
	_clear_map()
	
	# Build node buttons
	_create_node_buttons()
	
	# Draw path connections
	_draw_paths()
	
	# Update availability
	_update_node_availability()
	
	# Position player marker
	_update_player_marker()
	
	# Scroll to current position
	_scroll_to_current()
	
	visible = true


## Hide the map
func hide_map() -> void:
	# Kill all pulse tweens
	for node_id in pulse_tweens.keys():
		var tween: Tween = pulse_tweens[node_id]
		if tween and tween.is_valid():
			tween.kill()
	pulse_tweens.clear()
	
	visible = false


## Refresh availability state (after visiting a node)
func refresh_availability(visited_id: String) -> void:
	# Mark node as visited
	for node in current_nodes:
		if node.id == visited_id:
			node.is_visited = true
			node.is_available = false
			
			# Make connected nodes available
			for connected_id in node.connected_nodes:
				var connected: MapNode = _get_node_by_id(connected_id)
				if connected and not connected.is_visited:
					connected.is_available = true
	
	current_node_id = visited_id
	_update_node_availability()
	_update_player_marker()


# =============================================================================
# MAP BUILDING
# =============================================================================

func _clear_map() -> void:
	# Kill all pulse tweens
	for node_id in pulse_tweens.keys():
		var tween: Tween = pulse_tweens[node_id]
		if tween and tween.is_valid():
			tween.kill()
	pulse_tweens.clear()
	
	# Clear node buttons
	for child in nodes_container.get_children():
		child.queue_free()
	node_buttons.clear()
	
	# Clear path drawer
	if path_drawer:
		path_drawer.queue_redraw()


func _create_node_buttons() -> void:
	for node in current_nodes:
		var button := _create_node_button(node)
		nodes_container.add_child(button)
		node_buttons[node.id] = button


func _create_node_button(node: MapNode) -> Button:
	var button := Button.new()
	button.name = node.id
	button.custom_minimum_size = Vector2(50, 50)
	button.position = node.position - Vector2(25, 25)  # Center on position
	
	# Set visual based on node type
	button.text = node.get_icon()
	button.tooltip_text = node.get_display_name()
	
	# Style based on type
	_apply_node_style(button, node)
	
	# Connect signal
	button.pressed.connect(_on_node_pressed.bind(node))
	
	return button


func _apply_node_style(button: Button, node: MapNode) -> void:
	# Create style based on node type
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	
	match node.type:
		MapNode.NodeType.BATTLE:
			style.bg_color = _get_element_color(node.element)
			style.border_color = Color.WHITE
		MapNode.NodeType.ELITE:
			style.bg_color = Color(0.6, 0.2, 0.2, 1.0)
			style.border_color = Color.ORANGE_RED
		MapNode.NodeType.BOSS:
			style.bg_color = Color(0.5, 0.0, 0.0, 1.0)
			style.border_color = Color.GOLD
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
		MapNode.NodeType.SHOP:
			style.bg_color = Color(0.2, 0.4, 0.2, 1.0)
			style.border_color = Color.GOLD
		MapNode.NodeType.CAMP:
			style.bg_color = Color(0.3, 0.2, 0.1, 1.0)
			style.border_color = Color.ORANGE
		MapNode.NodeType.TREASURE:
			style.bg_color = Color(0.4, 0.3, 0.1, 1.0)
			style.border_color = Color.YELLOW
		MapNode.NodeType.EVENT:
			style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
			style.border_color = Color.PURPLE
	
	button.add_theme_stylebox_override("normal", style)
	
	# Hover style
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = hover_style.bg_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Disabled style
	var disabled_style := style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = disabled_style.bg_color.darkened(0.5)
	disabled_style.border_color = disabled_style.border_color.darkened(0.5)
	button.add_theme_stylebox_override("disabled", disabled_style)


func _get_element_color(element: Enums.Element) -> Color:
	match element:
		Enums.Element.FIRE:
			return Color(0.8, 0.2, 0.1, 1.0)
		Enums.Element.WATER:
			return Color(0.1, 0.4, 0.8, 1.0)
		Enums.Element.EARTH:
			return Color(0.5, 0.35, 0.2, 1.0)
		Enums.Element.AIR:
			return Color(0.6, 0.8, 0.9, 1.0)
		Enums.Element.NATURE:
			return Color(0.2, 0.6, 0.2, 1.0)
	return Color(0.4, 0.4, 0.4, 1.0)


# =============================================================================
# PATH DRAWING
# =============================================================================

func _draw_paths() -> void:
	# This function triggers the path drawer to redraw
	if path_drawer:
		path_drawer.queue_redraw()


## Custom path drawer node for lines
class PathDrawerNode extends Node2D:
	var map_ui: MapUI
	
	func _draw() -> void:
		if not map_ui:
			return
		
		for node in map_ui.current_nodes:
			for connected_id in node.connected_nodes:
				var connected: MapNode = map_ui._get_node_by_id(connected_id)
				if connected:
					var start: Vector2 = node.position
					var end: Vector2 = connected.position
					
					# Determine line color
					var line_color: Color = Color(0.5, 0.5, 0.5, 0.6)
					if node.is_visited and connected.is_available:
						line_color = Color(1.0, 0.8, 0.2, 0.9)
					elif node.is_visited or connected.is_visited:
						line_color = Color(0.3, 0.3, 0.3, 0.8)
					
					draw_line(start, end, line_color, 3.0, true)


# =============================================================================
# NODE AVAILABILITY
# =============================================================================

func _update_node_availability() -> void:
	for node in current_nodes:
		var button: Button = node_buttons.get(node.id)
		if not button:
			continue
		
		# Disable if not available or already visited
		button.disabled = not node.is_available or node.is_visited
		
		# Visual indication for visited nodes
		if node.is_visited:
			button.modulate = Color(0.5, 0.5, 0.5, 0.8)
		elif node.is_available:
			button.modulate = Color.WHITE
			# Pulse animation for available nodes
			_animate_available_node(button, node.id)
		else:
			button.modulate = Color(0.7, 0.7, 0.7, 0.9)


func _animate_available_node(button: Button, node_id: String):
	# Kill any existing tween for this node
	if pulse_tweens.has(node_id):
		var old_tween: Tween = pulse_tweens[node_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Create new pulse tween
	var tween := create_tween()
	pulse_tweens[node_id] = tween
	
	# Pulse animation - loops by calling itself when finished
	tween.tween_property(button, "modulate:a", 0.7, 0.5)
	tween.tween_property(button, "modulate:a", 1.0, 0.5)
	tween.finished.connect(_on_pulse_finished.bind(button, node_id))


func _on_pulse_finished(button: Button, node_id: String):
	# Only continue pulsing if button still exists and node is still available
	if not is_instance_valid(button) or not visible:
		pulse_tweens.erase(node_id)
		return
	
	# Check if node is still available
	var node: MapNode = _get_node_by_id(node_id)
	if node and node.is_available and not node.is_visited:
		_animate_available_node(button, node_id)
	else:
		pulse_tweens.erase(node_id)


# =============================================================================
# PLAYER MARKER
# =============================================================================

func _update_player_marker() -> void:
	if not player_marker or current_node_id.is_empty():
		if player_marker:
			player_marker.visible = false
		return
	
	var current: MapNode = _get_node_by_id(current_node_id)
	if current:
		player_marker.visible = true
		player_marker.position = current.position - Vector2(16, 40)


func _scroll_to_current() -> void:
	if not scroll_container or current_node_id.is_empty():
		return
	
	var current: MapNode = _get_node_by_id(current_node_id)
	if current:
		# Scroll to show current node in center
		var scroll_target: float = current.position.y - scroll_container.size.y / 2
		scroll_container.scroll_vertical = int(max(0, scroll_target))


# =============================================================================
# HELPERS
# =============================================================================

func _get_node_by_id(id: String) -> MapNode:
	for node in current_nodes:
		if node.id == id:
			return node
	return null


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_node_pressed(node: MapNode) -> void:
	if node.is_available and not node.is_visited:
		node_selected.emit(node)
