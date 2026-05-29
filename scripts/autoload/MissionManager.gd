extends Node

# ============================================================
# MissionManager — Autoload singleton
# Carga misiones desde data/missions/<id>.json
# Rastrea estado de misiones y objetivos.
# NUNCA modifica GameState directamente: usa apply_consequences().
# ============================================================

signal mission_available(mission_id: String)
signal mission_started(mission_id: String)
signal mission_objective_updated(mission_id: String, objective_id: String)
signal mission_completed(mission_id: String)
signal mission_failed(mission_id: String)
signal active_mission_changed(mission_id: String)

# Estado de cada misión: "locked" | "available" | "active" | "completed" | "failed"
var _mission_states: Dictionary = {}
# Datos cargados de JSON: mission_id → data dict
var _mission_data: Dictionary = {}
# Objetivos activos: mission_id → Array of objective dicts (con status mutable)
var _active_objectives: Dictionary = {}

const MISSION_IDS: Array[String] = [
	"mision_01_luz",
	"mision_02_favor",
	"mision_03_coche"
]

func _ready() -> void:
	_load_all_missions()
	_initialize_states()
	GameState.mission_relevant_state_changed.connect(_evaluate_unlock_conditions)
	GameState.mission_relevant_state_changed.connect(_evaluate_reach_state_objectives)
	DialogueManager.dialogue_node_changed.connect(_on_dialogue_node_changed)
	DialogueManager.mission_requested.connect(start_mission)
	_evaluate_unlock_conditions()

# ============================================================
# Carga
# ============================================================

func _load_all_missions() -> void:
	for mission_id in MISSION_IDS:
		var path = "res://data/missions/%s.json" % mission_id
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("MissionManager: no se puede abrir %s" % path)
			continue
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		file.close()
		if err != OK:
			push_error("MissionManager: error parseando %s" % path)
			continue
		_mission_data[mission_id] = json.get_data()

func _initialize_states() -> void:
	for mission_id in MISSION_IDS:
		_mission_states[mission_id] = "locked"

# ============================================================
# API pública
# ============================================================

func is_locked(mission_id: String) -> bool:
	return _mission_states.get(mission_id, "locked") == "locked"

func is_available(mission_id: String) -> bool:
	return _mission_states.get(mission_id, "locked") == "available"

func is_active(mission_id: String) -> bool:
	return _mission_states.get(mission_id, "locked") == "active"

func is_completed(mission_id: String) -> bool:
	return _mission_states.get(mission_id, "locked") == "completed"

func is_failed(mission_id: String) -> bool:
	return _mission_states.get(mission_id, "locked") == "failed"

func get_active_mission_id() -> String:
	for mission_id in MISSION_IDS:
		if is_active(mission_id):
			return mission_id
	return ""

func get_active_objectives(mission_id: String) -> Array:
	return _active_objectives.get(mission_id, [])

## Llamado por DialogueManager cuando emite mission_requested
func start_mission(mission_id: String) -> void:
	if not _mission_states.has(mission_id):
		push_warning("MissionManager: misión '%s' desconocida" % mission_id)
		return
	if is_active(mission_id) or is_completed(mission_id):
		return
	_mission_states[mission_id] = "active"
	var data = _mission_data[mission_id]
	# Copiar objetivos para tracking mutable
	_active_objectives[mission_id] = []
	for obj in data.get("objectives", []):
		_active_objectives[mission_id].append(obj.duplicate())
	mission_started.emit(mission_id)
	active_mission_changed.emit(mission_id)
	print("MissionManager: misión iniciada → ", mission_id)

## Marca un objetivo como completado
func complete_objective(mission_id: String, objective_id: String) -> void:
	if not is_active(mission_id):
		return
	var objectives = _active_objectives.get(mission_id, [])
	for obj in objectives:
		if obj["id"] == objective_id and obj["status"] == "pending":
			obj["status"] = "completed"
			mission_objective_updated.emit(mission_id, objective_id)
			print("MissionManager: objetivo completado → ", mission_id, "/", objective_id)
			_check_auto_complete(mission_id)
			return

## Completa la misión manualmente (para misiones con auto_complete: false)
func complete_mission(mission_id: String) -> void:
	if not is_active(mission_id):
		return
	_mission_states[mission_id] = "completed"
	var data = _mission_data[mission_id]
	var rewards = data.get("rewards", {})
	if not rewards.is_empty():
		GameState.apply_consequences(rewards)
	mission_completed.emit(mission_id)
	active_mission_changed.emit(get_active_mission_id())
	print("MissionManager: misión completada → ", mission_id)

func fail_mission(mission_id: String) -> void:
	if not is_active(mission_id):
		return
	_mission_states[mission_id] = "failed"
	var data = _mission_data[mission_id]
	var penalties = data.get("fail_penalties", {})
	if not penalties.is_empty():
		GameState.apply_consequences(penalties)
	mission_failed.emit(mission_id)
	active_mission_changed.emit(get_active_mission_id())
	print("MissionManager: misión fallida → ", mission_id)

# ============================================================
# Evaluación automática
# ============================================================

func _check_auto_complete(mission_id: String) -> void:
	var data = _mission_data.get(mission_id, {})
	var auto_complete = data.get("auto_complete", false)
	if not auto_complete:
		return
	var objectives = _active_objectives.get(mission_id, [])
	for obj in objectives:
		if obj["status"] == "pending":
			return
	complete_mission(mission_id)

func _evaluate_unlock_conditions() -> void:
	for mission_id in MISSION_IDS:
		if not is_locked(mission_id):
			continue
		var data = _mission_data.get(mission_id, {})
		var cond = data.get("conditions_to_unlock", {})
		if _check_unlock_conditions(cond):
			_mission_states[mission_id] = "available"
			mission_available.emit(mission_id)
			print("MissionManager: misión disponible → ", mission_id)

func _check_unlock_conditions(cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	if cond.has("day_min") and GameState.day < cond["day_min"]:
		return false
	if cond.has("family_min") and GameState.family < cond["family_min"]:
		return false
	if cond.has("respect_min") and GameState.respect < cond["respect_min"]:
		return false
	return true

func _evaluate_reach_state_objectives() -> void:
	var active_id = get_active_mission_id()
	if active_id == "":
		return
	var objectives = _active_objectives.get(active_id, [])
	for obj in objectives:
		if obj["status"] != "pending":
			continue
		if obj["type"] != "reach_state":
			continue
		var variable = obj.get("variable", "")
		var target = obj.get("target", 0)
		var current_value = GameState.get(variable)
		if current_value != null and current_value >= target:
			complete_objective(active_id, obj["id"])

func _on_dialogue_node_changed(node_id: String) -> void:
	# Evaluar objetivos talk_to_npc
	var active_id = get_active_mission_id()
	if active_id == "":
		return
	var objectives = _active_objectives.get(active_id, [])
	for obj in objectives:
		if obj["status"] != "pending":
			continue
		if obj["type"] != "talk_to_npc":
			continue
		var npc_id = obj.get("npc_id", "")
		var required_node = obj.get("dialogue_node", "")
		# El npc_id del DialogueManager se guarda en _current_npc_id
		# Accedemos via la señal que ya nos dio el node_id
		if node_id == required_node:
			# Verificar que sea el NPC correcto
			if DialogueManager._current_npc_id == npc_id:
				complete_objective(active_id, obj["id"])
				# Si auto_complete = false y todos los objetivos están listos,
				# la misión se completa cuando el NPC llama complete_mission()

## Llamado por VehicleBase cuando el jugador entra al vehículo
func _on_vehicle_entered(v_id: String) -> void:
	# Conectar la señal destination_reached del vehículo a MissionManager
	# Se hace dinámicamente cuando se detecta el vehículo
	pass

## Llamado por VehicleBase cuando llega al destino
func _on_destination_reached(v_id: String, marker_id: String) -> void:
	var active_id = get_active_mission_id()
	if active_id == "":
		return
	var objectives = _active_objectives.get(active_id, [])
	for obj in objectives:
		if obj["status"] != "pending":
			continue
		if obj["type"] != "drive_vehicle_to_point":
			continue
		if obj.get("vehicle_id", "") == v_id and obj.get("destination_marker", "") == marker_id:
			complete_objective(active_id, obj["id"])
			return
