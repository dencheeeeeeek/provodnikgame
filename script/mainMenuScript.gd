extends Node2D

var music_stream_path = "res://audio/backgroundMaiunMusic.mp3"
var music_stream: AudioStream = null
var is_music_on = true
var music_volume = -10

var music_player: AudioStreamPlayer
var settings_panel: Panel = null

func _ready():
	_music_init()
	_create_settings_panel()
	_create_settings_button()
	print("✅ MusicManager готов!")

func _music_init():
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = music_volume
	add_child(music_player)
	
	_load_music_settings()
	_load_music_stream()
	
	await get_tree().create_timer(0.5).timeout
	if music_player and is_music_on and music_stream:
		music_player.stream = music_stream
		music_player.play()
		music_player.finished.connect(_music_loop)

func _load_music_stream():
	if ResourceLoader.exists(music_stream_path):
		music_stream = ResourceLoader.load(music_stream_path, "AudioStream", ResourceLoader.CACHE_MODE_REUSE)
		if music_stream:
			print("✅ Музыка загружена: ", music_stream_path)
		else:
			print("❌ Ошибка загрузки музыки: ", music_stream_path)
	else:
		print("❌ Файл не найден: ", music_stream_path)
		
		var dir = DirAccess.open("res://audio/")
		if dir:
			print("📁 Доступные файлы в audio/:")
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				print("  - ", file_name)
				file_name = dir.get_next()
			dir.list_dir_end()

func _music_loop():
	if music_player and is_music_on and music_stream:
		music_player.stream = music_stream
		music_player.play()

func _load_music_settings():
	var save_path = "user://music_settings.json"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if data:
			if data.has("music_volume"):
				music_volume = data["music_volume"]
			if data.has("is_music_on"):
				is_music_on = data["is_music_on"]
			if music_player:
				if is_music_on:
					music_player.volume_db = music_volume
				else:
					music_player.volume_db = -80

func _save_music_settings():
	var save_data = {
		"music_volume": music_volume,
		"is_music_on": is_music_on
	}
	var save_path = "user://music_settings.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

func _create_settings_button():
	var existing_btn = get_node_or_null("SettingsButton")
	if existing_btn:
		return
	
	var btn = Button.new()
	btn.name = "SettingsButton"
	btn.text = "⚙️ НАСТРОЙКИ"
	btn.position = Vector2(get_viewport().size.x - 160, get_viewport().size.y - 50)
	btn.size = Vector2(150, 45)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_toggle_settings_panel)
	add_child(btn)
	
	get_viewport().size_changed.connect(_update_settings_button_position)

func _update_settings_button_position():
	var btn = get_node_or_null("SettingsButton")
	if btn:
		btn.position = Vector2(get_viewport().size.x - 160, get_viewport().size.y - 50)

func _create_settings_panel():
	settings_panel = Panel.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.position = Vector2(get_viewport().size.x / 2 - 175, get_viewport().size.y / 2 - 130)
	settings_panel.size = Vector2(350, 260)
	settings_panel.visible = false
	add_child(settings_panel)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.5, 0.7, 1, 1)
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	
	var title_panel = Panel.new()
	title_panel.size = Vector2(350, 45)
	title_panel.position = Vector2(0, 0)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.15, 0.15, 0.25, 1)
	title_style.corner_radius_top_left = 20
	title_style.corner_radius_top_right = 20
	title_style.corner_radius_bottom_left = 0
	title_style.corner_radius_bottom_right = 0
	title_panel.add_theme_stylebox_override("panel", title_style)
	settings_panel.add_child(title_panel)
	
	var title_label = Label.new()
	title_label.text = "⚙️ НАСТРОЙКИ ⚙️"
	title_label.position = Vector2(100, 10)
	title_label.size = Vector2(150, 25)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	title_panel.add_child(title_label)
	
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(315, 8)
	close_btn.size = Vector2(28, 28)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.5, 0.2, 0.2, 1)
	close_style.set_corner_radius_all(14)
	close_btn.add_theme_stylebox_override("normal", close_style)
	
	var close_hover_style = StyleBoxFlat.new()
	close_hover_style.bg_color = Color(0.7, 0.3, 0.3, 1)
	close_hover_style.set_corner_radius_all(14)
	close_btn.add_theme_stylebox_override("hover", close_hover_style)
	
	close_btn.pressed.connect(_close_settings_panel)
	title_panel.add_child(close_btn)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size = Vector2(350, 260)
	margin.position = Vector2(0, 45)
	settings_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var toggle_container = HBoxContainer.new()
	toggle_container.alignment = BoxContainer.ALIGNMENT_CENTER
	toggle_container.add_theme_constant_override("separation", 20)
	vbox.add_child(toggle_container)
	
	var toggle_label = Label.new()
	toggle_label.text = "Музыка:"
	toggle_label.add_theme_font_size_override("font_size", 16)
	toggle_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1, 1))
	toggle_container.add_child(toggle_label)
	
	var toggle_btn = Button.new()
	toggle_btn.text = "🔊 ВКЛ"
	toggle_btn.custom_minimum_size = Vector2(100, 40)
	toggle_btn.add_theme_font_size_override("font_size", 14)
	toggle_btn.pressed.connect(_toggle_music)
	toggle_container.add_child(toggle_btn)
	
	var volume_container = VBoxContainer.new()
	volume_container.add_theme_constant_override("separation", 10)
	vbox.add_child(volume_container)
	
	var volume_label = Label.new()
	volume_label.text = "Громкость музыки:"
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_label.add_theme_font_size_override("font_size", 14)
	volume_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1, 1))
	volume_container.add_child(volume_label)
	
	var volume_slider = HSlider.new()
	volume_slider.min_value = -30
	volume_slider.max_value = 0
	volume_slider.value = music_volume
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.custom_minimum_size = Vector2(250, 30)
	volume_slider.value_changed.connect(_set_music_volume)
	volume_container.add_child(volume_slider)
	
	var volume_value_label = Label.new()
	volume_value_label.text = str(int(music_volume)) + " dB"
	volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_value_label.add_theme_font_size_override("font_size", 12)
	volume_value_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 1))
	volume_container.add_child(volume_value_label)
	
	settings_panel.set_meta("toggle_btn", toggle_btn)
	settings_panel.set_meta("volume_slider", volume_slider)
	settings_panel.set_meta("volume_label", volume_value_label)
	
	_update_music_ui()

func _toggle_settings_panel():
	if settings_panel:
		settings_panel.visible = !settings_panel.visible

func _close_settings_panel():
	if settings_panel:
		settings_panel.visible = false
		print("✅ Панель настроек закрыта")

func _toggle_music():
	is_music_on = !is_music_on
	if music_player:
		if is_music_on:
			music_player.volume_db = music_volume
			music_player.play()
		else:
			music_player.volume_db = -80
	_update_music_ui()
	_save_music_settings()
	
	var notification = Label.new()
	notification.text = "🔊 Музыка включена" if is_music_on else "🔇 Музыка выключена"
	notification.add_theme_font_size_override("font_size", 16)
	notification.add_theme_color_override("font_color", Color.GREEN if is_music_on else Color.RED)
	notification.position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y - 50)
	add_child(notification)
	await get_tree().create_timer(2).timeout
	notification.queue_free()

func _set_music_volume(value: float):
	music_volume = value
	if music_player and is_music_on:
		music_player.volume_db = music_volume
	_update_music_ui()
	_save_music_settings()

func _update_music_ui():
	if not settings_panel:
		return
	
	var toggle_btn = settings_panel.get_meta("toggle_btn")
	var volume_slider = settings_panel.get_meta("volume_slider")
	var volume_label = settings_panel.get_meta("volume_label")
	
	if toggle_btn:
		toggle_btn.text = "🔇 ВЫКЛ" if not is_music_on else "🔊 ВКЛ"
	if volume_slider:
		volume_slider.value = music_volume
	if volume_label:
		volume_label.text = str(int(music_volume)) + " dB"
