## Spirit - Main entity script for both player and enemy spirits
## Handles stats, combat, abilities, status effects, and evolution.
class_name Spirit
extends Node2D


# =============================================================================
# SIGNALS
# =============================================================================

signal died(killer: Variant)
signal evolved(new_tier: Enums.Tier)
signal attack_performed(target: Spirit, damage: int)
signal ability_triggered(ability_name: String)
signal status_changed(effect: Enums.StatusEffect, active: bool)


# =============================================================================
# CONFIGURATION
# =============================================================================

## Spirit data resource
@export var spirit_data: SpiritData:
	set(value):
		spirit_data = value
		if value:
			_initialize_from_data()


# =============================================================================
# RUNTIME STATE
# =============================================================================

## Current health points
var current_hp: int = 100

## Maximum health (from base stats + buffs)
var max_hp: int = 100

## Current shield amount
var current_shield: int = 0

## Current XP (for evolution)
var current_xp: int = 0

## Current tier (may differ from spirit_data.tier after evolution)
var current_tier: Enums.Tier = Enums.Tier.T1

## Grid slot position (0-3)
var grid_slot: int = -1

## Whether this is an enemy (affects targeting)
var is_enemy: bool = false

## Whether this is a boss
var is_boss: bool = false

## Whether this spirit is corrupted (enemy spirits)
var is_corrupted: bool = false:
	set(value):
		is_corrupted = value
		_apply_corruption_visual()


# =============================================================================
# COMBAT STATE
# =============================================================================

## Attack timer
var attack_timer: float = 0.0

## Attack counter (for on-hit abilities)
var attack_count: int = 0

## Cooldown timers for abilities
var ability_cooldowns: Dictionary = {}

## Active status effects {effect_type: {duration: float, stacks: int}}
var status_effects: Dictionary = {}

## Haste bonus (attack speed multiplier)
var haste_bonus: float = 0.0


# =============================================================================
# NODES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var hp_bar: ProgressBar = $HPBar if has_node("HPBar") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	if spirit_data:
		_initialize_from_data()


func _initialize_from_data() -> void:
	if not spirit_data:
		return
	
	max_hp = spirit_data.base_hp
	current_hp = max_hp
	current_tier = spirit_data.tier
	attack_count = 0
	current_shield = 0
	haste_bonus = 0.0
	status_effects.clear()
	ability_cooldowns.clear()
	
	# Initialize cooldown abilities
	if spirit_data.ability_type == Enums.AbilityType.COOLDOWN:
		var cooldown: float = spirit_data.ability_params.get("cooldown", 4.0)
		ability_cooldowns["main"] = cooldown  # Start on cooldown
	
	_update_visuals()


func _update_visuals() -> void:
	if sprite and spirit_data and spirit_data.portrait:
		sprite.texture = spirit_data.portrait
	
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	
	# Apply corruption visual for enemies
	if is_enemy:
		is_corrupted = true


func _apply_corruption_visual() -> void:
	if not sprite:
		return
	
	if is_corrupted:
		# Dark purple tint for corrupted spirits
		sprite.modulate = Color(0.6, 0.3, 0.7, 1.0)
	else:
		sprite.modulate = Color.WHITE


# =============================================================================
# COMBAT LOOP
# =============================================================================

func _process(delta: float) -> void:
	if not is_alive():
		return
	
	# Update attack timer
	_process_attack_timer(delta)
	
	# Update ability cooldowns
	_process_cooldowns(delta)
	
	# Update status effects
	_process_status_effects(delta)


func _process_attack_timer(delta: float) -> void:
	attack_timer += delta
	
	var interval: float = CombatCalculator.get_attack_interval(
		spirit_data.attack_speed if spirit_data else 1.0,
		haste_bonus
	)
	
	if attack_timer >= interval:
		attack_timer -= interval
		_perform_auto_attack()


func _process_cooldowns(delta: float) -> void:
	for key in ability_cooldowns.keys():
		ability_cooldowns[key] -= delta
		
		if ability_cooldowns[key] <= 0:
			_trigger_cooldown_ability(key)
			# Reset cooldown
			if spirit_data and spirit_data.ability_type == Enums.AbilityType.COOLDOWN:
				ability_cooldowns[key] = spirit_data.ability_params.get("cooldown", 4.0)


func _process_status_effects(delta: float) -> void:
	var effects_to_remove: Array = []
	
	for effect_type in status_effects.keys():
		var effect_data: Dictionary = status_effects[effect_type]
		effect_data.duration -= delta
		
		# Apply DOT
		if effect_data.tick_timer <= 0:
			_apply_dot_damage(effect_type, effect_data.stacks)
			effect_data.tick_timer = 1.0  # Tick every second
		else:
			effect_data.tick_timer -= delta
		
		if effect_data.duration <= 0:
			effects_to_remove.append(effect_type)
	
	for effect_type in effects_to_remove:
		remove_status(effect_type)


# =============================================================================
# AUTO ATTACK
# =============================================================================

func _perform_auto_attack() -> void:
	var target: Spirit = _get_attack_target()
	if not target:
		return
	
	attack_count += 1
	
	# Calculate damage
	var damage_result: Dictionary = CombatCalculator.calculate_damage(
		spirit_data,
		target.spirit_data,
		current_tier,
		target.is_boss
	)
	
	# Apply damage
	target.take_damage(damage_result.damage, self, damage_result.is_crit)
	
	# Emit signals
	attack_performed.emit(target, damage_result.damage)
	EventBus.spirit_attacked.emit(self, target, damage_result.damage, damage_result.is_crit)
	
	# Trigger on-hit abilities
	_check_on_hit_abilities(target, damage_result)
	
	# Play attack animation
	_play_attack_animation()


func _get_attack_target() -> Spirit:
	# Get enemy team from battle manager
	var battle_manager: Node = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		return null
	
	var enemies: Array = battle_manager.get_enemy_team(is_enemy)
	var mode: Enums.TargetingMode = spirit_data.targeting_mode if spirit_data else Enums.TargetingMode.FRONT_FIRST
	
	return TargetingSystem.get_target(enemies, mode)


# =============================================================================
# DAMAGE & HEALING
# =============================================================================

## Take damage from a source
func take_damage(amount: int, source: Variant = null, is_crit: bool = false) -> void:
	if not is_alive():
		return
	
	var actual_damage: int = amount
	
	# Apply shield first
	if current_shield > 0:
		var is_mandible: bool = source is Spirit and source.is_boss and source.attack_count % 3 == 0
		var shield_result: Dictionary = CombatCalculator.calculate_shielded_damage(
			amount, current_shield, is_mandible
		)
		current_shield -= shield_result.shield_damage
		actual_damage = shield_result.hp_damage
	
	current_hp -= actual_damage
	
	# Emit damage event
	EventBus.spirit_damaged.emit(self, actual_damage, source)
	
	# Show floating damage
	var color: Color = Color.YELLOW if is_crit else Color.WHITE
	EventBus.floating_text_requested.emit(global_position, str(actual_damage), color)
	
	_update_hp_bar()
	
	# Trigger on-hurt abilities
	_check_on_hurt_abilities(source, actual_damage)
	
	# Check death
	if current_hp <= 0:
		_die(source)


## Heal HP
func heal(amount: int, source: Variant = null) -> void:
	if not is_alive():
		return
	
	var actual_heal: int = mini(amount, max_hp - current_hp)
	current_hp += actual_heal
	
	EventBus.spirit_healed.emit(self, actual_heal, source)
	EventBus.floating_text_requested.emit(global_position, "+%d" % actual_heal, Color.GREEN)
	
	_update_hp_bar()


## Apply shield
func apply_shield(amount: int) -> void:
	current_shield += amount
	# Visual feedback for shield application


func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.value = current_hp


# =============================================================================
# DEATH
# =============================================================================

func _die(killer: Variant) -> void:
	current_hp = 0
	
	# Trigger on-death abilities
	_check_on_death_abilities()
	
	# Emit signals
	died.emit(killer)
	EventBus.spirit_died.emit(self, killer)
	
	# Award XP to killer
	if killer is Spirit and not killer.is_enemy:
		var xp: int = CombatCalculator.calculate_kill_xp(current_tier)
		killer.gain_xp(xp)
		EventBus.xp_gained.emit(killer, xp, killer.current_xp)


func is_alive() -> bool:
	return current_hp > 0


# =============================================================================
# XP & EVOLUTION
# =============================================================================

## Gain XP
func gain_xp(amount: int) -> void:
	if is_enemy:
		return  # Enemies don't gain XP
	
	current_xp += amount
	
	# Check for evolution
	if CombatCalculator.can_evolve(spirit_data, current_xp):
		_evolve()


func _evolve() -> void:
	if not spirit_data or not spirit_data.evolves_into:
		return
	
	var old_tier: Enums.Tier = current_tier
	
	# Subtract XP cost
	current_xp -= spirit_data.xp_to_evolve
	
	# Update to evolved form
	spirit_data = spirit_data.evolves_into
	current_tier = spirit_data.tier
	
	# Refresh stats (keep HP percentage)
	var hp_percent: float = float(current_hp) / float(max_hp)
	max_hp = spirit_data.base_hp
	current_hp = int(max_hp * hp_percent)
	
	# Reset ability state
	attack_count = 0
	ability_cooldowns.clear()
	
	if spirit_data.ability_type == Enums.AbilityType.COOLDOWN:
		ability_cooldowns["main"] = 0  # Ready immediately after evolve
	
	# Visual update
	_update_visuals()
	
	# Emit signals
	evolved.emit(current_tier)
	EventBus.spirit_evolved.emit(self, old_tier, current_tier)
	
	# Evolution VFX
	_play_evolution_effect()


# =============================================================================
# STATUS EFFECTS
# =============================================================================

## Apply a status effect
func apply_status(effect: Enums.StatusEffect, duration: float, stacks: int = 1) -> void:
	if status_effects.has(effect):
		# Refresh duration, add stacks (up to max)
		status_effects[effect].duration = duration
		if effect == Enums.StatusEffect.POISON:
			status_effects[effect].stacks = mini(
				status_effects[effect].stacks + stacks,
				Constants.POISON_MAX_STACKS
			)
	else:
		status_effects[effect] = {
			"duration": duration,
			"stacks": stacks,
			"tick_timer": 1.0
		}
	
	status_changed.emit(effect, true)
	EventBus.status_applied.emit(self, effect, duration)


## Remove a status effect
func remove_status(effect: Enums.StatusEffect) -> void:
	if status_effects.has(effect):
		status_effects.erase(effect)
		status_changed.emit(effect, false)
		EventBus.status_removed.emit(self, effect)


## Check if has a status effect
func has_status(effect: Enums.StatusEffect) -> bool:
	return status_effects.has(effect)


func _apply_dot_damage(effect: Enums.StatusEffect, stacks: int) -> void:
	var damage: int = 0
	
	match effect:
		Enums.StatusEffect.BURN:
			damage = CombatCalculator.calculate_burn_damage()
		Enums.StatusEffect.POISON:
			damage = CombatCalculator.calculate_poison_damage(stacks)
	
	if damage > 0:
		take_damage(damage, effect)


# =============================================================================
# ABILITY TRIGGERS
# =============================================================================

func _check_on_hit_abilities(target: Spirit, damage_result: Dictionary) -> void:
	if not spirit_data or spirit_data.ability_type != Enums.AbilityType.ON_HIT:
		return
	
	var params: Dictionary = spirit_data.ability_params
	
	# Check trigger condition (e.g., every 3rd attack)
	if params.has("trigger_every"):
		if attack_count % params.trigger_every != 0:
			return
	
	# Execute ability effect
	_execute_on_hit_ability(target, params)


func _execute_on_hit_ability(target: Spirit, params: Dictionary) -> void:
	ability_triggered.emit(spirit_data.ability_name)
	
	# Bonus damage
	if params.has("bonus_damage"):
		target.take_damage(params.bonus_damage, self)
	
	# Apply burn
	if params.has("apply_burn") and params.apply_burn:
		target.apply_status(Enums.StatusEffect.BURN, Constants.BURN_DURATION)
	
	# Apply poison
	if params.has("apply_poison") and params.apply_poison:
		target.apply_status(Enums.StatusEffect.POISON, Constants.POISON_DURATION)
	
	# Lifesteal
	if params.has("heal_amount"):
		heal(params.heal_amount, self)


func _check_on_hurt_abilities(source: Variant, damage: int) -> void:
	if not spirit_data or spirit_data.ability_type != Enums.AbilityType.ON_HURT:
		return
	
	var params: Dictionary = spirit_data.ability_params
	
	# Reflect damage
	if params.has("reflect_percent") and source is Spirit:
		var reflect_damage: int = int(damage * params.reflect_percent)
		if reflect_damage > 0:
			source.take_damage(reflect_damage, self)
			ability_triggered.emit(spirit_data.ability_name)


func _check_on_death_abilities() -> void:
	if not spirit_data or spirit_data.ability_type != Enums.AbilityType.ON_DEATH:
		return
	
	var params: Dictionary = spirit_data.ability_params
	
	# Spawn minions (Queenopi)
	if params.has("spawn_on_death"):
		var battle_manager: Node = get_tree().get_first_node_in_group("battle_manager")
		if battle_manager:
			var spawn_data: SpiritData = load(params.spawn_on_death) as SpiritData
			var count: int = params.get("spawn_count", 1)
			battle_manager.spawn_minions(spawn_data, count, is_enemy, grid_slot)
		ability_triggered.emit(spirit_data.ability_name)


func _trigger_cooldown_ability(key: String) -> void:
	if not spirit_data or spirit_data.ability_type != Enums.AbilityType.COOLDOWN:
		return
	
	if key != "main":
		return
	
	var params: Dictionary = spirit_data.ability_params
	ability_triggered.emit(spirit_data.ability_name)
	
	# Heal lowest ally (Beezu)
	if params.has("heal_lowest_ally"):
		var battle_manager: Node = get_tree().get_first_node_in_group("battle_manager")
		if battle_manager:
			var allies: Array = battle_manager.get_ally_team(is_enemy)
			var target: Spirit = TargetingSystem.get_lowest_hp_ally(allies)
			if target:
				target.heal(params.heal_amount, self)


## Called at battle start for BATTLE_START abilities
func trigger_battle_start_ability(allies: Array) -> void:
	if not spirit_data or spirit_data.ability_type != Enums.AbilityType.BATTLE_START:
		return
	
	var params: Dictionary = spirit_data.ability_params
	ability_triggered.emit(spirit_data.ability_name)
	
	# Terrabear: Shield self and back row
	if params.has("shield_percent"):
		var shield_amount: int = CombatCalculator.calculate_shield_amount(max_hp, params.shield_percent)
		apply_shield(shield_amount)
		
		if params.get("affects_back_row", false):
			var back_row: Array = TargetingSystem.get_back_row_allies(allies)
			for ally in back_row:
				if ally != self:
					ally.apply_shield(shield_amount)
	
	# Zephyra: Team haste
	if params.has("team_haste"):
		var bonus: float = params.team_haste
		var duration: float = params.get("haste_duration", 5.0)
		for ally in allies:
			if ally.is_alive():
				ally.haste_bonus += bonus
				ally.apply_status(Enums.StatusEffect.HASTE, duration)


## Calculate aura bonuses for adjacent allies
func get_aura_bonus() -> Dictionary:
	if not spirit_data or spirit_data.ability_type != Enums.AbilityType.AURA:
		return {}
	
	return spirit_data.ability_params.duplicate()


# =============================================================================
# ANIMATIONS
# =============================================================================

func _play_attack_animation() -> void:
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	else:
		# Simple tween animation fallback
		var tween: Tween = create_tween()
		var attack_offset: Vector2 = Vector2(20, 0) if not is_enemy else Vector2(-20, 0)
		tween.tween_property(self, "position", position + attack_offset, 0.1)
		tween.tween_property(self, "position", position, 0.1)


func _play_evolution_effect() -> void:
	# Flash white
	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE * 2, 0.2)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	# Scale pop
	var scale_tween: Tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
