class_name AISecurityApp
extends RefCounted

var host
var step := 0
var conversation: VBoxContainer
var choice_box: VBoxContainer
var history: Array[Dictionary] = []

func _init(desktop_host) -> void:
	host = desktop_host

func open() -> void:
	var root: VBoxContainer = host.create_window("agent", "Codex — " + host.t("Student Data Review", "学生数据审查"), Vector2(760, 430))
	var workspace := HBoxContainer.new()
	var codex_theme := Theme.new()
	codex_theme.default_font = host.CJK_UI_FONT
	workspace.theme = codex_theme
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 0)
	root.add_child(workspace)
	var sidebar_panel := PanelContainer.new()
	sidebar_panel.custom_minimum_size.x = 176
	sidebar_panel.add_theme_stylebox_override("panel", UIFactory.flat(UIFactory.color("#171717"), UIFactory.color("#2e2e2e"), 1, 12, 12))
	workspace.add_child(sidebar_panel)
	var sidebar := VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 10)
	sidebar_panel.add_child(sidebar)
	var brand := HBoxContainer.new()
	brand.add_child(host.dark_label("◆", 18, UIFactory.color("#f4f4f4")))
	brand.add_child(host.dark_label("Codex", 17, UIFactory.color("#f4f4f4")))
	sidebar.add_child(brand)
	var new_task := Button.new()
	new_task.text = "＋  " + host.t("New task", "新任务")
	new_task.alignment = HORIZONTAL_ALIGNMENT_LEFT
	new_task.add_theme_color_override("font_color", UIFactory.color("#e8e8e8"))
	new_task.add_theme_stylebox_override("normal", UIFactory.flat(UIFactory.color("#262626"), UIFactory.color("#3b3b3b"), 1, 8, 5))
	new_task.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#333333"), UIFactory.color("#555555"), 1, 8, 5))
	new_task.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sidebar.add_child(new_task)
	sidebar.add_child(host.dark_label(host.t("TASKS", "任务"), 10, UIFactory.color("#8d8d8d")))
	var current_task := Button.new()
	current_task.text = host.t("Student data review", "学生数据审查")
	current_task.alignment = HORIZONTAL_ALIGNMENT_LEFT
	current_task.add_theme_color_override("font_color", Color.WHITE)
	current_task.add_theme_stylebox_override("normal", UIFactory.flat(UIFactory.color("#303030"), Color.TRANSPARENT, 0, 8, 5))
	current_task.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sidebar.add_child(current_task)
	var side_spacer := Control.new()
	side_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(side_spacer)
	sidebar.add_child(host.dark_label("▣  " + host.t("Local workspace", "本地工作区"), 11, UIFactory.color("#b5b5b5")))
	sidebar.add_child(host.dark_label("●  " + host.t("Offline · no API", "离线 · 无 API"), 11, UIFactory.color("#72c391")))
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 7)
	workspace.add_child(main)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var title: Label = host.dark_label(host.t("Student data review", "学生数据审查"), 16, UIFactory.color("#202020"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(host.dark_label(host.t("Step %d of 4" % mini(step + 1, 4), "第 %d / 4 步" % mini(step + 1, 4)), 11, UIFactory.color("#6b6b6b")))
	main.add_child(header)
	main.add_child(HSeparator.new())
	var chat_scroll := ScrollContainer.new()
	chat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(chat_scroll)
	conversation = VBoxContainer.new()
	conversation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conversation.add_theme_constant_override("separation", 10)
	chat_scroll.add_child(conversation)
	var composer := PanelContainer.new()
	composer.add_theme_stylebox_override("panel", UIFactory.flat(Color.WHITE, UIFactory.color("#bdbdbd"), 1, 10, 8))
	main.add_child(composer)
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 5)
	composer.add_child(choice_box)
	render_step()

func render_step() -> void:
	for child in conversation.get_children():
		child.queue_free()
	for child in choice_box.get_children():
		child.queue_free()
	var steps_en := [
		["1 • Understand the structure", "What should the assistant inspect first?", ["Open the one-row schema example", "Open the complete 1,200-record roster", "Email the roster to a remote model"], 0],
		["2 • Prepare the data", "How should identifiers be handled before analysis?", ["Remove names, IDs, addresses, birth dates and contacts locally", "Keep every field for maximum accuracy", "Replace names only; keep addresses and contacts"], 0],
		["3 • Run the analysis", "Where should the learning-support summary be computed?", ["Use the local offline analysis engine on minimized fields", "Upload the full workbook to a public chatbot", "Paste selected student rows into an online prompt"], 0],
		["4 • Share the result", "What may leave the secure computer?", ["Aggregate counts with small groups suppressed", "A list of students needing support", "The original workbook plus the report"], 0]
	]
	var steps_zh := [
		["1 • 了解结构", "助手首先应该查看什么？", ["打开单行数据结构示例", "打开完整的 1,200 条学生名册", "将名册发给远程模型"], 0],
		["2 • 准备数据", "分析前应如何处理标识信息？", ["在本地删除姓名、ID、地址、生日和联系方式", "保留所有字段以获得最高准确度", "只替换姓名，保留地址和联系方式"], 0],
		["3 • 执行分析", "学习支持汇总应在哪里计算？", ["使用本地离线引擎分析最少字段", "将完整工作簿上传到公共聊天机器人", "把部分学生记录粘贴到在线提示中"], 0],
		["4 • 分享结果", "哪些内容可以离开安全电脑？", ["仅分享汇总计数，并隐藏人数过少的群组", "需要帮助的学生名单", "原始工作簿和分析报告"], 0]
	]
	if history.is_empty():
		history.append({"role":"codex", "text":host.t(
			"I can help complete the Aurora District analysis without sending student records to a remote model. I’ll ask for one decision at each step.",
			"我可以协助完成极光区分析，并且不会把学生记录发送给远程模型。我会在每个步骤询问一个决定。"
		)})
	for message in history:
		add_message(message.role, message.text)
	if step >= 4:
		add_message("codex", host.t(
			"✓ Analysis complete. District-level support trends were produced locally. No student record left this computer.",
			"✓ 分析完成。已在本地生成地区级学习支持趋势，没有任何学生记录离开本机。"
		))
		choice_box.add_child(host.dark_label(host.t("Task completed", "任务已完成"), 12, UIFactory.color("#247244")))
		return
	var current: Array = (steps_zh if host.state.language == "zh" else steps_en)[step]
	add_message("codex", current[0] + "\n" + current[1])
	var input := Button.new()
	input.text = host.t("Choose an action…", "选择操作……")
	input.alignment = HORIZONTAL_ALIGNMENT_LEFT
	input.custom_minimum_size.y = 34
	input.add_theme_color_override("font_color", UIFactory.color("#767676"))
	input.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	input.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#f5f5f5"), Color.TRANSPARENT, 0, 5, 3))
	input.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	input.pressed.connect(show_choices.bind(input, current))
	choice_box.add_child(input)

func add_message(role: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if role == "user":
		var push := Control.new()
		push.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(push)
	var avatar: Label = host.dark_label("◆" if role == "codex" else "You", 11, UIFactory.color("#ffffff") if role == "codex" else UIFactory.color("#343434"))
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.custom_minimum_size = Vector2(30, 30)
	avatar.add_theme_stylebox_override("normal", UIFactory.flat(UIFactory.color("#1f1f1f") if role == "codex" else UIFactory.color("#e8e8e8"), Color.TRANSPARENT, 0, 5, 4))
	row.add_child(avatar)
	var bubble := Label.new()
	bubble.text = text
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_theme_font_size_override("font_size", 13)
	bubble.add_theme_color_override("font_color", UIFactory.color("#262626"))
	bubble.custom_minimum_size.x = 310 if role == "codex" else 250
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL if role == "codex" else Control.SIZE_SHRINK_END
	bubble.add_theme_stylebox_override("normal", UIFactory.flat(Color.TRANSPARENT if role == "codex" else UIFactory.color("#eeeeee"), Color.TRANSPARENT, 0, 8, 6))
	row.add_child(bubble)
	conversation.add_child(row)

func show_choices(input: Button, current: Array) -> void:
	input.queue_free()
	for index in current[2].size():
		var choice := Button.new()
		choice.text = current[2][index]
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.custom_minimum_size.y = 34
		choice.add_theme_font_size_override("font_size", 12)
		choice.add_theme_color_override("font_color", UIFactory.color("#262626"))
		choice.add_theme_stylebox_override("normal", UIFactory.flat(Color.WHITE, UIFactory.color("#dedede"), 1, 8, 4))
		choice.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#f0f0f0"), UIFactory.color("#a8a8a8"), 1, 8, 4))
		choice.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		choice.pressed.connect(select_choice.bind(index, current[3], current[2][index], current[0] + "\n" + current[1]))
		choice_box.add_child(choice)

func select_choice(index: int, correct_index: int, choice_text: String, question_text: String) -> void:
	history.append({"role":"codex", "text":question_text})
	history.append({"role":"user", "text":choice_text})
	if index != correct_index:
		host.stage_failed.emit(host.t("Unsafe decision: sensitive student data could be exposed. The project has been stopped.", "不安全的决定：学生敏感数据可能泄露。项目已停止。"))
		return
	history.append({"role":"codex", "text":host.t(
		"Good choice. This keeps the workflow private and limits unnecessary access to personal data.",
		"选择正确。这样可以保持流程私密，并限制对个人数据的不必要访问。"
	)})
	step += 1
	if step >= 4:
		render_step()
		host.stage_completed.emit()
	else:
		open()
