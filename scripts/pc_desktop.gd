class_name PCDesktop
extends Control

signal stage_completed
signal stage_failed(message: String)

const TASKBAR_H := 40.0
const ICON_DIR := "res://assets/icons/"
const MALWARE_PATH := "C:\\Profiles\\User\\AppData\\Roaming\\SystemCache\\UpdateService\\host_service.exe"
const MALWARE_FOLDER := "C:\\Profiles\\User\\AppData\\Roaming\\SystemCache\\UpdateService"
const SUPER_SECURE_ADDRESS := "https://www.supersecure.test"
const DAILY_NEWS_ADDRESS := "https://news.supersearch.test"
const LEARNING_ADDRESS := "https://learn.supersearch.test"
const SUPER_SEARCH_ADDRESS := "https://www.supersearch.test"

const APP_PATHS := {
	"my_pc": "C:\\Windows\\explorer.exe",
	"email": "C:\\Program Files\\SecMail\\SecMail.exe",
	"browser": "C:\\Program Files\\SuperBrowser\\browser.exe",
	"agent": "C:\\Program Files\\SillyAgent\\SillyAgent.exe",
	"recycle": "C:\\$Recycle.Bin",
	"antivirus": "C:\\Program Files\\Super Security\\SuperSecurity.exe"
}

var state: GameState
var stage: Dictionary
var desktop: Control
var window_layer: Control
var taskbar: PanelContainer
var system_tray: HBoxContainer
var context_menu: PopupMenu
var start_menu: PopupPanel
var current_context: Dictionary
var open_windows: Dictionary = {}
var process_manager := ProcessManager.new()
var processes: Dictionary = process_manager.processes
var deleted_items: Array[Dictionary] = []
var deleted_mail: Dictionary = {}
var app_buttons: Dictionary = {}
var reported: Dictionary = {}
var clock_label: Label
var antivirus_present := false
var firewall_enabled := true
var virus_protection_enabled := true
var antivirus_tray_button: Button
var antivirus_installer_present := false
var antivirus_installer_path := "C:\\Profiles\\User\\Desktop\\SuperSecuritySetup.exe"
var malware_restart_timer: Timer
var installer_desktop_button: Button
var process_context_menu: PopupMenu
var context_process_pid := -1
var virtual_fs := VirtualFileSystem.new()
var fs_items: Dictionary = virtual_fs.items
var browser_pages: BrowserPages
var window_manager: DesktopWindowManager
var sound_effects: SoundEffects

func setup(game_state: GameState, stage_data: Dictionary) -> void:
	state = game_state
	stage = stage_data
	browser_pages = BrowserPages.new(self)
	window_manager = DesktopWindowManager.new(self)
	antivirus_present = stage.get("antivirus_present", false)
	antivirus_installer_present = stage.get("antivirus_installer_present", false)
	antivirus_installer_path = stage.get("antivirus_installer_path", "C:\\Profiles\\User\\Desktop\\SuperSecuritySetup.exe")
	firewall_enabled = stage.get("firewall_enabled", true)
	virus_protection_enabled = stage.get("virus_protection_enabled", true)
	configure_malware_stage()
	configure_antivirus_installer()
	build_desktop()

func t(en: String, zh: String) -> String:
	return state.tr_text(en, zh)

func _input(event: InputEvent) -> void:
	if sound_effects == null:
		return
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	):
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and (hovered == self or is_ancestor_of(hovered)):
			sound_effects.play_click()

func ensure_virtual_folder(parent_path: String, folder_path: String, folder_name: String) -> void:
	virtual_fs.ensure_folder(parent_path, folder_path, folder_name)

func configure_malware_stage() -> void:
	if stage.id != "malware":
		return
	ensure_virtual_folder("C:\\Profiles\\User", "C:\\Profiles\\User\\AppData", "AppData")
	ensure_virtual_folder("C:\\Profiles\\User\\AppData", "C:\\Profiles\\User\\AppData\\Roaming", "Roaming")
	ensure_virtual_folder("C:\\Profiles\\User\\AppData\\Roaming", "C:\\Profiles\\User\\AppData\\Roaming\\SystemCache", "SystemCache")
	ensure_virtual_folder("C:\\Profiles\\User\\AppData\\Roaming\\SystemCache", MALWARE_FOLDER, "UpdateService")
	fs_items[MALWARE_PATH] = {
		"name": "host_service.exe",
		"type": "Executable",
		"kind": "executable",
		"path": MALWARE_PATH,
		"deletable": true,
		"malware": true
	}
	if MALWARE_PATH not in fs_items[MALWARE_FOLDER]["children"]:
		fs_items[MALWARE_FOLDER]["children"].append(MALWARE_PATH)

func configure_antivirus_installer() -> void:
	if not antivirus_installer_present:
		return
	var separator_index := antivirus_installer_path.rfind("\\")
	var downloads_path := antivirus_installer_path.substr(0, separator_index) if separator_index >= 0 else ""
	var installer_name := antivirus_installer_path.substr(separator_index + 1) if separator_index >= 0 else antivirus_installer_path
	if downloads_path.is_empty():
		downloads_path = "C:\\Profiles\\User\\Desktop"
	if not fs_items.has(downloads_path):
		var parent_separator := downloads_path.rfind("\\")
		var parent_path := downloads_path.substr(0, parent_separator) if parent_separator >= 0 else "D:\\"
		ensure_virtual_folder(parent_path, downloads_path, downloads_path.substr(parent_separator + 1))
	fs_items[antivirus_installer_path] = {
		"name": installer_name,
		"type": "Application installer",
		"kind": "executable",
		"path": antivirus_installer_path,
		"deletable": true,
		"installer_id": "antivirus"
	}
	if antivirus_installer_path not in fs_items[downloads_path]["children"]:
		fs_items[downloads_path]["children"].append(antivirus_installer_path)

func start_stage_processes() -> void:
	if stage.id != "malware" or not fs_items.has(MALWARE_PATH):
		return
	start_process("Host Update Service", MALWARE_PATH, true, true, 88.0)
	for pid in processes:
		if processes[pid].path == MALWARE_PATH:
			processes[pid]["persistent_malware"] = true
			break
	malware_restart_timer = Timer.new()
	malware_restart_timer.one_shot = true
	malware_restart_timer.wait_time = 3.0
	malware_restart_timer.timeout.connect(restart_malware_process)
	add_child(malware_restart_timer)

func restart_malware_process() -> void:
	if not fs_items.has(MALWARE_PATH):
		return
	start_stage_processes()
	refresh_task_manager_if_open()

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
	if antivirus_present:
		add_antivirus_desktop_icon()
	if antivirus_installer_present:
		add_installer_desktop_icon()
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
	start_stage_processes()

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
	var png_path := ICON_DIR + icon_name + ".png"
	if ResourceLoader.exists(png_path):
		return load(png_path) as Texture2D
	return load(ICON_DIR + icon_name + ".svg") as Texture2D

func app_icon_name(id: String) -> String:
	if id == "antivirus":
		return "antivirus_good" if firewall_enabled and virus_protection_enabled else "antivirus_bad"
	var names := {"my_pc":"my_pc", "email":"email", "browser":"browser", "agent":"silly_agent", "recycle":"recycle_bin", "photo_viewer":"photo", "document_viewer":"word_file", "antivirus":"antivirus_good"}
	return names.get(id, "executable")

func file_icon_name(item: Dictionary) -> String:
	var path: String = item.get("path", "")
	if item.get("installer_id", "") == "antivirus":
		return "antivirus_installer"
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

func add_antivirus_desktop_icon() -> void:
	if app_buttons.has("antivirus"):
		return
	var icon := desktop_icon("antivirus_good", "Super Security", Vector2(123, 106))
	icon.gui_input.connect(on_desktop_icon_input.bind("antivirus"))
	desktop.add_child(icon)
	if is_instance_valid(window_layer):
		desktop.move_child(icon, window_layer.get_index())
	app_buttons["antivirus"] = icon

func add_installer_desktop_icon() -> void:
	if is_instance_valid(installer_desktop_button):
		return
	installer_desktop_button = desktop_icon(
		"antivirus_installer",
		t("Super Security Setup", "Super Security 安装程序"),
		Vector2(123, 194)
	)
	installer_desktop_button.gui_input.connect(on_file_input.bind(antivirus_installer_path))
	desktop.add_child(installer_desktop_button)
	if is_instance_valid(window_layer):
		desktop.move_child(installer_desktop_button, window_layer.get_index())

func ensure_antivirus_tray_icon() -> void:
	if is_instance_valid(antivirus_tray_button):
		update_antivirus_tray()
		return
	antivirus_tray_button = Button.new()
	antivirus_tray_button.custom_minimum_size = Vector2(28, 28)
	antivirus_tray_button.flat = true
	antivirus_tray_button.expand_icon = true
	antivirus_tray_button.add_theme_constant_override("icon_max_width", 20)
	antivirus_tray_button.pressed.connect(open_antivirus)
	system_tray.add_child(antivirus_tray_button)
	system_tray.move_child(antivirus_tray_button, mini(1, system_tray.get_child_count() - 1))
	update_antivirus_tray()

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
	system_tray = HBoxContainer.new()
	system_tray.add_theme_constant_override("separation", 8)
	system_tray.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(system_tray)
	system_tray.add_child(UIFactory.label("▲", 9, Color.WHITE))
	if antivirus_present:
		ensure_antivirus_tray_icon()
	system_tray.add_child(UIFactory.label("Wi-Fi", 11, Color.WHITE))
	system_tray.add_child(UIFactory.label("🔊", 11, Color.WHITE))
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
	if current_context.scope == "file":
		var protected_path := find_non_deletable_item(path)
		if not protected_path.is_empty():
			var protected_name: String = fs_items[protected_path].get("name", protected_path)
			warn(t(
				"This folder cannot be deleted because it contains a protected item: %s" % protected_name,
				"无法删除此文件夹，因为其中包含受保护的项目：%s" % protected_name
			))
			return
	if path_has_running_process(path):
		warn(t(
			"The item is in use by a running process and cannot be deleted.",
			"该项目正被运行中的进程使用，无法删除。"
		))
		return
	if is_essential_system_path(path):
		crash_system()
		return
	var recycle_record: Dictionary = current_context.duplicate(true)
	if current_context.scope == "file":
		recycle_record["parent_path"] = find_parent_path(path)
		if fs_items.has(path) and fs_items[path].get("kind", "") == "folder":
			recycle_record["recursive_items"] = collect_virtual_subtree(path)
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
	var completes_malware_stage: bool = stage.id == "malware" and (
		path == MALWARE_PATH or MALWARE_PATH.begins_with(path.trim_suffix("\\") + "\\")
	)
	remove_virtual_item_recursive(path)
	if (
		(path == antivirus_installer_path or antivirus_installer_path.begins_with(path.trim_suffix("\\") + "\\"))
		and is_instance_valid(installer_desktop_button)
	):
		installer_desktop_button.queue_free()
		installer_desktop_button = null
	if open_windows.has("my_pc"):
		open_my_pc("C:\\")
	if completes_malware_stage:
		remove_malware_process()
		stage_completed.emit()

func remove_virtual_item_recursive(path: String) -> void:
	virtual_fs.remove_recursive(path)

func collect_virtual_subtree(path: String) -> Dictionary:
	return virtual_fs.collect_subtree(path)

func find_non_deletable_item(path: String) -> String:
	return virtual_fs.find_non_deletable(path)

func path_has_running_process(path: String) -> bool:
	var is_folder: bool = fs_items.has(path) and fs_items[path].get("kind", "") == "folder"
	return process_manager.has_path(path, is_folder)

func is_essential_system_path(path: String) -> bool:
	return path == "C:\\System" or path.begins_with("C:\\System\\")

func crash_system() -> void:
	var crash := ColorRect.new()
	crash.color = UIFactory.color("#0078d7")
	crash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crash.mouse_filter = Control.MOUSE_FILTER_STOP
	desktop.add_child(crash)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crash.add_child(center)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 14)
	var face := UIFactory.label(":(", 58, Color.WHITE)
	copy.add_child(face)
	var heading := UIFactory.label(t(
		"Your PC ran into a problem and needs to restart.",
		"你的电脑遇到问题，需要重新启动。"
	), 21, Color.WHITE)
	copy.add_child(heading)
	var detail := UIFactory.label(t(
		"You deleted essential system files and the system crashed.",
		"你删除了重要的系统文件，系统已经崩溃。"
	), 15, Color.WHITE)
	copy.add_child(detail)
	center.add_child(copy)
	stage_failed.emit(t(
		"You deleted essential system files and the system crashed.",
		"你删除了重要的系统文件，系统已经崩溃。"
	))

func remove_malware_process() -> void:
	if is_instance_valid(malware_restart_timer):
		malware_restart_timer.stop()
	process_manager.remove_for_path(MALWARE_PATH)
	refresh_task_manager_if_open()

func find_parent_path(path: String) -> String:
	var parent_path := virtual_fs.find_parent(path)
	return parent_path if not parent_path.is_empty() else "root"

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
	var names := {"my_pc":t("My PC", "我的电脑"), "email":t("Email", "电子邮件"), "browser":t("Browser", "浏览器"), "agent":t("SillyAgent", "智慧助手"), "recycle":t("Recycle Bin", "回收站"), "antivirus":"Super Security"}
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
		"antivirus": open_antivirus()

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
	window_manager.on_titlebar_input(event, id, panel)

func on_window_panel_input(event: InputEvent, id: String) -> void:
	window_manager.on_panel_input(event, id)

func toggle_maximize(id: String) -> void:
	window_manager.toggle_maximize(id)

func raise_window(panel: Control) -> void:
	window_manager.raise_window(panel)

func refresh_window_borders() -> void:
	window_manager.refresh_borders()

func clamp_window_to_desktop(panel: Control) -> void:
	window_manager.clamp_to_desktop(panel)

func minimize_window(id: String) -> void:
	window_manager.minimize(id)

func minimize_all_windows() -> void:
	window_manager.minimize_all()

func restore_window(id: String) -> void:
	window_manager.restore(id)

func close_window(id: String) -> void:
	window_manager.close(id)

func refresh_task_buttons() -> void:
	window_manager.refresh_task_buttons()

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
		"task_manager":t("Task Manager", "任务管理器"),
		"antivirus":"Super Security"
	}
	return names.get(id, id.capitalize())

func start_process(name: String, path: String, killable := true, path_visible := true, cpu := -1.0, window_id := "") -> void:
	process_manager.start(name, path, APP_PATHS, killable, path_visible, cpu, window_id)
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
	if item.get("installer_id", "") == "antivirus":
		open_antivirus_installer()
		return
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
func open_antivirus_installer() -> void:
	if antivirus_present:
		warn(t("Super Security is already installed.", "Super Security 已经安装。"))
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = t("User Account Control", "用户账户控制")
	dialog.dialog_text = t(
		"Do you want to allow this app to make changes to your device?\n\nSuper Security Installer",
		"是否允许此应用对你的设备进行更改？\n\nSuper Security 安装程序"
	)
	dialog.get_ok_button().text = t("Yes", "是")
	dialog.get_cancel_button().text = t("No", "否")
	dialog.get_label().add_theme_color_override("font_color", UIFactory.color("#1a1a1a"))
	dialog.get_label().add_theme_font_size_override("font_size", 13)
	dialog.add_theme_stylebox_override("panel", UIFactory.win10_window())
	UIFactory.style_win10_button(dialog.get_ok_button())
	UIFactory.style_win10_button(dialog.get_cancel_button())
	dialog.confirmed.connect(install_antivirus)
	add_child(dialog)
	dialog.popup_centered()

func install_antivirus() -> void:
	antivirus_present = true
	firewall_enabled = true
	virus_protection_enabled = true
	add_antivirus_desktop_icon()
	ensure_antivirus_tray_icon()
	warn(t(
		"Super Security was installed successfully.",
		"Super Security 已成功安装。"
	), false)

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
	address.name = "BrowserAddress"
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
	for bookmark in [
		[SUPER_SECURE_ADDRESS, "Super Secure"],
		[DAILY_NEWS_ADDRESS, t("Daily News", "每日新闻")],
		[LEARNING_ADDRESS, t("Learning Portal", "学习中心")]
	]:
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
	var web_content := VBoxContainer.new()
	web_content.name = "WebContent"
	web_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	web_content.add_theme_constant_override("separation", 8)
	page_panel.add_child(web_content)
	if not initial.is_empty():
		navigate_browser(initial)
	else:
		browser_pages.render_new_tab(web_content)

func navigate_browser(value: String) -> void:
	if not open_windows.has("browser"):
		open_browser(value)
		return
	var web_content: VBoxContainer = open_windows.browser.find_child("WebContent", true, false)
	var address: LineEdit = open_windows.browser.find_child("BrowserAddress", true, false)
	var normalized := normalize_game_address(value)
	if normalized == "www.supersecure.test":
		address.text = SUPER_SECURE_ADDRESS
		browser_pages.render_super_secure(web_content)
	elif normalized == "news.supersearch.test":
		address.text = DAILY_NEWS_ADDRESS
		browser_pages.render_news(web_content)
	elif normalized == "learn.supersearch.test":
		address.text = LEARNING_ADDRESS
		browser_pages.render_learning(web_content)
	elif normalized == "www.supersearch.test":
		address.text = SUPER_SEARCH_ADDRESS
		browser_pages.render_search_home(web_content)
	elif "." not in normalized:
		address.text = SUPER_SEARCH_ADDRESS + "/search?q=" + value.strip_edges().replace(" ", "+")
		browser_pages.render_search_results(web_content, value.strip_edges())
	else:
		address.text = value
		browser_pages.render_unavailable(web_content, value)

func normalize_game_address(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	for prefix in ["https://", "http://"]:
		if normalized.begins_with(prefix):
			normalized = normalized.trim_prefix(prefix)
	normalized = normalized.trim_suffix("/")
	return normalized

func download_antivirus_installer() -> void:
	if antivirus_installer_present and fs_items.has(antivirus_installer_path):
		warn(t("The installer is already on the desktop.", "安装程序已在桌面上。"))
		return
	antivirus_installer_present = true
	antivirus_installer_path = "C:\\Profiles\\User\\Desktop\\SuperSecuritySetup.exe"
	configure_antivirus_installer()
	add_installer_desktop_icon()
	warn(t(
		"SuperSecuritySetup.exe was downloaded to the desktop.",
		"SuperSecuritySetup.exe 已下载到桌面。"
	), false)

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

func open_antivirus() -> void:
	if not antivirus_present:
		return
	if open_windows.has("antivirus") and is_instance_valid(open_windows["antivirus"]):
		restore_window("antivirus")
		return
	var root := create_window("antivirus", "Super Security", Vector2(690, 410))
	var antivirus: AntivirusApp = load("res://scenes/antivirus_app.tscn").instantiate()
	antivirus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	antivirus.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(antivirus)
	antivirus.setup(state, firewall_enabled, virus_protection_enabled)
	antivirus.protection_changed.connect(on_antivirus_protection_changed)
	antivirus.scan_completed.connect(on_antivirus_scan_completed.bind(antivirus))
	antivirus.clean_requested.connect(clean_detected_malware.bind(antivirus))

func on_antivirus_protection_changed(firewall: bool, virus_protection: bool) -> void:
	firewall_enabled = firewall
	virus_protection_enabled = virus_protection
	update_antivirus_tray()
	refresh_task_buttons()

func on_antivirus_scan_completed(antivirus: AntivirusApp) -> void:
	if fs_items.has(MALWARE_PATH):
		antivirus.show_threat_detected(fs_items[MALWARE_PATH].name)

func clean_detected_malware(antivirus: AntivirusApp) -> void:
	if not fs_items.has(MALWARE_PATH):
		return
	remove_virtual_item_recursive(MALWARE_FOLDER)
	for item in fs_items.values():
		if item.has("children"):
			item.children.erase(MALWARE_FOLDER)
	remove_malware_process()
	antivirus.show_clean_result()
	stage_completed.emit()

func update_antivirus_tray() -> void:
	if not is_instance_valid(antivirus_tray_button):
		return
	var fully_protected := firewall_enabled and virus_protection_enabled
	antivirus_tray_button.icon = icon_texture("antivirus_good" if fully_protected else "antivirus_bad")
	antivirus_tray_button.tooltip_text = (
		t("Super Security: Your device is protected", "Super Security：设备已受保护")
		if fully_protected
		else t("Super Security: Action needed", "Super Security：需要操作")
	)

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
			if item.has("recursive_items"):
				virtual_fs.restore_subtree(
					item.recursive_items,
					item.get("parent_path", "root"),
					item.path
				)
			else:
				var restored: Dictionary = item.duplicate(true)
				restored.erase("scope")
				restored.erase("parent_path")
				restored.erase("recursive_items")
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
		"recycle":["recycle_bin", t("Recycle Bin", "回收站"), 4],
		"antivirus":["antivirus_good", "Super Security", 5]
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
	ensure_process_context_menu()
	var total := 0.0
	for process in processes.values():
		total += process.cpu
	var malware_is_active := false
	for process in processes.values():
		malware_is_active = malware_is_active or process.path == MALWARE_PATH
	if total > 35.0 and not malware_is_active:
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
		label.tooltip_text = t("Right-click for process options", "右键单击以查看进程选项")
		label.gui_input.connect(on_process_row_input.bind(pid))
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
	idle.add_child(dark_label("%.1f%%" % maxf(0.0, 100.0 - total), 14, UIFactory.color("#15803d")))
	list.add_child(idle)

func ensure_process_context_menu() -> void:
	if is_instance_valid(process_context_menu):
		return
	process_context_menu = PopupMenu.new()
	process_context_menu.id_pressed.connect(on_process_context_action)
	add_child(process_context_menu)

func on_process_row_input(event: InputEvent, pid: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		context_process_pid = pid
		process_context_menu.clear()
		process_context_menu.add_item(t("Open file location", "打开文件所在位置"), 1)
		process_context_menu.add_item(t("End task", "结束任务"), 2)
		process_context_menu.position = Vector2i(event.global_position)
		process_context_menu.popup()

func on_process_context_action(action_id: int) -> void:
	if not processes.has(context_process_pid):
		return
	if action_id == 1:
		open_process_file_location(context_process_pid)
	elif action_id == 2:
		kill_process(context_process_pid)

func open_process_file_location(pid: int) -> void:
	if not processes.has(pid):
		return
	if not processes[pid].path_visible:
		warn(t("Access denied. The process path is protected.", "访问被拒绝。该进程路径受保护。"))
		return
	var path: String = processes[pid].path
	var separator := path.rfind("\\")
	var parent := path.substr(0, separator) if separator >= 0 else "root"
	if fs_items.has(parent):
		open_my_pc(parent)
	else:
		warn(t("Process path:\n", "进程路径：\n") + path, false)

func show_process_path(pid: int) -> void:
	if not processes.has(pid):
		return
	if not processes[pid].path_visible:
		warn(t("Access denied. The process path is protected.", "访问被拒绝。该进程路径受保护。"))
	else:
		warn(t("Process path:\n", "进程路径：\n") + processes[pid].path, false)

func kill_process(pid: int) -> void:
	if not processes.has(pid):
		return
	var process: Dictionary = processes[pid]
	if not process.killable:
		warn(t("This is a protected system process and cannot be ended.", "这是受保护的系统进程，无法结束。"))
		return
	var window_id: String = process.window_id
	var restart_malware: bool = process.get("persistent_malware", false)
	processes.erase(pid)
	if not window_id.is_empty() and open_windows.has(window_id):
		open_windows[window_id].queue_free()
		open_windows.erase(window_id)
	refresh_window_borders()
	refresh_task_buttons()
	open_task_manager()
	if restart_malware and fs_items.has(MALWARE_PATH) and is_instance_valid(malware_restart_timer):
		malware_restart_timer.start()

func warn(message: String, play_error_sound := true) -> void:
	if play_error_sound and sound_effects != null:
		sound_effects.play_error()
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
