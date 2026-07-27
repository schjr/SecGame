class_name AntivirusApp
extends Control

signal protection_changed(firewall_enabled: bool, virus_protection_enabled: bool)
signal scan_completed
signal clean_requested
signal network_attacker_identified(ip: String)

var state: GameState
var firewall_enabled := true
var virus_protection_enabled := true
var page_host: VBoxContainer
var scan_progress: ProgressBar
var scan_status: Label
var scan_timer: Timer
var scan_actions: VBoxContainer
var stage_data: Dictionary
var network_feedback: Label
var selected_network_ip := ""

func setup(game_state: GameState, firewall: bool, virus_protection: bool, current_stage: Dictionary = {}) -> void:
	state = game_state
	firewall_enabled = firewall
	virus_protection_enabled = virus_protection
	stage_data = current_stage
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
	if stage_data.get("id", "") == "network":
		var firewall_nav := nav_button("≋  " + t("Firewall activity", "防火墙活动"))
		firewall_nav.pressed.connect(show_firewall_activity)
		navigation.add_child(firewall_nav)
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
	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	page_scroll.follow_focus = true
	content_margin.add_child(page_scroll)
	page_host = VBoxContainer.new()
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_host.add_theme_constant_override("separation", 12)
	page_scroll.add_child(page_host)
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

func show_firewall_activity() -> void:
	clear_page()
	page_host.add_child(UIFactory.label(t("Incoming connections", "传入连接"), 22, UIFactory.color("#202020")))
	var alert := UIFactory.label(t(
		"Network attack detected. Select the source IP whose behavior indicates an attack.",
		"检测到网络攻击。请选择行为表明正在发动攻击的来源 IP。"
	), 12, UIFactory.color("#c42b1c"))
	alert.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_host.add_child(alert)
	var header := HBoxContainer.new()
	for value in [t("Time", "时间"), t("Source IP", "来源 IP"), t("Port", "端口"), t("Activity", "活动")]:
		var label := UIFactory.label(value, 11, UIFactory.color("#555555"))
		label.custom_minimum_size.x = 78 if header.get_child_count() != 3 else 180
		header.add_child(label)
	page_host.add_child(header)
	var choices := ButtonGroup.new()
	for record in stage_data.get("network_connections", []):
		var row := HBoxContainer.new()
		var radio := CheckBox.new()
		radio.button_group = choices
		radio.custom_minimum_size.x = 22
		radio.toggled.connect(func(on: bool, ip: String = record.ip): if on: selected_network_ip = ip)
		row.add_child(radio)
		for value in [record.time, record.ip, record.port, record.get("event_zh" if state.language == "zh" else "event_en", "")]:
			var cell := UIFactory.label(str(value), 11, UIFactory.color("#282828"))
			cell.custom_minimum_size.x = 78 if row.get_child_count() != 4 else 180
			row.add_child(cell)
		page_host.add_child(row)
	var actions := HBoxContainer.new()
	var block := Button.new()
	block.text = t("Classify and block selected IP", "分类并阻止所选 IP")
	UIFactory.style_win10_button(block)
	block.pressed.connect(check_network_selection)
	actions.add_child(block)
	network_feedback = UIFactory.label("", 12)
	network_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(network_feedback)
	page_host.add_child(actions)

func check_network_selection() -> void:
	if selected_network_ip.is_empty():
		network_feedback.text = t("Select a connection first.", "请先选择一条连接。")
		network_feedback.add_theme_color_override("font_color", UIFactory.color("#a15c00"))
		return
	if selected_network_ip != str(stage_data.get("attacker_ip", "")):
		network_feedback.text = t(
			"That source shows routine traffic. Compare repeated failures, probes, and port sweeps.",
			"该来源显示的是常规流量。请比较重复失败、探测和端口扫描行为。"
		)
		network_feedback.add_theme_color_override("font_color", UIFactory.color("#c42b1c"))
		return
	state.session_flags["network_investigation_complete"] = true
	network_feedback.text = t("Attacker classified and blocked. Report the IP on the mission note.", "攻击者已分类并阻止。请在任务便笺中报告该 IP。")
	network_feedback.add_theme_color_override("font_color", UIFactory.color("#16833b"))
	network_attacker_identified.emit(selected_network_ip)

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
