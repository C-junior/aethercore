## SynergyManager - Tracks and applies synergy bonuses based on team composition
## Autoload singleton that recalculates synergies when spirits are placed/removed.
extends Node


# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when active synergies change
signal synergies_changed(active_synergies: Dictionary)

## Emitted when a specific synergy tier is activated
signal synergy_activated(element: Enums.Element, tier: int, synergy_data: SynergyData)


# =============================================================================
# SYNERGY DATA
# =============================================================================

## Loaded synergy data by element
var synergy_data: Dictionary = {}  # Enums.Element -> SynergyData

## Currently active synergies and their tier levels
var active_synergies: Dictionary = {}  # Enums.Element -> int (tier level)

## Cached total bonuses for quick access during combat
var cached_bonuses: Dictionary = {
	"attack_percent": 0.0,
	"hp_percent": 0.0,
	"speed_percent": 0.0,
	"ability_percent": 0.0,
	"damage_reduction": 0.0,
	"special_effects": []  # Array of active special effect strings
}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_load_synergies()
	_connect_signals()
	print("[SynergyManager] Initialized with %d synergy types" % synergy_data.size())


func _load_synergies() -> void:
	var synergy_dir: String = "res://resources/synergies/"
	var synergy_files: Array[String] = [
		"fire_synergy.tres",
		"water_synergy.tres",
		"earth_synergy.tres",
		"air_synergy.tres",
		"nature_synergy.tres"
	]
	
	for file_name in synergy_files:
		var path: String = synergy_dir + file_name
		if ResourceLoader.exists(path):
			var data: SynergyData = load(path) as SynergyData
			if data:
				synergy_data[data.element] = data
				print("[SynergyManager] Loaded synergy: %s (%s)" % [data.display_name, file_name])


func _connect_signals() -> void:
	# Connect to grid change events
	if EventBus.has_signal("spirit_placed"):
		EventBus.spirit_placed.connect(_on_grid_changed)
	if EventBus.has_signal("spirit_removed"):
		EventBus.spirit_removed.connect(_on_grid_changed)
	
	# Also recalculate on phase changes (in case grid was modified)
	EventBus.phase_changed.connect(_on_phase_changed)


# =============================================================================
# SYNERGY CALCULATION
# =============================================================================

## Recalculate all active synergies based on current grid state
func recalculate_synergies() -> void:
	var old_synergies: Dictionary = active_synergies.duplicate()
	
	# Count spirits per element on grid
	var element_counts: Dictionary = {}
	for spirit in GameManager.grid_spirits:
		if spirit and spirit is SpiritData:
			var elem: Enums.Element = spirit.element
			element_counts[elem] = element_counts.get(elem, 0) + 1
	
	# Determine active synergy tiers
	active_synergies.clear()
	for element in element_counts:
		if synergy_data.has(element):
			var count: int = element_counts[element]
			var data: SynergyData = synergy_data[element]
			var tier: int = data.get_tier_for_count(count)
			if tier > 0:
				active_synergies[element] = tier
				
				# Check if this is a new activation
				if not old_synergies.has(element) or old_synergies[element] < tier:
					synergy_activated.emit(element, tier, data)
	
	# Recache bonuses
	_update_cached_bonuses()
	
	# Emit change signal
	synergies_changed.emit(active_synergies)
	
	print("[SynergyManager] Active synergies: %s" % str(active_synergies))


func _update_cached_bonuses() -> void:
	# Reset cached values
	cached_bonuses["attack_percent"] = 0.0
	cached_bonuses["hp_percent"] = 0.0
	cached_bonuses["speed_percent"] = 0.0
	cached_bonuses["ability_percent"] = 0.0
	cached_bonuses["damage_reduction"] = 0.0
	cached_bonuses["special_effects"] = []
	
	# Accumulate bonuses from all active synergies
	for element in active_synergies:
		var tier: int = active_synergies[element]
		var data: SynergyData = synergy_data[element]
		var bonuses: Dictionary = data.get_tier_bonuses(tier)
		
		cached_bonuses["attack_percent"] += bonuses.get("attack_percent", 0.0)
		cached_bonuses["hp_percent"] += bonuses.get("hp_percent", 0.0)
		cached_bonuses["speed_percent"] += bonuses.get("speed_percent", 0.0)
		cached_bonuses["ability_percent"] += bonuses.get("ability_percent", 0.0)
		cached_bonuses["damage_reduction"] += bonuses.get("damage_reduction", 0.0)
		
		var special: String = bonuses.get("special_effect", "")
		if special != "":
			cached_bonuses["special_effects"].append(special)


# =============================================================================
# PUBLIC ACCESSORS (for combat calculations)
# =============================================================================

## Get total attack bonus from synergies
func get_attack_bonus() -> float:
	return cached_bonuses["attack_percent"]


## Get total HP bonus from synergies
func get_hp_bonus() -> float:
	return cached_bonuses["hp_percent"]


## Get total speed bonus from synergies
func get_speed_bonus() -> float:
	return cached_bonuses["speed_percent"]


## Get total ability power bonus from synergies
func get_ability_bonus() -> float:
	return cached_bonuses["ability_percent"]


## Get total damage reduction from synergies
func get_damage_reduction() -> float:
	return cached_bonuses["damage_reduction"]


## Check if a specific special effect is active
func has_special_effect(effect_name: String) -> bool:
	return effect_name in cached_bonuses["special_effects"]


## Get all active special effects
func get_special_effects() -> Array:
	return cached_bonuses["special_effects"]


## Get the synergy data for an element
func get_synergy_for_element(element: Enums.Element) -> SynergyData:
	return synergy_data.get(element, null)


## Get active tier for an element (0 if not active)
func get_active_tier(element: Enums.Element) -> int:
	return active_synergies.get(element, 0)


## Get all active synergies as [{element, tier, data}]
func get_active_synergy_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for element in active_synergies:
		result.append({
			"element": element,
			"tier": active_synergies[element],
			"data": synergy_data[element]
		})
	return result


# =============================================================================
# SPIRIT-SPECIFIC BONUSES
# =============================================================================

## Get synergy bonuses applicable to a specific spirit
## @param spirit: The SpiritData to check
## @return: Dictionary of bonuses this spirit receives from synergies
func get_bonuses_for_spirit(spirit: SpiritData) -> Dictionary:
	var bonuses: Dictionary = {
		"attack_percent": 0.0,
		"hp_percent": 0.0,
		"speed_percent": 0.0,
		"ability_percent": 0.0,
		"damage_reduction": 0.0,
		"special_effects": []
	}
	
	# Spirits benefit from their own element's synergy
	var elem: Enums.Element = spirit.element
	if active_synergies.has(elem):
		var tier: int = active_synergies[elem]
		var data: SynergyData = synergy_data[elem]
		var tier_bonuses: Dictionary = data.get_tier_bonuses(tier)
		
		bonuses["attack_percent"] = tier_bonuses.get("attack_percent", 0.0)
		bonuses["hp_percent"] = tier_bonuses.get("hp_percent", 0.0)
		bonuses["speed_percent"] = tier_bonuses.get("speed_percent", 0.0)
		bonuses["ability_percent"] = tier_bonuses.get("ability_percent", 0.0)
		bonuses["damage_reduction"] = tier_bonuses.get("damage_reduction", 0.0)
		
		var special: String = tier_bonuses.get("special_effect", "")
		if special != "":
			bonuses["special_effects"].append(special)
	
	return bonuses


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_grid_changed(_spirit: Variant = null, _slot: Variant = null) -> void:
	recalculate_synergies()


func _on_phase_changed(new_phase: Enums.GamePhase, _old_phase: Enums.GamePhase) -> void:
	# Recalculate when entering preparation or battle
	if new_phase in [Enums.GamePhase.PREPARATION, Enums.GamePhase.BATTLE]:
		recalculate_synergies()
