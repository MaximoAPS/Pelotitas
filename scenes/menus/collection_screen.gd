extends Control
class_name CollectionScreen
## Hub mínimo: roster de pelotitas y catálogo de habilidades (nivel 1).

static var start_tab: int = 0

var _tab: int = 0
var _content: VBoxContainer


func _ready() -> void:
	_tab = start_tab
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.16, 0.2, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_top = 24
	root.offset_right = -40
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	top.add_child(_btn("Volver", _go_menu, Vector2(160, 64)))
	var title := Label.new()
	title.text = "Colección"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	top.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	root.add_child(tabs)
	tabs.add_child(_btn("Pelotitas", _show_tab.bind(0), Vector2(0, 72)))
	tabs.add_child(_btn("Habilidades", _show_tab.bind(1), Vector2(0, 72)))

	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 18)
	note.text = "Nivel 1: un disparo del elemento dominante. Ganar da XP; el XP da puntos elementales para aprender el resto."
	root.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)
	_refresh()


func _show_tab(tab: int) -> void:
	_tab = tab
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()
	if _tab == 0:
		_fill_pelotitas()
	else:
		_fill_abilities()


func _fill_pelotitas() -> void:
	Progression.ensure_roster()
	for pid in Progression.pelotitas_data.keys():
		var data: Dictionary = Progression.pelotitas_data[pid]
		var el := int(data.get("dominant_element", GameRules.dominant_element(data.get("affinity_weights", {}))))
		var card := PanelContainer.new()
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		var name_lbl := Label.new()
		name_lbl.add_theme_font_size_override("font_size", 28)
		var selected := str(pid) == Progression.selected_id
		name_lbl.text = "%s%s" % [str(data.get("id", pid)), "  (en uso)" if selected else ""]
		name_lbl.add_theme_color_override("font_color", GameRules.shot_color(el))
		box.add_child(name_lbl)
		var stats := Label.new()
		stats.add_theme_font_size_override("font_size", 20)
		stats.text = "Nv %d  XP %d  %s\nATK %s  DEF %s  SPD %s\nHP %s  masa %.1f" % [
			int(data.get("level", 1)),
			int(data.get("experience", 0)),
			GameRules.element_label(el),
			int(data.get("ataque", 0)),
			int(data.get("defensa", 0)),
			int(data.get("velocidad", 0)),
			GameRules.max_health_from_bonus(int(GameRules.combat_stats_from(data).bonus_hp)),
			float(data.get("masa", 1.0)),
		]
		box.add_child(stats)
		if not selected:
			box.add_child(_btn("Usar en duelo", func():
				Progression.select_pelotita(str(pid))
				_refresh()
			, Vector2(0, 56)))
		box.add_child(_btn("Resetear a nv 1", func():
			Progression.reset_pelotita(str(pid))
			_refresh()
		, Vector2(0, 56)))
		_content.add_child(card)
	var cap := Label.new()
	cap.add_theme_font_size_override("font_size", 18)
	cap.text = "Una sola pelotita. Resetear la vuelve a nivel 1 con elemento y stats nuevos."
	_content.add_child(cap)


func _fill_abilities() -> void:
	var learned: Array = Progression.selected_pelotita().get("learned_skills", [])
	var points: Dictionary = Progression.selected_pelotita().get("skill_points", {})
	var pts := Label.new()
	pts.add_theme_font_size_override("font_size", 20)
	pts.text = "Puntos: Fuego %d  Agua %d  Tierra %d  Aire %d" % [
		int(points.get(0, points.get("0", 0))),
		int(points.get(1, points.get("1", 0))),
		int(points.get(2, points.get("2", 0))),
		int(points.get(3, points.get("3", 0))),
	]
	_content.add_child(pts)
	for el in range(4):
		var id := GameRules.basic_shot_id(el)
		var unlocked := id in learned
		var card := PanelContainer.new()
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)
		var title := Label.new()
		title.add_theme_font_size_override("font_size", 26)
		title.add_theme_color_override("font_color", GameRules.shot_color(el))
		title.text = "%s%s" % [GameRules.shot_name(el), "" if unlocked else "  — bloqueada"]
		box.add_child(title)
		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", 20)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.text = GameRules.shot_blurb(el) if unlocked else "Se aprende con 1 punto de %s (después del nivel 1)." % GameRules.element_label(el)
		box.add_child(desc)
		_content.add_child(card)


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _btn(text: String, callback: Callable, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 26)
	btn.pressed.connect(callback)
	return btn
