## EventData - Resource class defining random event encounters
## Events present players with choices that have different outcomes.
class_name EventData
extends Resource


# =============================================================================
# IDENTITY
# =============================================================================

## Unique identifier for this event
@export var id: String = ""

## Display title
@export var title: String = ""

## Event description/narrative
@export_multiline var description: String = ""

## Icon emoji for UI display
@export var icon: String = "❓"


# =============================================================================
# CHOICES
# =============================================================================

## Available choices for this event
## Each choice is a Dictionary with:
##   - text: String - Display text for the choice button
##   - outcome_text: String - Text shown after choosing
##   - effects: Dictionary - Effects to apply
##     - gold: int (positive = gain, negative = spend)
##     - xp: int - XP for all spirits
##     - heal_percent: float - Heal spirits by this percentage (0.0-1.0)
##     - damage_percent: float - Damage spirits by this percentage
##     - item_id: String - Give an item
##     - spirit_element: int - Give a random spirit of this element
##     - remove_spirit: bool - Lose a random bench spirit
@export var choices: Array[Dictionary] = []


# =============================================================================
# CONDITIONS
# =============================================================================

## Minimum act this event can appear in (1-3)
@export var min_act: int = 1

## Maximum act this event can appear in (1-3)
@export var max_act: int = 3

## Weight for random selection (higher = more common)
@export var weight: float = 1.0

## Whether this event can only occur once per run
@export var one_time: bool = false


# =============================================================================
# HELPERS
# =============================================================================

## Get choice text by index
func get_choice_text(index: int) -> String:
	if index < 0 or index >= choices.size():
		return ""
	return choices[index].get("text", "???")


## Get outcome text by index
func get_outcome_text(index: int) -> String:
	if index < 0 or index >= choices.size():
		return ""
	return choices[index].get("outcome_text", "")


## Get effects for a choice
func get_choice_effects(index: int) -> Dictionary:
	if index < 0 or index >= choices.size():
		return {}
	return choices[index].get("effects", {})
