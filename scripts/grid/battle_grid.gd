## BattleGrid - Manages the 2x2 grid for spirit placement
## Handles slot positions, adjacency, and drag-drop placement.
class_name BattleGrid
extends Node2D


# =============================================================================
# SIGNALS
# =============================================================================

signal spirit_placed(spirit: Node, slot_index: int)
signal spirit_removed(spirit: Node, slot_index: int)
signal spirits_swapped(spirit_a: Node, slot_a: int, spirit_b: Node, slot_b: int)


# =============================================================================
# CONFIGURATION
# =============================================================================

## Size of each grid slot in pixels
@export var slot_size: Vector2 = Vector2(100, 100)

## Spacing between slots
@export var slot_spacing: float = 20.0

## Whether this is the ally grid (true) or enemy grid (false)
@export var is_ally_grid: bool = true


# =============================================================================
# STATE
# =============================================================================

## Spirits in each slot (index = slot, null = empty)
var slots: Array = [null, null, null, null]

## Grid slot visual nodes
var slot_nodes: Array[Node2D] = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_slot_visuals()


func _create_slot_visuals() -> void:
	slot_nodes.clear()
	
	for i in Constants.GRID_TOTAL_SLOTS:
		var slot_visual := Node2D.new()
		slot_visual.name = "Slot_%d" % i
		slot_visual.position = get_slot_position(i)
		add_child(slot_visual)
		slot_nodes.append(slot_visual)


# =============================================================================
# POSITION CALCULATIONS
# =============================================================================

## Get the world position for a grid slot
func get_slot_position(slot_index: int) -> Vector2:
	var row: int = slot_index / Constants.GRID_COLS
	var col: int = slot_index % Constants.GRID_COLS
	
	var x: float = col * (slot_size.x + slot_spacing)
	var y: float = row * (slot_size.y + slot_spacing)
	
	# Center the grid
	var total_width: float = Constants.GRID_COLS * slot_size.x + (Constants.GRID_COLS - 1) * slot_spacing
	var total_height: float = Constants.GRID_ROWS * slot_size.y + (Constants.GRID_ROWS - 1) * slot_spacing
	
	x -= total_width / 2.0 - slot_size.x / 2.0
	y -= total_height / 2.0 - slot_size.y / 2.0
	
	return Vector2(x, y)


## Get the slot index from a world position
func get_slot_from_position(world_pos: Vector2) -> int:
	var local_pos: Vector2 = to_local(world_pos)
	
	for i in Constants.GRID_TOTAL_SLOTS:
		var slot_pos: Vector2 = get_slot_position(i)
		var rect := Rect2(slot_pos - slot_size / 2.0, slot_size)
		
		if rect.has_point(local_pos):
			return i
	
	return -1  # No valid slot


# =============================================================================
# SLOT QUERIES
# =============================================================================

## Check if a slot is empty
func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	return slots[slot_index] == null


## Get spirit in a slot
func get_spirit_in_slot(slot_index: int) -> Node:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]


## Get first empty slot
func get_first_empty_slot() -> int:
	for i in slots.size():
		if slots[i] == null:
			return i
	return -1


## Get all occupied slots
func get_occupied_slots() -> Array[int]:
	var result: Array[int] = []
	for i in slots.size():
		if slots[i] != null:
			result.append(i)
	return result


## Get all spirits in grid
func get_all_spirits() -> Array:
	return slots.filter(func(s): return s != null)


## Get count of spirits in grid
func get_spirit_count() -> int:
	return get_all_spirits().size()


# =============================================================================
# SLOT MANIPULATION
# =============================================================================

## Place a spirit in a slot
func place_spirit(spirit: Node, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= Constants.GRID_TOTAL_SLOTS:
		return false
	
	# If slot occupied, swap
	if slots[slot_index] != null:
		var existing: Node = slots[slot_index]
		var old_slot: int = _find_spirit_slot(spirit)
		
		if old_slot >= 0:
			# Swap positions
			slots[old_slot] = existing
			existing.grid_slot = old_slot
			existing.position = get_slot_position(old_slot)
			spirits_swapped.emit(spirit, slot_index, existing, old_slot)
		else:
			# Can't place here if occupied and spirit not already on grid
			return false
	
	# Update old slot if spirit was already placed
	var old_slot: int = _find_spirit_slot(spirit)
	if old_slot >= 0 and old_slot != slot_index:
		slots[old_slot] = null
	
	# Place spirit
	slots[slot_index] = spirit
	spirit.grid_slot = slot_index
	spirit.position = get_slot_position(slot_index)
	
	if spirit.get_parent() != self:
		if spirit.get_parent():
			spirit.get_parent().remove_child(spirit)
		add_child(spirit)
	
	spirit_placed.emit(spirit, slot_index)
	return true


## Remove a spirit from its slot
func remove_spirit(spirit: Node) -> void:
	var slot: int = _find_spirit_slot(spirit)
	if slot >= 0:
		slots[slot] = null
		spirit_removed.emit(spirit, slot)


## Clear all spirits from grid
func clear_grid() -> void:
	for i in slots.size():
		if slots[i] != null:
			spirit_removed.emit(slots[i], i)
			slots[i] = null


## Find which slot a spirit is in
func _find_spirit_slot(spirit: Node) -> int:
	for i in slots.size():
		if slots[i] == spirit:
			return i
	return -1


# =============================================================================
# ROW QUERIES
# =============================================================================

## Check if a slot is in the front row
func is_front_row_slot(slot_index: int) -> bool:
	return slot_index in Constants.FRONT_ROW_SLOTS


## Get all spirits in front row
func get_front_row_spirits() -> Array:
	var result: Array = []
	for slot in Constants.FRONT_ROW_SLOTS:
		if slots[slot] != null:
			result.append(slots[slot])
	return result


## Get all spirits in back row
func get_back_row_spirits() -> Array:
	var result: Array = []
	for slot in Constants.BACK_ROW_SLOTS:
		if slots[slot] != null:
			result.append(slots[slot])
	return result


# =============================================================================
# ADJACENCY
# =============================================================================

## Get adjacent spirits to a slot
func get_adjacent_spirits(slot_index: int) -> Array:
	var adjacent_slots: Array[int] = Constants.ADJACENCY_MAP.get(slot_index, [])
	var result: Array = []
	
	for adj_slot in adjacent_slots:
		if slots[adj_slot] != null:
			result.append(slots[adj_slot])
	
	return result
