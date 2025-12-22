## Constants - Global game constants for Aether Core
## Contains all tunable values for combat, economy, and progression.
extends Node


# =============================================================================
# COMBAT TIMING
# =============================================================================

## Base tick rate for combat simulation (100ms per tick)
const BASE_TICK_RATE: float = 0.1

## Duration of attack animation
const ATTACK_ANIMATION_TIME: float = 0.3

## Delay before damage is applied after attack starts
const DAMAGE_DELAY: float = 0.15

## Maximum battle duration before timeout (in seconds)
const BATTLE_MAX_TIME: float = 60.0

## Boss battle extended time
const BOSS_BATTLE_MAX_TIME: float = 90.0


# =============================================================================
# DAMAGE CALCULATIONS
# =============================================================================

## Base critical hit chance (10%)
const CRIT_CHANCE: float = 0.10

## Bonus damage on critical hit
const CRIT_BONUS_DAMAGE: int = 5

## Minimum damage per hit (after all reductions)
const MIN_DAMAGE: int = 1


# =============================================================================
# TYPE EFFECTIVENESS CHART
# =============================================================================
## Returns the damage multiplier for attacker element vs defender element
## Fire > Nature > Water > Fire (primary triangle)
## Air > Earth > Electric > Air (secondary - future)

const TYPE_CHART: Dictionary = {
	# Fire matchups
	Enums.Element.FIRE: {
		Enums.Element.FIRE: 0.75,
		Enums.Element.WATER: 0.67,
		Enums.Element.EARTH: 1.0,
		Enums.Element.AIR: 1.0,
		Enums.Element.NATURE: 1.5,
		Enums.Element.NEUTRAL: 1.0,
	},
	# Water matchups
	Enums.Element.WATER: {
		Enums.Element.FIRE: 1.5,
		Enums.Element.WATER: 0.75,
		Enums.Element.EARTH: 1.0,
		Enums.Element.AIR: 1.0,
		Enums.Element.NATURE: 0.67,
		Enums.Element.NEUTRAL: 1.0,
	},
	# Earth matchups
	Enums.Element.EARTH: {
		Enums.Element.FIRE: 1.0,
		Enums.Element.WATER: 1.0,
		Enums.Element.EARTH: 0.75,
		Enums.Element.AIR: 1.5,
		Enums.Element.NATURE: 1.0,
		Enums.Element.NEUTRAL: 1.0,
	},
	# Air matchups
	Enums.Element.AIR: {
		Enums.Element.FIRE: 1.0,
		Enums.Element.WATER: 1.0,
		Enums.Element.EARTH: 0.67,
		Enums.Element.AIR: 0.75,
		Enums.Element.NATURE: 1.0,
		Enums.Element.NEUTRAL: 1.0,
	},
	# Nature matchups
	Enums.Element.NATURE: {
		Enums.Element.FIRE: 0.67,
		Enums.Element.WATER: 1.5,
		Enums.Element.EARTH: 1.0,
		Enums.Element.AIR: 1.0,
		Enums.Element.NATURE: 0.75,
		Enums.Element.NEUTRAL: 1.0,
	},
	# Neutral matchups (for generic enemies)
	Enums.Element.NEUTRAL: {
		Enums.Element.FIRE: 1.0,
		Enums.Element.WATER: 1.0,
		Enums.Element.EARTH: 1.0,
		Enums.Element.AIR: 1.0,
		Enums.Element.NATURE: 1.0,
		Enums.Element.NEUTRAL: 1.0,
	},
}


## Get type effectiveness multiplier
static func get_type_multiplier(attacker_element: Enums.Element, defender_element: Enums.Element) -> float:
	if TYPE_CHART.has(attacker_element) and TYPE_CHART[attacker_element].has(defender_element):
		return TYPE_CHART[attacker_element][defender_element]
	return 1.0


# =============================================================================
# ECONOMY VALUES
# =============================================================================

## Starting gold for a new run
const STARTING_GOLD: int = 10

## Gold earned per wave
const WAVE_GOLD_REWARDS: Dictionary = {
	1: 5,
	2: 7,
	3: 10,
}

## Interest rate (gold per 10 saved, capped)
const INTEREST_RATE: int = 1
const INTEREST_CAP: int = 5
const INTEREST_THRESHOLD: int = 10

## Shop costs
const SPIRIT_COST: int = 3
const REROLL_COST: int = 1
const XP_PURCHASE_COST: int = 4
const XP_PURCHASE_AMOUNT: int = 10

## Sell values by tier
const SELL_VALUES: Dictionary = {
	Enums.Tier.T1: 1,
	Enums.Tier.T2: 3,
	Enums.Tier.T3: 7,
	Enums.Tier.HYPER: 10,
}


# =============================================================================
# SHOP SETTINGS
# =============================================================================

## Number of spirits shown in shop
const SHOP_SIZE: int = 3

## Number of starter options
const STARTER_OPTIONS: int = 3


# =============================================================================
# PROGRESSION (XP & EVOLUTION)
# =============================================================================

## XP required to evolve to next tier
const XP_TO_EVOLVE: Dictionary = {
	Enums.Tier.T1: 100,  ## T1 -> T2
	Enums.Tier.T2: 250,  ## T2 -> T3
	Enums.Tier.T3: 999,  ## T3 cannot evolve normally (Hyper requires item)
}

## XP gained from various actions
const XP_BATTLE_PARTICIPATION: int = 25
const XP_KILL_ENEMY: int = 15
const XP_WIN_BATTLE_BONUS: int = 10


# =============================================================================
# GRID SETTINGS
# =============================================================================

## Grid dimensions (2x2)
const GRID_ROWS: int = 2
const GRID_COLS: int = 2
const GRID_TOTAL_SLOTS: int = 4

## Slot indices
## [0, 1] = Front row
## [2, 3] = Back row
const FRONT_ROW_SLOTS: Array[int] = [0, 1]
const BACK_ROW_SLOTS: Array[int] = [2, 3]

## Adjacency map (which slots are adjacent to which)
const ADJACENCY_MAP: Dictionary = {
	0: [1, 2],      ## Slot 0 is adjacent to 1 (right) and 2 (behind)
	1: [0, 3],      ## Slot 1 is adjacent to 0 (left) and 3 (behind)
	2: [0, 3],      ## Slot 2 is adjacent to 0 (in front) and 3 (right)
	3: [1, 2],      ## Slot 3 is adjacent to 1 (in front) and 2 (left)
}


# =============================================================================
# STATUS EFFECT DEFAULTS
# =============================================================================

## Burn damage per second
const BURN_DPS: int = 3
const BURN_DURATION: float = 3.0

## Poison damage per second (per stack)
const POISON_DPS: int = 5
const POISON_DURATION: float = 2.0
const POISON_MAX_STACKS: int = 3


# =============================================================================
# BOSS: QUEENSTRUCTION
# =============================================================================

## Boss specific settings
const BOSS_T1_DAMAGE_REDUCTION: float = 0.5  ## Takes 50% less from T1 spirits
const BOSS_SWARM_CALL_COOLDOWN: float = 10.0
const BOSS_CRUSHING_MANDIBLE_DAMAGE: int = 40
const BOSS_CRUSHING_MANDIBLE_SHIELD_PIERCE: float = 0.5


# =============================================================================
# MAP & SCALING
# =============================================================================

## HP/ATK scaling per floor (percentage increase)
const FLOOR_HP_SCALING: float = 0.08
const FLOOR_ATK_SCALING: float = 0.06

## Elite encounter multipliers
const ELITE_HP_MULTIPLIER: float = 1.5
const ELITE_ATK_MULTIPLIER: float = 1.3
const ELITE_GOLD_MULTIPLIER: float = 2.0

## Team size checkpoints (recommended team size by floor)
const TEAM_SIZE_FLOOR_4: int = 2
const TEAM_SIZE_FLOOR_7: int = 3
const TEAM_SIZE_BOSS: int = 4

## Evolution checkpoints (minimum tier needed)
const EVOLUTION_FLOOR_5: int = 2  # Need T2 by floor 5
const EVOLUTION_BOSS: int = 2     # Need T2+ for boss damage

## Map generation defaults
const MAP_NODES_PER_FLOOR_MIN: int = 2
const MAP_NODES_PER_FLOOR_MAX: int = 4
const MAP_FLOORS_PER_ACT: int = 10

