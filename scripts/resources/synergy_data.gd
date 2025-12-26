## SynergyData - Resource class defining synergy bonuses per element
## Synergies activate when multiple spirits of the same element are on the grid.
class_name SynergyData
extends Resource


# =============================================================================
# IDENTITY
# =============================================================================

## Element this synergy applies to
@export var element: Enums.Element = Enums.Element.FIRE

## Display name (e.g., "Flame Pact")
@export var display_name: String = ""

## Description of the synergy bonuses
@export_multiline var description: String = ""

## Icon emoji for UI display
@export var icon_emoji: String = "🔥"


# =============================================================================
# TIER CONFIGURATION
# =============================================================================

## Number of spirits required for each tier (e.g., [2, 3, 4] means tier 1 at 2 spirits)
@export var tier_thresholds: Array[int] = [2, 3, 4]


# =============================================================================
# TIER BONUSES
# =============================================================================

## Tier 1 bonuses (activated at tier_thresholds[0] spirits)
@export_group("Tier 1 Bonus")
@export var t1_attack_percent: float = 0.0
@export var t1_hp_percent: float = 0.0
@export var t1_speed_percent: float = 0.0
@export var t1_ability_percent: float = 0.0
@export var t1_damage_reduction: float = 0.0

## Tier 2 bonuses (activated at tier_thresholds[1] spirits)
@export_group("Tier 2 Bonus")
@export var t2_attack_percent: float = 0.0
@export var t2_hp_percent: float = 0.0
@export var t2_speed_percent: float = 0.0
@export var t2_ability_percent: float = 0.0
@export var t2_damage_reduction: float = 0.0

## Tier 3 bonuses (activated at tier_thresholds[2] spirits)
@export_group("Tier 3 Bonus")
@export var t3_attack_percent: float = 0.0
@export var t3_hp_percent: float = 0.0
@export var t3_speed_percent: float = 0.0
@export var t3_ability_percent: float = 0.0
@export var t3_damage_reduction: float = 0.0

## Special effect at max tier (e.g., "burn_on_hit", "regeneration", "first_strike")
@export var t3_special_effect: String = ""


# =============================================================================
# COMPUTED BONUSES
# =============================================================================

## Get bonuses for a specific tier level
## @param tier: Tier level (1, 2, or 3)
## @return: Dictionary of bonus values
func get_tier_bonuses(tier: int) -> Dictionary:
	match tier:
		1:
			return {
				"attack_percent": t1_attack_percent,
				"hp_percent": t1_hp_percent,
				"speed_percent": t1_speed_percent,
				"ability_percent": t1_ability_percent,
				"damage_reduction": t1_damage_reduction,
				"special_effect": ""
			}
		2:
			return {
				"attack_percent": t2_attack_percent,
				"hp_percent": t2_hp_percent,
				"speed_percent": t2_speed_percent,
				"ability_percent": t2_ability_percent,
				"damage_reduction": t2_damage_reduction,
				"special_effect": ""
			}
		3:
			return {
				"attack_percent": t3_attack_percent,
				"hp_percent": t3_hp_percent,
				"speed_percent": t3_speed_percent,
				"ability_percent": t3_ability_percent,
				"damage_reduction": t3_damage_reduction,
				"special_effect": t3_special_effect
			}
	return {}


## Get the tier level based on spirit count
## @param spirit_count: Number of spirits of this element on grid
## @return: Tier level (0 if not enough spirits, 1-3 otherwise)
func get_tier_for_count(spirit_count: int) -> int:
	var tier: int = 0
	for i in tier_thresholds.size():
		if spirit_count >= tier_thresholds[i]:
			tier = i + 1
	return tier


## Get description for specific tier
func get_tier_description(tier: int) -> String:
	var bonuses: Dictionary = get_tier_bonuses(tier)
	var parts: Array[String] = []
	
	if bonuses.get("attack_percent", 0.0) > 0:
		parts.append("+%d%% ATK" % int(bonuses["attack_percent"] * 100))
	if bonuses.get("hp_percent", 0.0) > 0:
		parts.append("+%d%% HP" % int(bonuses["hp_percent"] * 100))
	if bonuses.get("speed_percent", 0.0) > 0:
		parts.append("+%d%% SPD" % int(bonuses["speed_percent"] * 100))
	if bonuses.get("ability_percent", 0.0) > 0:
		parts.append("+%d%% Ability" % int(bonuses["ability_percent"] * 100))
	if bonuses.get("damage_reduction", 0.0) > 0:
		parts.append("+%d%% DR" % int(bonuses["damage_reduction"] * 100))
	if bonuses.get("special_effect", "") != "":
		parts.append(_format_special_effect(bonuses["special_effect"]))
	
	return ", ".join(parts) if parts.size() > 0 else "No bonus"


func _format_special_effect(effect: String) -> String:
	match effect:
		"burn_on_hit":
			return "🔥 Burn on Hit"
		"regeneration":
			return "💚 Regeneration"
		"shield_start":
			return "🛡️ Shield at Start"
		"first_strike":
			return "⚡ First Strike"
		"poison_on_hit":
			return "☠️ Poison on Hit"
		"taunt_front":
			return "🎯 Taunt Front Row"
	return effect
