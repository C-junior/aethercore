## ItemData - Resource for held items in AetherCore
## Items can be equipped to spirits for stat boosts or Hyper Evolution triggers.
class_name ItemData
extends Resource


# =============================================================================
# ITEM TYPES
# =============================================================================

enum ItemType {
	STAT_BOOST,      ## Increases spirit stats
	EVOLUTION_KEY,   ## Triggers Hyper Evolution when held
	CONSUMABLE,      ## Single use item
}


# =============================================================================
# PROPERTIES
# =============================================================================

## Unique identifier
@export var id: String = ""

## Display name
@export var display_name: String = "Unknown Item"

## Description
@export_multiline var description: String = ""

## Item type
@export var type: ItemType = ItemType.STAT_BOOST

## Icon texture
@export var icon: Texture2D = null


# =============================================================================
# STAT MODIFIERS (for STAT_BOOST type)
# =============================================================================

## HP bonus
@export var hp_bonus: int = 0

## Attack bonus
@export var attack_bonus: int = 0

## Attack speed bonus (multiplier)
@export var speed_bonus: float = 0.0


# =============================================================================
# EVOLUTION KEY (for EVOLUTION_KEY type)
# =============================================================================

## ID of the spirit this key evolves (e.g., "embera_t3" -> "inferna_hyper")
@export var evolves_spirit_id: String = ""

## ID of the evolution result
@export var evolution_result_id: String = ""


# =============================================================================
# ECONOMY
# =============================================================================

## Shop buy price
@export var buy_price: int = 10

## Sell value (50% of buy price by default)
func get_sell_value() -> int:
	return buy_price / 2


# =============================================================================
# HELPERS
# =============================================================================

## Get display icon (emoji for now)
func get_icon_emoji() -> String:
	match type:
		ItemType.STAT_BOOST:
			return "⚔️"
		ItemType.EVOLUTION_KEY:
			return "🔑"
		ItemType.CONSUMABLE:
			return "🧪"
	return "📦"
