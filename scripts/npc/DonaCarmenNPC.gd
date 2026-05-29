extends "res://scripts/npc/NPCBase.gd"

func _ready() -> void:
	super._ready()
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func get_dialogue_entry_node() -> String:
	if MissionManager.is_completed("mision_01_luz"):
		return "mision_completada"
	if MissionManager.is_active("mision_01_luz"):
		var objectives = MissionManager.get_active_objectives("mision_01_luz")
		for obj in objectives:
			if obj["id"] == "conseguir_dinero" and obj["status"] == "pending":
				return "mision_activa"
		# Todos los objetivos anteriores cumplidos → nodo de entrega
		return "entregar_dinero_check"
	return "saludo_inicial"

func _on_dialogue_finished() -> void:
	if MissionManager.is_active("mision_01_luz"):
		var objectives = MissionManager.get_active_objectives("mision_01_luz")
		var all_done = true
		for obj in objectives:
			if obj["status"] == "pending":
				all_done = false
				break
		if all_done:
			MissionManager.complete_mission("mision_01_luz")
