extends Node

# ============================================================
# DialogueManager — Autoload singleton
# Gestiona árboles de diálogo node-based cargados desde JSON.
# Cada NPC tiene su propio archivo: data/dialogues/<npc_id>.json
# ============================================================

signal dialogue_started(npc_id: String)
signal dialogue_node_changed(node_id: String)
signal dialogue_finished()
signal mission_requested(mission_id: String)

var is_active: bool = false

var _current_npc_id: String = ""
var _current_node: Dictionary = {}
var _tree: Dictionary = {}   # id → node dictionary

# ============================================================
# API pública
# ============================================================

## Inicia un diálogo. npc_id = nombre del archivo JSON (sin .json).
## entry_node = id del primer nodo a mostrar.
func start_dialogue(npc_id: String, entry_node: String) -> void:
	_tree = _load_tree(npc_id)
	if _tree.is_empty():
		push_warning("DialogueManager: no se encontró árbol para '%s'" % npc_id)
		return
	if not _tree.has(entry_node):
		push_warning("DialogueManager: nodo '%s' no existe en '%s'" % [entry_node, npc_id])
		return
	_current_npc_id = npc_id
	is_active = true
	dialogue_started.emit(npc_id)
	_go_to_node(entry_node)

## Devuelve el nodo actual (para que DialogueBox lea speaker, text, options).
func get_current_node() -> Dictionary:
	return _current_node

## Avanza en un nodo lineal (sin options).
func advance() -> void:
	if not is_active:
		return
	var next = _current_node.get("next", null)
	if next == null:
		_finish()
	else:
		_go_to_node(next)

## El jugador elige la opción con índice idx.
func choose_option(idx: int) -> void:
	if not is_active:
		return
	var options = get_available_options()
	if idx < 0 or idx >= options.size():
		push_warning("DialogueManager: índice de opción inválido: %d" % idx)
		return
	var option = options[idx]
	var consequences = option.get("consequences", {})
	if not consequences.is_empty():
		GameState.apply_consequences(consequences)
	var next = option.get("next", null)
	if next == null:
		_finish()
	else:
		_go_to_node(next)

## Filtra opciones del nodo actual según conditions.
func get_available_options() -> Array:
	var all_options = _current_node.get("options", [])
	var result: Array = []
	for opt in all_options:
		if _check_conditions(opt.get("conditions", {})):
			result.append(opt)
	return result

# ============================================================
# Internals
# ============================================================

func _go_to_node(node_id: String) -> void:
	if not _tree.has(node_id):
		push_warning("DialogueManager: nodo '%s' no encontrado, terminando diálogo" % node_id)
		_finish()
		return
	_current_node = _tree[node_id]

	# Consecuencias del nodo (no de la opción)
	var consequences = _current_node.get("consequences", {})
	if not consequences.is_empty():
		GameState.apply_consequences(consequences)

	# Emitir señal de misión si el nodo la tiene
	var mission_id = _current_node.get("start_mission", "")
	if mission_id != "":
		mission_requested.emit(mission_id)

	dialogue_node_changed.emit(node_id)

	# Si no tiene options y next == null → auto-terminar tras emitir
	# DialogueBox controlará cuándo avanzar (input del jugador)

func _finish() -> void:
	is_active = false
	_current_node = {}
	_current_npc_id = ""
	dialogue_finished.emit()

func _check_conditions(cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	if cond.has("money_min") and GameState.money < cond["money_min"]:
		return false
	if cond.has("respect_min") and GameState.respect < cond["respect_min"]:
		return false
	if cond.has("heat_max") and GameState.heat > cond["heat_max"]:
		return false
	if cond.has("criminal_heat_max") and GameState.criminal_heat > cond["criminal_heat_max"]:
		return false
	if cond.has("family_trust_min") and GameState.family_trust < cond["family_trust_min"]:
		return false
	return true

func _load_tree(npc_id: String) -> Dictionary:
	var path = "res://data/dialogues/%s.json" % npc_id
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: no se puede abrir %s" % path)
		return {}
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("DialogueManager: error parseando %s: %s" % [path, json.get_error_message()])
		return {}
	var nodes_array = json.get_data()
	var result: Dictionary = {}
	for node in nodes_array:
		result[node["id"]] = node
	return result
