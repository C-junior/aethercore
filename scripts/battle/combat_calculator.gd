## CombatCalculator - Handles all damage and combat calculations
## Pure utility class with static methods for combat math.
class_name CombatCalculator
extends RefCounted


# =============================================================================
# DAMAGE CALCULATION
# =============================================================================

## Calculate damage from attacker to defender
## @param attacker_data: Attacker's SpiritData
## @param defender_data: Defender's SpiritData
## @param attacker_tier: Current tier of attacker (for boss damage reduction)
## @param is_boss_target: Whether the defender is a boss
## @return: Dictionary with "damage", "is_crit", "effectiveness"
static func calculate_damage(
	attacker_data: SpiritData,
	defender_data: SpiritData,
	attacker_tier: Enums.Tier = Enums.Tier.T1,
	is_boss_target: bool = false
) -> Dictionary:
	var result: Dictionary = {
		"damage": 0,
		"is_crit": false,
		"effectiveness": 1.0,
		"effectiveness_text": "normal"
	}
	
	# Base damage (includes item bonuses)
	var base_damage: float = attacker_data.get_effective_attack()
	
	# Type effectiveness
	var type_mult: float = Constants.get_type_multiplier(
		attacker_data.element,
		defender_data.element
	)
	result.effectiveness = type_mult
	
	if type_mult > 1.0:
		result.effectiveness_text = "super_effective"
	elif type_mult < 1.0:
		result.effectiveness_text = "resisted"
	
	base_damage *= type_mult
	
	# Boss special: T1 damage reduction
	if is_boss_target and attacker_tier == Enums.Tier.T1:
		base_damage *= (1.0 - Constants.BOSS_T1_DAMAGE_REDUCTION)
	
	# Flat damage reduction from defender
	base_damage = maxf(Constants.MIN_DAMAGE, base_damage - defender_data.damage_reduction)
	
	# Critical hit check
	if randf() < Constants.CRIT_CHANCE:
		base_damage += Constants.CRIT_BONUS_DAMAGE
		result.is_crit = true
	
	result.damage = int(base_damage)
	return result


# =============================================================================
# TYPE EFFECTIVENESS
# =============================================================================

## Get type effectiveness multiplier
static func get_type_effectiveness(attacker_element: Enums.Element, defender_element: Enums.Element) -> float:
	return Constants.get_type_multiplier(attacker_element, defender_element)


## Get readable effectiveness string
static func get_effectiveness_string(multiplier: float) -> String:
	if multiplier > 1.0:
		return "Super Effective!"
	elif multiplier < 1.0:
		return "Resisted..."
	return ""


# =============================================================================
# HEALING CALCULATION
# =============================================================================

## Calculate heal amount (simple for now, can be expanded)
static func calculate_heal(base_heal: int, _healer_data: SpiritData = null) -> int:
	# Future: Add healing bonuses from items/synergies
	return base_heal


# =============================================================================
# DOT (Damage Over Time) CALCULATION
# =============================================================================

## Calculate burn damage tick
static func calculate_burn_damage() -> int:
	return Constants.BURN_DPS


## Calculate poison damage tick (accounts for stacks)
static func calculate_poison_damage(stacks: int) -> int:
	stacks = clampi(stacks, 0, Constants.POISON_MAX_STACKS)
	return Constants.POISON_DPS * stacks


# =============================================================================
# SHIELD CALCULATION
# =============================================================================

## Calculate shield amount based on percentage of HP
static func calculate_shield_amount(spirit_hp: int, shield_percent: float) -> int:
	return int(spirit_hp * shield_percent)


## Calculate damage absorbed by shield and remaining damage
## @return: Dictionary with "shield_damage", "hp_damage", "shield_broken"
static func calculate_shielded_damage(damage: int, current_shield: int, is_mandible: bool = false) -> Dictionary:
	var result: Dictionary = {
		"shield_damage": 0,
		"hp_damage": 0,
		"shield_broken": false
	}
	
	var effective_shield: int = current_shield
	
	# Boss Crushing Mandible pierces 50% of shield
	if is_mandible:
		effective_shield = int(current_shield * (1.0 - Constants.BOSS_CRUSHING_MANDIBLE_SHIELD_PIERCE))
	
	if effective_shield >= damage:
		# Shield absorbs all damage
		result.shield_damage = damage
	else:
		# Shield breaks, remaining goes to HP
		result.shield_damage = effective_shield
		result.hp_damage = damage - effective_shield
		result.shield_broken = true
	
	return result


# =============================================================================
# XP CALCULATION
# =============================================================================

## Calculate XP gained from killing an enemy
static func calculate_kill_xp(enemy_tier: Enums.Tier) -> int:
	var base_xp: int = Constants.XP_KILL_ENEMY
	
	# Bonus XP for higher tier enemies
	match enemy_tier:
		Enums.Tier.T2: base_xp += 5
		Enums.Tier.T3: base_xp += 10
	
	return base_xp


## Check if spirit has enough XP to evolve
static func can_evolve(spirit_data: SpiritData, current_xp: int) -> bool:
	if not spirit_data.can_evolve():
		return false
	return current_xp >= spirit_data.xp_to_evolve


# =============================================================================
# ATTACK SPEED CALCULATION
# =============================================================================

## Calculate attack interval from attack speed (includes item bonuses)
static func get_attack_interval(attack_speed: float, haste_bonus: float = 0.0) -> float:
	var effective_speed: float = attack_speed * (1.0 + haste_bonus)
	effective_speed = maxf(0.1, effective_speed)  # Cap at 10 attacks/sec
	return 1.0 / effective_speed


## Calculate attack interval from spirit data (uses effective speed with item bonuses)
static func get_spirit_attack_interval(spirit_data: SpiritData, haste_bonus: float = 0.0) -> float:
	var effective_speed: float = spirit_data.get_effective_speed() * (1.0 + haste_bonus)
	effective_speed = maxf(0.1, effective_speed)  # Cap at 10 attacks/sec
	return 1.0 / effective_speed

