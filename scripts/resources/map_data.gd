## MapData - Resource defining an Act's map structure and generation parameters
## Controls procedural generation of the roguelike map.
class_name MapData
extends Resource


# =============================================================================
# ACT INFORMATION
# =============================================================================

## Act number (1, 2, or 3)
@export var act_number: int = 1

## Display name shown to player
@export var display_name: String = "Act 1: Verdant Grove"

## Description of the act
@export var description: String = "A lush forest teeming with nature and fire spirits."

## Total number of floors (excluding boss floor)
@export var floor_count: int = 9

## Boss spirit ID for this act
@export var boss_id: String = "queenstruction"


# =============================================================================
# MAP GENERATION PARAMETERS
# =============================================================================

## Min/Max number of nodes per floor
@export var nodes_per_floor: Vector2i = Vector2i(2, 4)

## Node type weights (probabilities)
@export_group("Node Weights")
@export_range(0.0, 1.0) var battle_weight: float = 0.45
@export_range(0.0, 1.0) var elite_weight: float = 0.15
@export_range(0.0, 1.0) var shop_weight: float = 0.12
@export_range(0.0, 1.0) var camp_weight: float = 0.12
@export_range(0.0, 1.0) var treasure_weight: float = 0.08
@export_range(0.0, 1.0) var event_weight: float = 0.08


# =============================================================================
# ELEMENT DISTRIBUTION
# =============================================================================

## Elements that appear in this act (for enemy encounters)
@export var available_elements: Array[Enums.Element] = [
	Enums.Element.FIRE,
	Enums.Element.NATURE,
	Enums.Element.EARTH
]


# =============================================================================
# DIFFICULTY SCALING
# =============================================================================

## Base HP multiplier for enemies in this act
@export var base_hp_multiplier: float = 1.0

## Base ATK multiplier for enemies in this act
@export var base_atk_multiplier: float = 1.0

## HP scaling per floor (percentage increase)
@export var floor_hp_scaling: float = 0.08

## ATK scaling per floor (percentage increase)
@export var floor_atk_scaling: float = 0.06


# =============================================================================
# SPECIAL FLOOR RULES
# =============================================================================

## Floors where elite battles can appear
@export var elite_floors: Array[int] = [3, 5, 7]

## Floors where shop is guaranteed on at least one path
@export var guaranteed_shop_floors: Array[int] = [4, 8]

## Floor before boss (usually rest or shop)
@export var pre_boss_floor_type: MapNode.NodeType = MapNode.NodeType.CAMP


# =============================================================================
# REWARDS
# =============================================================================

## Base gold reward per battle
@export var base_gold_reward: int = 8

## Gold bonus per floor
@export var gold_per_floor: int = 2

## XP reward per battle
@export var base_xp_reward: int = 30


# =============================================================================
# HELPERS
# =============================================================================

## Get a random element from available pool
func get_random_element() -> Enums.Element:
	if available_elements.is_empty():
		return Enums.Element.NEUTRAL
	return available_elements[randi() % available_elements.size()]


## Calculate HP multiplier for a given floor
func get_floor_hp_multiplier(floor_num: int) -> float:
	return base_hp_multiplier * (1.0 + floor_hp_scaling * (floor_num - 1))


## Calculate ATK multiplier for a given floor
func get_floor_atk_multiplier(floor_num: int) -> float:
	return base_atk_multiplier * (1.0 + floor_atk_scaling * (floor_num - 1))


## Calculate gold reward for a floor
func get_floor_gold_reward(floor_num: int) -> int:
	return base_gold_reward + gold_per_floor * (floor_num - 1)


## Check if elites can spawn on this floor
func can_spawn_elite(floor_num: int) -> bool:
	return floor_num in elite_floors


## Check if shop is guaranteed on this floor
func is_shop_guaranteed(floor_num: int) -> bool:
	return floor_num in guaranteed_shop_floors
