## ShopUI - Shop interface for purchasing spirits
## Handles shop display, purchases, rerolls, and drag-drop selling.
extends Control


# =============================================================================
# SIGNALS
# =============================================================================

signal spirit_purchased(shop_index: int)
signal reroll_requested
signal sell_requested(spirit: Node)


# =============================================================================
# NODES
# =============================================================================

@onready var shop_container: HBoxContainer = $ShopContainer
@onready var reroll_button: Button = $RerollButton
@onready var gold_label: Label = $GoldLabel
@onready var sell_zone: Control = $SellZone


# =============================================================================
# STATE
# =============================================================================

var shop_slots: Array[Control] = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_shop_slots()
	_connect_signals()
	update_display()


func _create_shop_slots() -> void:
	for child in shop_container.get_children():
		child.queue_free()
	
	shop_slots.clear()
	
	for i in Constants.SHOP_SIZE:
		var slot := _create_shop_slot(i)
		shop_container.add_child(slot)
		shop_slots.append(slot)


func _create_shop_slot(index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 140)
	panel.name = "ShopSlot_%d" % index
	
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(80, 80)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(portrait)
	
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.text = "%d G" % Constants.SPIRIT_COST
	vbox.add_child(cost_label)
	
	var buy_button := Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "Buy"
	buy_button.pressed.connect(_on_buy_pressed.bind(index))
	vbox.add_child(buy_button)
	
	return panel


func _connect_signals() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.shop_rerolled.connect(_on_shop_rerolled)
	EventBus.spirit_purchased.connect(_on_spirit_purchased_event)


# =============================================================================
# DISPLAY
# =============================================================================

func update_display() -> void:
	_update_gold_display()
	_update_shop_slots()
	_update_button_states()


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % GameManager.gold


func _update_shop_slots() -> void:
	for i in shop_slots.size():
		var slot: Control = shop_slots[i]
		var spirit_data: SpiritData = null
		
		if i < GameManager.shop_offerings.size():
			spirit_data = GameManager.shop_offerings[i] as SpiritData
		
		_update_slot_display(slot, spirit_data)


func _update_slot_display(slot: Control, spirit_data: SpiritData) -> void:
	var portrait: TextureRect = slot.get_node("VBoxContainer/Portrait") if slot.has_node("VBoxContainer/Portrait") else null
	var name_label: Label = slot.get_node("VBoxContainer/NameLabel") if slot.has_node("VBoxContainer/NameLabel") else null
	var buy_button: Button = slot.get_node("VBoxContainer/BuyButton") if slot.has_node("VBoxContainer/BuyButton") else null
	
	if spirit_data:
		slot.visible = true
		if portrait and spirit_data.portrait:
			portrait.texture = spirit_data.portrait
		if name_label:
			name_label.text = spirit_data.display_name
		if buy_button:
			buy_button.disabled = GameManager.gold < Constants.SPIRIT_COST
	else:
		slot.visible = false


func _update_button_states() -> void:
	if reroll_button:
		reroll_button.disabled = GameManager.gold < Constants.REROLL_COST
		reroll_button.text = "Reroll (%dG)" % Constants.REROLL_COST


# =============================================================================
# ACTIONS
# =============================================================================

func _on_buy_pressed(index: int) -> void:
	if GameManager.purchase_spirit(index):
		update_display()


func _on_reroll_pressed() -> void:
	if GameManager.reroll_shop():
		update_display()


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	update_display()


func _on_shop_rerolled() -> void:
	update_display()


func _on_spirit_purchased_event(_spirit_data: Resource) -> void:
	update_display()


# =============================================================================
# VISIBILITY
# =============================================================================

func show_shop() -> void:
	visible = true
	update_display()


func hide_shop() -> void:
	visible = false
