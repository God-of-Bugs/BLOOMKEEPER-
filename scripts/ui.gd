class_name BloomkeeperUI
extends CanvasLayer

signal game_started

@onready var spirits_label: Label = $HUD/MarginContainer/VBoxContainer/SpiritsLabel
@onready var health_label: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var energy_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/EnergyBox/EnergyBar
@onready var absorption_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/AbsorptionBox/AbsorptionBar
@onready var absorption_label: Label = $HUD/MarginContainer/VBoxContainer/AbsorptionBox/AbsorptionLabel
@onready var energy_label: Label = $HUD/MarginContainer/VBoxContainer/EnergyBox/EnergyLabel
@onready var title_panel: PanelContainer = $TitlePanel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var game_over_panel: PanelContainer = $GameOverPanel

var is_game_started: bool = false
var is_paused: bool = false
var _elapsed_seconds: float = 0.0
var _bloomed_count: int = 0
var _total_count: int = 5
var _best_time: float = 0.0
var _page_overlay: Control = null
var _page_title: Label = null
var _page_body: Label = null
var _page_buttons: VBoxContainer = null
var _game_manager: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var player_node: Node3D = get_parent().get_node_or_null("Player") as Node3D
	var title_prompt: Label3D = player_node.get_node_or_null("AbsorbPrompt") as Label3D if player_node else null
	if title_prompt:
		title_prompt.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_panel.visible = false
	victory_panel.visible = false
	game_over_panel.visible = false
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.visible = false
	$TitlePanel/MarginContainer/VBoxContainer/ObjectiveLabel.text = "RESTORE THE FOREST\nFind five wandering Prowlers. Approach within 2.7 m from the front to automatically absorb their shadow. Each bloom restores its clearing; all five awaken the whole forest.\n\nWASD Move  ·  Mouse Look\nE / Right Mouse Bloom Pulse  ·  Shift Dash  ·  ESC Pause"
	$TitlePanel/MarginContainer/VBoxContainer/PromptLabel.text = "Choose how to enter the forest"
	var objective_label: Label = $TitlePanel/MarginContainer/VBoxContainer/ObjectiveLabel as Label
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 520.0
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.offset_left = -310.0
	title_panel.offset_top = -310.0
	title_panel.offset_right = 310.0
	title_panel.offset_bottom = 310.0
	title_panel.add_theme_stylebox_override("panel", _make_panel_style())
	$TitlePanel/MarginContainer.add_theme_constant_override("margin_left", 24)
	$TitlePanel/MarginContainer.add_theme_constant_override("margin_right", 24)
	$TitlePanel/MarginContainer.add_theme_constant_override("margin_top", 18)
	$TitlePanel/MarginContainer.add_theme_constant_override("margin_bottom", 18)
	_build_title_buttons()
	_build_navigation_page()
	_load_best_time()
	var main_node: Node = get_parent()
	_game_manager = main_node.get_node_or_null("GameManager")
	var player: Node = main_node.get_node_or_null("Player")
	if _game_manager:
		if _game_manager.has_signal("status_updated"):
			_game_manager.connect("status_updated", _on_status_updated)
		if _game_manager.has_signal("victory_achieved"):
			_game_manager.connect("victory_achieved", _on_victory)
		if _game_manager.has_signal("game_over_triggered"):
			_game_manager.connect("game_over_triggered", _on_game_over)
	if player:
		if player.has_signal("health_changed"):
			player.connect("health_changed", _on_health_changed)
		if player.has_signal("energy_changed"):
			player.connect("energy_changed", _on_energy_changed)
		if player.has_signal("absorption_status_changed"):
			player.connect("absorption_status_changed", _on_absorption_status_changed)


func _process(delta: float) -> void:
	if is_game_started and not get_tree().paused:
		_elapsed_seconds += delta


func _build_title_buttons() -> void:
	var menu: VBoxContainer = $TitlePanel/MarginContainer/VBoxContainer as VBoxContainer
	_add_button(menu, "ENTER THE FOREST", start_game)
	_add_button(menu, "HOW TO PLAY", _show_how_to_play)
	_add_button(menu, "SCORE / DASHBOARD", _show_dashboard)


func _build_navigation_page() -> void:
	_page_overlay = Control.new()
	_page_overlay.name = "NavigationOverlay"
	_page_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page_overlay.visible = false
	_page_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_page_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.035, 0.028, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_page_overlay.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_overlay.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "PagePanel"
	panel.custom_minimum_size = Vector2(560.0, 420.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)
	var margins: MarginContainer = MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 30)
	margins.add_theme_constant_override("margin_right", 30)
	margins.add_theme_constant_override("margin_top", 24)
	margins.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margins)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margins.add_child(content)
	_page_title = Label.new()
	_page_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_title.add_theme_font_size_override("font_size", 30)
	_page_title.add_theme_color_override("font_color", Color("d7f0b3"))
	content.add_child(_page_title)
	content.add_child(HSeparator.new())
	_page_body = Label.new()
	_page_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_page_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_body.add_theme_font_size_override("font_size", 17)
	_page_body.add_theme_color_override("font_color", Color("e1e8d4"))
	content.add_child(_page_body)
	_page_buttons = VBoxContainer.new()
	_page_buttons.add_theme_constant_override("separation", 8)
	content.add_child(_page_buttons)


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.085, 0.064, 0.98)
	style.border_color = Color("9ab878")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	return style


func _add_button(parent: Node, text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 42.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("e8f3d7"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_stylebox_override("normal", _make_button_style(Color("31533d")))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("496c4b")))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("263d32")))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _make_button_style(fill: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("6c8a60")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _show_page(title: String, body: String, button_data: Array) -> void:
	_page_title.text = title
	_page_body.text = body
	for old_button: Node in _page_buttons.get_children():
		_page_buttons.remove_child(old_button)
		old_button.queue_free()
	for button_item: Dictionary in button_data:
		_add_button(_page_buttons, str(button_item["text"]), button_item["callback"] as Callable)
	_page_overlay.visible = true
	_page_overlay.move_to_front()
	if is_game_started and not get_tree().paused:
		get_tree().paused = true
		is_paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _show_how_to_play() -> void:
	var body: String = "RESTORATION\nWalk to a Prowler and face its front. Within 2.7 metres, the bloom begins automatically—no button or hold required. Stay close and facing it until the transformation completes.\n\nTOOLS\nWASD to move; mouse to look (click to recapture, Esc to release). Hold E or Right Mouse to charge a Bloom Pulse. Shift dashes.\n\nEach Prowler restores its own clearing. The arena blooms only after all five have transformed."
	_show_page("HOW TO PLAY", body, [{"text": "BACK TO TITLE", "callback": _close_page_to_title}])


func _show_dashboard() -> void:
	var time_text: String = _format_time(_elapsed_seconds)
	var best_text: String = _format_time(_best_time) if _best_time > 0.0 else "Not yet recorded"
	var body: String = "CURRENT SANCTUARY\nProwlers bloomed: %d / %d\nTime: %s\n\nPERSONAL BEST\nFastest completed restoration: %s\n\nDashboard scores are stored locally on this device." % [_bloomed_count, _total_count, time_text, best_text]
	var return_callback: Callable = _close_page_to_title
	if is_game_started and not get_tree().paused:
		return_callback = _close_page_to_game
	elif is_game_started and _bloomed_count >= _total_count:
		return_callback = _close_page_to_victory
	elif is_game_started and _bloomed_count > 0 and _game_manager and bool(_game_manager.get("is_game_over")):
		return_callback = _close_page_to_game_over
	_show_page("SCORE / DASHBOARD", body, [{"text": "BACK", "callback": return_callback}, {"text": "MAIN MENU", "callback": _return_to_title}])


func _show_victory_dashboard() -> void:
	var time_text: String = _format_time(_elapsed_seconds)
	var best_text: String = _format_time(_best_time) if _best_time > 0.0 else "Not yet recorded"
	var body: String = "RESTORATION COMPLETE\nFive of five Prowlers bloomed.\nWhole-forest restoration time: %s\n\nPERSONAL BEST\n%s" % [time_text, best_text]
	_show_page("SANCTUARY DASHBOARD", body, [{"text": "BACK TO VICTORY", "callback": _close_page_to_victory}, {"text": "MAIN MENU", "callback": _return_to_title}])


func _close_page_to_title() -> void:
	_page_overlay.visible = false
	if is_game_started:
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	title_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_page_to_game() -> void:
	_page_overlay.visible = false
	is_paused = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _close_page_to_victory() -> void:
	_page_overlay.visible = false
	_show_victory_page()


func _return_to_title() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _close_page_to_game_over() -> void:
	_page_overlay.visible = false
	_show_game_over_page()


func _show_victory_page() -> void:
	var body: String = "THE FOREST REMEMBERS\nAll five Prowlers have transformed. The restored flowers and awakened forest are yours to revisit.\n\nRestoration time: %s" % _format_time(_elapsed_seconds)
	_show_page("FOREST RESTORED", body, [{"text": "PLAY AGAIN", "callback": _return_to_title}, {"text": "SCORE / DASHBOARD", "callback": _show_victory_dashboard}, {"text": "MAIN MENU", "callback": _return_to_title}, {"text": "QUIT", "callback": _quit_game}])


func _show_game_over_page() -> void:
	var body: String = "THE LIGHT FADES\nYou can always begin again.\n\nProwlers bloomed: %d / %d\nTime: %s" % [_bloomed_count, _total_count, _format_time(_elapsed_seconds)]
	_show_page("THE FOREST WAITS", body, [{"text": "RETRY", "callback": _return_to_title}, {"text": "SCORE / DASHBOARD", "callback": _show_dashboard}, {"text": "MAIN MENU", "callback": _return_to_title}, {"text": "QUIT", "callback": _quit_game}])


func _quit_game() -> void:
	get_tree().quit()


func _load_best_time() -> void:
	var score_file: ConfigFile = ConfigFile.new()
	if score_file.load("user://bloomkeeper_score.cfg") == OK:
		_best_time = float(score_file.get_value("score", "best_time", 0.0))


func _save_completed_time() -> void:
	if _best_time <= 0.0 or _elapsed_seconds < _best_time:
		_best_time = _elapsed_seconds
		var score_file: ConfigFile = ConfigFile.new()
		score_file.set_value("score", "best_time", _best_time)
		var save_error: Error = score_file.save("user://bloomkeeper_score.cfg")
		if save_error != OK:
			push_warning("Could not save local Bloomkeeper score: %s" % error_string(save_error))


func _format_time(seconds: float) -> String:
	var whole_seconds: int = maxi(0, int(seconds))
	return "%02d:%02d" % [int(whole_seconds / 60.0), whole_seconds % 60]


func start_game() -> void:
	if is_game_started:
		return
	is_game_started = true
	title_panel.visible = false
	$HUD.visible = true
	_page_overlay.visible = false
	_elapsed_seconds = 0.0
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var player_node: Node3D = get_parent().get_node_or_null("Player") as Node3D
	var title_prompt: Label3D = player_node.get_node_or_null("AbsorbPrompt") as Label3D if player_node else null
	if title_prompt:
		title_prompt.visible = false
	var first_prowler: Node3D = get_tree().get_first_node_in_group("prowlers") as Node3D
	if first_prowler:
		var face_vector: Vector3 = player_node.global_position - first_prowler.global_position if player_node else Vector3.ZERO
		face_vector.y = 0.0
		if face_vector.length_squared() > 0.001:
			first_prowler.rotation.y = atan2(-face_vector.x, -face_vector.z) + PI
	game_started.emit()


func toggle_pause() -> void:
	if not is_game_started or _page_overlay.visible or victory_panel.visible or game_over_panel.visible:
		return
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not is_game_started:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			start_game()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _page_overlay.visible:
			_close_page_to_game()
		elif is_paused:
			is_paused = false
			get_tree().paused = false
			pause_panel.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			toggle_pause()


func _on_status_updated(bloomed: int, total: int) -> void:
	_bloomed_count = bloomed
	_total_count = total
	spirits_label.text = "PROWLERS BLOOMED  ·  %d / %d" % [bloomed, total]


func _on_health_changed(current_hp: int, _max_hp: int) -> void:
	var hearts: String = ""
	for heart_index: int in range(current_hp):
		hearts += "♥ "
	health_label.text = "VITALITY  %s" % hearts.strip_edges()


func _on_energy_changed(current_energy: float, max_energy: float) -> void:
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy
	energy_label.text = "LUMEN  %d%%" % roundi(current_energy)


func _on_absorption_status_changed(progress: float, active: bool, available: bool, in_range: bool) -> void:
	if absorption_bar:
		absorption_bar.value = progress * 100.0
		absorption_bar.visible = available and in_range
	if absorption_label:
		absorption_label.visible = available and in_range
		absorption_label.text = "BLOOMING AUTOMATICALLY  ·  %d%%" % roundi(progress * 100.0) if active else "FACE THE PROWLER TO BEGIN BLOOM"


func _on_victory() -> void:
	_save_completed_time()
	victory_panel.visible = false
	_show_victory_page()


func _on_game_over() -> void:
	game_over_panel.visible = false
	_show_game_over_page()
