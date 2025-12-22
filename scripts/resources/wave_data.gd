## WaveData - Resource class defining enemy wave configuration
## Each wave specifies enemies, positions, rewards, and boss status.
@tool
class_name WaveData
extends Resource


# =============================================================================
# WAVE IDENTITY
# =============================================================================

## Wave number (1-indexed)
@export var wave_number: int = 1

## Display name (e.g., "Wave 1" or "BOSS: Queenstruction")
@export var display_name: String = ""


# =============================================================================
# ENEMIES
# =============================================================================

## Enemy spirit data resources
@export var enemies: Array[SpiritData] = []

## Grid positions for each enemy (parallel array with enemies)
## Values 0-3 correspond to grid slots
@export var enemy_positions: Array[int] = []


# =============================================================================
# REWARDS
# =============================================================================

## Gold earned for completing this wave
@export var gold_reward: int = 5


# =============================================================================
# BOSS
# =============================================================================

## Whether this is a boss wave
@export var is_boss: bool = false

## Boss intro text (displayed before boss fight)
@export_multiline var boss_intro_text: String = ""


# =============================================================================
# MODIFIERS (Future scaling)
# =============================================================================

@export_group("Modifiers")

## HP multiplier for all enemies in this wave
@export var hp_multiplier: float = 1.0

## Attack multiplier for all enemies in this wave
@export var attack_multiplier: float = 1.0


# =============================================================================
# HELPERS
# =============================================================================

## Get total enemy count
func get_enemy_count() -> int:
	return enemies.size()


## Validate that positions match enemies
func is_valid() -> bool:
	return enemies.size() == enemy_positions.size()


## Get enemy at specific grid position
func get_enemy_at_position(slot: int) -> SpiritData:
	for i in enemy_positions.size():
		if enemy_positions[i] == slot and i < enemies.size():
			return enemies[i]
	return null
