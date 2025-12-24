## HUDController - Heads-up display manager
## Shows gold, wave info, battle timer, and floating text.
extends CanvasLayer


# =============================================================================
# NODES
# =============================================================================

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var phase_label: Label = $TopBar/PhaseLabel
@onready var timer_label: Label = $BattleTimer
@onready var start_button: Button = $StartBattleButton
@onready var floating_text_container: Node2D = $FloatingTextContainer


# =============================================================================
# STATE
# =============================================================================

var battle_timer: float = 0.0
var is_battle_active: bool = false


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_connect_signals()
	update_display()


func _connect_signals() -> void:
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.floating_text_requested.connect(_on_floating_text_requested)
	
	if start_button:
		start_button.pressed.connect(_on_start_battle_pressed)


# =============================================================================
# PROCESS
# =============================================================================

func _process(delta: float) -> void:
	if is_battle_active:
		battle_timer += delta
		_update_timer_display()


# =============================================================================
# DISPLAY UPDATES
# =============================================================================

func update_display() -> void:
	_update_gold_display()
	_update_wave_display()
	_update_phase_display()
	_update_button_states()


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "💰 %d" % GameManager.gold


func _update_wave_display() -> void:
	if wave_label:
		var wave: int = GameManager.current_wave
		if wave > 0:
			wave_label.text = "Wave %d/4" % wave
		else:
			wave_label.text = "Ready"


func _update_phase_display() -> void:
	if phase_label:
		match GameManager.current_phase:
			Enums.GamePhase.STARTER_SELECTION:
				phase_label.text = "🎯 Select Starter"
			Enums.GamePhase.PREPARATION:
				phase_label.text = "⚙️ Preparation"
			Enums.GamePhase.BATTLE:
				phase_label.text = "⚔️ Battle!"
			Enums.GamePhase.BATTLE_END:
				phase_label.text = "✅ Victory!"
			Enums.GamePhase.BOSS_INTRO:
				phase_label.text = "👑 Boss Incoming!"
			Enums.GamePhase.GAME_OVER:
				phase_label.text = "🏁 Game Over"


func _update_timer_display() -> void:
	if timer_label:
		var remaining: float = Constants.BATTLE_MAX_TIME - battle_timer
		timer_label.text = "%.1f" % maxf(0, remaining)
		timer_label.visible = is_battle_active


func _update_button_states() -> void:
	if start_button:
		var can_start: bool = GameManager.current_phase == Enums.GamePhase.PREPARATION
		start_button.visible = can_start
		start_button.disabled = not can_start


# =============================================================================
# FLOATING TEXT
# =============================================================================

func _on_floating_text_requested(position: Vector2, text: String, color: Color) -> void:
	_spawn_floating_text(position, text, color)


func _spawn_floating_text(world_position: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = world_position - Vector2(50, 0)
	
	if floating_text_container:
		floating_text_container.add_child(label)
	else:
		add_child(label)
	
	# Animate float up and fade
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	_update_gold_display()


func _on_wave_started(wave_number: int, is_boss: bool) -> void:
	_update_wave_display()
	
	if is_boss:
		_show_boss_intro()


func _on_phase_changed(new_phase: Enums.GamePhase, _old_phase: Enums.GamePhase) -> void:
	_update_phase_display()
	_update_button_states()


func _on_battle_started() -> void:
	is_battle_active = true
	battle_timer = 0.0
	_update_timer_display()


func _on_battle_ended(_result: Enums.BattleResult) -> void:
	is_battle_active = false
	if timer_label:
		timer_label.visible = false
	_update_button_states()


func _on_start_battle_pressed() -> void:
	# Disable button during countdown
	if start_button:
		start_button.disabled = true
	
	# Start countdown
	_start_battle_countdown()


func _start_battle_countdown() -> void:
	# Create countdown label
	var countdown_label := Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.add_theme_font_size_override("font_size", 72)
	countdown_label.add_theme_color_override("font_color", Color.WHITE)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.anchors_preset = Control.PRESET_CENTER
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_right = 0.5
	countdown_label.anchor_top = 0.5
	countdown_label.anchor_bottom = 0.5
	countdown_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	countdown_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	countdown_label.offset_left = -100
	countdown_label.offset_right = 100
	countdown_label.offset_top = -50
	countdown_label.offset_bottom = 50
	add_child(countdown_label)
	
	# Animate countdown 3-2-1-FIGHT
	var tween: Tween = create_tween()
	
	# 3
	countdown_label.text = "3"
	countdown_label.scale = Vector2(1.5, 1.5)
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_interval(0.7)
	
	# 2
	tween.tween_callback(func(): countdown_label.text = "2"; countdown_label.scale = Vector2(1.5, 1.5))
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_interval(0.7)
	
	# 1
	tween.tween_callback(func(): countdown_label.text = "1"; countdown_label.scale = Vector2(1.5, 1.5))
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_interval(0.7)
	
	# FIGHT!
	tween.tween_callback(func(): 
		countdown_label.text = "FIGHT!"
		countdown_label.add_theme_color_override("font_color", Color.YELLOW)
		countdown_label.scale = Vector2(2.0, 2.0)
	)
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_interval(0.3)
	
	# Cleanup and start battle
	tween.tween_callback(func():
		countdown_label.queue_free()
		GameManager.current_phase = Enums.GamePhase.BATTLE
		EventBus.battle_requested.emit()
	)


# =============================================================================
# BOSS INTRO
# =============================================================================

func _show_boss_intro() -> void:
	# Simple boss intro display
	var intro_label := Label.new()
	intro_label.text = "⚠️ BOSS FIGHT ⚠️"
	intro_label.add_theme_font_size_override("font_size", 36)
	intro_label.add_theme_color_override("font_color", Color.RED)
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.anchors_preset = Control.PRESET_CENTER
	add_child(intro_label)
	
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(intro_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(intro_label.queue_free)
