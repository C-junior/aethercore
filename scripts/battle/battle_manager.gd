## BattleManager - Controls battle flow and state
## Manages battle start/end, team references, and combat orchestration.
class_name BattleManager
extends Node


# =============================================================================
# SIGNALS
# =============================================================================

signal battle_ready
signal battle_tick(delta: float)
signal battle_timeout


# =============================================================================
# STATE
# =============================================================================

## Whether a battle is currently in progress
var is_battle_active: bool = false

## Current battle timer
var battle_timer: float = 0.0

## Maximum battle duration
var max_battle_time: float = Constants.BATTLE_MAX_TIME

## Reference to ally grid
var ally_grid: BattleGrid

## Reference to enemy grid
var enemy_grid: BattleGrid

## Current wave data
var current_wave: WaveData


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	add_to_group("battle_manager")
	
	EventBus.battle_requested.connect(_on_battle_requested)
	EventBus.spirit_died.connect(_on_spirit_died)


func setup(ally_grid_ref: BattleGrid, enemy_grid_ref: BattleGrid) -> void:
	ally_grid = ally_grid_ref
	enemy_grid = enemy_grid_ref


# =============================================================================
# BATTLE FLOW
# =============================================================================

func _process(delta: float) -> void:
	if not is_battle_active:
		return
	
	battle_timer += delta
	battle_tick.emit(delta)
	
	# Check for battle end conditions
	_check_battle_end()
	
	# Check timeout
	if battle_timer >= max_battle_time:
		_end_battle(Enums.BattleResult.TIMEOUT)


## Start a new battle
func start_battle(wave_data: WaveData = null) -> void:
	if is_battle_active:
		return
	
	current_wave = wave_data
	
	# Set max time based on boss status
	if current_wave and current_wave.is_boss:
		max_battle_time = Constants.BOSS_BATTLE_MAX_TIME
	else:
		max_battle_time = Constants.BATTLE_MAX_TIME
	
	# Spawn enemies from wave data
	if current_wave:
		_spawn_wave_enemies()
	
	# Trigger battle start abilities
	_trigger_battle_start_abilities()
	
	# Apply aura effects
	_calculate_aura_effects()
	
	battle_timer = 0.0
	is_battle_active = true
	
	EventBus.battle_started.emit()
	battle_ready.emit()


func _end_battle(result: Enums.BattleResult) -> void:
	is_battle_active = false
	
	# Award XP for participation
	_award_battle_xp(result)
	
	# Award gold if victory
	if result == Enums.BattleResult.VICTORY and current_wave:
		EventBus.wave_completed.emit(current_wave.wave_number, current_wave.gold_reward)
	
	# Clear enemy grid
	_cleanup_enemies()
	
	EventBus.battle_ended.emit(result)


## Check if battle should end
func _check_battle_end() -> void:
	var allies_alive: bool = _has_alive_spirits(ally_grid)
	var enemies_alive: bool = _has_alive_spirits(enemy_grid)
	
	if not allies_alive:
		_end_battle(Enums.BattleResult.DEFEAT)
	elif not enemies_alive:
		_end_battle(Enums.BattleResult.VICTORY)


func _has_alive_spirits(grid: BattleGrid) -> bool:
	if not grid:
		return false
	
	for spirit in grid.get_all_spirits():
		if spirit and spirit.is_alive():
			return true
	
	return false


# =============================================================================
# WAVE SPAWNING
# =============================================================================

func _spawn_wave_enemies() -> void:
	if not current_wave or not enemy_grid:
		return
	
	for i in current_wave.enemies.size():
		var enemy_data: SpiritData = current_wave.enemies[i]
		var position: int = current_wave.enemy_positions[i] if i < current_wave.enemy_positions.size() else i
		
		_spawn_enemy(enemy_data, position, current_wave.is_boss)


func _spawn_enemy(spirit_data: SpiritData, slot: int, is_boss: bool = false) -> void:
	var enemy_scene: PackedScene = preload("res://scenes/battle/spirit.tscn")
	var enemy: Spirit = enemy_scene.instantiate() as Spirit
	
	enemy.spirit_data = spirit_data.duplicate_spirit()
	enemy.is_enemy = true
	enemy.is_boss = is_boss
	
	# Apply wave modifiers
	if current_wave:
		enemy.max_hp = int(enemy.max_hp * current_wave.hp_multiplier)
		enemy.current_hp = enemy.max_hp
	
	enemy_grid.place_spirit(enemy, slot)


## Spawn minions (for on-death abilities like Queenopi)
func spawn_minions(spirit_data: SpiritData, count: int, for_enemy: bool, near_slot: int) -> void:
	var grid: BattleGrid = enemy_grid if for_enemy else ally_grid
	
	for i in count:
		var empty_slot: int = grid.get_first_empty_slot()
		if empty_slot >= 0:
			var minion_scene: PackedScene = preload("res://scenes/battle/spirit.tscn")
			var minion: Spirit = minion_scene.instantiate() as Spirit
			
			minion.spirit_data = spirit_data.duplicate_spirit()
			minion.is_enemy = for_enemy
			
			grid.place_spirit(minion, empty_slot)


# =============================================================================
# BATTLE START ABILITIES
# =============================================================================

func _trigger_battle_start_abilities() -> void:
	if not ally_grid:
		return
	
	var allies: Array = ally_grid.get_all_spirits()
	
	for spirit in allies:
		if spirit and spirit.is_alive():
			spirit.trigger_battle_start_ability(allies)


# =============================================================================
# AURA EFFECTS
# =============================================================================

func _calculate_aura_effects() -> void:
	if not ally_grid:
		return
	
	# Reset all aura bonuses first
	for spirit in ally_grid.get_all_spirits():
		if spirit:
			spirit.haste_bonus = 0.0
	
	# Apply aura from each spirit to adjacent allies
	for spirit in ally_grid.get_all_spirits():
		if not spirit or not spirit.is_alive():
			continue
		
		var aura: Dictionary = spirit.get_aura_bonus()
		if aura.is_empty():
			continue
		
		var adjacent: Array = ally_grid.get_adjacent_spirits(spirit.grid_slot)
		
		for ally in adjacent:
			if ally and ally.is_alive():
				# Apply attack speed bonus
				if aura.has("attack_speed_bonus"):
					ally.haste_bonus += aura.attack_speed_bonus


# =============================================================================
# TEAM ACCESS (for targeting)
# =============================================================================

## Get the enemy team for a spirit
## @param is_spirit_enemy: Is the requesting spirit an enemy?
func get_enemy_team(is_spirit_enemy: bool) -> Array:
	if is_spirit_enemy:
		return ally_grid.get_all_spirits() if ally_grid else []
	else:
		return enemy_grid.get_all_spirits() if enemy_grid else []


## Get the ally team for a spirit
func get_ally_team(is_spirit_enemy: bool) -> Array:
	if is_spirit_enemy:
		return enemy_grid.get_all_spirits() if enemy_grid else []
	else:
		return ally_grid.get_all_spirits() if ally_grid else []


# =============================================================================
# XP DISTRIBUTION
# =============================================================================

func _award_battle_xp(result: Enums.BattleResult) -> void:
	if not ally_grid:
		return
	
	for spirit in ally_grid.get_all_spirits():
		if spirit and spirit.is_alive():
			spirit.gain_xp(Constants.XP_BATTLE_PARTICIPATION)
			
			if result == Enums.BattleResult.VICTORY:
				spirit.gain_xp(Constants.XP_WIN_BATTLE_BONUS)


# =============================================================================
# CLEANUP
# =============================================================================

func _cleanup_enemies() -> void:
	if not enemy_grid:
		return
	
	for spirit in enemy_grid.get_all_spirits():
		if spirit:
			spirit.queue_free()
	
	enemy_grid.clear_grid()


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_battle_requested() -> void:
	var wave_data: WaveData = GameManager.get_current_wave_data() as WaveData
	start_battle(wave_data)


func _on_spirit_died(spirit: Node, _killer: Variant) -> void:
	if not is_battle_active:
		return
	
	# Recalculate auras when a spirit dies
	call_deferred("_calculate_aura_effects")
