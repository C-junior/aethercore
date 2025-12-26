## GameManager - Global game state manager for Aether Core
## Handles run state, spirit pool, economy, map progression, and phase transitions.
extends Node


# =============================================================================
# RUN STATE
# =============================================================================

## Current gold amount
var gold: int = Constants.STARTING_GOLD:
	set(value):
		var delta: int = value - gold
		gold = max(0, value)
		EventBus.gold_changed.emit(gold, delta)

## Current act number (1-3)
var current_act: int = 1

## Current game phase
var current_phase: Enums.GamePhase = Enums.GamePhase.STARTER_SELECTION:
	set(value):
		var old_phase: Enums.GamePhase = current_phase
		current_phase = value
		EventBus.phase_changed.emit(current_phase, old_phase)

## Player's owned spirits (SpiritData resources)
var owned_spirits: Array[Resource] = []

## Spirits currently placed on grid (index = slot, null = empty)
var grid_spirits: Array = [null, null, null, null]

## Shop offerings (SpiritData resources)
var shop_offerings: Array[Resource] = []

## Player's item inventory (ItemData resources)
var item_inventory: Array[Resource] = []


# =============================================================================
# MAP STATE
# =============================================================================

## Current map data resource
var current_map_data: MapData = null

## Generated map nodes for current act
var current_map: Array[MapNode] = []

## Currently selected node ID
var current_node_id: String = ""

## IDs of visited nodes
var visited_nodes: Array[String] = []

## Current node being encountered (for battle/shop/etc)
var active_node: MapNode = null


# =============================================================================
# SPIRIT POOL
# =============================================================================

## All available spirit data resources (loaded at start)
var spirit_pool: Array[Resource] = []

## Starter spirit options
var starter_spirits: Array[Resource] = []

## Spirits organized by element (for elemental encounters)
var spirits_by_element: Dictionary = {}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_load_spirit_pool()
	_connect_signals()


func _load_spirit_pool() -> void:
	# Load all T1 spirits from resources folder
	var spirit_dirs: Array[String] = ["fire", "water", "earth", "air", "nature"]
	
	for element_dir in spirit_dirs:
		var path: String = "res://resources/spirits/%s/" % element_dir
		var dir := DirAccess.open(path)
		
		if dir:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			
			while file_name != "":
				if file_name.ends_with("_t1.tres"):
					var spirit: Resource = load(path + file_name)
					if spirit:
						spirit_pool.append(spirit)
						# Also organize by element
						var element: int = spirit.get("element") if spirit.has_method("get") else 0
						if not spirits_by_element.has(element):
							spirits_by_element[element] = []
						spirits_by_element[element].append(spirit)
				file_name = dir.get_next()
			
			dir.list_dir_end()
	
	print("[GameManager] Loaded %d spirits into pool" % spirit_pool.size())


func _connect_signals() -> void:
	EventBus.spirit_purchased.connect(_on_spirit_purchased)
	EventBus.spirit_sold.connect(_on_spirit_sold)
	EventBus.shop_rerolled.connect(_on_shop_rerolled)
	EventBus.starter_selected.connect(_on_starter_selected)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.map_node_selected.connect(_on_map_node_selected)


# =============================================================================
# RUN MANAGEMENT
# =============================================================================

## Start a new run
func start_new_run() -> void:
	gold = Constants.STARTING_GOLD
	current_act = 1
	owned_spirits.clear()
	grid_spirits = [null, null, null, null]
	shop_offerings.clear()
	current_map.clear()
	visited_nodes.clear()
	current_node_id = ""
	active_node = null
	
	# Give starter items for testing
	item_inventory.clear()
	_add_starter_items()
	
	_generate_starter_options()
	current_phase = Enums.GamePhase.STARTER_SELECTION


## Add starter items to inventory
func _add_starter_items() -> void:
	var starter_items: Array[String] = [
		"res://resources/items/iron_sword.tres",
		"res://resources/items/health_charm.tres"
	]
	
	for item_path in starter_items:
		if ResourceLoader.exists(item_path):
			var item: Resource = load(item_path)
			if item:
				item_inventory.append(item)
				print("[GameManager] Added starter item: %s" % item.get("display_name"))


## Start a specific act
func start_act(act_number: int) -> void:
	current_act = act_number
	current_map.clear()
	visited_nodes.clear()
	current_node_id = ""
	active_node = null
	
	# Load act map data
	var map_path: String = "res://resources/maps/act_%d.tres" % act_number
	if ResourceLoader.exists(map_path):
		current_map_data = load(map_path) as MapData
	else:
		push_error("[GameManager] Could not load map data for act %d" % act_number)
		return
	
	# Generate map
	current_map = MapGenerator.generate_map(current_map_data)
	
	# Set first node as current
	if current_map.size() > 0:
		current_node_id = current_map[0].id
		current_map[0].is_available = true
	
	EventBus.act_started.emit(act_number, current_map_data)
	EventBus.map_generated.emit(current_map)
	current_phase = Enums.GamePhase.MAP_SELECTION


## Generate starter spirit options
func _generate_starter_options() -> void:
	starter_spirits.clear()
	
	# For MVP, offer one of each element
	var available: Array[Resource] = spirit_pool.duplicate()
	available.shuffle()
	
	for i in Constants.STARTER_OPTIONS:
		if available.size() > 0:
			starter_spirits.append(available.pop_front())


## Calculate interest based on saved gold
func calculate_interest() -> int:
	var interest_tiers: int = gold / Constants.INTEREST_THRESHOLD
	return mini(interest_tiers * Constants.INTEREST_RATE, Constants.INTEREST_CAP)


# =============================================================================
# MAP NAVIGATION
# =============================================================================

## Select a map node to visit
func select_map_node(node_id: String) -> void:
	var node: MapNode = _get_node_by_id(node_id)
	if not node or not node.is_available or node.is_visited:
		return
	
	# Mark as current and visited
	node.is_visited = true
	node.is_available = false
	visited_nodes.append(node_id)
	active_node = node
	
	# Update connected nodes to be available
	for connected_id in node.connected_nodes:
		var connected: MapNode = _get_node_by_id(connected_id)
		if connected and not connected.is_visited:
			connected.is_available = true
	
	current_node_id = node_id
	
	# Enter the node encounter
	_enter_node(node)


## Handle entering a node
func _enter_node(node: MapNode) -> void:
	match node.type:
		MapNode.NodeType.BATTLE, MapNode.NodeType.ELITE:
			# Generate encounter and go to preparation
			generate_shop()
			current_phase = Enums.GamePhase.PREPARATION
		
		MapNode.NodeType.BOSS:
			# Boss intro then preparation
			current_phase = Enums.GamePhase.BOSS_INTRO
		
		MapNode.NodeType.SHOP:
			# Go directly to shop
			generate_shop()
			current_phase = Enums.GamePhase.SHOP
		
		MapNode.NodeType.CAMP:
			# Rest/upgrade phase
			current_phase = Enums.GamePhase.CAMP
		
		MapNode.NodeType.TREASURE:
			# Auto-reward and return to map
			_give_treasure_rewards(node)
			_complete_node(node)
		
		MapNode.NodeType.EVENT:
			# TODO: Event system
			_complete_node(node)


## Complete current node and return to map
func _complete_node(node: MapNode, reward_spirit: Resource = null) -> void:
	EventBus.node_completed.emit(node, reward_spirit)
	
	# Check for boss completion
	if node.type == MapNode.NodeType.BOSS:
		_on_boss_defeated()
	else:
		current_phase = Enums.GamePhase.MAP_SELECTION


## Handle boss defeat
func _on_boss_defeated() -> void:
	if current_act >= 3:
		# Game won!
		EventBus.run_ended.emit(true)
		current_phase = Enums.GamePhase.GAME_OVER
	else:
		# Proceed to next act
		EventBus.act_completed.emit(current_act)
		current_phase = Enums.GamePhase.ACT_COMPLETE


## Proceed to next act after completion screen
func proceed_to_next_act() -> void:
	start_act(current_act + 1)


func _get_node_by_id(node_id: String) -> MapNode:
	for node in current_map:
		if node.id == node_id:
			return node
	return null


func _give_treasure_rewards(node: MapNode) -> void:
	# Give gold based on floor
	var gold_reward: int = int(current_map_data.get_floor_gold_reward(node.floor_number) * node.gold_multiplier)
	gold += gold_reward
	print("[GameManager] Treasure rewards: +%d gold" % gold_reward)


# =============================================================================
# ENCOUNTER GENERATION
# =============================================================================

## Get encounter data for current active node
func get_current_encounter() -> Dictionary:
	if not active_node:
		return {}
	
	var encounter: Dictionary = {
		"element": active_node.element,
		"enemy_count": active_node.enemy_count,
		"enemy_tier": active_node.enemy_tier,
		"is_elite": active_node.is_elite,
		"is_boss": active_node.type == MapNode.NodeType.BOSS,
		"hp_multiplier": current_map_data.get_floor_hp_multiplier(active_node.floor_number) if current_map_data else 1.0,
		"atk_multiplier": current_map_data.get_floor_atk_multiplier(active_node.floor_number) if current_map_data else 1.0,
		"gold_reward": int(current_map_data.get_floor_gold_reward(active_node.floor_number) * active_node.gold_multiplier) if current_map_data else 10,
	}
	
	# For elite/boss, apply additional multipliers
	if active_node.is_elite:
		encounter["hp_multiplier"] *= 1.5
		encounter["atk_multiplier"] *= 1.3
	
	return encounter


## Get a spirit of a specific element for rewards
func get_spirit_by_element(element: Enums.Element) -> Resource:
	if spirits_by_element.has(element) and spirits_by_element[element].size() > 0:
		var spirits: Array = spirits_by_element[element]
		return spirits[randi() % spirits.size()]
	
	# Fallback to random
	if spirit_pool.size() > 0:
		return spirit_pool[randi() % spirit_pool.size()]
	
	return null


# =============================================================================
# SHOP MANAGEMENT
# =============================================================================

## Generate new shop offerings
func generate_shop() -> void:
	shop_offerings.clear()
	
	# Prefer spirits of active node's element if in a battle node
	var preferred_element: Enums.Element = Enums.Element.NEUTRAL
	if active_node and (active_node.type == MapNode.NodeType.BATTLE or active_node.type == MapNode.NodeType.ELITE):
		preferred_element = active_node.element
	
	var available: Array[Resource] = spirit_pool.duplicate()
	available.shuffle()
	
	# Add one guaranteed spirit of the node's element
	if preferred_element != Enums.Element.NEUTRAL and spirits_by_element.has(preferred_element):
		var element_spirits: Array = spirits_by_element[preferred_element]
		if element_spirits.size() > 0:
			var guaranteed: Resource = element_spirits[randi() % element_spirits.size()]
			shop_offerings.append(guaranteed)
			available.erase(guaranteed)
	
	# Fill rest randomly
	for i in range(shop_offerings.size(), Constants.SHOP_SIZE):
		if available.size() > 0:
			shop_offerings.append(available.pop_front())


## Attempt to purchase a spirit from shop
## @param shop_index: Index in shop_offerings array
## @return: true if purchase successful
func purchase_spirit(shop_index: int) -> bool:
	if shop_index < 0 or shop_index >= shop_offerings.size():
		return false
	
	if gold < Constants.SPIRIT_COST:
		return false
	
	var spirit_data: Resource = shop_offerings[shop_index]
	if spirit_data == null:
		return false
	
	gold -= Constants.SPIRIT_COST
	owned_spirits.append(spirit_data)
	shop_offerings[shop_index] = null  # Mark slot as purchased
	
	EventBus.spirit_purchased.emit(spirit_data)
	return true


## Attempt to reroll the shop
## @return: true if reroll successful
func reroll_shop() -> bool:
	if gold < Constants.REROLL_COST:
		return false
	
	gold -= Constants.REROLL_COST
	generate_shop()
	EventBus.shop_rerolled.emit()
	return true


## Sell a spirit
## @param spirit_data: The SpiritData to sell
## @param tier: The spirit's current tier (for sell value)
func sell_spirit(spirit_data: Resource, tier: Enums.Tier = Enums.Tier.T1) -> void:
	var sell_value: int = Constants.SELL_VALUES.get(tier, 1)
	gold += sell_value
	
	# Remove from owned if present
	var idx: int = owned_spirits.find(spirit_data)
	if idx >= 0:
		owned_spirits.remove_at(idx)


# =============================================================================
# GRID MANAGEMENT
# =============================================================================

## Place a spirit on a grid slot
## @param spirit_data: The SpiritData to place
## @param slot_index: Grid slot (0-3)
## @return: true if placement successful
func place_spirit_on_grid(spirit_data: Resource, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= Constants.GRID_TOTAL_SLOTS:
		return false
	
	# If slot is occupied, swap
	var existing: Resource = grid_spirits[slot_index]
	grid_spirits[slot_index] = spirit_data
	
	if existing and existing != spirit_data:
		# Find where the new spirit was and put the old one there
		for i in grid_spirits.size():
			if grid_spirits[i] == spirit_data and i != slot_index:
				grid_spirits[i] = existing
				break
	
	EventBus.auras_recalculate_requested.emit()
	return true


## Remove a spirit from grid
## @param slot_index: Grid slot to clear
func remove_spirit_from_grid(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < Constants.GRID_TOTAL_SLOTS:
		grid_spirits[slot_index] = null
		EventBus.auras_recalculate_requested.emit()


## Get adjacent slot indices
## @param slot_index: Source slot
## @return: Array of adjacent slot indices
func get_adjacent_slots(slot_index: int) -> Array:
	if Constants.ADJACENCY_MAP.has(slot_index):
		return Constants.ADJACENCY_MAP[slot_index].duplicate()
	return []


## Get a map node by its ID
## @param node_id: The unique ID of the node
## @return: MapNode or null if not found
func get_map_node_by_id(node_id: String) -> MapNode:
	for node in current_map:
		if node.id == node_id:
			return node
	return null


## Check if a slot is in the front row
func is_front_row(slot_index: int) -> bool:
	return slot_index in Constants.FRONT_ROW_SLOTS


# =============================================================================
# ITEM MANAGEMENT
# =============================================================================

## Equip an item to a spirit
## @param item: The ItemData to equip
## @param spirit: The SpiritData to receive the item
## @return: true if equip successful
func equip_item_to_spirit(item: Resource, spirit: Resource) -> bool:
	var item_data: ItemData = item as ItemData
	var spirit_data: SpiritData = spirit as SpiritData
	
	if not item_data or not spirit_data:
		return false
	
	# Check if spirit already has an item
	if spirit_data.held_item:
		# Return existing item to inventory
		item_inventory.append(spirit_data.held_item)
	
	# Assign new item
	spirit_data.held_item = item_data
	
	# Remove item from inventory
	var idx: int = item_inventory.find(item)
	if idx >= 0:
		item_inventory.remove_at(idx)
	
	EventBus.item_equipped.emit(item, spirit)
	print("[GameManager] Equipped %s to %s" % [item_data.display_name, spirit_data.display_name])
	return true


## Add an item to player inventory
func add_item_to_inventory(item: Resource) -> void:
	if item:
		item_inventory.append(item)
		print("[GameManager] Added item to inventory: %s" % item.get("display_name"))


# =============================================================================
# BENCH XP SYSTEM
# =============================================================================

## Award XP to bench spirits after battle
## @param battle_xp: XP earned by active spirits in battle
func award_bench_xp(battle_xp: int) -> void:
	# Bench spirits get 50% of battle XP (per GDD 2.2)
	var bench_xp: int = int(battle_xp * 0.5)
	if bench_xp <= 0:
		return
	
	# Get bench spirits (owned but not on grid)
	var bench_spirits: Array = []
	for spirit in owned_spirits:
		if spirit and spirit not in grid_spirits:
			bench_spirits.append(spirit)
	
	if bench_spirits.size() == 0:
		return
	
	# Award XP to each bench spirit
	for spirit in bench_spirits:
		var spirit_data: SpiritData = spirit as SpiritData
		if spirit_data:
			_apply_xp_to_spirit(spirit_data, bench_xp)
	
	EventBus.bench_xp_awarded.emit(bench_spirits, bench_xp)
	print("[GameManager] Awarded %d bench XP to %d spirits" % [bench_xp, bench_spirits.size()])


## Apply XP to a spirit and check for evolution
func _apply_xp_to_spirit(spirit: SpiritData, xp: int) -> void:
	# Check if spirit can evolve normally
	if spirit.evolves_into and spirit.xp_to_evolve > 0:
		# Track XP (we'll need to add a current_xp property or use a dictionary)
		# For now, we'll check if accumulated XP triggers evolution
		pass  # TODO: Track spirit XP properly
	
	# Check for Hyper Evolution
	check_hyper_evolution(spirit)


# =============================================================================
# HYPER EVOLUTION
# =============================================================================

## Check if a spirit should trigger Hyper Evolution
## @param spirit: The SpiritData to check
## @return: true if Hyper Evolution was triggered
func check_hyper_evolution(spirit: Resource) -> bool:
	var spirit_data: SpiritData = spirit as SpiritData
	if not spirit_data:
		return false
	
	# Must be T3 tier
	if spirit_data.tier != Enums.Tier.T3:
		return false
	
	# Must have held item
	if not spirit_data.held_item:
		return false
	
	var held_item: ItemData = spirit_data.held_item as ItemData
	if not held_item:
		return false
	
	# Must be evolution key type
	if held_item.type != ItemData.ItemType.EVOLUTION_KEY:
		return false
	
	# Check if key matches this spirit
	if held_item.evolves_spirit_id != spirit_data.id:
		return false
	
	# Load the Hyper evolution result
	var hyper_path: String = "res://resources/spirits/"
	# Try to find the hyper form based on evolution_result_id
	var result_id: String = held_item.evolution_result_id
	if result_id.is_empty():
		return false
	
	# Search for the hyper spirit in all element folders
	var element_dirs: Array[String] = ["fire", "water", "earth", "air", "nature"]
	var hyper_spirit: SpiritData = null
	
	for element_dir in element_dirs:
		var path: String = "res://resources/spirits/%s/%s.tres" % [element_dir, result_id]
		if ResourceLoader.exists(path):
			hyper_spirit = load(path) as SpiritData
			break
	
	if not hyper_spirit:
		push_warning("[GameManager] Could not find Hyper evolution: %s" % result_id)
		return false
	
	# Trigger evolution
	var old_spirit: SpiritData = spirit_data
	
	# Replace in owned_spirits
	var idx: int = owned_spirits.find(spirit_data)
	if idx >= 0:
		owned_spirits[idx] = hyper_spirit
	
	# Replace in grid if present
	for i in grid_spirits.size():
		if grid_spirits[i] == spirit_data:
			grid_spirits[i] = hyper_spirit
			break
	
	# Consume the item
	spirit_data.held_item = null
	
	EventBus.hyper_evolution_triggered.emit(old_spirit, hyper_spirit)
	print("[GameManager] HYPER EVOLUTION: %s -> %s" % [old_spirit.display_name, hyper_spirit.display_name])
	return true



## Current wave number (legacy support)
var current_wave: int = 0

## Get wave data for current wave (legacy - now uses encounter generation)
func get_current_wave_data() -> Resource:
	# Return active node as encounter data
	if active_node:
		# Create a legacy-compatible wave data
		return _create_wave_from_node(active_node)
	
	# Fallback to old wave files
	var wave_file: String = "res://resources/waves/wave_%d.tres" % current_wave
	
	if current_wave == 4:  # Boss wave
		wave_file = "res://resources/waves/wave_boss.tres"
	
	if ResourceLoader.exists(wave_file):
		return load(wave_file)
	
	return null


func _create_wave_from_node(node: MapNode) -> Resource:
	# Create a new WaveData resource directly
	var wave := WaveData.new()
	wave.wave_number = node.floor_number
	wave.display_name = node.get_display_name()
	wave.gold_reward = int(current_map_data.get_floor_gold_reward(node.floor_number) * node.gold_multiplier) if current_map_data else 10
	wave.is_boss = node.type == MapNode.NodeType.BOSS
	wave.hp_multiplier = current_map_data.get_floor_hp_multiplier(node.floor_number) if current_map_data else 1.0
	
	# Generate enemies based on element
	for i in node.enemy_count:
		var enemy: SpiritData = _get_enemy_for_element(node.element, node.enemy_tier) as SpiritData
		if enemy:
			wave.enemies.append(enemy)
			wave.enemy_positions.append(i)
	
	return wave


func _get_enemy_for_element(element: Enums.Element, tier: int) -> Resource:
	# Use corrupted versions of player spirits when possible
	if spirits_by_element.has(element) and spirits_by_element[element].size() > 0:
		var element_spirits: Array = spirits_by_element[element]
		return element_spirits.pick_random()
	
	# Fallback: use all spirits if no matching element
	if spirit_pool.size() > 0:
		return spirit_pool.pick_random()
	
	# Legacy fallback: use dedicated enemy files
	var enemy_files: Array[String] = [
		"res://resources/enemies/goblin.tres",
		"res://resources/enemies/slime.tres",
		"res://resources/enemies/orc.tres",
	]
	
	var file: String = enemy_files[randi() % enemy_files.size()]
	if ResourceLoader.exists(file):
		return load(file)
	
	return null


## Advance to next wave (legacy - now uses map progression)
func advance_wave() -> void:
	current_wave += 1
	
	# If using old wave system, emit wave started
	var wave_data: Resource = get_current_wave_data()
	var is_boss: bool = wave_data != null and wave_data.get("is_boss") == true
	EventBus.wave_started.emit(current_wave, is_boss)


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_spirit_purchased(spirit_data: Resource) -> void:
	print("[GameManager] Spirit purchased: %s" % spirit_data.get("display_name"))


func _on_spirit_sold(_spirit: Node, _gold_value: int) -> void:
	pass  # Already handled in sell_spirit


func _on_shop_rerolled() -> void:
	print("[GameManager] Shop rerolled")


func _on_starter_selected(spirit_data: Resource) -> void:
	owned_spirits.append(spirit_data)
	# Auto-place starter in first slot
	grid_spirits[0] = spirit_data
	
	# Start Act 1
	start_act(1)


func _on_battle_ended(result: Enums.BattleResult) -> void:
	match result:
		Enums.BattleResult.VICTORY:
			# Award bench XP (base XP per battle, could be scaled by floor)
			var battle_xp: int = 25  # Base XP per battle
			if active_node:
				battle_xp = 25 + (active_node.floor_number * 5)
			award_bench_xp(battle_xp)
			
			# Victory handling (rewards, capture, node completion) 
			# is now managed by main.gd through capture UI
		
		Enums.BattleResult.DEFEAT, Enums.BattleResult.TIMEOUT:
			EventBus.run_ended.emit(false)
			current_phase = Enums.GamePhase.GAME_OVER


func _on_map_node_selected(node: Resource) -> void:
	if node is MapNode:
		select_map_node(node.id)
