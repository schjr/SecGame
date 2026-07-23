class_name GameState
extends RefCounted

const SAVE_PATH := "user://settings.cfg"
const STAGES := [
	{
		"id":"malware",
		"title_en":"Endpoint Protection I: Malicious Software",
		"title_zh":"终端防护 I：恶意软件",
		"desc_en":"Find and remove the malware consuming this computer's resources.",
		"desc_zh":"找到并移除占用此计算机资源的恶意软件。",
		"emails":[]
	},
	{
		"id":"antivirus",
		"title_en":"Endpoint Protection II: Virus Protection",
		"title_zh":"终端防护 II：病毒防护",
		"desc_en":"Stage content will be defined later.",
		"desc_zh":"关卡内容将在之后定义。",
		"emails":[]
	},
	{
		"id":"spam",
		"title_en":"Spam Recognition",
		"title_zh":"垃圾邮件识别",
		"desc_en":"Stage content will be defined later.",
		"desc_zh":"关卡内容将在之后定义。",
		"emails":[
		{"from":"IT Support <support@company-secure.example>", "subject":"Scheduled password maintenance", "body":"No action is required. The maintenance window begins tonight.", "spam":false},
		{"from":"Prize Center <winner@free-gifts.example>", "subject":"YOU WON! Claim in 10 minutes", "body":"Click the link and enter your banking details to receive your prize.", "spam":true},
		{"from":"Alex Chen <alex.chen@company.example>", "subject":"Team meeting notes", "body":"Here are the notes from today's security review. Thanks!", "spam":false},
		{"from":"Account Team <verify@micros0ft-login.example>", "subject":"Urgent: mailbox will be deleted", "body":"Your mailbox is over quota. Sign in immediately using the attached link.", "spam":true}
		]
	},
	{
		"id":"network",
		"title_en":"Network Protection",
		"title_zh":"网络防护",
		"desc_en":"Stage content will be defined later.",
		"desc_zh":"关卡内容将在之后定义。",
		"emails":[]
	},
	{
		"id":"ai_security",
		"title_en":"AI Security",
		"title_zh":"人工智能安全",
		"desc_en":"Stage content will be defined later.",
		"desc_zh":"关卡内容将在之后定义。",
		"emails":[]
	}
]

var language := "en"
var volume := 0.8
var completed: Dictionary = {}

func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		language = config.get_value("settings", "language", "en")
		volume = config.get_value("settings", "volume", 0.8)
		completed = config.get_value("progress", "completed", {})
	apply_volume()

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "language", language)
	config.set_value("settings", "volume", volume)
	config.set_value("progress", "completed", completed)
	config.save(SAVE_PATH)

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

func tr_text(en: String, zh: String) -> String:
	return zh if language == "zh" else en

func stage_title(stage: Dictionary) -> String:
	return stage["title_zh"] if language == "zh" else stage["title_en"]

func stage_desc(stage: Dictionary) -> String:
	return stage["desc_zh"] if language == "zh" else stage["desc_en"]
