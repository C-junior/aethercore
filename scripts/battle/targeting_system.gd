## TargetingSystem - Handles target selection for spirits
## Pure utility class for finding valid attack targets.
class_name TargetingSystem
extends RefCounted


# =============================================================================
# TARGET SELECTION
# =============================================================================

## Find the best target based on targeting mode
## @param enemies: Array of Spirit nodes (enemy team)
## @param mode: TargetingMode enum value
## @param ignore_taunt: Whether to ignore taunt (for abilities)
## @return: Selected Spirit node or null if no valid targets
static func get_target(
	enemies: Array,
	mode: Enums.TargetingMode,
	ignore_taunt: bool = false
) -> Node:
	# Filter to alive enemies only
	var alive_enemies: Array = enemies.filter(func(e): return e != null and e.is_alive())
	
	if alive_enemies.is_empty():
		return null
	
	# Check for taunt first (unless ignoring)
	if not ignore_taunt:
		var taunter: Node = _find_taunter(alive_enemies)
		if taunter:
			return taunter
	
	# Apply targeting mode
	match mode:
		Enums.TargetingMode.FRONT_FIRST:
			return _get_front_first_target(alive_enemies)
		Enums.TargetingMode.LOWEST_HP:
			return _get_lowest_hp_target(alive_enemies)
		Enums.TargetingMode.HIGHEST_ATK:
			return _get_highest_atk_target(alive_enemies)
		Enums.TargetingMode.BACK_FIRST:
			return _get_back_first_target(alive_enemies)
		Enums.TargetingMode.RANDOM:
			return alive_enemies.pick_random()
	
	# Fallback
	return alive_enemies[0]


# =============================================================================
# TARGETING MODES
# =============================================================================

## Standard front-to-back targeting
static func _get_front_first_target(enemies: Array) -> Node:
	# Sort by grid position (front row = 0-1, back row = 2-3)
	var sorted: Array = enemies.duplicate()
	sorted.sort_custom(func(a, b): return a.grid_slot < b.grid_slot)
	
	# Get front row first
	for enemy in sorted:
		if enemy.grid_slot in Constants.FRONT_ROW_SLOTS:
			return enemy
	
	# No front row, get back row
	return sorted[0] if sorted.size() > 0 else null


## Target with lowest HP
static func _get_lowest_hp_target(enemies: Array) -> Node:
	var lowest: Node = null
	var lowest_hp: int = 999999
	
	for enemy in enemies:
		if enemy.current_hp < lowest_hp:
			lowest_hp = enemy.current_hp
			lowest = enemy
	
	return lowest


## Target with highest attack
static func _get_highest_atk_target(enemies: Array) -> Node:
	var highest: Node = null
	var highest_atk: int = 0
	
	for enemy in enemies:
		var atk: int = enemy.spirit_data.base_attack if enemy.spirit_data else 0
		if atk > highest_atk:
			highest_atk = atk
			highest = enemy
	
	return highest


## Back row first targeting (assassin)
static func _get_back_first_target(enemies: Array) -> Node:
	var sorted: Array = enemies.duplicate()
	sorted.sort_custom(func(a, b): return a.grid_slot > b.grid_slot)
	
	# Get back row first
	for enemy in sorted:
		if enemy.grid_slot in Constants.BACK_ROW_SLOTS:
			return enemy
	
	# No back row, get front row
	return sorted[0] if sorted.size() > 0 else null


## Find a taunting enemy
static func _find_taunter(enemies: Array) -> Node:
	for enemy in enemies:
		if enemy.has_status(Enums.StatusEffect.TAUNT):
			return enemy
	return null


# =============================================================================
# AREA TARGETING
# =============================================================================

## Get all enemies adjacent to a position
## @param all_enemies: All enemy Spirit nodes
## @param center_slot: Grid slot to check adjacency from
## @return: Array of adjacent Spirit nodes
static func get_adjacent_enemies(all_enemies: Array, center_slot: int) -> Array:
	var adjacent_slots: Array = Constants.ADJACENCY_MAP.get(center_slot, [])
	var result: Array = []
	
	for enemy in all_enemies:
		if enemy != null and enemy.is_alive() and enemy.grid_slot in adjacent_slots:
			result.append(enemy)
	
	return result


## Get all enemies in a specific row
static func get_enemies_in_row(all_enemies: Array, row: Enums.GridRow) -> Array:
	var slots: Array = Constants.FRONT_ROW_SLOTS if row == Enums.GridRow.FRONT else Constants.BACK_ROW_SLOTS
	var result: Array = []
	
	for enemy in all_enemies:
		if enemy != null and enemy.is_alive() and enemy.grid_slot in slots:
			result.append(enemy)
	
	return result


# =============================================================================
# ALLY TARGETING (FOR SUPPORT ABILITIES)
# =============================================================================

## Get lowest HP ally
static func get_lowest_hp_ally(allies: Array) -> Node:
	return _get_lowest_hp_target(allies.filter(func(a): return a != null and a.is_alive()))


## Get all adjacent allies
static func get_adjacent_allies(all_allies: Array, center_slot: int) -> Array:
	return get_adjacent_enemies(all_allies, center_slot)  # Same logic


## Get allies in back row
static func get_back_row_allies(all_allies: Array) -> Array:
	return get_enemies_in_row(all_allies, Enums.GridRow.BACK)


## Get all allies (for team-wide buffs)
static func get_all_alive_allies(allies: Array) -> Array:
	return allies.filter(func(a): return a != null and a.is_alive())
