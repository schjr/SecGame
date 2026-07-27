class_name DesktopEmailApp
extends RefCounted

var host
var stage: Dictionary:
	get: return host.stage
var deleted_mail: Dictionary:
	get: return host.deleted_mail
var current_context: Dictionary:
	get: return host.current_context
	set(value): host.current_context = value
var reported: Dictionary:
	get: return host.reported

func _init(desktop_host) -> void:
	host = desktop_host

func t(en: String, zh: String) -> String:
	return host.t(en, zh)

func create_window(id: String, title: String, window_size := Vector2(650, 365), track_process := true) -> VBoxContainer:
	return host.create_window(id, title, window_size, track_process)

func make_app_toolbar() -> HBoxContainer:
	return host.make_app_toolbar()

func make_sidebar(width := 135.0) -> VBoxContainer:
	return host.make_sidebar(width)

func sidebar_item(text: String, selected := false) -> Button:
	return host.sidebar_item(text, selected)

func dark_label(text: String, font_size := 16, color := UIFactory.color("#172033")) -> Label:
	return host.dark_label(text, font_size, color)

func show_context_menu(pos: Vector2) -> void:
	host.show_context_menu(pos)

func warn(message: String, play_error_sound := true) -> void:
	host.warn(message, play_error_sound)

func open() -> void:
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
		host.stage_completed.emit()

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
