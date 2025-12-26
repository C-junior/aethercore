## EventBus - Global signal hub for Aether Core
## All game events are channeled through this autoload for decoupled communication.
extends Node


# =============================================================================
# BATTLE EVENTS
# =============================================================================

## Emitted when a battle starts
signal battle_started

## Emitted when a battle ends
## @param result: BattleResult enum value
signal battle_ended(result: Enums.BattleResult)

## Emitted when a spirit attacks another
## @param attacker: The attacking Spirit
## @param target: The target Spirit
## @param damage: Amount of damage dealt
## @param is_crit: Whether this was a critical hit
signal spirit_attacked(attacker: Node, target: Node, damage: int, is_crit: bool)

## Emitted when a spirit takes damage
## @param spirit: The Spirit that took damage
## @param damage: Amount of damage taken
## @param source: The source of damage (Spirit or StatusEffect name)
signal spirit_damaged(spirit: Node, damage: int, source: Variant)

## Emitted when a spirit dies
## @param spirit: The Spirit that died
## @param killer: The Spirit that killed it (or null for DOT)
signal spirit_died(spirit: Node, killer: Variant)

## Emitted when a spirit heals
## @param spirit: The Spirit that healed
## @param amount: Amount healed
## @param source: Source of healing
signal spirit_healed(spirit: Node, amount: int, source: Variant)


# =============================================================================
# STATUS EFFECT EVENTS
# =============================================================================

## Emitted when a status effect is applied
## @param spirit: Target Spirit
## @param effect: StatusEffect enum value
## @param duration: Effect duration
signal status_applied(spirit: Node, effect: Enums.StatusEffect, duration: float)

## Emitted when a status effect expires or is removed
## @param spirit: Target Spirit
## @param effect: StatusEffect enum value
signal status_removed(spirit: Node, effect: Enums.StatusEffect)


# =============================================================================
# EVOLUTION EVENTS
# =============================================================================

## Emitted when a spirit gains XP
## @param spirit: The Spirit that gained XP
## @param amount: XP gained
## @param new_total: New total XP
signal xp_gained(spirit: Node, amount: int, new_total: int)

## Emitted when a spirit evolves
## @param old_spirit: The SpiritData before evolution
## @param new_spirit: The SpiritData after evolution
signal spirit_evolved(old_spirit: Resource, new_spirit: Resource)


# =============================================================================
# ECONOMY EVENTS
# =============================================================================

## Emitted when gold amount changes
## @param new_amount: New gold total
## @param delta: Change amount (positive = gain, negative = spent)
signal gold_changed(new_amount: int, delta: int)

## Emitted when a spirit is purchased from shop
## @param spirit_data: The SpiritData resource purchased
signal spirit_purchased(spirit_data: Resource)

## Emitted when a spirit is sold
## @param spirit: The Spirit sold
## @param gold_value: Gold received
signal spirit_sold(spirit: Node, gold_value: int)

## Emitted when shop is rerolled
signal shop_rerolled


# =============================================================================
# WAVE & PROGRESSION EVENTS
# =============================================================================

## Emitted when a wave is completed
## @param wave_number: The wave that was completed
## @param gold_reward: Gold earned
signal wave_completed(wave_number: int, gold_reward: int)

## Emitted when entering a new wave
## @param wave_number: The new wave number
## @param is_boss: Whether this is a boss wave
signal wave_started(wave_number: int, is_boss: bool)


# =============================================================================
# GAME PHASE EVENTS
# =============================================================================

## Emitted when game phase changes
## @param new_phase: The new GamePhase
## @param old_phase: The previous GamePhase
signal phase_changed(new_phase: Enums.GamePhase, old_phase: Enums.GamePhase)

## Emitted when player selects a starter spirit
## @param spirit_data: The chosen SpiritData
signal starter_selected(spirit_data: Resource)

## Emitted when player clicks "Start Battle" button
signal battle_requested

## Emitted when a run ends (victory or defeat)
## @param is_victory: Whether the player won
signal run_ended(is_victory: bool)


# =============================================================================
# UI EVENTS
# =============================================================================

## Emitted when a spirit is selected (clicked)
## @param spirit: The selected Spirit node (or null if deselected)
signal spirit_selected(spirit: Variant)

## Emitted when player tries to drag a spirit
## @param spirit: The Spirit being dragged
signal spirit_drag_started(spirit: Node)

## Emitted when player drops a spirit
## @param spirit: The Spirit dropped
## @param slot_index: Target grid slot (-1 if invalid)
signal spirit_drag_ended(spirit: Node, slot_index: int)

## Emitted to show floating text (damage numbers, gold, etc.)
## @param position: World position to show text
## @param text: Text to display
## @param color: Text color
signal floating_text_requested(position: Vector2, text: String, color: Color)


# =============================================================================
# ABILITY EVENTS
# =============================================================================

## Emitted when an ability activates
## @param spirit: The Spirit using the ability
## @param ability_name: Name of the ability
## @param targets: Array of affected targets
signal ability_activated(spirit: Node, ability_name: String, targets: Array)

## Emitted when aura effects need recalculation (positioning changed)
signal auras_recalculate_requested


# =============================================================================
# MAP & ACT EVENTS
# =============================================================================

## Emitted when a map node is selected
## @param node: The MapNode resource selected
signal map_node_selected(node: Resource)

## Emitted when a new map is generated
## @param nodes: Array of MapNode resources
signal map_generated(nodes: Array)

## Emitted when an act is completed (boss defeated)
## @param act_number: The act that was completed
signal act_completed(act_number: int)

## Emitted when a new act starts
## @param act_number: The act number starting
## @param map_data: The MapData resource for this act
signal act_started(act_number: int, map_data: Resource)

## Emitted when a node encounter is completed
## @param node: The MapNode that was completed
## @param reward_spirit: Optional spirit reward from the encounter
signal node_completed(node: Resource, reward_spirit: Resource)

## Emitted when player captures a spirit from battle
## @param spirit_data: The captured SpiritData
signal spirit_captured(spirit_data: Resource)


# =============================================================================
# ITEM EVENTS
# =============================================================================

## Emitted when an item is equipped to a spirit
## @param item: The ItemData equipped
## @param spirit: The SpiritData receiving the item
signal item_equipped(item: Resource, spirit: Resource)

## Emitted when an item is selected for equipping
## @param item: The ItemData selected (null if deselected)
signal item_selected(item: Resource)


# =============================================================================
# BENCH & PASSIVE XP EVENTS
# =============================================================================

## Emitted when bench spirits receive passive XP
## @param spirits: Array of SpiritData that received XP
## @param xp_amount: XP awarded to each
signal bench_xp_awarded(spirits: Array, xp_amount: int)

## Emitted when a Hyper Evolution is triggered
## @param old_spirit: The T3 spirit being evolved
## @param new_spirit: The Hyper form result
signal hyper_evolution_triggered(old_spirit: Resource, new_spirit: Resource)


# =============================================================================
# SPIRIT HOVER EVENTS
# =============================================================================

## Emitted when mouse hovers over a spirit (bench or grid)
## @param spirit_data: The SpiritData being hovered
## @param screen_pos: Screen position for tooltip placement
signal spirit_hovered(spirit_data: Resource, screen_pos: Vector2)

## Emitted when mouse leaves a spirit
signal spirit_unhovered


# =============================================================================
# GRID MANAGEMENT EVENTS
# =============================================================================

## Emitted when a spirit is placed on the battle grid
## @param spirit_data: The SpiritData placed
## @param slot_index: Grid slot index (0-3)
signal spirit_placed(spirit_data: Resource, slot_index: int)

## Emitted when a spirit is removed from the battle grid
## @param spirit_data: The SpiritData removed
## @param slot_index: Grid slot index it was removed from
signal spirit_removed(spirit_data: Resource, slot_index: int)
