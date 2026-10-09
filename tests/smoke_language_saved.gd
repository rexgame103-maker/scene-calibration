extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var language := root.get_node("GameLanguage")
	assert(language.current_language == "zh_CN", "Saved language must be loaded on a new process")
	assert(TranslationServer.get_locale() == "zh_CN")
	assert(String(TranslationServer.translate("开始游戏")) == "开始游戏")
	language.set_language("en")
	assert(String(TranslationServer.translate("开始游戏")) == "New Game")
	assert(String(TranslationServer.translate("购买  ¥500")) == "Buy  ¥500")
	language.set_language("unsupported", false)
	assert(language.current_language == "en", "Unsupported locale falls back to English")
	root.get_node("GameAudio").stop_all()
	await create_timer(0.15).timeout
	print("LANGUAGE_SAVED_OK: persisted across restart, invalid locale fallback")
	quit()
