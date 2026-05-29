extends CanvasLayer

# ============================================================
# DialogueBox — Widget de diálogo en pantalla
# Conectado a DialogueManager. Muestra nodo actual y opciones.
# ============================================================

@onready var box: TextureRect = $Box
@onready var speaker_label: Label = $Box/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $Box/VBoxContainer/TextLabel
@onready var options_container: VBoxContainer = $Box/OptionsContainer

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_node_changed.connect(_on_node_changed)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	box.visible = false

func _on_dialogue_started(_npc_id: String) -> void:
	box.visible = true

func _on_node_changed(_node_id: String) -> void:
	var node = DialogueManager.get_current_node()
	speaker_label.text = node.get("speaker", "")
	text_label.text = node.get("text", "")
	_refresh_options(node)

func _refresh_options(node: Dictionary) -> void:
	for child in options_container.get_children():
		child.queue_free()

	var options = DialogueManager.get_available_options()
	if options.is_empty():
		# Nodo lineal: mostrar prompt "Continuar"
		var btn = Button.new()
		btn.text = "Continuar"
		btn.pressed.connect(DialogueManager.advance)
		options_container.add_child(btn)
	else:
		for i in options.size():
			var opt = options[i]
			var btn = Button.new()
			btn.text = opt.get("label", "...")
			var idx = i  # capturar para closure
			btn.pressed.connect(func(): DialogueManager.choose_option(idx))
			options_container.add_child(btn)

func _on_dialogue_finished() -> void:
	box.visible = false
