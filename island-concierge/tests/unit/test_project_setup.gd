## Vérifie la configuration du projet décidée pour la V0.1.
extends GutTest


func test_engine_is_at_least_4_4() -> void:
	var v := Engine.get_version_info()
	assert_eq(v.major, 4)
	assert_gte(v.minor, 4)


func test_engine_matches_pinned_version() -> void:
	var pinned := FileAccess.get_file_as_string("res://.godot-version").strip_edges()
	var v := Engine.get_version_info()
	var running := "%d.%d.%d.%s" % [v.major, v.minor, v.patch, v.status]
	assert_eq(running, pinned, "Version de Godot différente de .godot-version")


func test_landscape_orientation() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/handheld/orientation"),
			DisplayServer.SCREEN_LANDSCAPE)


func test_stretch_settings_for_multiple_screen_sizes() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_mobile_renderer() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "mobile")


func test_french_is_fallback_locale() -> void:
	assert_eq(ProjectSettings.get_setting("internationalization/locale/fallback"), "fr")


func test_french_strings_are_loaded() -> void:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("fr")
	assert_eq(TranslationServer.translate(&"APP_TAGLINE"), "Bienvenue à Mahana !")
	TranslationServer.set_locale(previous)


func test_event_bus_autoload_is_present() -> void:
	assert_not_null(get_tree().root.get_node_or_null("EventBus"))
