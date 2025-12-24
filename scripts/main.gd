## Main - Main game scene controller
## Manages game flow, phase transitions, and scene coordination.
extends Control


# =============================================================================
# NODES
# =============================================================================

@onready var battle_scene: Node2D = $BattleScene
@onready var shop_ui: Control = $ShopUI
@onready var hud: CanvasLayer = $HUD
@onready var starter_selection: Control = $StarterSelection
@onready var game_over_screen: Control = $GameOverScreen
@onready var map_ui: Control = $MapUI
@onready var capture_ui: Control = $CaptureUI
@onready var bench_ui: Control = $BenchUI


# =============================================================================
# REFERENCES
# =============================================================================

var battle_manager: BattleManager
var ally_grid: BattleGrid
var enemy_grid: BattleGrid


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_setup_references()
	_connect_signals()
	_start_new_run()


func _setup_references() -> void:
	if battle_scene:
		battle_manager = battle_scene.get_node_or_null("BattleManager")
		ally_grid = battle_scene.get_node_or_null("AllyGrid")
		enemy_grid = battle_scene.get_node_or_null("EnemyGrid")
		
		if battle_manager and ally_grid and enemy_grid:
			battle_manager.setup(ally_grid, enemy_grid)


func _connect_signals() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.starter_selected.connect(_on_starter_selected)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.map_generated.connect(_on_map_generated)
	EventBus.act_started.connect(_on_act_started)
	EventBus.spirit_captured.connect(_on_spirit_captured)
	
	# Connect map UI signal
	if map_ui:
		map_ui.node_selected.connect(_on_map_node_selected)
	
	# Connect capture UI signals
	if capture_ui:
		capture_ui.spirit_captured.connect(_on_capture_spirit_selected)
		capture_ui.capture_skipped.connect(_on_capture_skipped)
	
	# Connect bench UI signals
	if bench_ui:
		bench_ui.spirit_selected.connect(_on_bench_spirit_selected)
	
	# Connect ally grid signals for placement
	if ally_grid:
		ally_grid.spirit_placed.connect(_on_ally_grid_spirit_placed)


# =============================================================================
# GAME FLOW
# =============================================================================

func _start_new_run() -> void:
	GameManager.start_new_run()
	_show_starter_selection()


func _show_starter_selection() -> void:
	if starter_selection:
		starter_selection.visible = true
		_populate_starter_options()
	
	if shop_ui:
		shop_ui.visible = false
	
	if game_over_screen:
		game_over_screen.visible = false
	
	if map_ui:
		map_ui.visible = false
	
	if battle_scene:
		battle_scene.visible = false


func _populate_starter_options() -> void:
	if not starter_selection:
		return
	
	var container: Node = starter_selection.get_node_or_null("StarterContainer")
	if not container:
		return
	
	# Clear existing
	for child in container.get_children():
		child.queue_free()
	
	# Create starter buttons
	for i in GameManager.starter_spirits.size():
		var spirit_data: SpiritData = GameManager.starter_spirits[i] as SpiritData
		if spirit_data:
			var button := _create_starter_button(spirit_data, i)
			container.add_child(button)


func _create_starter_button(spirit_data: SpiritData, index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 200)
	
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(100, 100)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if spirit_data.portrait:
		portrait.texture = spirit_data.portrait
	vbox.add_child(portrait)
	
	var name_label := Label.new()
	name_label.text = spirit_data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	var element_label := Label.new()
	element_label.text = _get_element_emoji(spirit_data.element)
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(element_label)
	
	var select_button := Button.new()
	select_button.text = "Choose"
	select_button.pressed.connect(_on_starter_chosen.bind(index))
	vbox.add_child(select_button)
	
	return panel


func _get_element_emoji(element: Enums.Element) -> String:
	match element:
		Enums.Element.FIRE: return "🔥 Fire"
		Enums.Element.WATER: return "💧 Water"
		Enums.Element.EARTH: return "🪨 Earth"
		Enums.Element.AIR: return "💨 Air"
		Enums.Element.NATURE: return "🌿 Nature"
	return "⚪ Neutral"


func _on_starter_chosen(index: int) -> void:
	if index < GameManager.starter_spirits.size():
		var spirit_data: SpiritData = GameManager.starter_spirits[index]
		EventBus.starter_selected.emit(spirit_data)


# =============================================================================
# PHASE HANDLERS
# =============================================================================

func _on_phase_changed(new_phase: Enums.GamePhase, _old_phase: Enums.GamePhase) -> void:
	match new_phase:
		Enums.GamePhase.STARTER_SELECTION:
			_show_starter_selection()
		
		Enums.GamePhase.MAP_SELECTION:
			_show_map_selection()
		
		Enums.GamePhase.PREPARATION:
			_show_preparation()
		
		Enums.GamePhase.BATTLE:
			_show_battle()
		
		Enums.GamePhase.SHOP:
			_show_shop_only()
		
		Enums.GamePhase.CAMP:
			_show_camp()
		
		Enums.GamePhase.BOSS_INTRO:
			_show_boss_intro()
		
		Enums.GamePhase.ACT_COMPLETE:
			_show_act_complete()
		
		Enums.GamePhase.GAME_OVER:
			_show_game_over()


func _show_map_selection() -> void:
	if starter_selection:
		starter_selection.visible = false
	if shop_ui:
		shop_ui.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	if battle_scene:
		battle_scene.visible = false
	if bench_ui:
		bench_ui.hide_bench()
	
	# Show the map
	if map_ui and GameManager.current_map.size() > 0:
		var act_name: String = GameManager.current_map_data.display_name if GameManager.current_map_data else "Act %d" % GameManager.current_act
		map_ui.display_map(GameManager.current_map, GameManager.current_node_id, act_name)


func _show_preparation() -> void:
	if starter_selection:
		starter_selection.visible = false
	if map_ui:
		map_ui.hide_map()
	if game_over_screen:
		game_over_screen.visible = false
	
	# Shop is NOT visible during preparation - only on SHOP map nodes
	if shop_ui:
		shop_ui.visible = false
	
	# Show bench for spirit positioning
	if bench_ui:
		bench_ui.show_bench()
	
	if battle_scene:
		battle_scene.visible = true
		# Spawn allies from grid
		_sync_grid_to_battle()


func _show_battle() -> void:
	if shop_ui:
		shop_ui.visible = false
	if bench_ui:
		bench_ui.hide_bench()


func _show_shop_only() -> void:
	if starter_selection:
		starter_selection.visible = false
	if map_ui:
		map_ui.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	if battle_scene:
		battle_scene.visible = false
	
	if shop_ui:
		shop_ui.visible = true
		shop_ui.update_display()


func _show_camp() -> void:
	if starter_selection:
		starter_selection.visible = false
	if map_ui:
		map_ui.visible = false
	if battle_scene:
		battle_scene.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	if shop_ui:
		shop_ui.visible = false
	
	# TODO: Implement camp UI
	# For now, heal all spirits and return to map
	_heal_all_spirits()
	
	# Auto-complete camp node
	await get_tree().create_timer(1.0).timeout
	if GameManager.active_node:
		GameManager._complete_node(GameManager.active_node)


func _show_boss_intro() -> void:
	# TODO: Implement boss intro sequence
	# For now, skip to preparation
	await get_tree().create_timer(0.5).timeout
	GameManager.current_phase = Enums.GamePhase.PREPARATION


func _show_act_complete() -> void:
	# TODO: Implement act complete screen with rewards
	# For now, auto-proceed to next act
	await get_tree().create_timer(2.0).timeout
	GameManager.proceed_to_next_act()


func _heal_all_spirits() -> void:
	# Heal all spirits in grid to full HP
	for spirit in ally_grid.get_all_spirits() if ally_grid else []:
		if spirit and spirit.is_alive():
			spirit.current_hp = spirit.spirit_data.base_hp


func _sync_grid_to_battle() -> void:
	# Clear existing ally grid
	if ally_grid:
		for spirit in ally_grid.get_all_spirits():
			if spirit:
				spirit.queue_free()
		ally_grid.clear_grid()
	
	# Spawn spirits from GameManager.grid_spirits
	for i in GameManager.grid_spirits.size():
		var spirit_data: Resource = GameManager.grid_spirits[i]
		if spirit_data:
			_spawn_ally_spirit(spirit_data as SpiritData, i)


func _on_starter_selected(spirit_data: SpiritData) -> void:
	# Spawn the starter spirit on the ally grid
	if ally_grid and spirit_data:
		_spawn_ally_spirit(spirit_data, 0)


func _spawn_ally_spirit(spirit_data: SpiritData, slot: int) -> void:
	var spirit_scene: PackedScene = preload("res://scenes/battle/spirit.tscn")
	var spirit: Spirit = spirit_scene.instantiate() as Spirit
	
	spirit.spirit_data = spirit_data.duplicate_spirit()
	spirit.is_enemy = false
	
	ally_grid.place_spirit(spirit, slot)


func _on_battle_ended(result: Enums.BattleResult) -> void:
	match result:
		Enums.BattleResult.VICTORY:
			# Award XP to all spirits
			_show_victory_screen()
		
		Enums.BattleResult.DEFEAT, Enums.BattleResult.TIMEOUT:
			# Handled by phase change to GAME_OVER
			pass


func _show_victory_screen() -> void:
	# Get defeated enemies for capture selection
	var wave_data: WaveData = GameManager.get_current_wave_data() as WaveData
	var defeated_spirits: Array[SpiritData] = []
	
	if wave_data and wave_data.enemies.size() > 0:
		for enemy in wave_data.enemies:
			if enemy:
				defeated_spirits.append(enemy)
	
	# Show capture UI if there are spirits to capture
	if defeated_spirits.size() > 0 and capture_ui:
		# Brief pause before showing capture UI
		await get_tree().create_timer(0.5).timeout
		GameManager.current_phase = Enums.GamePhase.CAPTURE_SELECTION
		capture_ui.show_capture_options(defeated_spirits)
	else:
		# No spirits to capture, proceed directly
		_complete_battle_victory()


func _on_capture_spirit_selected(spirit_data: SpiritData) -> void:
	# Add captured spirit to owned spirits
	var purified_spirit := spirit_data.duplicate_spirit()
	GameManager.owned_spirits.append(purified_spirit)
	EventBus.spirit_captured.emit(purified_spirit)
	
	# Continue with battle completion
	_complete_battle_victory()


func _on_capture_skipped() -> void:
	# Player chose not to capture, proceed
	_complete_battle_victory()


func _complete_battle_victory() -> void:
	if capture_ui:
		capture_ui.visible = false
	
	# Complete the node and return to map
	if GameManager.active_node:
		var node: MapNode = GameManager.active_node
		var gold_reward: int = GameManager.current_map_data.get_floor_gold_reward(node.floor_number) * int(node.gold_multiplier) if GameManager.current_map_data else 10
		GameManager.gold += gold_reward
		GameManager.gold += GameManager.calculate_interest()
		
		# Check boss completion
		if node.type == MapNode.NodeType.BOSS:
			GameManager._on_boss_defeated()
		else:
			GameManager.current_phase = Enums.GamePhase.MAP_SELECTION
			_update_map_after_completion(node)


func _on_run_ended(is_victory: bool) -> void:
	_show_game_over(is_victory)


func _show_game_over(is_victory: bool = false) -> void:
	if game_over_screen:
		game_over_screen.visible = true
		
		var title_label: Label = game_over_screen.get_node_or_null("TitleLabel")
		if title_label:
			title_label.text = "VICTORY!" if is_victory else "DEFEAT"
		
		var restart_button: Button = game_over_screen.get_node_or_null("RestartButton")
		if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
			restart_button.pressed.connect(_on_restart_pressed)


func _on_restart_pressed() -> void:
	# Clear grids
	if ally_grid:
		for spirit in ally_grid.get_all_spirits():
			if spirit:
				spirit.queue_free()
		ally_grid.clear_grid()
	
	if enemy_grid:
		for spirit in enemy_grid.get_all_spirits():
			if spirit:
				spirit.queue_free()
		enemy_grid.clear_grid()
	
	# Start new run
	_start_new_run()


# =============================================================================
# MAP HANDLERS
# =============================================================================

func _on_map_generated(nodes: Array) -> void:
	print("[Main] Map generated with %d nodes" % nodes.size())


func _on_act_started(act_number: int, map_data: Resource) -> void:
	print("[Main] Starting Act %d: %s" % [act_number, map_data.display_name if map_data else "Unknown"])


func _on_map_node_selected(node: MapNode) -> void:
	EventBus.map_node_selected.emit(node)


func _update_map_after_completion(completed_node: MapNode) -> void:
	# Mark node as completed and update availability
	completed_node.is_completed = true
	completed_node.is_available = false
	
	# Update connected nodes to be available
	for connected_id in completed_node.connected_nodes:
		var connected_node: MapNode = GameManager.get_map_node_by_id(connected_id)
		if connected_node and not connected_node.is_completed:
			connected_node.is_available = true
	
	# Show map with updated state
	if map_ui:
		map_ui.display_map(GameManager.current_map, GameManager.current_node_id, "")


func _on_spirit_captured(spirit_data: Resource) -> void:
	# Show capture notification
	print("[Main] Spirit captured: %s" % spirit_data.get("display_name"))
	# TODO: Add visual feedback for capture


# =============================================================================
# BENCH & GRID PLACEMENT
# =============================================================================

func _on_bench_spirit_selected(spirit_data: SpiritData) -> void:
	# Enable grid slot clicking when spirit is selected
	_enable_grid_slot_clicking(true)


func _on_ally_grid_spirit_placed(spirit: Node, slot_index: int) -> void:
	# Spirit was placed on grid
	if bench_ui:
		bench_ui.update_bench()


func _enable_grid_slot_clicking(enable: bool) -> void:
	# During preparation, allow clicking empty grid slots when spirit selected
	if enable and GameManager.current_phase == Enums.GamePhase.PREPARATION:
		# Already connected via _input or grid signals
		pass


func _input(event: InputEvent) -> void:
	# Handle grid slot clicking during preparation with selected spirit
	if GameManager.current_phase != Enums.GamePhase.PREPARATION:
		return
	
	if not bench_ui or not bench_ui.selected_spirit:
		return
	
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			# Check if clicked on ally grid
			if ally_grid:
				var slot_index: int = ally_grid.get_slot_from_position(mb.global_position)
				if slot_index >= 0 and ally_grid.is_slot_empty(slot_index):
					# Place selected spirit on this slot
					bench_ui.place_on_grid(slot_index)
					
					# Sync to battle scene
					_sync_grid_to_battle()
