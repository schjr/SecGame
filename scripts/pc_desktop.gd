class_name PCDesktop
extends Control

signal stage_completed

const TASKBAR_H := 40.0
const ICON_DIR := "res://assets/icons/"

const APP_PATHS := {
	"my_pc": "C:\\Windows\\explorer.exe",
	"email": "C:\\Program Files\\SecMail\\SecMail.exe",
	"browser": "C:\\Program Files\\SuperBrowser\\browser.exe",
	"agent": "C:\\Program Files\\SillyAgent\\SillyAgent.exe",
	"recycle": "C:\\$Recycle.Bin"
}

var state: GameState
var stage: Dictionary
var desktop: Control
var window_layer: Control
var taskbar: PanelContainer
var context_menu: PopupMenu
var start_menu: PopupPanel
var current_context: Dictionary
var open_windows: Dictionary = {}
var processes: Dictionary = {}
var deleted_items: Array[Dictionary] = []
var deleted_mail: Dictionary = {}
var app_buttons: Dictionary = {}
var reported: Dictionary = {}
var next_pid := 2400
var clock_label: Label
var dragged_window: Control
var drag_offset := Vector2.ZERO

var fs_items: Dictionary = {
	"C:\\": {"name":"Local Disk (C:)", "type":"Disk", "kind":"disk", "path":"C:\\", "deletable":true, "children":["C:\\System", "C:\\Profiles"]},
	"C:\\System": {"name":"System", "type":"Folder", "kind":"folder", "path":"C:\\System", "deletable":true, "children":["C:\\System\\kernel32.sys", "C:\\System\\svchost.exe", "C:\\System\\netservice.dll", "C:\\System\\securityd.exe"]},
	"C:\\System\\kernel32.sys": {"name":"kernel32.sys", "type":"System file", "kind":"file", "path":"C:\\System\\kernel32.sys", "deletable":true},
	"C:\\System\\svchost.exe": {"name":"svchost.exe", "type":"Executable", "kind":"executable", "path":"C:\\System\\svchost.exe", "deletable":true},
	"C:\\System\\netservice.dll": {"name":"netservice.dll", "type":"Program library", "kind":"program", "path":"C:\\System\\netservice.dll", "deletable":true},
	"C:\\System\\securityd.exe": {"name":"securityd.exe", "type":"Executable", "kind":"executable", "path":"C:\\System\\securityd.exe", "deletable":true},
	"C:\\Profiles": {"name":"Profiles", "type":"Folder", "kind":"folder", "path":"C:\\Profiles", "deletable":true, "children":["C:\\Profiles\\User"]},
	"C:\\Profiles\\User": {"name":"User", "type":"Folder", "kind":"folder", "path":"C:\\Profiles\\User", "deletable":true, "children":["C:\\Profiles\\User\\user.dat", "C:\\Profiles\\User\\settings.ini", "C:\\Profiles\\User\\login_helper.exe"]},
	"C:\\Profiles\\User\\user.dat": {"name":"user.dat", "type":"Profile data", "kind":"file", "path":"C:\\Profiles\\User\\user.dat", "deletable":true},
	"C:\\Profiles\\User\\settings.ini": {"name":"settings.ini", "type":"Text configuration", "kind":"text", "path":"C:\\Profiles\\User\\settings.ini", "deletable":true},
	"C:\\Profiles\\User\\login_helper.exe": {"name":"login_helper.exe", "type":"Executable", "kind":"executable", "path":"C:\\Profiles\\User\\login_helper.exe", "deletable":true},
	"D:\\": {"name":"Data Disk (D:)", "type":"Disk", "kind":"disk", "path":"D:\\", "deletable":true, "children":["D:\\Photos", "D:\\Documents"]},
	"D:\\Photos": {"name":"Photos", "type":"Folder", "kind":"folder", "path":"D:\\Photos", "deletable":true, "children":["D:\\Photos\\beach.jpg", "D:\\Photos\\family.png", "D:\\Photos\\cat.jpg"]},
	"D:\\Photos\\beach.jpg": {"name":"beach.jpg", "type":"JPEG photo", "kind":"photo", "path":"D:\\Photos\\beach.jpg", "deletable":true},
	"D:\\Photos\\family.png": {"name":"family.png", "type":"PNG photo", "kind":"photo", "path":"D:\\Photos\\family.png", "deletable":true},
	"D:\\Photos\\cat.jpg": {"name":"cat.jpg", "type":"JPEG photo", "kind":"photo", "path":"D:\\Photos\\cat.jpg", "deletable":true},
	"D:\\Documents": {"name":"Documents", "type":"Folder", "kind":"folder", "path":"D:\\Documents", "deletable":true, "children":["D:\\Documents\\project_notes.txt", "D:\\Documents\\budget.pdf", "D:\\Documents\\meeting.docx"]},
	"D:\\Documents\\project_notes.txt": {"name":"project_notes.txt", "type":"Text document", "kind":"text", "path":"D:\\Documents\\project_notes.txt", "deletable":true},
	"D:\\Documents\\budget.pdf": {"name":"budget.pdf", "type":"PDF document", "kind":"document", "path":"D:\\Documents\\budget.pdf", "deletable":true},
	"D:\\Documents\\meeting.docx": {"name":"meeting.docx", "type":"Word document", "kind":"document", "path":"D:\\Documents\\meeting.docx", "deletable":true}
}

func setup(game_state: GameState, stage_data: Dictionary) -> void:
	state = game_state
	stage = stage_data
	build_desktop()

func t(en: String, zh: String) -> String:
	return state.tr_text(en, zh)

func build_desktop() -> void:
	make_wallpaper()
	var apps := [
		["my_pc", "my_pc", t("My PC", "我的电脑")], ["email", "email", t("Email", "电子邮件")],
		["browser", "browser", t("Browser", "浏览器")], ["agent", "silly_agent", t("SillyAgent", "智慧助手")],
		["recycle", "recycle_bin", t("Recycle Bin", "回收站")]
	]
	for i in apps.size():
		var app: Array = apps[i]
		var icon := desktop_icon(app[1], app[2], Vector2(18 + (i / 4 as int) * 105, 18 + (i % 4) * 88))
		icon.gui_input.connect(on_desktop_icon_input.bind(app[0]))
		desktop.add_child(icon)
		app_buttons[app[0]] = icon
	window_layer = Control.new()
	window_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desktop.add_child(window_layer)
	make_taskbar()
	make_start_menu()
	make_context_menu()
	start_process("Desktop Window Manager", "C:\\Windows\\dwm.exe", false, false, 2.8)
	start_process("System Security", "C:\\System\\securityd.exe", false, false, 1.7)
	start_process("Network Service", "C:\\System\\svchost.exe", false, true, 1.1)

func make_wallpaper() -> void:
	desktop = ColorRect.new()
	desktop.color = UIFactory.color("#001d4a")
	desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.25, 0.65, 1.0, 0.55))
	grad.set_color(1, Color(0.25, 0.65, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.62, 0.42)
	tex.fill_to = Vector2(1.15, 0.42)
	tex.width = 1024
	tex.height = 600
	var glow := TextureRect.new()
	glow.texture = tex
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desktop.add_child(glow)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desktop.add_child(center)
	var panes := GridContainer.new()
	panes.columns = 2
	panes.add_theme_constant_override("h_separation", 8)
	panes.add_theme_constant_override("v_separation", 8)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in 4:
		var pane := ColorRect.new()
		pane.custom_minimum_size = Vector2(46, 46)
		pane.color = Color(0.55, 0.85, 1.0, 0.9)
		pane.material = mat
		panes.add_child(pane)
	center.add_child(panes)

func icon_texture(icon_name: String) -> Texture2D:
	return load(ICON_DIR + icon_name + ".png") as Texture2D

func app_icon_name(id: String) -> String:
	var names := {"my_pc":"my_pc", "email":"email", "browser":"browser", "agent":"silly_agent", "recycle":"recycle_bin", "photo_viewer":"photo", "document_viewer":"word_file"}
	return names.get(id, "executable")

func file_icon_name(item: Dictionary) -> String:
	var path: String = item.get("path", "")
	if item.get("kind", "") == "disk":
		return "disk_c" if path.begins_with("C:") else "disk_d"
	if item.get("kind", "") == "folder":
		return "profile_folder" if path.ends_with("\\User") else "folder"
	if item.get("kind", "") == "photo":
		return "photo"
	if item.get("kind", "") == "executable":
		return "executable"
	if item.get("kind", "") == "program":
		return "dll_file"
	if path.to_lower().ends_with(".pdf"):
		return "pdf_file"
	if path.to_lower().ends_with(".docx"):
		return "word_file"
	if item.get("kind", "") == "text":
		return "text_file"
	return "system_file"

func desktop_icon(icon_name: String, caption: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = caption
	b.icon = icon_texture(icon_name)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 44)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.position = pos
	b.size = Vector2(100, 86)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("shadow_offset_x", 1)
	b.add_theme_constant_override("shadow_offset_y", 1)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", UIFactory.flat(Color(0.55, 0.79, 0.98, 0.3), Color(0.8, 0.9, 1, 0.5), 1))
	b.add_theme_stylebox_override("pressed", UIFactory.flat(Color(0.55, 0.79, 0.98, 0.45), Color(0.8, 0.9, 1, 0.7), 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func on_desktop_icon_input(event: InputEvent, app_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			open_app(app_id)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			current_context = {"scope":"app", "id":app_id, "name":app_display_name(app_id), "path":APP_PATHS[app_id], "type":t("Program", "程序"), "deletable":true}
			show_context_menu(event.global_position)

func make_taskbar() -> void:
	taskbar = PanelContainer.new()
	taskbar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	taskbar.offset_top = -TASKBAR_H
	taskbar.offset_bottom = 0
	taskbar.add_theme_stylebox_override("panel", UIFactory.flat(Color(0.075, 0.075, 0.075, 0.95)))
	taskbar.gui_input.connect(on_taskbar_input)
	desktop.add_child(taskbar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	taskbar.add_child(row)
	var start := taskbar_button("⊞", 46)
	start.add_theme_font_size_override("font_size", 17)
	start.tooltip_text = t("Start", "开始")
	start.pressed.connect(toggle_start_menu)
	row.add_child(start)
	var search := LineEdit.new()
	search.placeholder_text = t("Type here to search", "在此输入以搜索")
	search.custom_minimum_size = Vector2(220, 26)
	search.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UIFactory.style_win10_lineedit(search)
	search.text_submitted.connect(func(query: String): open_browser(query))
	row.add_child(search)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 6
	row.add_child(spacer)
	var running := HBoxContainer.new()
	running.name = "RunningApps"
	running.add_theme_constant_override("separation", 2)
	running.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(running)
	var tray := HBoxContainer.new()
	tray.add_theme_constant_override("separation", 8)
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(tray)
	tray.add_child(UIFactory.label("▲", 9, Color.WHITE))
	tray.add_child(UIFactory.label("Wi-Fi", 11, Color.WHITE))
	tray.add_child(UIFactory.label("🔊", 11, Color.WHITE))
	clock_label = UIFactory.label("", 11, Color.WHITE)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clock_label.custom_minimum_size.x = 72
	clock_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(clock_label)
	var show_desktop := taskbar_button("", 6)
	show_desktop.tooltip_text = t("Show desktop", "显示桌面")
	show_desktop.add_theme_stylebox_override("normal", UIFactory.flat(Color(1, 1, 1, 0.12)))
	show_desktop.pressed.connect(minimize_all_windows)
	row.add_child(show_desktop)
	var clock_timer := Timer.new()
	clock_timer.wait_time = 5.0
	clock_timer.autostart = true
	clock_timer.timeout.connect(update_clock)
	add_child(clock_timer)
	update_clock()

func update_clock() -> void:
	if not is_instance_valid(clock_label):
		return
	var d := Time.get_datetime_dict_from_system()
	var h: int = d.hour % 12
	if h == 0:
		h = 12
	clock_label.text = "%d:%02d %s\n%d/%d/%d" % [h, d.minute, "AM" if d.hour < 12 else "PM", d.month, d.day, d.year]

func taskbar_button(text: String, min_w := 110.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 0)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", UIFactory.flat(Color(1, 1, 1, 0.1)))
	b.add_theme_stylebox_override("pressed", UIFactory.flat(Color(1, 1, 1, 0.18)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func make_start_menu() -> void:
	start_menu = PopupPanel.new()
	start_menu.add_theme_stylebox_override("panel", UIFactory.flat(Color(0.1, 0.1, 0.1, 0.97), Color(0.35, 0.35, 0.35), 1))
	add_child(start_menu)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	start_menu.add_child(margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	margin.add_child(list)
	list.add_child(UIFactory.label(t("Pinned", "已固定"), 12, Color(1, 1, 1, 0.6)))
	for app in ["my_pc", "email", "browser", "agent", "recycle"]:
		var b := start_menu_item(app_display_name(app))
		b.icon = icon_texture(app_icon_name(app))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 24)
		b.pressed.connect(open_start_app.bind(app))
		list.add_child(b)
	var sep := HSeparator.new()
	list.add_child(sep)
	var tm := start_menu_item("▦   " + t("Task Manager", "任务管理器"))
	tm.pressed.connect(func(): start_menu.hide(); open_task_manager())
	list.add_child(tm)

func open_start_app(id: String) -> void:
	start_menu.hide()
	open_app(id)

func start_menu_item(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 34)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := UIFactory.flat(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, 2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", UIFactory.flat(Color(1, 1, 1, 0.12), Color.TRANSPARENT, 0, 8, 2))
	b.add_theme_stylebox_override("pressed", UIFactory.flat(UIFactory.accent(), Color.TRANSPARENT, 0, 8, 2))
	b.add_theme_stylebox_override("focus", normal)
	return b

func toggle_start_menu() -> void:
	if start_menu.visible:
		start_menu.hide()
		return
	var menu_size := Vector2i(250, 290)
	var dr := desktop.get_global_rect()
	var origin := Vector2i(int(dr.position.x), int(dr.position.y + dr.size.y - TASKBAR_H) - menu_size.y)
	start_menu.popup(Rect2i(origin, menu_size))

func on_taskbar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		current_context = {"scope":"taskbar"}
		context_menu.clear()
		context_menu.add_item(t("Task Manager", "任务管理器"), 10)
		context_menu.position = Vector2i(event.global_position)
		context_menu.popup()

func make_context_menu() -> void:
	context_menu = PopupMenu.new()
	context_menu.add_theme_font_size_override("font_size", 13)
	context_menu.add_theme_color_override("font_color", UIFactory.color("#1a1a1a"))
	context_menu.add_theme_color_override("font_hover_color", UIFactory.color("#1a1a1a"))
	context_menu.add_theme_stylebox_override("panel", UIFactory.flat(Color.WHITE, UIFactory.color("#a0a0a0"), 1, 4, 4))
	context_menu.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#e5f1fb")))
	var sep := UIFactory.flat(UIFactory.color("#d4d4d4"))
	sep.content_margin_top = 1
	context_menu.add_theme_stylebox_override("separator", sep)
	context_menu.id_pressed.connect(on_context_action)
	add_child(context_menu)

func show_context_menu(pos: Vector2) -> void:
	context_menu.clear()
	context_menu.add_item(t("Open", "打开"), 1)
	context_menu.add_item(t("Delete", "删除"), 2)
	context_menu.add_separator()
	context_menu.add_item(t("Properties", "属性"), 3)
	context_menu.position = Vector2i(pos)
	context_menu.popup()

func on_context_action(id: int) -> void:
	if id == 10:
		open_task_manager()
		return
	match id:
		1: open_context_item()
		2: delete_context_item()
		3: show_properties(current_context)

func open_context_item() -> void:
	if current_context.scope == "app":
		open_app(current_context.id)
	elif current_context.scope == "file":
		open_file_item(current_context.path)
	elif current_context.scope == "mail":
		read_mail(current_context.index, current_context.mail)

func delete_context_item() -> void:
	if not current_context.get("deletable", false):
		warn(t("This item cannot be deleted.", "无法删除此项目。"))
		return
	if current_context.scope == "app" and open_windows.has(current_context.id):
		warn(t("The program is running. Close it before deleting it.", "程序正在运行。请先关闭程序再删除。"))
		return
	var path: String = current_context.path
	for process in processes.values():
		if process.path == path:
			warn(t("The file is in use by a running process.", "该文件正被运行中的进程使用。"))
			return
	var recycle_record: Dictionary = current_context.duplicate(true)
	if current_context.scope == "file":
		recycle_record["parent_path"] = find_parent_path(path)
	deleted_items.append(recycle_record)
	if current_context.scope == "file":
		remove_from_filesystem(path)
	elif current_context.scope == "mail":
		deleted_mail[current_context.index] = true
		open_email()
	elif current_context.scope == "app":
		if app_buttons.has(current_context.id) and is_instance_valid(app_buttons[current_context.id]):
			app_buttons[current_context.id].queue_free()
		app_buttons.erase(current_context.id)
	else:
		warn(t("This item cannot be deleted.", "无法删除此项目。"))

func remove_from_filesystem(path: String) -> void:
	fs_items.erase(path)
	for item in fs_items.values():
		if item.has("children"):
			item.children.erase(path)
	if open_windows.has("my_pc"):
		open_my_pc("C:\\")

func find_parent_path(path: String) -> String:
	for candidate_path in fs_items:
		var candidate: Dictionary = fs_items[candidate_path]
		if candidate.has("children") and path in candidate.children:
			return candidate_path
	return "root"

func show_properties(item: Dictionary) -> void:
	var root := create_window("properties", t("Properties", "属性") + " — " + item.get("name", ""), Vector2(430, 270), false)
	var displayed_type: String = item.get("type", "")
	if item.get("kind", "") == "folder":
		displayed_type = t("Folder", "文件夹")
	var tabs := HBoxContainer.new()
	tabs.add_child(sidebar_item(t("General", "常规"), true))
	tabs.add_child(sidebar_item(t("Security", "安全")))
	root.add_child(tabs)
	var identity := HBoxContainer.new()
	var icon_name := file_icon_name(item) if item.get("scope", "") == "file" else app_icon_name(item.get("id", "my_pc"))
	identity.add_child(app_icon_rect(icon_name, 54))
	var name_label := dark_label(item.get("name", ""), 17)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity.add_child(name_label)
	root.add_child(identity)
	root.add_child(HSeparator.new())
	root.add_child(dark_label(t("Type of item:  ", "项目类型：  ") + displayed_type, 14))
	root.add_child(dark_label(t("Location:      ", "位置：      ") + item.get("path", ""), 14))
	root.add_child(HSeparator.new())
	root.add_child(dark_label(t("Attributes:    ☑ Archive     ☐ Hidden", "属性：    ☑ 存档     ☐ 隐藏"), 13, UIFactory.color("#555555")))

func app_display_name(id: String) -> String:
	var names := {"my_pc":t("My PC", "我的电脑"), "email":t("Email", "电子邮件"), "browser":t("Browser", "浏览器"), "agent":t("SillyAgent", "智慧助手"), "recycle":t("Recycle Bin", "回收站")}
	return names.get(id, id)

func open_app(id: String) -> void:
	# A desktop or taskbar click restores an existing instance instead of
	# rebuilding it. Other applications remain open in the background.
	if open_windows.has(id) and is_instance_valid(open_windows[id]):
		restore_window(id)
		return
	match id:
		"my_pc": open_my_pc("root")
		"email": open_email()
		"browser": open_browser("")
		"agent": open_agent()
		"recycle": open_recycle_bin()

func create_window(id: String, title: String, window_size := Vector2(650, 365), track_process := true) -> VBoxContainer:
	if open_windows.has(id) and is_instance_valid(open_windows[id]):
		# Rebuild the contents for navigation (for example, moving between
		# Explorer folders) while preserving the window's one process.
		open_windows[id].queue_free()
		open_windows.erase(id)
	var panel := PanelContainer.new()
	panel.position = Vector2(110 + open_windows.size() * 14, 30 + open_windows.size() * 10)
	panel.size = window_size
	panel.add_theme_stylebox_override("panel", UIFactory.win10_window())
	panel.gui_input.connect(on_window_panel_input.bind(id))
	window_layer.add_child(panel)
	clamp_window_to_desktop(panel)
	open_windows[id] = panel
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	panel.add_child(layout)
	var titlebar := HBoxContainer.new()
	titlebar.custom_minimum_size.y = 30
	titlebar.add_theme_constant_override("separation", 0)
	titlebar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	titlebar.tooltip_text = t("Drag to move; double-click to maximize", "拖动以移动窗口，双击可最大化")
	titlebar.gui_input.connect(on_titlebar_input.bind(id, panel))
	layout.add_child(titlebar)
	var pad := Control.new()
	pad.custom_minimum_size.x = 8
	titlebar.add_child(pad)
	var title_icon := TextureRect.new()
	title_icon.texture = icon_texture(app_icon_name(id))
	title_icon.custom_minimum_size = Vector2(18, 18)
	title_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titlebar.add_child(title_icon)
	var icon_gap := Control.new()
	icon_gap.custom_minimum_size.x = 6
	titlebar.add_child(icon_gap)
	var heading := dark_label(title, 13, UIFactory.color("#1a1a1a"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.clip_text = true
	titlebar.add_child(heading)
	var minimize := caption_button("—", t("Minimize", "最小化"))
	minimize.pressed.connect(minimize_window.bind(id))
	titlebar.add_child(minimize)
	var maximize := caption_button("▢", t("Maximize / Restore", "最大化 / 还原"))
	maximize.pressed.connect(toggle_maximize.bind(id))
	titlebar.add_child(maximize)
	var close := caption_button("✕", t("Close", "关闭"), true)
	close.pressed.connect(close_window.bind(id))
	titlebar.add_child(close)
	var line := ColorRect.new()
	line.color = UIFactory.color("#e6e6e6")
	line.custom_minimum_size.y = 1
	layout.add_child(line)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)
	if track_process:
		start_process(title, APP_PATHS.get(id, "C:\\Program Files\\" + id + ".exe"), true, true, -1.0, id)
		refresh_task_buttons()
	raise_window(panel)
	return root

func make_app_toolbar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 34
	bar.add_theme_constant_override("separation", 4)
	bar.add_theme_stylebox_override("panel", UIFactory.flat(UIFactory.color("#f5f5f5"), UIFactory.color("#d7d7d7"), 1, 6, 3))
	return bar

func make_sidebar(width := 135.0) -> VBoxContainer:
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = width
	side.add_theme_constant_override("separation", 2)
	side.add_theme_stylebox_override("panel", UIFactory.flat(UIFactory.color("#f3f3f3"), UIFactory.color("#dedede"), 1, 6, 6))
	return side

func sidebar_item(text: String, selected := false) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 30
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", UIFactory.color("#202020"))
	b.add_theme_color_override("font_hover_color", UIFactory.color("#202020"))
	var normal_color := UIFactory.color("#dbeaf7") if selected else Color.TRANSPARENT
	b.add_theme_stylebox_override("normal", UIFactory.flat(normal_color, Color.TRANSPARENT, 0, 8, 3))
	b.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#e5f1fb"), Color.TRANSPARENT, 0, 8, 3))
	b.add_theme_stylebox_override("pressed", UIFactory.flat(UIFactory.color("#cce4f7"), Color.TRANSPARENT, 0, 8, 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func app_icon_rect(name: String, size_px := 24) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = icon_texture(name)
	icon.custom_minimum_size = Vector2(size_px, size_px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func caption_button(text: String, tooltip: String, is_close := false) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tooltip
	b.custom_minimum_size = Vector2(46, 30)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", UIFactory.color("#1a1a1a"))
	var hover := UIFactory.color("#e81123") if is_close else UIFactory.color("#e0e0e0")
	var pressed := UIFactory.color("#f1707a") if is_close else UIFactory.color("#c0c0c0")
	var on_hover := Color.WHITE if is_close else UIFactory.color("#1a1a1a")
	b.add_theme_color_override("font_hover_color", on_hover)
	b.add_theme_color_override("font_pressed_color", on_hover)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", UIFactory.flat(hover))
	b.add_theme_stylebox_override("pressed", UIFactory.flat(pressed))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func on_titlebar_input(event: InputEvent, id: String, panel: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			raise_window(panel)
			if event.double_click:
				toggle_maximize(id)
				return
			if panel.get_meta("maximized", false):
				return
			dragged_window = panel
			drag_offset = event.global_position - panel.global_position
		else:
			dragged_window = null
	elif event is InputEventMouseMotion and dragged_window == panel:
		var desired_global: Vector2 = event.global_position - drag_offset
		panel.global_position = desired_global
		clamp_window_to_desktop(panel)

func on_window_panel_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if open_windows.has(id) and is_instance_valid(open_windows[id]):
			raise_window(open_windows[id])

func toggle_maximize(id: String) -> void:
	if not open_windows.has(id) or not is_instance_valid(open_windows[id]):
		return
	var panel: Control = open_windows[id]
	if panel.get_meta("maximized", false):
		var rect: Rect2 = panel.get_meta("restore_rect")
		panel.position = rect.position
		panel.size = rect.size
		panel.set_meta("maximized", false)
		clamp_window_to_desktop(panel)
	else:
		panel.set_meta("restore_rect", Rect2(panel.position, panel.size))
		panel.position = Vector2.ZERO
		panel.size = Vector2(window_layer.size.x, maxf(0.0, window_layer.size.y - TASKBAR_H))
		panel.set_meta("maximized", true)
	raise_window(panel)

func raise_window(panel: Control) -> void:
	window_layer.move_child(panel, window_layer.get_child_count() - 1)
	refresh_window_borders()

func refresh_window_borders() -> void:
	var top: Control = null
	for i in range(window_layer.get_child_count() - 1, -1, -1):
		var child := window_layer.get_child(i)
		if child.visible:
			top = child
			break
	for id in open_windows:
		var window: Control = open_windows[id]
		if not is_instance_valid(window):
			continue
		var style: StyleBoxFlat = window.get_theme_stylebox("panel").duplicate()
		style.border_color = UIFactory.accent() if window == top else UIFactory.color("#9a9a9a")
		window.add_theme_stylebox_override("panel", style)

func clamp_window_to_desktop(panel: Control) -> void:
	# The complete window must remain inside the monitor, excluding the
	# taskbar. This constrains every edge, not only the title bar.
	var usable_size := Vector2(window_layer.size.x, maxf(0.0, window_layer.size.y - TASKBAR_H))
	var max_x: float = maxf(0.0, usable_size.x - panel.size.x)
	var max_y: float = maxf(0.0, usable_size.y - panel.size.y)
	panel.position = Vector2(
		clampf(panel.position.x, 0.0, max_x),
		clampf(panel.position.y, 0.0, max_y)
	)

func minimize_window(id: String) -> void:
	if open_windows.has(id) and is_instance_valid(open_windows[id]):
		open_windows[id].hide()
	refresh_window_borders()
	refresh_task_buttons()

func minimize_all_windows() -> void:
	for id in open_windows:
		if is_instance_valid(open_windows[id]):
			open_windows[id].hide()
	refresh_window_borders()
	refresh_task_buttons()

func restore_window(id: String) -> void:
	if not open_windows.has(id) or not is_instance_valid(open_windows[id]):
		return
	var panel: Control = open_windows[id]
	panel.show()
	raise_window(panel)
	refresh_task_buttons()

func close_window(id: String) -> void:
	if open_windows.has(id) and is_instance_valid(open_windows[id]):
		open_windows[id].queue_free()
	open_windows.erase(id)
	for pid in processes.keys():
		if processes[pid].window_id == id:
			processes.erase(pid)
	refresh_window_borders()
	refresh_task_buttons()
	refresh_task_manager_if_open()

func refresh_task_buttons() -> void:
	var holder := taskbar.find_child("RunningApps", true, false)
	if holder == null:
		return
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	for id in open_windows.keys():
		if id in ["properties", "mail_read", "compose", "warning"]:
			continue
		var window: Control = open_windows[id] as Control
		var minimized: bool = not window.visible
		var b := Button.new()
		b.text = window_display_name(id)
		b.icon = icon_texture(app_icon_name(id))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 22)
		b.custom_minimum_size = Vector2(76, 0)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.tooltip_text = t("Restore window", "还原窗口") if minimized else t("Bring to front", "置于前台")
		b.add_theme_font_size_override("font_size", 12)
		var font_color := Color(1, 1, 1, 0.55) if minimized else Color.WHITE
		b.add_theme_color_override("font_color", font_color)
		b.add_theme_color_override("font_hover_color", font_color)
		var underline := Color.TRANSPARENT if minimized else UIFactory.accent()
		var normal := UIFactory.flat(Color.TRANSPARENT)
		normal.border_color = underline
		normal.border_width_bottom = 2
		var hover := UIFactory.flat(Color(1, 1, 1, 0.1))
		hover.border_color = underline
		hover.border_width_bottom = 2
		var pressed := UIFactory.flat(Color(1, 1, 1, 0.18))
		pressed.border_color = underline
		pressed.border_width_bottom = 2
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", pressed)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(restore_window.bind(id))
		holder.add_child(b)

func refresh_task_manager_if_open() -> void:
	if open_windows.has("task_manager") and is_instance_valid(open_windows["task_manager"]):
		call_deferred("open_task_manager")

func window_glyph(id: String) -> String:
	var glyphs := {"my_pc":"▣", "email":"✉", "browser":"◎", "agent":"✦", "recycle":"♲", "photo_viewer":"▰", "document_viewer":"▤"}
	return glyphs.get(id, "▣")

func window_display_name(id: String) -> String:
	var names := {
		"photo_viewer":t("Photos", "照片"),
		"document_viewer":t("Document", "文档"),
		"my_pc":t("My PC", "我的电脑"),
		"email":t("Email", "电子邮件"),
		"browser":t("Browser", "浏览器"),
		"agent":t("SillyAgent", "智慧助手"),
		"recycle":t("Recycle Bin", "回收站"),
		"task_manager":t("Task Manager", "任务管理器")
	}
	return names.get(id, id.capitalize())

func start_process(name: String, path: String, killable := true, path_visible := true, cpu := -1.0, window_id := "") -> void:
	for process in processes.values():
		if not window_id.is_empty() and process.window_id == window_id:
			return
		if window_id.is_empty() and process.name == name:
			return
	next_pid += randi_range(7, 31)
	var app_id := ""
	for id in APP_PATHS:
		if APP_PATHS[id] == path:
			app_id = id
	processes[next_pid] = {"pid":next_pid, "name":name, "path":path, "killable":killable, "path_visible":path_visible, "cpu":cpu if cpu >= 0 else randf_range(0.5, 6.0), "app_id":app_id, "window_id":window_id}
	refresh_task_manager_if_open()

func open_my_pc(path: String) -> void:
	var root := create_window("my_pc", t("File Explorer", "文件资源管理器") + " — " + (t("This PC", "此电脑") if path == "root" else fs_items.get(path, {}).get("name", path)), Vector2(680, 390))
	var ribbon := make_app_toolbar()
	for tab_name in [t("File", "文件"), t("Computer", "计算机"), t("View", "查看")]:
		var tab := Button.new()
		tab.text = tab_name
		UIFactory.style_win10_button(tab)
		ribbon.add_child(tab)
	root.add_child(ribbon)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	root.add_child(nav)
	var back := Button.new()
	back.text = "←"
	back.tooltip_text = t("Back to This PC", "返回此电脑")
	UIFactory.style_win10_button(back)
	back.pressed.connect(open_my_pc.bind("root"))
	nav.add_child(back)
	var up := Button.new()
	up.text = "↑"
	up.tooltip_text = t("Up one level", "向上一级")
	UIFactory.style_win10_button(up)
	up.pressed.connect(navigate_up.bind(path))
	nav.add_child(up)
	var address := LineEdit.new()
	address.text = breadcrumb(path)
	address.editable = false
	address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.style_win10_lineedit(address)
	nav.add_child(address)
	var search_box := LineEdit.new()
	search_box.placeholder_text = t("Search", "搜索")
	search_box.custom_minimum_size.x = 125
	UIFactory.style_win10_lineedit(search_box)
	nav.add_child(search_box)
	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 8)
	root.add_child(workspace)
	var side := make_sidebar(125)
	side.add_child(sidebar_item("★  " + t("Quick access", "快速访问")))
	side.add_child(sidebar_item("▣  " + t("Desktop", "桌面")))
	side.add_child(sidebar_item("▤  " + t("Documents", "文档"), path.begins_with("D:\\Documents")))
	side.add_child(sidebar_item("▰  " + t("Pictures", "图片"), path.begins_with("D:\\Photos")))
	side.add_child(sidebar_item("▣  " + t("This PC", "此电脑"), path == "root"))
	workspace.add_child(side)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var paths: Array = ["C:\\", "D:\\"] if path == "root" else fs_items.get(path, {}).get("children", [])
	for child_path in paths:
		if not fs_items.has(child_path):
			continue
		var item: Dictionary = fs_items[child_path]
		var b := Button.new()
		b.text = item.name
		b.icon = icon_texture(file_icon_name(item))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 48)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.custom_minimum_size = Vector2(145, 94)
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", UIFactory.color("#0f172a"))
		b.add_theme_color_override("font_hover_color", UIFactory.color("#0f172a"))
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#e5f1fb"), UIFactory.color("#cce8ff"), 1))
		b.add_theme_stylebox_override("pressed", UIFactory.flat(UIFactory.color("#cce4f7"), UIFactory.color("#99d1ff"), 1))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.gui_input.connect(on_file_input.bind(child_path))
		grid.add_child(b)

func breadcrumb(path: String) -> String:
	if path == "root":
		return t("This PC", "此电脑")
	var crumbs: Array[String] = [t("This PC", "此电脑")]
	var parts := path.trim_suffix("\\").split("\\")
	var key := ""
	for i in parts.size():
		if i == 0:
			key = parts[0] + "\\"
		else:
			key += "\\" + parts[i]
		if fs_items.has(key):
			crumbs.append(fs_items[key].name)
	return "  ›  ".join(crumbs)

func navigate_up(path: String) -> void:
	if path == "root":
		return
	if path.ends_with(":\\"):
		open_my_pc("root")
		return
	var trimmed := path.trim_suffix("\\")
	var idx := trimmed.rfind("\\")
	var parent := trimmed.substr(0, idx + 1)
	if fs_items.has(parent):
		open_my_pc(parent)
	else:
		open_my_pc("root")

func on_file_input(event: InputEvent, path: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			open_file_item(path)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			current_context = fs_items[path].duplicate(true)
			current_context.scope = "file"
			show_context_menu(event.global_position)

func open_file_item(path: String) -> void:
	if not fs_items.has(path):
		return
	var item: Dictionary = fs_items[path]
	if item.kind in ["disk", "folder"]:
		open_my_pc(path)
	elif item.kind == "photo":
		var root := create_window("photo_viewer", t("Photos", "照片") + " — " + item.name, Vector2(500, 330))
		var preview := ColorRect.new()
		preview.color = UIFactory.color("#87b8d8")
		preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(preview)
		var caption := UIFactory.label("▰  " + t("Photo preview", "照片预览"), 24)
		caption.position = Vector2(140, 110)
		preview.add_child(caption)
	else:
		var root := create_window("document_viewer", item.name, Vector2(520, 310))
		var content := dark_label(t("File contents preview\n\nThis is a simulated file used by the security lab.", "文件内容预览\n\n这是安全实验室使用的模拟文件。"), 18)
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(content)
	if stage.id == "malware" and path.ends_with("login_helper.exe"):
		stage_completed.emit()

func open_email() -> void:
	var root := create_window("email", t("SecMail", "安全邮箱"), Vector2(710, 400))
	var toolbar := make_app_toolbar()
	var compose := Button.new()
	compose.text = "✉  " + t("New mail", "写邮件")
	UIFactory.style_win10_button(compose)
	compose.pressed.connect(open_compose)
	toolbar.add_child(compose)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)
	var sync := Button.new()
	sync.text = "↻  " + t("Sync", "同步")
	UIFactory.style_win10_button(sync)
	toolbar.add_child(sync)
	root.add_child(toolbar)
	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 8)
	root.add_child(workspace)
	var side := make_sidebar(145)
	side.add_child(dark_label(t("FOLDERS", "文件夹"), 11, UIFactory.color("#666666")))
	side.add_child(sidebar_item("▣  " + t("Inbox", "收件箱") + "  %d" % stage.get("emails", []).size(), true))
	side.add_child(sidebar_item("☆  " + t("Drafts", "草稿")))
	side.add_child(sidebar_item("➤  " + t("Sent", "已发送")))
	side.add_child(sidebar_item("♲  " + t("Deleted", "已删除")))
	workspace.add_child(side)
	var inbox := VBoxContainer.new()
	inbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inbox.add_child(dark_label(t("Focused inbox", "重点收件箱"), 16, UIFactory.color("#202020")))
	workspace.add_child(inbox)
	var emails: Array = stage.get("emails", [])
	if emails.is_empty():
		var empty := dark_label(t("You're all caught up\nThere is no mail to show.", "所有邮件都已处理\n没有可显示的邮件。"), 18, UIFactory.color("#64748b"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		inbox.add_child(empty)
		return
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for i in emails.size():
		if deleted_mail.get(i, false):
			continue
		var mail: Dictionary = emails[i]
		var row := Button.new()
		row.text = mail.from + "\n" + mail.subject
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size.y = 62
		row.add_theme_font_size_override("font_size", 13)
		row.add_theme_color_override("font_color", UIFactory.color("#0f172a"))
		row.add_theme_color_override("font_hover_color", UIFactory.color("#0f172a"))
		row.add_theme_stylebox_override("normal", UIFactory.flat(Color.WHITE, UIFactory.color("#e0e0e0"), 1, 8, 4))
		row.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#e5f1fb"), UIFactory.color("#0078d7"), 1, 8, 4))
		row.add_theme_stylebox_override("pressed", UIFactory.flat(UIFactory.color("#cce4f7"), UIFactory.color("#005499"), 1, 8, 4))
		row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.gui_input.connect(on_mail_input.bind(i, mail))
		list.add_child(row)

func on_mail_input(event: InputEvent, index: int, mail: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			read_mail(index, mail)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			current_context = {"scope":"mail", "name":mail.subject, "type":t("Email message", "电子邮件"), "path":t("Mailbox/Inbox", "邮箱/收件箱"), "deletable":true, "index":index, "mail":mail}
			show_context_menu(event.global_position)

func read_mail(index: int, mail: Dictionary) -> void:
	var root := create_window("mail_read", t("Message", "邮件") + " — " + mail.subject, Vector2(600, 340), false)
	root.add_child(dark_label(t("From: ", "发件人：") + mail.from, 14))
	root.add_child(dark_label(t("Subject: ", "主题：") + mail.subject, 16))
	var body := dark_label(mail.body, 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var report := Button.new()
	report.text = t("Report as suspicious", "举报可疑邮件")
	UIFactory.style_win10_button(report)
	report.pressed.connect(report_mail.bind(index, mail))
	root.add_child(report)

func report_mail(index: int, mail: Dictionary) -> void:
	if mail.spam:
		reported[index] = true
	else:
		warn(t("This appears to be a legitimate message.", "这似乎是一封正常邮件。"))
	var needed := 0
	for item in stage.get("emails", []):
		if item.spam:
			needed += 1
	if needed > 0 and reported.size() == needed:
		stage_completed.emit()

func open_compose() -> void:
	var root := create_window("compose", t("New message", "新邮件"), Vector2(560, 340), false)
	for placeholder in [t("To", "收件人"), t("Subject", "主题")]:
		var field := LineEdit.new()
		field.placeholder_text = placeholder
		UIFactory.style_win10_lineedit(field)
		root.add_child(field)
	var body := TextEdit.new()
	body.placeholder_text = t("Write a message...", "撰写邮件……")
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIFactory.style_win10_textedit(body)
	root.add_child(body)
	var send := Button.new()
	send.text = t("Send", "发送")
	UIFactory.style_win10_button(send)
	send.pressed.connect(func(): warn(t("Sending mail is unavailable in this training computer.", "训练电脑暂不支持发送邮件。")))
	root.add_child(send)

func open_browser(initial: String) -> void:
	var root := create_window("browser", t("SuperBrowser", "超级浏览器"), Vector2(710, 400))
	var tabs := HBoxContainer.new()
	tabs.custom_minimum_size.y = 30
	tabs.add_theme_constant_override("separation", 2)
	var active_tab := sidebar_item("◎  " + t("New tab", "新标签页"), true)
	active_tab.custom_minimum_size.x = 180
	tabs.add_child(active_tab)
	var new_tab := sidebar_item("+")
	new_tab.custom_minimum_size.x = 34
	tabs.add_child(new_tab)
	root.add_child(tabs)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	var refresh := Button.new()
	refresh.text = "↻"
	refresh.tooltip_text = t("Refresh", "刷新")
	UIFactory.style_win10_button(refresh)
	nav.add_child(refresh)
	var address := LineEdit.new()
	address.text = initial
	address.placeholder_text = t("Search or enter an address", "搜索或输入网址")
	address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.style_win10_lineedit(address)
	address.text_submitted.connect(func(value: String): navigate_browser(value))
	nav.add_child(address)
	refresh.pressed.connect(func(): navigate_browser(address.text))
	var go := Button.new()
	go.text = t("Go", "前往")
	UIFactory.style_win10_button(go)
	go.pressed.connect(func(): navigate_browser(address.text))
	nav.add_child(go)
	root.add_child(nav)
	var bookmarks := HBoxContainer.new()
	bookmarks.add_theme_constant_override("separation", 4)
	for bookmark in [["security.local", t("Security Center", "安全中心")], ["news.local", t("Daily News", "每日新闻")], ["learn.local", t("Learning Portal", "学习中心")]]:
		var b := Button.new()
		b.text = "★  " + bookmark[1]
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", UIFactory.color("#333333"))
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#e5e5e5"), Color.TRANSPARENT, 0, 5, 2))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(navigate_browser.bind(bookmark[0]))
		bookmarks.add_child(b)
	root.add_child(bookmarks)
	var page_panel := PanelContainer.new()
	page_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_panel.add_theme_stylebox_override("panel", UIFactory.flat(Color.WHITE, UIFactory.color("#d6d6d6"), 1, 20, 18))
	root.add_child(page_panel)
	var page := dark_label(t("SuperBrowser\n\nWelcome to your new tab\nUse a bookmark, enter a local domain, or search with SuperSearch.", "超级浏览器\n\n欢迎打开新标签页\n请选择书签、输入本地域名，或使用超级搜索。"), 15)
	page.name = "WebPage"
	page.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_panel.add_child(page)
	if not initial.is_empty():
		navigate_browser(initial)

func navigate_browser(value: String) -> void:
	if not open_windows.has("browser"):
		open_browser(value)
		return
	var page: Label = open_windows.browser.find_child("WebPage", true, false)
	var normalized := value.strip_edges().to_lower()
	var sites := {
		"security.local": t("Security Center\n\nSystem status: Protected\nFirewall: On\nDefinitions: Up to date", "安全中心\n\n系统状态：受保护\n防火墙：已开启\n病毒库：最新"),
		"news.local": t("Daily News\n\nTechnology, community, and world headlines appear here.", "每日新闻\n\n此处显示科技、社区和全球新闻。"),
		"learn.local": t("Learning Portal\n\nSecurity courses and training resources.", "学习中心\n\n安全课程与培训资源。")
	}
	if sites.has(normalized):
		page.text = sites[normalized]
	elif "." not in normalized:
		page.text = t("SuperSearch results for: ", "超级搜索结果：") + value + t("\n\nSearch functionality will be added later.", "\n\n搜索功能将在之后添加。")
	else:
		page.text = t("This simulated website is unavailable.", "此模拟网站不可用。") + "\n" + value

func open_agent() -> void:
	var root := create_window("agent", t("SillyAgent", "智慧助手"), Vector2(650, 390))
	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 8)
	root.add_child(workspace)
	var side := make_sidebar(155)
	var new_chat := sidebar_item("＋  " + t("New chat", "新对话"), true)
	side.add_child(new_chat)
	side.add_child(dark_label(t("RECENT", "最近"), 11, UIFactory.color("#666666")))
	side.add_child(sidebar_item(t("Security questions", "安全问题")))
	side.add_child(sidebar_item(t("Getting started", "开始使用")))
	var side_spacer := Control.new()
	side_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(side_spacer)
	side.add_child(sidebar_item("⚙  " + t("Settings", "设置")))
	workspace.add_child(side)
	var conversation := VBoxContainer.new()
	conversation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conversation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conversation.add_theme_constant_override("separation", 8)
	workspace.add_child(conversation)
	var header := HBoxContainer.new()
	header.add_child(app_icon_rect("silly_agent", 30))
	var agent_title := dark_label(t("SillyAgent", "智慧助手"), 17)
	agent_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(agent_title)
	header.add_child(dark_label(t("Ready", "就绪"), 12, UIFactory.color("#16833b")))
	conversation.add_child(header)
	var chat := PanelContainer.new()
	chat.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat.add_theme_stylebox_override("panel", UIFactory.flat(UIFactory.color("#f7f7f8"), UIFactory.color("#d0d7e5"), 1, 18, 16))
	var welcome := dark_label(t("Hello! I'm SillyAgent.\n\nHow can I help you today?\n\n(This assistant will become interactive in a later stage.)", "你好！我是智慧助手。\n\n今天有什么可以帮你？\n\n（助手功能将在后续阶段实现。）"), 14)
	welcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat.add_child(welcome)
	conversation.add_child(chat)
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 4)
	var input := LineEdit.new()
	input.placeholder_text = t("Message SillyAgent", "给智慧助手发消息")
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIFactory.style_win10_lineedit(input)
	input_row.add_child(input)
	var send := Button.new()
	send.text = "➤"
	UIFactory.style_win10_button(send)
	input_row.add_child(send)
	conversation.add_child(input_row)

func open_recycle_bin() -> void:
	var root := create_window("recycle", t("Recycle Bin", "回收站"), Vector2(600, 350))
	var toolbar := make_app_toolbar()
	var empty_button := Button.new()
	empty_button.text = "♲  " + t("Empty Recycle Bin", "清空回收站")
	UIFactory.style_win10_button(empty_button)
	empty_button.disabled = deleted_items.is_empty()
	empty_button.pressed.connect(confirm_empty_recycle_bin)
	toolbar.add_child(empty_button)
	var toolbar_space := Control.new()
	toolbar_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(toolbar_space)
	toolbar.add_child(dark_label(t("Manage", "管理"), 12, UIFactory.color("#666666")))
	root.add_child(toolbar)
	var address := LineEdit.new()
	address.text = t("This PC  ›  Recycle Bin", "此电脑  ›  回收站")
	address.editable = false
	UIFactory.style_win10_lineedit(address)
	root.add_child(address)
	if deleted_items.is_empty():
		var empty_state := CenterContainer.new()
		empty_state.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var empty_box := VBoxContainer.new()
		empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
		var bin_icon := app_icon_rect("recycle_bin", 72)
		empty_box.add_child(bin_icon)
		var empty := dark_label(t("This folder is empty.", "此文件夹为空。"), 16, UIFactory.color("#666666"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_box.add_child(empty)
		empty_state.add_child(empty_box)
		root.add_child(empty_state)
		return
	var columns := HBoxContainer.new()
	columns.custom_minimum_size.y = 25
	var name_header := dark_label(t("Name", "名称"), 12, UIFactory.color("#555555"))
	name_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(name_header)
	var location_header := dark_label(t("Original location", "原始位置"), 12, UIFactory.color("#555555"))
	location_header.custom_minimum_size.x = 180
	columns.add_child(location_header)
	var actions_header := dark_label(t("Actions", "操作"), 12, UIFactory.color("#555555"))
	actions_header.custom_minimum_size.x = 190
	columns.add_child(actions_header)
	root.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for index in deleted_items.size():
		var item: Dictionary = deleted_items[index]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 42
		row.add_child(app_icon_rect(file_icon_name(item) if item.get("scope", "") == "file" else app_icon_name(item.get("id", "recycle")), 30))
		var details := dark_label(item.get("name", ""), 13)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var original_path := dark_label(item.get("path", ""), 12, UIFactory.color("#666666"))
		original_path.custom_minimum_size.x = 180
		original_path.clip_text = true
		row.add_child(original_path)
		var restore := Button.new()
		restore.text = t("Restore", "还原")
		UIFactory.style_win10_button(restore)
		restore.pressed.connect(restore_recycle_item.bind(index))
		row.add_child(restore)
		var remove := Button.new()
		remove.text = t("Delete permanently", "永久删除")
		UIFactory.style_win10_button(remove)
		remove.pressed.connect(confirm_permanent_delete.bind(index))
		row.add_child(remove)
		list.add_child(row)
	var status := dark_label(t("%d item(s)", "%d 个项目") % deleted_items.size(), 12, UIFactory.color("#666666"))
	root.add_child(status)

func restore_recycle_item(index: int) -> void:
	if index < 0 or index >= deleted_items.size():
		return
	var item: Dictionary = deleted_items[index]
	match item.get("scope", ""):
		"file":
			var restored: Dictionary = item.duplicate(true)
			restored.erase("scope")
			restored.erase("parent_path")
			fs_items[item.path] = restored
			var parent_path: String = item.get("parent_path", "root")
			if parent_path != "root" and fs_items.has(parent_path):
				var children: Array = fs_items[parent_path].get("children", [])
				if item.path not in children:
					children.append(item.path)
				fs_items[parent_path]["children"] = children
		"mail":
			deleted_mail.erase(item.index)
		"app":
			restore_desktop_app(item.id)
	deleted_items.remove_at(index)
	open_recycle_bin()

func restore_desktop_app(id: String) -> void:
	if app_buttons.has(id):
		return
	var definitions := {
		"my_pc":["my_pc", t("My PC", "我的电脑"), 0], "email":["email", t("Email", "电子邮件"), 1],
		"browser":["browser", t("Browser", "浏览器"), 2], "agent":["silly_agent", t("SillyAgent", "智慧助手"), 3],
		"recycle":["recycle_bin", t("Recycle Bin", "回收站"), 4]
	}
	if not definitions.has(id):
		return
	var definition: Array = definitions[id]
	var slot: int = definition[2]
	var icon := desktop_icon(definition[0], definition[1], Vector2(18 + (slot / 4) * 105, 18 + (slot % 4) * 88))
	icon.gui_input.connect(on_desktop_icon_input.bind(id))
	desktop.add_child(icon)
	app_buttons[id] = icon

func confirm_permanent_delete(index: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = t("Delete permanently", "永久删除")
	dialog.dialog_text = t("Permanently delete this item? This cannot be undone.", "确定永久删除此项目吗？此操作无法撤销。")
	dialog.confirmed.connect(permanently_delete_item.bind(index))
	add_child(dialog)
	dialog.popup_centered()

func permanently_delete_item(index: int) -> void:
	if index >= 0 and index < deleted_items.size():
		deleted_items.remove_at(index)
	open_recycle_bin()

func confirm_empty_recycle_bin() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = t("Empty Recycle Bin", "清空回收站")
	dialog.dialog_text = t("Permanently delete all items? This cannot be undone.", "确定永久删除所有项目吗？此操作无法撤销。")
	dialog.confirmed.connect(empty_recycle_bin)
	add_child(dialog)
	dialog.popup_centered()

func empty_recycle_bin() -> void:
	deleted_items.clear()
	open_recycle_bin()

func open_task_manager() -> void:
	var root := create_window("task_manager", t("Task Manager", "任务管理器"), Vector2(690, 400), false)
	var total := 0.0
	for process in processes.values():
		total += process.cpu
	if total > 35.0:
		var scale := 35.0 / total
		for process in processes.values():
			process.cpu *= scale
			total = 35.0
	var menu := HBoxContainer.new()
	for menu_name in [t("File", "文件"), t("Options", "选项"), t("View", "查看")]:
		var menu_button := sidebar_item(menu_name)
		menu_button.custom_minimum_size.x = 70
		menu.add_child(menu_button)
	root.add_child(menu)
	var tabs := HBoxContainer.new()
	for tab_name in [t("Processes", "进程"), t("Performance", "性能"), t("App history", "应用历史"), t("Startup", "启动")]:
		var tab := sidebar_item(tab_name, tab_name == t("Processes", "进程"))
		tab.custom_minimum_size.x = 105
		tabs.add_child(tab)
	root.add_child(tabs)
	var utilization := HBoxContainer.new()
	var utilization_title := dark_label(t("Processes", "进程"), 16)
	utilization_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utilization.add_child(utilization_title)
	utilization.add_child(dark_label(t("CPU usage  ", "CPU 使用率  ") + "%.1f%%" % total, 14, UIFactory.color("#0078d7")))
	root.add_child(utilization)
	var header := HBoxContainer.new()
	var name_header := dark_label(t("Processes", "进程"), 14, UIFactory.color("#5a5a5a"))
	name_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_header)
	var cpu_header := dark_label("CPU", 14, UIFactory.color("#5a5a5a"))
	cpu_header.custom_minimum_size.x = 70
	cpu_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(cpu_header)
	var action_header := dark_label(t("Actions", "操作"), 14, UIFactory.color("#5a5a5a"))
	action_header.custom_minimum_size.x = 180
	header.add_child(action_header)
	root.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for pid in processes.keys():
		var process: Dictionary = processes[pid]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var label := dark_label("%s  (PID %d)" % [process.name, pid], 13)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var cpu := ProgressBar.new()
		cpu.min_value = 0
		cpu.max_value = 40
		cpu.value = process.cpu
		cpu.show_percentage = false
		cpu.custom_minimum_size = Vector2(70, 18)
		cpu.tooltip_text = "%.1f%% CPU" % process.cpu
		row.add_child(cpu)
		var path := Button.new()
		path.text = t("Path", "路径")
		UIFactory.style_win10_button(path)
		path.pressed.connect(show_process_path.bind(pid))
		row.add_child(path)
		var kill := Button.new()
		kill.text = t("End task", "结束任务")
		UIFactory.style_win10_button(kill)
		kill.pressed.connect(kill_process.bind(pid))
		row.add_child(kill)
		list.add_child(row)
	var idle := HBoxContainer.new()
	var idle_name := dark_label("IDLE", 14)
	idle_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idle.add_child(idle_name)
	idle.add_child(dark_label("%.1f%%" % (100.0 - total), 14, UIFactory.color("#15803d")))
	list.add_child(idle)

func show_process_path(pid: int) -> void:
	if not processes.has(pid):
		return
	if not processes[pid].path_visible:
		warn(t("Access denied. The process path is protected.", "访问被拒绝。该进程路径受保护。"))
	else:
		warn(t("Process path:\n", "进程路径：\n") + processes[pid].path)

func kill_process(pid: int) -> void:
	if not processes.has(pid):
		return
	var process: Dictionary = processes[pid]
	if not process.killable:
		warn(t("This is a protected system process and cannot be ended.", "这是受保护的系统进程，无法结束。"))
		return
	var window_id: String = process.window_id
	processes.erase(pid)
	if not window_id.is_empty() and open_windows.has(window_id):
		open_windows[window_id].queue_free()
		open_windows.erase(window_id)
	refresh_window_borders()
	refresh_task_buttons()
	open_task_manager()

func warn(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = t("Notice", "提示")
	dialog.dialog_text = message
	dialog.get_label().add_theme_color_override("font_color", UIFactory.color("#1a1a1a"))
	dialog.get_label().add_theme_font_size_override("font_size", 13)
	dialog.add_theme_stylebox_override("panel", UIFactory.win10_window())
	UIFactory.style_win10_button(dialog.get_ok_button())
	add_child(dialog)
	dialog.popup_centered()

func dark_label(text: String, font_size := 16, color := UIFactory.color("#172033")) -> Label:
	var label := UIFactory.label(text, font_size, color)
	return label
