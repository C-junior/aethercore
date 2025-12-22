## MapNode - Resource defining a single node on the roguelike map
## Each node represents an encounter, shop, camp, or event the player can visit.
class_name MapNode
extends Resource


# =============================================================================
# NODE TYPES
# =============================================================================

enum NodeType {
	BATTLE,       ## Normal enemy encounter
	ELITE,        ## Harder fight, better rewards
	BOSS,         ## Act boss encounter
	SHOP,         ## Buy spirits/items
	CAMP,         ## Heal or upgrade spirits
	TREASURE,     ## Free rewards (gold, items)
	EVENT,        ## Random choice encounter
}


# =============================================================================
# NODE PROPERTIES
# =============================================================================

## Unique identifier for this node
@export var id: String = ""

## Type of node encounter
@export var type: NodeType = NodeType.BATTLE

## Element affinity for battle nodes (determines enemy types)
@export var element: Enums.Element = Enums.Element.NEUTRAL

## Floor number (1-indexed, determines difficulty scaling)
@export var floor_number: int = 1

## Visual position on the map (for UI display)
@export var position: Vector2 = Vector2.ZERO

## IDs of nodes that can be reached from this node
@export var connected_nodes: Array[String] = []

## Whether the player has already visited this node
@export var is_visited: bool = false

## Whether the player can currently select this node
@export var is_available: bool = false


# =============================================================================
# ENCOUNTER PROPERTIES (for BATTLE/ELITE/BOSS nodes)
# =============================================================================

## Number of enemies to spawn
@export var enemy_count: int = 2

## Tier of enemies (1-3)
@export var enemy_tier: int = 1

## Whether this is an elite encounter (harder enemies)
@export var is_elite: bool = false


# =============================================================================
# REWARD MODIFIERS
# =============================================================================

## Gold reward multiplier
@export var gold_multiplier: float = 1.0

## XP reward multiplier
@export var xp_multiplier: float = 1.0

## Guaranteed spirit drop of this element (empty = random)
@export var spirit_reward_element: Enums.Element = Enums.Element.NEUTRAL


# =============================================================================
# HELPERS
# =============================================================================

## Get the icon emoji for this node type
func get_icon() -> String:
	match type:
		NodeType.BATTLE:
			return _get_element_icon()
		NodeType.ELITE:
			return "💀"
		NodeType.BOSS:
			return "👑"
		NodeType.SHOP:
			return "🛒"
		NodeType.CAMP:
			return "⛺"
		NodeType.TREASURE:
			return "💎"
		NodeType.EVENT:
			return "❓"
	return "⚔️"


## Get element-specific icon for battle nodes
func _get_element_icon() -> String:
	match element:
		Enums.Element.FIRE:
			return "🔥"
		Enums.Element.WATER:
			return "💧"
		Enums.Element.EARTH:
			return "🪨"
		Enums.Element.AIR:
			return "💨"
		Enums.Element.NATURE:
			return "🌿"
	return "⚔️"


## Get display name for this node
func get_display_name() -> String:
	match type:
		NodeType.BATTLE:
			return "%s Battle" % _get_element_name()
		NodeType.ELITE:
			return "Elite Encounter"
		NodeType.BOSS:
			return "BOSS"
		NodeType.SHOP:
			return "Spirit Shop"
		NodeType.CAMP:
			return "Rest Camp"
		NodeType.TREASURE:
			return "Treasure"
		NodeType.EVENT:
			return "Mystery Event"
	return "Unknown"


func _get_element_name() -> String:
	match element:
		Enums.Element.FIRE:
			return "Fire"
		Enums.Element.WATER:
			return "Water"
		Enums.Element.EARTH:
			return "Earth"
		Enums.Element.AIR:
			return "Air"
		Enums.Element.NATURE:
			return "Nature"
	return ""


## Create a duplicate of this node for map generation
func duplicate_node() -> MapNode:
	var copy: MapNode = MapNode.new()
	copy.id = id
	copy.type = type
	copy.element = element
	copy.floor_number = floor_number
	copy.position = position
	copy.connected_nodes = connected_nodes.duplicate()
	copy.is_visited = is_visited
	copy.is_available = is_available
	copy.enemy_count = enemy_count
	copy.enemy_tier = enemy_tier
	copy.is_elite = is_elite
	copy.gold_multiplier = gold_multiplier
	copy.xp_multiplier = xp_multiplier
	copy.spirit_reward_element = spirit_reward_element
	return copy
