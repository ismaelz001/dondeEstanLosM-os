extends Control

# ============================================================
# MainMenu — Menú principal del juego
# ============================================================

@onready var btn_new_game: Button  = $VBoxContainer/Button_NewGame
@onready var btn_continue: Button  = $VBoxContainer/Button_Continue
@onready var btn_quit: Button      = $VBoxContainer/Button_Quit

func _ready() -> void:
	btn_new_game.pressed.connect(_on_new_game)
	btn_continue.pressed.connect(_on_continue)
	btn_quit.pressed.connect(_on_quit)
	# Desactivar Continuar si no hay guardado
	btn_continue.disabled = not SaveSystem.has_save()

func _on_new_game() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main/character_select.tscn")

func _on_continue() -> void:
	if SaveSystem.load_game():
		get_tree().change_scene_to_file("res://scenes/world/barrio_exterior.tscn")

func _on_btn_demo_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/barrio_demo.tscn")

func _on_quit() -> void:
	get_tree().quit()
