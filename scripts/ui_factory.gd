class_name UIFactory
extends RefCounted

static func color(hex: String) -> Color:
	return Color(hex)

static func panel(bg: Color, radius := 14, border := Color.TRANSPARENT, width := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = width
	s.border_width_top = width
	s.border_width_right = width
	s.border_width_bottom = width
	s.border_color = border
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s

static func button_style(bg: Color, radius := 10) -> StyleBoxFlat:
	return panel(bg, radius)

static func style_button(button: Button, accent := false) -> void:
	button.custom_minimum_size = Vector2(220, 52)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var base := color("#2563eb") if accent else color("#24324a")
	button.add_theme_stylebox_override("normal", button_style(base))
	button.add_theme_stylebox_override("hover", button_style(base.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", button_style(base.darkened(0.12)))
	button.add_theme_stylebox_override("focus", button_style(base.lightened(0.08)))

static func accent() -> Color:
	return color("#0078d7")

static func flat(bg: Color, border := Color.TRANSPARENT, width := 0, pad_x := 0, pad_y := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = width
	s.border_width_top = width
	s.border_width_right = width
	s.border_width_bottom = width
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	return s

static func win10_window() -> StyleBoxFlat:
	var s := flat(Color.WHITE, accent(), 1, 1, 1)
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 12
	return s

static func style_win10_button(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", color("#1a1a1a"))
	b.add_theme_color_override("font_hover_color", color("#1a1a1a"))
	b.add_theme_color_override("font_pressed_color", color("#1a1a1a"))
	b.add_theme_color_override("font_focus_color", color("#1a1a1a"))
	var normal := flat(color("#e1e1e1"), color("#adadad"), 1, 12, 5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", flat(color("#e5f1fb"), color("#0078d7"), 1, 12, 5))
	b.add_theme_stylebox_override("pressed", flat(color("#cce4f7"), color("#005499"), 1, 12, 5))
	b.add_theme_stylebox_override("focus", normal)

static func style_win10_lineedit(le: LineEdit) -> void:
	le.add_theme_font_size_override("font_size", 13)
	le.add_theme_color_override("font_color", color("#1a1a1a"))
	le.add_theme_color_override("font_placeholder_color", color("#757575"))
	le.add_theme_color_override("caret_color", color("#1a1a1a"))
	var normal := flat(Color.WHITE, color("#7a7a7a"), 1, 6, 3)
	le.add_theme_stylebox_override("normal", normal)
	le.add_theme_stylebox_override("focus", flat(Color.WHITE, accent(), 1, 6, 3))
	le.add_theme_stylebox_override("read_only", normal)

static func style_win10_textedit(te: TextEdit) -> void:
	te.add_theme_font_size_override("font_size", 13)
	te.add_theme_color_override("font_color", color("#1a1a1a"))
	te.add_theme_color_override("font_placeholder_color", color("#757575"))
	var normal := flat(Color.WHITE, color("#7a7a7a"), 1, 6, 4)
	te.add_theme_stylebox_override("normal", normal)
	te.add_theme_stylebox_override("focus", flat(Color.WHITE, accent(), 1, 6, 4))
	te.add_theme_stylebox_override("read_only", normal)

static func label(text: String, size := 18, font_color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", font_color)
	return l

