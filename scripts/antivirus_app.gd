class_name AntivirusApp
extends Control

signal protection_changed(firewall_enabled: bool, virus_protection_enabled: bool)
signal scan_completed
signal clean_requested

var state: GameState
var firewall_enabled := true
var virus_protection_enabled := true
var page_host: VBoxContainer
var scan_progress: ProgressBar
var scan_status: Label
var scan_timer: Timer
var scan_actions: VBoxContainer

func setup(game_state: GameState, firewall: bool, virus_protection: bool) -> void:
	state = game_state
	firewall_enabled = firewall
	virus_protection_enabled = virus_protection
	build_shell()

func t(en: String, zh: String) -> String:
	return state.tr_text(en, zh)

func build_shell() -> void:
	var workspace := HBoxContainer.new()
	workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workspace.add_theme_constant_override("separation", 0)
	add_child(workspace)
	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size.x = 155
	side_panel.add_theme_stylebox_override("panel", UIFactory.flat(UIFactory.color("#f2f2f2"), UIFactory.color("#d8d8d8"), 1, 8, 10))
	workspace.add_child(side_panel)
	var navigation := VBoxContainer.new()
	navigation.add_theme_constant_override("separation", 4)
	side_panel.add_child(navigation)
	var brand := HBoxContainer.new()
	brand.add_child(make_icon("antivirus_good", 34))
	var brand_label := UIFactory.label("Super Security", 16, UIFactory.color("#202020"))
	brand_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand.add_child(brand_label)
	navigation.add_child(brand)
	navigation.add_child(HSeparator.new())
	var scan_nav := nav_button("⌕  " + t("Virus scan", "病毒扫描"), true)
	scan_nav.pressed.connect(show_scan_page)
	navigation.add_child(scan_nav)
	var protection_nav := nav_button("▣  " + t("Protection", "防护设置"))
	protection_nav.pressed.connect(show_protection_page)
	navigation.add_child(protection_nav)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	navigation.add_child(spacer)
	navigation.add_child(UIFactory.label(t("Security status", "安全状态"), 11, UIFactory.color("#666666")))
	var status := UIFactory.label("", 12)
	status.name = "OverallStatus"
	navigation.add_child(status)
	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_top", 18)
	content_margin.add_theme_constant_override("margin_bottom", 18)
	workspace.add_child(content_margin)
	page_host = VBoxContainer.new()
	page_host.add_theme_constant_override("separation", 12)
	content_margin.add_child(page_host)
	scan_timer = Timer.new()
	scan_timer.wait_time = 0.12
	scan_timer.timeout.connect(advance_scan)
	add_child(scan_timer)
	update_overall_status()
	show_scan_page()

func nav_button(text: String, selected := false) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 38
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", UIFactory.color("#202020"))
	button.add_theme_color_override("font_hover_color", UIFactory.color("#202020"))
	var normal := UIFactory.color("#dbeaf7") if selected else Color.TRANSPARENT
	button.add_theme_stylebox_override("normal", UIFactory.flat(normal, Color.TRANSPARENT, 0, 8, 4))
	button.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#e5f1fb"), Color.TRANSPARENT, 0, 8, 4))
	button.add_theme_stylebox_override("pressed", UIFactory.flat(UIFactory.color("#cce4f7"), Color.TRANSPARENT, 0, 8, 4))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func clear_page() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

func show_scan_page() -> void:
	clear_page()
	page_host.add_child(UIFactory.label(t("Virus & threat scan", "病毒和威胁扫描"), 22, UIFactory.color("#202020")))
	page_host.add_child(UIFactory.label(t("Scan files and running programs for security threats.", "扫描文件和运行中的程序以查找安全威胁。"), 13, UIFactory.color("#666666")))
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UIFactory.flat(Color.WHITE, UIFactory.color("#d6d6d6"), 1, 22, 18))
	page_host.add_child(card)
	var card_content := VBoxContainer.new()
	card_content.alignment = BoxContainer.ALIGNMENT_CENTER
	card_content.add_theme_constant_override("separation", 14)
	card.add_child(card_content)
	card_content.add_child(make_icon("antivirus_good" if virus_protection_enabled else "antivirus_bad", 70))
	scan_status = UIFactory.label(t("No current threats", "当前没有威胁"), 18, UIFactory.color("#202020"))
	scan_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_content.add_child(scan_status)
	scan_progress = ProgressBar.new()
	scan_progress.min_value = 0
	scan_progress.max_value = 100
	scan_progress.value = 0
	scan_progress.custom_minimum_size = Vector2(330, 20)
	card_content.add_child(scan_progress)
	var scan_button := Button.new()
	scan_button.text = t("Quick scan", "快速扫描")
	UIFactory.style_win10_button(scan_button)
	scan_button.pressed.connect(start_scan)
	card_content.add_child(scan_button)
	scan_actions = VBoxContainer.new()
	scan_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	card_content.add_child(scan_actions)

func start_scan() -> void:
	if not scan_timer.is_stopped():
		return
	scan_progress.value = 0
	scan_status.text = t("Scanning files…", "正在扫描文件……")
	scan_timer.start()

func advance_scan() -> void:
	scan_progress.value += 4
	if scan_progress.value >= 100:
		scan_timer.stop()
		scan_status.text = t("Scan complete — no threats found", "扫描完成——未发现威胁")
		scan_completed.emit()

func show_threat_detected(threat_name: String) -> void:
	if not is_instance_valid(scan_status) or not is_instance_valid(scan_actions):
		return
	scan_status.text = t("Threat detected: ", "检测到威胁：") + threat_name
	scan_status.add_theme_color_override("font_color", UIFactory.color("#c42b1c"))
	for child in scan_actions.get_children():
		child.queue_free()
	var warning := UIFactory.label(t(
		"Super Security recommends removing this malicious file.",
		"Super Security 建议移除此恶意文件。"
	), 13, UIFactory.color("#c42b1c"))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scan_actions.add_child(warning)
	var clean_button := Button.new()
	clean_button.text = t("Remove threat", "移除威胁")
	UIFactory.style_win10_button(clean_button)
	clean_button.pressed.connect(func(): clean_requested.emit())
	scan_actions.add_child(clean_button)

func show_clean_result() -> void:
	if not is_instance_valid(scan_status):
		return
	scan_status.text = t("Threat removed. Your computer is protected.", "威胁已移除。你的计算机已受保护。")
	scan_status.add_theme_color_override("font_color", UIFactory.color("#16833b"))
	if is_instance_valid(scan_actions):
		for child in scan_actions.get_children():
			child.queue_free()

func show_protection_page() -> void:
	clear_page()
	page_host.add_child(UIFactory.label(t("Protection settings", "防护设置"), 22, UIFactory.color("#202020")))
	page_host.add_child(UIFactory.label(t("Manage the protections used by this computer.", "管理此计算机使用的防护功能。"), 13, UIFactory.color("#666666")))
	add_protection_row(
		t("Firewall", "防火墙"),
		t("Blocks unauthorized network connections.", "阻止未经授权的网络连接。"),
		firewall_enabled,
		func(enabled: bool): firewall_enabled = enabled; emit_protection_state()
	)
	add_protection_row(
		t("Virus protection", "病毒防护"),
		t("Monitors files and programs for malware.", "监控文件和程序中的恶意软件。"),
		virus_protection_enabled,
		func(enabled: bool): virus_protection_enabled = enabled; emit_protection_state()
	)

func add_protection_row(title: String, description: String, enabled: bool, callback: Callable) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIFactory.flat(Color.WHITE, UIFactory.color("#d6d6d6"), 1, 16, 12))
	page_host.add_child(card)
	var row := HBoxContainer.new()
	card.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(UIFactory.label(title, 16, UIFactory.color("#202020")))
	copy.add_child(UIFactory.label(description, 12, UIFactory.color("#666666")))
	row.add_child(copy)
	var toggle := CheckButton.new()
	toggle.text = t("On", "开")
	toggle.button_pressed = enabled
	toggle.toggled.connect(func(value: bool): toggle.text = t("On", "开") if value else t("Off", "关"); callback.call(value))
	row.add_child(toggle)

func emit_protection_state() -> void:
	update_overall_status()
	protection_changed.emit(firewall_enabled, virus_protection_enabled)

func update_overall_status() -> void:
	var status: Label = find_child("OverallStatus", true, false)
	if status == null:
		return
	var protected := firewall_enabled and virus_protection_enabled
	status.text = t("● Protected", "● 已保护") if protected else t("● Action needed", "● 需要操作")
	status.add_theme_color_override("font_color", UIFactory.color("#16833b") if protected else UIFactory.color("#c42b1c"))

func make_icon(name: String, size_px: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load("res://assets/icons/" + name + ".svg")
	icon.custom_minimum_size = Vector2(size_px, size_px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon
