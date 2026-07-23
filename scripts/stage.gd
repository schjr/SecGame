extends Control

var state: GameState
var stage: Dictionary
var return_callback: Callable
var pc_window: PanelContainer
var note_window: PanelContainer
var reported: Dictionary = {}

func setup(game_state: GameState, stage_data: Dictionary, go_back: Callable) -> void:
	state = game_state
	stage = stage_data
	return_callback = go_back
	build()

func build() -> void:
	var bg := ColorRect.new()
	bg.color = UIFactory.color("#263b32")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Wooden desk bands give the stage a physical desktop feel without external art.
	for y in range(0, 720, 90):
		var band := ColorRect.new()
		band.color = UIFactory.color("#5b3a29") if (y / 90 as int) % 2 == 0 else UIFactory.color("#674331")
		band.position = Vector2(0, y)
		band.size = Vector2(1280, 90)
		add_child(band)
	var top := HBoxContainer.new()
	top.position = Vector2(28, 22)
	top.size = Vector2(1224, 55)
	add_child(top)
	var back := Button.new()
	back.text = "← " + state.tr_text("Stages", "关卡")
	UIFactory.style_button(back)
	back.custom_minimum_size = Vector2(135, 44)
	back.pressed.connect(return_callback)
	top.add_child(back)
	var title := UIFactory.label(state.stage_title(stage), 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var status := UIFactory.label(state.tr_text("Completed", "已完成") if state.completed.get(stage.id, false) else state.tr_text("In progress", "进行中"), 17, UIFactory.color("#86efac"))
	status.custom_minimum_size.x = 135
	top.add_child(status)
	make_monitor()
	make_note()

func make_monitor() -> void:
	var monitor := PanelContainer.new()
	monitor.position = Vector2(90, 105)
	monitor.size = Vector2(850, 525)
	monitor.add_theme_stylebox_override("panel", UIFactory.panel(UIFactory.color("#111827"), 18, UIFactory.color("#334155"), 8))
	add_child(monitor)
	var pc: PCDesktop = load("res://scenes/pc_desktop.tscn").instantiate()
	pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	monitor.add_child(pc)
	pc.setup(state, stage)
	pc.stage_completed.connect(complete_stage)
	pc.stage_failed.connect(fail_stage)
	var stand := ColorRect.new()
	stand.color = UIFactory.color("#1f2937")
	stand.position = Vector2(390, 630)
	stand.size = Vector2(70, 55)
	add_child(stand)

func make_desktop_icon(symbol: String, caption: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.text = symbol + "\n" + caption
	button.position = pos
	button.size = Vector2(100, 90)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", UIFactory.panel(Color(0,0,0,0), 6))
	button.add_theme_stylebox_override("hover", UIFactory.panel(Color(0.2,0.6,1,0.35), 6))
	return button

func make_note() -> void:
	var note := Button.new()
	note.text = state.tr_text("NOTE\n\nClick to read", "便笺\n\n点击阅读")
	note.position = Vector2(995, 180)
	note.size = Vector2(210, 230)
	note.rotation = 0.04
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", UIFactory.color("#422006"))
	note.add_theme_stylebox_override("normal", UIFactory.panel(UIFactory.color("#fde68a"), 4))
	note.add_theme_stylebox_override("hover", UIFactory.panel(UIFactory.color("#fef3c7"), 4))
	note.pressed.connect(open_note)
	add_child(note)

func close_popup() -> void:
	if pc_window:
		pc_window.queue_free()
		pc_window = null
	if note_window:
		note_window.queue_free()
		note_window = null

func popup_base(title: String, size := Vector2(700, 430)) -> VBoxContainer:
	close_popup()
	pc_window = PanelContainer.new()
	pc_window.position = Vector2(165, 145)
	pc_window.size = size
	pc_window.add_theme_stylebox_override("panel", UIFactory.panel(UIFactory.color("#f8fafc"), 8, UIFactory.color("#334155"), 2))
	add_child(pc_window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	pc_window.add_child(root)
	var bar := HBoxContainer.new()
	var heading := UIFactory.label(title, 22, UIFactory.color("#0f172a"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(heading)
	var close := Button.new()
	close.text = "✕"
	close.pressed.connect(close_popup)
	bar.add_child(close)
	root.add_child(bar)
	return root

func open_email() -> void:
	var root := popup_base(state.tr_text("Mail — Inbox", "邮件 — 收件箱"))
	var emails: Array = stage.get("emails", [])
	if emails.is_empty():
		var empty := UIFactory.label(state.tr_text("Your inbox is empty.", "收件箱为空。"), 20, UIFactory.color("#64748b"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(empty)
		return
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for i in emails.size():
		var mail: Dictionary = emails[i]
		var row := Button.new()
		row.text = mail.from + "\n" + mail.subject + "\n" + mail.body + "\n" + (state.tr_text("✓ Reported", "✓ 已举报") if reported.get(i, false) else state.tr_text("Report as suspicious", "举报可疑邮件"))
		row.custom_minimum_size.y = 105
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_color_override("font_color", UIFactory.color("#0f172a"))
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_stylebox_override("normal", UIFactory.panel(UIFactory.color("#e2e8f0"), 6))
		row.pressed.connect(report_email.bind(i, mail))
		list.add_child(row)

func report_email(index: int, mail: Dictionary) -> void:
	if mail.spam:
		reported[index] = true
	open_email()
	var required := 0
	for item in stage.get("emails", []):
		if item.spam:
			required += 1
	if required > 0 and reported.size() == required:
		complete_stage()

func open_files() -> void:
	var root := popup_base(state.tr_text("File Explorer", "文件资源管理器"))
	var info := state.tr_text("Downloads\n  report.pdf\n  holiday_photo.jpg", "下载\n  report.pdf\n  holiday_photo.jpg")
	if stage.id == "malware":
		info += state.tr_text("\n  ⚠ free_game_crack.exe  — infected", "\n  ⚠ free_game_crack.exe  — 已感染")
	var files := UIFactory.label(info, 19, UIFactory.color("#1e293b"))
	files.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(files)
	if stage.id == "malware":
		var clean := Button.new()
		clean.text = state.tr_text("Remove infected file", "移除感染文件")
		UIFactory.style_button(clean, true)
		clean.pressed.connect(complete_stage)
		root.add_child(clean)

func open_note() -> void:
	close_popup()
	note_window = PanelContainer.new()
	note_window.position = Vector2(345, 160)
	note_window.size = Vector2(590, 360)
	note_window.add_theme_stylebox_override("panel", UIFactory.panel(UIFactory.color("#fef3c7"), 5))
	add_child(note_window)
	var content := VBoxContainer.new()
	note_window.add_child(content)
	content.add_child(UIFactory.label(state.tr_text("Mission Note", "任务便笺"), 26, UIFactory.color("#422006")))
	var body := UIFactory.label(state.stage_desc(stage), 20, UIFactory.color("#713f12"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	var close := Button.new()
	close.text = state.tr_text("Got it", "明白")
	UIFactory.style_button(close, true)
	close.pressed.connect(close_popup)
	content.add_child(close)

func complete_stage() -> void:
	state.completed[stage.id] = true
	state.save_data()
	close_popup()
	var dialog := AcceptDialog.new()
	dialog.title = state.tr_text("Stage complete", "关卡完成")
	dialog.dialog_text = state.tr_text("Great work! Your progress has been saved.", "做得好！你的进度已保存。")
	dialog.confirmed.connect(return_callback)
	add_child(dialog)
	dialog.popup_centered()

func fail_stage(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = state.tr_text("Stage failed", "关卡失败")
	dialog.dialog_text = message
	dialog.confirmed.connect(return_callback)
	add_child(dialog)
	dialog.popup_centered()
