extends Control

var state := GameState.new()
var page: Control
var background_music: BackgroundMusic
var sound_effects: SoundEffects

func _ready() -> void:
	# Keep the 1280x720 design coordinate system, but render controls directly
	# at the native target resolution so text stays sharp on HiDPI displays.
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	state.load_data()
	background_music = BackgroundMusic.new()
	add_child(background_music)
	background_music.set_enabled(true)
	sound_effects = SoundEffects.new()
	add_child(sound_effects)
	show_main_menu()

func clear_page() -> void:
	if page:
		page.queue_free()
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	var bg := ColorRect.new()
	bg.color = UIFactory.color("#0b1220")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(bg)
	page.move_child(bg, 0)

func show_main_menu() -> void:
	clear_page()
	var wrap := VBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.set_anchors_preset(Control.PRESET_CENTER)
	wrap.position = Vector2(-260, -250)
	wrap.size = Vector2(520, 500)
	wrap.add_theme_constant_override("separation", 16)
	page.add_child(wrap)
	var logo := UIFactory.label("SECURITY\nDESKTOP ACADEMY", 38, UIFactory.color("#dbeafe"))
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrap.add_child(logo)
	var subtitle := UIFactory.label(state.tr_text("Learn security by doing", "在实践中学习网络安全"), 17, UIFactory.color("#93c5fd"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrap.add_child(subtitle)
	add_spacer(wrap, 25)
	add_menu_button(wrap, state.tr_text("Start", "开始"), show_stage_select, true)
	add_menu_button(wrap, state.tr_text("Settings", "设置"), show_settings)
	add_menu_button(wrap, state.tr_text("Exit", "退出"), get_tree().quit)

func add_spacer(parent: Control, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)

func add_menu_button(parent: Control, text: String, callback: Callable, accent := false) -> void:
	var button := Button.new()
	button.text = text
	UIFactory.style_button(button, accent)
	button.pressed.connect(play_click_and_call.bind(callback))
	parent.add_child(button)

func play_click_and_call(callback: Callable) -> void:
	sound_effects.play_click()
	callback.call()

func add_header(title: String, back: Callable) -> VBoxContainer:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 48)
	root.add_theme_constant_override("separation", 24)
	page.add_child(root)
	var row := HBoxContainer.new()
	root.add_child(row)
	var back_button := Button.new()
	back_button.text = "←  " + state.tr_text("Back", "返回")
	UIFactory.style_button(back_button)
	back_button.custom_minimum_size = Vector2(130, 45)
	back_button.pressed.connect(play_click_and_call.bind(back))
	row.add_child(back_button)
	var heading := UIFactory.label(title, 32, UIFactory.color("#dbeafe"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(heading)
	var balance := Control.new()
	balance.custom_minimum_size.x = 130
	row.add_child(balance)
	return root

func show_settings() -> void:
	clear_page()
	var root := add_header(state.tr_text("Settings", "设置"), show_main_menu)
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 20)
	card.add_theme_stylebox_override("panel", UIFactory.panel(UIFactory.color("#151f31")))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIFactory.panel(UIFactory.color("#151f31")))
	panel.custom_minimum_size = Vector2(620, 390)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_child(card)
	root.add_child(panel)
	card.add_child(UIFactory.label(state.tr_text("Language", "语言"), 20))
	var language := OptionButton.new()
	language.add_item("English")
	language.add_item("简体中文")
	language.selected = 1 if state.language == "zh" else 0
	language.custom_minimum_size.y = 48
	language.add_theme_font_size_override("font_size", 17)
	language.item_selected.connect(func(index: int):
		state.language = "zh" if index == 1 else "en"
		state.save_data()
		show_settings()
	)
	card.add_child(language)
	card.add_child(UIFactory.label(state.tr_text("Sound effects volume", "音效音量"), 20))
	var sfx_volume_row := HBoxContainer.new()
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = state.sfx_volume * 100
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sfx_value_label := UIFactory.label("%d%%" % int(sfx_slider.value), 18, UIFactory.color("#93c5fd"))
	sfx_value_label.custom_minimum_size.x = 60
	sfx_slider.value_changed.connect(func(value: float):
		state.sfx_volume = value / 100.0
		sfx_value_label.text = "%d%%" % int(value)
		state.apply_audio_volumes()
		state.save_data()
	)
	sfx_volume_row.add_child(sfx_slider)
	sfx_volume_row.add_child(sfx_value_label)
	card.add_child(sfx_volume_row)
	card.add_child(UIFactory.label(state.tr_text("Background music volume", "背景音乐音量"), 20))
	var music_volume_row := HBoxContainer.new()
	var music_slider := HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = state.music_volume * 100
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var music_value_label := UIFactory.label("%d%%" % int(music_slider.value), 18, UIFactory.color("#93c5fd"))
	music_value_label.custom_minimum_size.x = 60
	music_slider.value_changed.connect(func(value: float):
		state.music_volume = value / 100.0
		music_value_label.text = "%d%%" % int(value)
		state.apply_audio_volumes()
		state.save_data()
	)
	music_volume_row.add_child(music_slider)
	music_volume_row.add_child(music_value_label)
	card.add_child(music_volume_row)

func show_stage_select() -> void:
	clear_page()
	var root := add_header(state.tr_text("Choose a Stage", "选择关卡"), show_main_menu)
	var subtitle := UIFactory.label(state.tr_text("Stages can be played in any order.", "关卡可以按任意顺序游玩。"), 17, UIFactory.color("#94a3b8"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)
	var stage_scroll := ScrollContainer.new()
	stage_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stage_scroll)
	var grid := HFlowContainer.new()
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_scroll.add_child(grid)
	for stage in GameState.STAGES:
		var card := Button.new()
		var done: bool = state.completed.get(stage.id, false)
		card.text = ("✓  " if done else "○  ") + state.stage_title(stage) + "\n\n" + state.stage_desc(stage) + "\n\n" + state.tr_text("Completed", "已完成") if done else ("○  " + state.stage_title(stage) + "\n\n" + state.stage_desc(stage) + "\n\n" + state.tr_text("Not completed", "未完成"))
		card.custom_minimum_size = Vector2(350, 230)
		card.add_theme_font_size_override("font_size", 17)
		card.add_theme_stylebox_override("normal", UIFactory.panel(UIFactory.color("#132033"), 14, UIFactory.color("#22c55e") if done else UIFactory.color("#334155"), 2))
		card.add_theme_stylebox_override("hover", UIFactory.panel(UIFactory.color("#1d3150"), 14, UIFactory.color("#60a5fa"), 2))
		card.pressed.connect(enter_stage.bind(stage))
		grid.add_child(card)

func enter_stage(stage: Dictionary) -> void:
	sound_effects.play_click()
	sound_effects.play_stage_enter()
	open_stage(stage)

func open_stage(stage: Dictionary) -> void:
	var scene: Control = load("res://scenes/stage.tscn").instantiate()
	page.queue_free()
	page = scene
	add_child(page)
	page.setup(state, stage, show_stage_select)
