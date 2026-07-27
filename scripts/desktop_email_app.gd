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
var read_mail_status: Dictionary:
	get: return host.read_mail_status
var current_folder := "inbox"

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

func open(folder := "") -> void:
	if not folder.is_empty():
		current_folder = folder
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
	var unread_count := 0
	var junk_count := 0
	for i in stage.get("emails", []).size():
		if deleted_mail.get(i, false):
			continue
		if reported.get(i, false):
			junk_count += 1
		elif not read_mail_status.get(i, false):
			unread_count += 1
	var inbox_button := sidebar_item("▣  " + t("Inbox", "收件箱") + "  %d" % unread_count, current_folder == "inbox")
	inbox_button.pressed.connect(open.bind("inbox"))
	side.add_child(inbox_button)
	var junk_button := sidebar_item("⚠  " + t("Junk Emails", "垃圾邮件") + "  %d" % junk_count, current_folder == "junk")
	junk_button.pressed.connect(open.bind("junk"))
	side.add_child(junk_button)
	side.add_child(sidebar_item("☆  " + t("Drafts", "草稿")))
	side.add_child(sidebar_item("➤  " + t("Sent", "已发送")))
	side.add_child(sidebar_item("♲  " + t("Deleted", "已删除")))
	workspace.add_child(side)
	var mail_view := VBoxContainer.new()
	mail_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mail_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var view_title := t("Junk Emails", "垃圾邮件") if current_folder == "junk" else t("Focused inbox", "重点收件箱")
	mail_view.add_child(dark_label(view_title, 16, UIFactory.color("#202020")))
	workspace.add_child(mail_view)
	var emails: Array = stage.get("emails", [])
	var visible_indices: Array[int] = []
	for i in emails.size():
		if deleted_mail.get(i, false):
			continue
		var is_junk: bool = reported.get(i, false)
		if (current_folder == "junk" and is_junk) or (current_folder == "inbox" and not is_junk):
			visible_indices.append(i)
	if visible_indices.is_empty():
		var empty_text := t(
			"No messages have been reported as junk.",
			"尚未有邮件被举报为垃圾邮件。"
		) if current_folder == "junk" else t(
			"You're all caught up\nThere is no mail to show.",
			"所有邮件都已处理\n没有可显示的邮件。"
		)
		var empty := dark_label(empty_text, 18, UIFactory.color("#64748b"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		mail_view.add_child(empty)
		return
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mail_view.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for i in visible_indices:
		var mail: Dictionary = emails[i]
		var row := Button.new()
		var read_marker := "○  " if read_mail_status.get(i, false) else "●  "
		row.text = read_marker + localized_mail_value(mail, "from") + "\n    " + localized_mail_value(mail, "subject")
		row.tooltip_text = t("Read", "已读") if read_mail_status.get(i, false) else t("Unread", "未读")
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
			var folder_path := t("Mailbox/Junk Emails", "邮箱/垃圾邮件") if current_folder == "junk" else t("Mailbox/Inbox", "邮箱/收件箱")
			current_context = {"scope":"mail", "name":localized_mail_value(mail, "subject"), "type":t("Email message", "电子邮件"), "path":folder_path, "deletable":true, "index":index, "mail":mail}
			show_context_menu(event.global_position)

func read_mail(index: int, mail: Dictionary) -> void:
	read_mail_status[index] = true
	if host.open_windows.has("email"):
		open()
	var root := create_window("mail_read", t("Message", "邮件") + " — " + localized_mail_value(mail, "subject"), Vector2(620, 390), false)
	root.add_child(dark_label(t("From: ", "发件人：") + localized_mail_value(mail, "from"), 14))
	root.add_child(dark_label(t("Subject: ", "主题：") + localized_mail_value(mail, "subject"), 16))
	var body := dark_label(localized_mail_value(mail, "body"), 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	if mail.has("action_url"):
		var address := dark_label(t("Link: ", "链接：") + mail.action_url, 12, UIFactory.color("#475569"))
		address.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(address)
		var action := Button.new()
		action.text = localized_mail_value(mail, "action_label")
		UIFactory.style_win10_button(action)
		action.pressed.connect(open_mail_link.bind(mail.action_url))
		root.add_child(action)
	var report := Button.new()
	var already_reported: bool = reported.get(index, false)
	report.text = t("Already in Junk Emails", "已移至垃圾邮件") if already_reported else t("Report as suspicious", "举报可疑邮件")
	report.disabled = already_reported
	UIFactory.style_win10_button(report)
	report.pressed.connect(report_mail.bind(index, mail))
	root.add_child(report)

func report_mail(index: int, mail: Dictionary) -> void:
	if mail.get("kind", "") in ["junk", "phishing"] or mail.get("spam", false):
		reported[index] = true
		host.close_window("mail_read")
		open("junk")
		report_mail_feedback(mail)
	else:
		warn(t("This appears to be a legitimate message.", "这似乎是一封正常邮件。"))

func localized_mail_value(mail: Dictionary, key: String) -> String:
	if host.state.language == "zh" and mail.has(key + "_zh"):
		return str(mail[key + "_zh"])
	return str(mail.get(key, ""))

func open_mail_link(url: String) -> void:
	host.open_browser(url)

func report_mail_feedback(mail: Dictionary) -> void:
	if mail.get("kind", "") == "phishing":
		warn(t("Reported. Good catch — this message uses a lookalike sender or unsafe request.", "已举报。发现得好——这封邮件使用了仿冒发件人或不安全的请求。"), false)
	else:
		warn(t("Reported as junk. Keep looking for the real business request.", "已标记为垃圾邮件。请继续寻找真实的业务请求。"), false)

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
