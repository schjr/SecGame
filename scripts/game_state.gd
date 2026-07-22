class_name GameState
extends RefCounted

const SAVE_PATH := "user://settings.cfg"
const STAGES := [
	{"id":"malware", "title_en":"Malware Cleanup", "title_zh":"恶意软件清理", "desc_en":"Inspect suspicious files and remove the infected one.", "desc_zh":"检查可疑文件并移除被感染的文件。", "emails":[]},
	{"id":"spam", "title_en":"Spam Recognition", "title_zh":"垃圾邮件识别", "desc_en":"Review the inbox and report every suspicious message.", "desc_zh":"检查收件箱并举报所有可疑邮件。", "emails":[
		{"from":"IT Support <support@company-secure.example>", "subject":"Scheduled password maintenance", "body":"No action is required. The maintenance window begins tonight.", "spam":false},
		{"from":"Prize Center <winner@free-gifts.example>", "subject":"YOU WON! Claim in 10 minutes", "body":"Click the link and enter your banking details to receive your prize.", "spam":true},
		{"from":"Alex Chen <alex.chen@company.example>", "subject":"Team meeting notes", "body":"Here are the notes from today's security review. Thanks!", "spam":false},
		{"from":"Account Team <verify@micros0ft-login.example>", "subject":"Urgent: mailbox will be deleted", "body":"Your mailbox is over quota. Sign in immediately using the attached link.", "spam":true}
	]},
	{"id":"passwords", "title_en":"Password Safety", "title_zh":"密码安全", "desc_en":"Learn what makes a password resistant to guessing.", "desc_zh":"了解如何创建难以猜测的密码。", "emails":[]}
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
