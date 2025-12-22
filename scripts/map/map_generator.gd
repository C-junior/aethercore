## MapGenerator - Procedural map generation for roguelike progression
## Generates Slay the Spire-style branching maps with strategic node placement.
class_name MapGenerator
extends RefCounted


# =============================================================================
# GENERATION CONSTANTS
# =============================================================================

const NODE_SPACING_X: float = 120.0
const NODE_SPACING_Y: float = 100.0
const MAP_START_Y: float = 50.0
const MAP_WIDTH: float = 500.0


# =============================================================================
# MAIN GENERATION
# =============================================================================

## Generate a complete map for an act
## @param map_data: The MapData resource defining act parameters
## @return: Array of MapNode resources representing the complete map
static func generate_map(map_data: MapData) -> Array[MapNode]:
	var nodes: Array[MapNode] = []
	var floor_nodes: Array = []  # 2D array: floor_nodes[floor][index]
	
	# Generate each floor
	for floor_num in range(1, map_data.floor_count + 2):  # +1 for boss floor
		var floor_node_list: Array[MapNode] = _generate_floor(map_data, floor_num)
		floor_nodes.append(floor_node_list)
		nodes.append_array(floor_node_list)
	
	# Connect nodes between floors
	_connect_floors(floor_nodes)
	
	# Mark first floor as available
	for node in floor_nodes[0]:
		node.is_available = true
	
	return nodes


## Generate nodes for a single floor
static func _generate_floor(map_data: MapData, floor_num: int) -> Array[MapNode]:
	var nodes: Array[MapNode] = []
	
	# Special cases
	if floor_num == 1:
		# Floor 1: Single easy battle (tutorial)
		nodes.append(_create_battle_node(map_data, floor_num, 0, 1, false))
		return nodes
	
	if floor_num == map_data.floor_count + 1:
		# Boss floor
		nodes.append(_create_boss_node(map_data, floor_num))
		return nodes
	
	if floor_num == map_data.floor_count:
		# Pre-boss floor: Guaranteed rest or shop
		var node := MapNode.new()
		node.id = "node_%d_0" % floor_num
		node.type = map_data.pre_boss_floor_type
		node.floor_number = floor_num
		node.position = _calculate_node_position(floor_num, 0, 1)
		nodes.append(node)
		return nodes
	
	# Normal floors: Generate 2-4 nodes with varied types
	var node_count: int = randi_range(map_data.nodes_per_floor.x, map_data.nodes_per_floor.y)
	
	# Determine if shop is guaranteed on this floor
	var shop_placed: bool = not map_data.is_shop_guaranteed(floor_num)
	
	for i in node_count:
		var node := _generate_node_for_floor(map_data, floor_num, i, node_count, shop_placed)
		if node.type == MapNode.NodeType.SHOP:
			shop_placed = true
		nodes.append(node)
	
	return nodes


## Generate a single node based on floor parameters
static func _generate_node_for_floor(map_data: MapData, floor_num: int, index: int, total: int, shop_placed: bool) -> MapNode:
	var node := MapNode.new()
	node.id = "node_%d_%d" % [floor_num, index]
	node.floor_number = floor_num
	node.position = _calculate_node_position(floor_num, index, total)
	
	# Determine node type
	node.type = _roll_node_type(map_data, floor_num, shop_placed)
	
	# Set properties based on type
	match node.type:
		MapNode.NodeType.BATTLE:
			_setup_battle_node(node, map_data, floor_num, false)
		MapNode.NodeType.ELITE:
			_setup_battle_node(node, map_data, floor_num, true)
		MapNode.NodeType.SHOP:
			node.gold_multiplier = 0.0
		MapNode.NodeType.CAMP:
			node.gold_multiplier = 0.0
		MapNode.NodeType.TREASURE:
			node.gold_multiplier = 2.0
		MapNode.NodeType.EVENT:
			pass
	
	return node


## Roll for node type based on weights
static func _roll_node_type(map_data: MapData, floor_num: int, shop_already_placed: bool) -> MapNode.NodeType:
	var total_weight: float = map_data.battle_weight + map_data.shop_weight + map_data.camp_weight + map_data.treasure_weight + map_data.event_weight
	
	# Add elite weight only on allowed floors
	if map_data.can_spawn_elite(floor_num):
		total_weight += map_data.elite_weight
	
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	
	# Check battle
	cumulative += map_data.battle_weight
	if roll < cumulative:
		return MapNode.NodeType.BATTLE
	
	# Check elite (if allowed)
	if map_data.can_spawn_elite(floor_num):
		cumulative += map_data.elite_weight
		if roll < cumulative:
			return MapNode.NodeType.ELITE
	
	# Check shop (skip if guaranteed shop already placed)
	if not shop_already_placed:
		cumulative += map_data.shop_weight
		if roll < cumulative:
			return MapNode.NodeType.SHOP
	else:
		cumulative += map_data.shop_weight * 0.3  # Reduced chance for extra shops
		if roll < cumulative:
			return MapNode.NodeType.SHOP
	
	# Check camp
	cumulative += map_data.camp_weight
	if roll < cumulative:
		return MapNode.NodeType.CAMP
	
	# Check treasure
	cumulative += map_data.treasure_weight
	if roll < cumulative:
		return MapNode.NodeType.TREASURE
	
	# Check event
	cumulative += map_data.event_weight
	if roll < cumulative:
		return MapNode.NodeType.EVENT
	
	# Default to battle
	return MapNode.NodeType.BATTLE


## Create a battle-specific node
static func _create_battle_node(map_data: MapData, floor_num: int, index: int, total: int, is_elite: bool) -> MapNode:
	var node := MapNode.new()
	node.id = "node_%d_%d" % [floor_num, index]
	node.floor_number = floor_num
	node.position = _calculate_node_position(floor_num, index, total)
	node.type = MapNode.NodeType.ELITE if is_elite else MapNode.NodeType.BATTLE
	_setup_battle_node(node, map_data, floor_num, is_elite)
	return node


## Configure a battle node's encounter properties
static func _setup_battle_node(node: MapNode, map_data: MapData, floor_num: int, is_elite: bool) -> void:
	node.is_elite = is_elite
	node.element = map_data.get_random_element()
	node.spirit_reward_element = node.element
	
	# Enemy count scales with floor
	if floor_num <= 2:
		node.enemy_count = 1
	elif floor_num <= 5:
		node.enemy_count = 2
	else:
		node.enemy_count = randi_range(2, 3)
	
	# Elite encounters have more enemies
	if is_elite:
		node.enemy_count += 1
		node.gold_multiplier = 2.0
		node.xp_multiplier = 1.5
	
	# Enemy tier scales with floor
	if floor_num >= 7:
		node.enemy_tier = 2
	elif floor_num >= 4:
		node.enemy_tier = randi_range(1, 2)
	else:
		node.enemy_tier = 1


## Create the boss node
static func _create_boss_node(map_data: MapData, floor_num: int) -> MapNode:
	var node := MapNode.new()
	node.id = "node_boss"
	node.type = MapNode.NodeType.BOSS
	node.floor_number = floor_num
	node.position = _calculate_node_position(floor_num, 0, 1)
	node.enemy_count = 1
	node.enemy_tier = 3
	node.is_elite = true
	node.gold_multiplier = 5.0
	node.xp_multiplier = 3.0
	return node


## Calculate visual position for a node on the map
static func _calculate_node_position(floor_num: int, index: int, total: int) -> Vector2:
	var y: float = MAP_START_Y + (floor_num - 1) * NODE_SPACING_Y
	
	if total == 1:
		return Vector2(MAP_WIDTH / 2.0, y)
	
	var spacing: float = MAP_WIDTH / (total + 1)
	var x: float = spacing * (index + 1)
	
	# Add slight randomness for visual variety
	x += randf_range(-15.0, 15.0)
	y += randf_range(-8.0, 8.0)
	
	return Vector2(x, y)


# =============================================================================
# CONNECTION LOGIC
# =============================================================================

## Connect nodes between floors (Slay the Spire style)
static func _connect_floors(floor_nodes: Array) -> void:
	for floor_idx in range(floor_nodes.size() - 1):
		var current_floor: Array = floor_nodes[floor_idx]
		var next_floor: Array = floor_nodes[floor_idx + 1]
		
		if current_floor.is_empty() or next_floor.is_empty():
			continue
		
		# Each node connects to 1-2 nodes on next floor
		for node in current_floor:
			var connections: Array[String] = _get_valid_connections(node, next_floor)
			node.connected_nodes = connections
		
		# Ensure all next floor nodes are reachable
		_ensure_all_reachable(current_floor, next_floor)


## Get valid connection targets for a node
static func _get_valid_connections(node: MapNode, next_floor: Array) -> Array[String]:
	var connections: Array[String] = []
	
	if next_floor.size() == 1:
		# Only one option - connect to it
		connections.append(next_floor[0].id)
		return connections
	
	# Find closest nodes by position
	var sorted_by_distance: Array = next_floor.duplicate()
	sorted_by_distance.sort_custom(func(a: MapNode, b: MapNode) -> bool:
		return abs(a.position.x - node.position.x) < abs(b.position.x - node.position.x)
	)
	
	# Connect to 1-2 closest nodes
	var connection_count: int = randi_range(1, mini(2, sorted_by_distance.size()))
	for i in connection_count:
		connections.append(sorted_by_distance[i].id)
	
	return connections


## Ensure all nodes on next floor are reachable from at least one previous node
static func _ensure_all_reachable(current_floor: Array, next_floor: Array) -> void:
	for next_node in next_floor:
		var is_reachable: bool = false
		
		for current_node in current_floor:
			if next_node.id in current_node.connected_nodes:
				is_reachable = true
				break
		
		if not is_reachable:
			# Find closest node on current floor and add connection
			var closest: MapNode = null
			var min_distance: float = INF
			
			for current_node in current_floor:
				var dist: float = abs(current_node.position.x - next_node.position.x)
				if dist < min_distance:
					min_distance = dist
					closest = current_node
			
			if closest:
				closest.connected_nodes.append(next_node.id)
