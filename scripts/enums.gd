## Enums - Global enumeration types for Aether Core
## This file defines all enum types used throughout the game.
extends Node


## Element types for spirits and damage calculations
enum Element {
	FIRE,
	WATER,
	EARTH,
	AIR,
	NATURE,
	NEUTRAL  ## For enemies without elemental affinity
}


## Ability trigger types - determines when an ability activates
enum AbilityType {
	PASSIVE,       ## Always active (e.g., damage reduction)
	ON_HIT,        ## Triggers when this spirit deals damage
	ON_HURT,       ## Triggers when this spirit takes damage
	COOLDOWN,      ## Triggers every X seconds
	BATTLE_START,  ## Triggers once at battle start
	ON_DEATH,      ## Triggers when this spirit dies
	ON_KILL,       ## Triggers when this spirit kills an enemy
	AURA           ## Affects adjacent allies continuously
}


## Targeting mode for attacks
enum TargetingMode {
	FRONT_FIRST,   ## Target front row, then back row (default)
	LOWEST_HP,     ## Target enemy with lowest current HP
	HIGHEST_ATK,   ## Target enemy with highest attack
	RANDOM,        ## Random target selection
	BACK_FIRST     ## Target back row first (assassin behavior)
}


## Spirit tier/evolution level
enum Tier {
	T1 = 1,
	T2 = 2,
	T3 = 3,
	HYPER = 4  ## Future: Hyper evolution tier
}


## Status effect types
enum StatusEffect {
	BURN,      ## Fire DOT
	POISON,    ## Nature DOT (stacks)
	SHIELD,    ## Damage absorption
	TAUNT,     ## Forces enemies to target this unit
	HASTE,     ## Attack speed buff
	SLOW,      ## Attack speed debuff
	STUN       ## Cannot attack (future)
}


## Grid row position
enum GridRow {
	FRONT = 0,
	BACK = 1
}


## Game phase states
enum GamePhase {
	STARTER_SELECTION,  ## Picking initial spirit
	MAP_SELECTION,      ## Choosing next node on map
	PREPARATION,        ## Pre-battle setup, positioning
	BATTLE,             ## Combat in progress
	BATTLE_END,         ## Victory/defeat screen
	SHOP,               ## At shop node
	CAMP,               ## At camp/rest node
	BOSS_INTRO,         ## Boss encounter intro
	GAME_OVER,          ## Run ended (win or lose)
	ACT_COMPLETE,       ## Beat act boss, transition to next
}


## Battle result
enum BattleResult {
	VICTORY,
	DEFEAT,
	TIMEOUT
}
