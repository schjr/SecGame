class_name BrowserPages
extends RefCounted

var host

func _init(desktop_host) -> void:
	host = desktop_host

func clear(content: VBoxContainer) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func add_header(content: VBoxContainer, brand: String, links: Array[String]) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 32
	var brand_label: Label = host.dark_label(brand, 16, UIFactory.color("#172033"))
	brand_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand_label)
	for link in links:
		var link_button := Button.new()
		link_button.text = link
		link_button.add_theme_font_size_override("font_size", 12)
		link_button.add_theme_color_override("font_color", UIFactory.color("#334155"))
		link_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		link_button.add_theme_stylebox_override("hover", UIFactory.flat(UIFactory.color("#e5f1fb"), Color.TRANSPARENT, 0, 5, 2))
		link_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		header.add_child(link_button)
	content.add_child(header)
	content.add_child(HSeparator.new())

func render_new_tab(content: VBoxContainer) -> void:
	clear(content)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var copy := VBoxContainer.new()
	var title: Label = host.dark_label("SuperBrowser", 23, UIFactory.color("#0078d7"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(title)
	var hint: Label = host.dark_label(host.t("Search the web or enter an address", "搜索网页或输入网址"), 14, UIFactory.color("#64748b"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(hint)
	center.add_child(copy)
	content.add_child(center)

func render_super_secure(content: VBoxContainer) -> void:
	clear(content)
	add_header(content, "◆  Super Secure", [host.t("Products", "产品"), host.t("Support", "支持"), host.t("About", "关于")])
	var hero := PanelContainer.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.add_theme_stylebox_override("panel", UIFactory.flat(UIFactory.color("#e8f3fb"), UIFactory.color("#b7d7ee"), 1, 18, 14))
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 16)
	hero.add_child(hero_row)
	hero_row.add_child(host.app_icon_rect("antivirus_good", 62))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(host.dark_label("Super Security", 22, UIFactory.color("#0b3a60")))
	var slogan: Label = host.dark_label(host.t(
		"Simple, dependable protection for your digital life.",
		"为你的数字生活提供简单、可靠的保护。"
	), 14, UIFactory.color("#334155"))
	slogan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(slogan)
	var download := Button.new()
	download.name = "VendorDownload"
	download.text = host.t("Download for this PC", "下载到此电脑")
	download.custom_minimum_size.x = 205
	UIFactory.style_win10_button(download)
	download.pressed.connect(host.download_antivirus_installer)
	copy.add_child(download)
	if host.stage.id == "antivirus":
		var recovery_note: Label = host.dark_label(host.t(
			"Already installed but unable to open? Use our portable Emergency Kit to repair a compromised installation.",
			"已经安装但无法打开？请使用便携式急救箱修复被破坏的安装。"
		), 12, UIFactory.color("#475569"))
		recovery_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(recovery_note)
		var emergency_download := Button.new()
		emergency_download.name = "EmergencyKitDownload"
		emergency_download.text = host.t(
			"Download Emergency Kit (.zip)",
			"下载急救箱（.zip）"
		)
		emergency_download.custom_minimum_size.x = 205
		UIFactory.style_win10_button(emergency_download)
		emergency_download.pressed.connect(host.download_emergency_kit)
		copy.add_child(emergency_download)
	hero_row.add_child(copy)
	content.add_child(hero)
	var features := HBoxContainer.new()
	features.add_theme_constant_override("separation", 8)
	for feature in [
		host.t("✓ Malware scanning", "✓ 恶意软件扫描"),
		host.t("✓ Virus protection", "✓ 病毒防护"),
		host.t("✓ Network firewall", "✓ 网络防火墙")
	]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UIFactory.flat(Color.WHITE, UIFactory.color("#d6d6d6"), 1, 8, 7))
		var label: Label = host.dark_label(feature, 12, UIFactory.color("#334155"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(label)
		features.add_child(card)
	content.add_child(features)
	var footer: Label = host.dark_label(host.t(
		"Super Secure Software  •  Privacy  •  Terms",
		"Super Secure 软件  •  隐私  •  条款"
	), 10, UIFactory.color("#718096"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(footer)

func render_news(content: VBoxContainer) -> void:
	clear(content)
	add_header(content, host.t("Daily News", "每日新闻"), [host.t("World", "国际"), host.t("Technology", "科技"), host.t("Local", "本地")])
	content.add_child(host.dark_label(host.t("Today's top stories", "今日要闻"), 21, UIFactory.color("#202020")))
	for headline in [
		host.t("Technology teams announce new security initiatives", "科技团队公布新的安全计划"),
		host.t("Community organizations expand digital education", "社区组织扩大数字教育活动"),
		host.t("Researchers publish the week's science briefing", "研究人员发布本周科学简报")
	]:
		var story := PanelContainer.new()
		story.add_theme_stylebox_override("panel", UIFactory.flat(UIFactory.color("#f8fafc"), UIFactory.color("#d6d6d6"), 1, 10, 7))
		story.add_child(host.dark_label(headline, 13, UIFactory.color("#202020")))
		content.add_child(story)

func render_learning(content: VBoxContainer) -> void:
	clear(content)
	add_header(content, host.t("Learning Portal", "学习中心"), [host.t("Courses", "课程"), host.t("Library", "资料库"), host.t("Progress", "进度")])
	content.add_child(host.dark_label(host.t("Security learning center", "安全学习中心"), 21, UIFactory.color("#202020")))
	content.add_child(host.dark_label(host.t(
		"Browse interactive lessons and practical security exercises.",
		"浏览互动课程和实用安全练习。"
	), 14, UIFactory.color("#64748b")))
	for course in [host.t("Endpoint fundamentals", "终端基础"), host.t("Safer communication", "安全通信"), host.t("Network awareness", "网络意识")]:
		content.add_child(host.sidebar_item("▤  " + course))

func render_search_home(content: VBoxContainer) -> void:
	clear(content)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title: Label = host.dark_label("SuperSearch", 28, UIFactory.color("#0078d7"))
	center.add_child(title)
	content.add_child(center)

func render_search_results(content: VBoxContainer, query: String) -> void:
	clear(content)
	add_header(content, "SuperSearch", [host.t("Web", "网页"), host.t("Images", "图片"), host.t("News", "新闻")])
	content.add_child(host.dark_label(host.t("Search results for: ", "搜索结果：") + query, 17, UIFactory.color("#202020")))
	content.add_child(host.dark_label(host.t(
		"No indexed results are available in this training browser.",
		"训练浏览器中没有可用的索引结果。"
	), 13, UIFactory.color("#64748b")))

func render_unavailable(content: VBoxContainer, address: String) -> void:
	clear(content)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var message: Label = host.dark_label(host.t(
		"This simulated website is unavailable.",
		"此模拟网站不可用。"
	) + "\n" + address, 16, UIFactory.color("#64748b"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(message)
	content.add_child(center)
