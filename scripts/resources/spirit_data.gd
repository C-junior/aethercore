## SpiritData - Resource class defining spirit properties
## Each spirit has base stats, element, evolution data, and ability configuration.
@tool
class_name SpiritData
extends Resource


# =============================================================================
# IDENTITY
# =============================================================================

## Unique identifier for this spirit (e.g., "embera_t1")
@export var id: String = ""

## Display name shown to player
@export var display_name: String = ""

## Spirit description/lore
@export_multiline var description: String = ""

## Visual placeholder texture (until final art)
@export var portrait: Texture2D


# =============================================================================
# CLASSIFICATION
# =============================================================================

## Elemental type
@export var element: Enums.Element = Enums.Element.FIRE

## Evolution tier
@export var tier: Enums.Tier = Enums.Tier.T1


# =============================================================================
# BASE STATS
# =============================================================================

@export_group("Base Stats")

## Maximum health points
@export var base_hp: int = 100

## Attack damage per hit
@export var base_attack: int = 10

## Attacks per second (1.0 = 1 attack/sec)
@export var attack_speed: float = 1.0

## Flat damage reduction (tanks)
@export var damage_reduction: int = 0


# =============================================================================
# EVOLUTION
# =============================================================================

@export_group("Evolution")

## XP required to evolve to next tier
@export var xp_to_evolve: int = 100

## Reference to evolved form (null if cannot evolve)
@export var evolves_into: SpiritData


# =============================================================================
# ABILITY
# =============================================================================

@export_group("Ability")

## Ability display name
@export var ability_name: String = ""

## Ability description for UI
@export_multiline var ability_description: String = ""

## When the ability triggers
@export var ability_type: Enums.AbilityType = Enums.AbilityType.PASSIVE

## Ability parameters (flexible dictionary for different ability types)
## Examples:
##   ON_HIT: {"trigger_every": 3, "bonus_damage": 10}
##   COOLDOWN: {"cooldown": 4.0, "heal_amount": 15}
##   AURA: {"stat": "attack_speed", "bonus_percent": 0.10}
##   BATTLE_START: {"shield_percent": 0.4, "affects_back_row": true}
@export var ability_params: Dictionary = {}


# =============================================================================
# TARGETING
# =============================================================================

@export_group("Targeting")

## How this spirit selects targets
@export var targeting_mode: Enums.TargetingMode = Enums.TargetingMode.FRONT_FIRST

## Whether this spirit attacks from range (affects visuals)
@export var is_ranged: bool = false


# =============================================================================
# VISUALS (Future)
# =============================================================================

@export_group("Visuals")

## Color tint for effects
@export var effect_color: Color = Color.WHITE

## Sprite animation set name
@export var animation_set: String = "default"


# =============================================================================
# HELPERS
# =============================================================================

## Get the Power Budget score for this spirit (for balancing)
func get_power_budget() -> float:
	var hp_cost: float = base_hp / 10.0
	var dps_cost: float = base_attack * attack_speed
	var ability_cost: float = ability_params.get("budget_value", 5.0)
	return hp_cost + dps_cost + ability_cost


## Check if this spirit can evolve
func can_evolve() -> bool:
	return evolves_into != null


## Get display string for tier
func get_tier_string() -> String:
	match tier:
		Enums.Tier.T1: return "★"
		Enums.Tier.T2: return "★★"
		Enums.Tier.T3: return "★★★"
		Enums.Tier.HYPER: return "✦"
	return ""


## Clone this spirit data (for instancing)
func duplicate_spirit() -> SpiritData:
	var copy: SpiritData = duplicate(true) as SpiritData
	return copy
