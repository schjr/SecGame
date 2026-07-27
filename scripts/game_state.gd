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
		"note_en":"Oh dear, this computer is running terribly slowly!\n\nPlease find out what is using so many system resources and fix the problem.",
		"note_zh":"糟糕，这台电脑运行得太慢了！\n\n请找出是什么占用了大量系统资源，并解决这个问题。",
		"emails":[]
	},
	{
		"id":"antivirus",
		"title_en":"Endpoint Protection II: Virus Protection",
		"title_zh":"终端防护 II：病毒防护",
		"desc_en":"Repair a tampered antivirus installation and remove a persistent virus.",
		"desc_zh":"修复被病毒破坏的防病毒软件，并清除顽固病毒。",
		"note_en":"Oh no, this computer has become extremely slow again!\n\nI tried opening Super Security, but it just won't open. I don't know what happened or what else to try.\n\nCould you please take a look and help me fix it?",
		"note_zh":"糟糕，这台电脑又变得特别慢了！\n\n我试着打开 Super Security，可它怎么也打不开。我不知道发生了什么，也不知道还能怎么办。\n\n能请你帮我看看，把电脑修好吗？",
		"antivirus_present":true,
		"firewall_enabled":false,
		"virus_protection_enabled":false,
		"emails":[]
	},
	{
		"id":"spam",
		"title_en":"Spam Recognition",
		"title_zh":"垃圾邮件识别",
		"desc_en":"Find the one legitimate business request without falling for spam or phishing.",
		"desc_zh":"从垃圾邮件和钓鱼邮件中找出唯一真实的业务请求。",
		"note_en":"Please take care of the Brightline Office Supply invoice today.\n\nOur Accounts Payable staff use email addresses ending in @northstar.example. Find Maya Ortiz's message, open the payment portal she provides, and submit purchase order AP-2048 with invoice total $6,480.00.\n\nThanks for handling this.",
		"note_zh":"请今天处理 Brightline Office Supply 的发票。\n\n我们应付账款部门员工使用以 @northstar.example 结尾的邮箱地址。请找到 Maya Ortiz 的邮件，打开她提供的付款门户，并提交采购订单号 AP-2048 和发票总额 $6,480.00。\n\n谢谢你处理此事。",
		"task_po":"AP-2048",
		"task_total":"$6,480.00",
		"legitimate_portal":"pay.northstar.example",
		"emails":[
			{"from":"MegaOffice Deals <offers@megaoffice.example>", "from_zh":"MegaOffice 优惠 <offers@megaoffice.example>", "subject":"Desks, chairs and more — 70% off today", "subject_zh":"办公桌椅等今日低至三折", "body":"Refresh your workspace during our summer clearance. Browse hundreds of office products. This is a promotional message; unsubscribe any time.", "body_zh":"夏季清仓，焕新办公空间。数百种办公用品可供选购。这是一封促销邮件，可随时退订。", "kind":"junk"},
			{"from":"Northstar AP Alerts <payments@northstar-payments.example>", "from_zh":"Northstar 应付账款提醒 <payments@northstar-payments.example>", "subject":"Action required: approve Brightline invoice BL-7781", "subject_zh":"待办：审批 Brightline 发票 BL-7781", "body":"Your approval is overdue. Use the secure payment page below within 30 minutes or the supplier account will be frozen. Enter the PO total and your company password to release payment.\n\nSecurity notice: do not contact Accounts Payable about this automated alert.", "body_zh":"你的审批已经逾期。请在 30 分钟内使用下方安全付款页面，否则供应商账户将被冻结。请输入采购订单总额和公司密码以放款。\n\n安全提示：请勿就此自动提醒联系应付账款部门。", "kind":"phishing", "action_label":"Review urgent invoice", "action_label_zh":"紧急审核发票", "action_url":"https://pay.northstar-payments.example"},
			{"from":"CloudPro Newsletter <news@cloudpro.example>", "from_zh":"CloudPro 简报 <news@cloudpro.example>", "subject":"Five ways to organize your remote team", "subject_zh":"组织远程团队的五种方法", "body":"Read this month's productivity tips, customer stories and product announcements.", "body_zh":"阅读本月生产力技巧、客户故事和产品公告。", "kind":"junk"},
			{"from":"Maya Ortiz <maya.ortiz@northstarr.example>", "from_zh":"Maya Ortiz <maya.ortiz@northstarr.example>", "subject":"RE: Action required: approve Brightline invoice", "subject_zh":"回复：待办：审批 Brightline 发票", "body":"I had to move the invoice to our new verification site. Please approve it today. The form may ask for your sign-in details because this is the first time you have used the new system.\n\nSent from my phone", "body_zh":"我不得不把这张发票移到新的验证网站。请今天完成审批。由于你第一次使用新系统，表单可能会要求登录信息。\n\n发自我的手机", "kind":"phishing", "action_label":"Open new verification site", "action_label_zh":"打开新验证网站", "action_url":"https://pay.northstarr.example"},
			{"from":"TravelFlash <deals@travelflash.example>", "from_zh":"TravelFlash 特惠 <deals@travelflash.example>", "subject":"Weekend fares from $39", "subject_zh":"周末机票低至 39 美元", "body":"Limited promotional fares are available on selected routes. Terms and blackout dates apply.", "body_zh":"指定航线提供限时促销票价，适用条款及限制日期。", "kind":"junk"},
			{"from":"Maya Ortiz, Accounts Payable <maya.ortiz@northstar.example>", "from_zh":"应付账款部 Maya Ortiz <maya.ortiz@northstar.example>", "subject":"Action required: approve Brightline invoice BL-7781", "subject_zh":"待办：审批 Brightline 发票 BL-7781", "body":"Hello,\n\nBrightline Office Supply's invoice BL-7781 has been matched to purchase order AP-2048. Please open the Northstar Payment Portal and confirm the PO number and invoice total shown in your mission note.\n\nThe portal address is pay.northstar.example. No password or banking information is required.\n\nMaya Ortiz\nAccounts Payable • ext. 241", "body_zh":"你好：\n\nBrightline Office Supply 的发票 BL-7781 已与采购订单 AP-2048 匹配。请打开 Northstar 付款门户，并填写任务便笺中的采购订单号和发票总额。\n\n门户地址为 pay.northstar.example，不会要求密码或银行信息。\n\nMaya Ortiz\n应付账款部 • 分机 241", "kind":"legitimate", "action_label":"Open Northstar Payment Portal", "action_label_zh":"打开 Northstar 付款门户", "action_url":"https://pay.northstar.example"},
			{"from":"Northstar Finance <invoice-review@northstar.example.security-check.example>", "from_zh":"Northstar 财务部 <invoice-review@northstar.example.security-check.example>", "subject":"Invoice BL-7781 failed security validation", "subject_zh":"发票 BL-7781 安全验证失败", "body":"We detected a validation error on invoice BL-7781. Re-submit the approval immediately to avoid a late fee. For verification, the secure form requires the PO details and your mailbox password.", "body_zh":"我们发现发票 BL-7781 验证出错。请立即重新提交审批以避免滞纳金。为验证身份，安全表单需要采购订单信息和你的邮箱密码。", "kind":"phishing", "action_label":"Fix validation error", "action_label_zh":"修复验证错误", "action_url":"https://northstar.example.security-check.example"},
			{"from":"Global Conference Weekly <digest@events-weekly.example>", "from_zh":"全球会议周刊 <digest@events-weekly.example>", "subject":"12 leadership conferences you cannot miss", "subject_zh":"不容错过的 12 场领导力会议", "body":"This week's sponsored events digest features conferences in Singapore, Berlin and Toronto.", "body_zh":"本周赞助活动简报为你推荐新加坡、柏林和多伦多的会议。", "kind":"junk"},
			{"from":"Procurement Desk <procurement@northstar-internal.example>", "from_zh":"采购部 <procurement@northstar-internal.example>", "subject":"Updated supplier approval workflow — sign in now", "subject_zh":"供应商审批流程更新——立即登录", "body":"A new approval workflow is mandatory for invoice BL-7781. Complete migration before processing the invoice. Failure to comply may result in suspension.\n\nNote: this external preview system is not yet listed in the employee directory.", "body_zh":"发票 BL-7781 必须使用新的审批流程。请在处理发票前完成迁移，否则账户可能被停用。\n\n注意：此外部预览系统尚未列入员工目录。", "kind":"phishing", "action_label":"Migrate and approve", "action_label_zh":"迁移并审批", "action_url":"https://northstar-internal.example"},
			{"from":"Lucky Rewards <winner@lucky-rewards.example>", "from_zh":"幸运奖励 <winner@lucky-rewards.example>", "subject":"Congratulations! Your mystery box is waiting", "subject_zh":"恭喜！你的神秘礼盒正在等待领取", "body":"You were randomly selected for a premium reward. Pay a small shipping charge to claim it before midnight.", "body_zh":"你被随机选中获得高级奖品。午夜前支付少量运费即可领取。", "kind":"junk"}
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
		"desc_en":"Complete a district analysis without exposing sensitive student records.",
		"desc_zh":"在不泄露学生敏感记录的前提下完成地区数据分析。",
		"note_en":"The Aurora District needs a learning-support summary from 1,200 synthetic student records.\n\nUse SillyAgent's guided workflow. Keep personal data on this computer, minimize what the system sees, and release only safe aggregate findings.",
		"note_zh":"极光区需要根据 1,200 条合成学生记录制作学习支持汇总。\n\n请使用智慧助手的引导流程。将个人数据留在本机，尽量减少系统接触的数据，并且只发布安全的汇总结果。",
		"emails":[]
	}
]

var language := "en"
var sfx_volume := 0.8
var music_volume := 0.55
var completed: Dictionary = {}

func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		language = config.get_value("settings", "language", "en")
		var legacy_volume: float = config.get_value("settings", "volume", 0.8)
		var legacy_music_enabled: bool = config.get_value("settings", "music_enabled", true)
		sfx_volume = config.get_value("settings", "sfx_volume", legacy_volume)
		music_volume = config.get_value(
			"settings",
			"music_volume",
			0.55 if legacy_music_enabled else 0.0
		)
		completed = config.get_value("progress", "completed", {})
	apply_audio_volumes()

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "language", language)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("progress", "completed", completed)
	config.save(SAVE_PATH)

func apply_audio_volumes() -> void:
	set_bus_linear_volume("SFX", sfx_volume)
	set_bus_linear_volume("Music", music_volume)

func set_bus_linear_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(value, 0.0001, 1.0)))
		AudioServer.set_bus_mute(bus_index, value <= 0.0)

func tr_text(en: String, zh: String) -> String:
	return zh if language == "zh" else en

func stage_title(stage: Dictionary) -> String:
	return stage["title_zh"] if language == "zh" else stage["title_en"]

func stage_desc(stage: Dictionary) -> String:
	return stage["desc_zh"] if language == "zh" else stage["desc_en"]
