class_name DesktopWindowManager
extends RefCounted

const TASKBAR_HEIGHT := 40.0

var host
var dragged_window: Control
var drag_offset := Vector2.ZERO

func _init(desktop_host) -> void:
	host = desktop_host

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
		panel.global_position = event.global_position - drag_offset
		clamp_to_desktop(panel)

func on_panel_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if host.open_windows.has(id) and is_instance_valid(host.open_windows[id]):
			raise_window(host.open_windows[id])

func toggle_maximize(id: String) -> void:
	if not host.open_windows.has(id) or not is_instance_valid(host.open_windows[id]):
		return
	var panel: Control = host.open_windows[id]
	if panel.get_meta("maximized", false):
		var rect: Rect2 = panel.get_meta("restore_rect")
		panel.position = rect.position
		panel.size = rect.size
		panel.set_meta("maximized", false)
		clamp_to_desktop(panel)
	else:
		panel.set_meta("restore_rect", Rect2(panel.position, panel.size))
		panel.position = Vector2.ZERO
		panel.size = Vector2(host.window_layer.size.x, maxf(0.0, host.window_layer.size.y - TASKBAR_HEIGHT))
		panel.set_meta("maximized", true)
	raise_window(panel)

func raise_window(panel: Control) -> void:
	host.window_layer.move_child(panel, host.window_layer.get_child_count() - 1)
	refresh_borders()

func refresh_borders() -> void:
	var top: Control = null
	for i in range(host.window_layer.get_child_count() - 1, -1, -1):
		var child: Control = host.window_layer.get_child(i)
		if child.visible:
			top = child
			break
	for id in host.open_windows:
		var window: Control = host.open_windows[id]
		if not is_instance_valid(window):
			continue
		var style: StyleBoxFlat = window.get_theme_stylebox("panel").duplicate()
		style.border_color = UIFactory.accent() if window == top else UIFactory.color("#9a9a9a")
		window.add_theme_stylebox_override("panel", style)

func clamp_to_desktop(panel: Control) -> void:
	var usable_size := Vector2(host.window_layer.size.x, maxf(0.0, host.window_layer.size.y - TASKBAR_HEIGHT))
	var max_x: float = maxf(0.0, usable_size.x - panel.size.x)
	var max_y: float = maxf(0.0, usable_size.y - panel.size.y)
	panel.position = Vector2(
		clampf(panel.position.x, 0.0, max_x),
		clampf(panel.position.y, 0.0, max_y)
	)

func minimize(id: String) -> void:
	if host.open_windows.has(id) and is_instance_valid(host.open_windows[id]):
		host.open_windows[id].hide()
	refresh_borders()
	refresh_task_buttons()

func minimize_all() -> void:
	for id in host.open_windows:
		if is_instance_valid(host.open_windows[id]):
			host.open_windows[id].hide()
	refresh_borders()
	refresh_task_buttons()

func restore(id: String) -> void:
	if not host.open_windows.has(id) or not is_instance_valid(host.open_windows[id]):
		return
	var panel: Control = host.open_windows[id]
	panel.show()
	raise_window(panel)
	refresh_task_buttons()

func close(id: String) -> void:
	if host.open_windows.has(id) and is_instance_valid(host.open_windows[id]):
		host.open_windows[id].queue_free()
	host.open_windows.erase(id)
	host.process_manager.remove_for_window(id)
	refresh_borders()
	refresh_task_buttons()
	host.refresh_task_manager_if_open()

func refresh_task_buttons() -> void:
	var holder: Node = host.taskbar.find_child("RunningApps", true, false)
	if holder == null:
		return
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	for id in host.open_windows.keys():
		if id in ["properties", "mail_read", "compose", "warning"]:
			continue
		var window: Control = host.open_windows[id] as Control
		var minimized: bool = not window.visible
		var button := Button.new()
		button.text = host.window_display_name(id)
		button.icon = host.icon_texture(host.app_icon_name(id))
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 22)
		button.custom_minimum_size = Vector2(76, 0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.tooltip_text = host.t("Restore window", "还原窗口") if minimized else host.t("Bring to front", "置于前台")
		button.add_theme_font_size_override("font_size", 12)
		var font_color := Color(1, 1, 1, 0.55) if minimized else Color.WHITE
		button.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_hover_color", font_color)
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
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(restore.bind(id))
		holder.add_child(button)
