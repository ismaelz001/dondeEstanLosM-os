extends "res://scripts/npc/NPCBase.gd"

func _ready() -> void:
	super._ready()
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func get_dialogue_entry_node() -> String:
	if MissionManager.is_completed("mision_02_favor"):
		return "mision_completada"
	if MissionManager.is_active("mision_02_favor"):
		var objectives = MissionManager.get_active_objectives("mision_02_favor")
		var vecino_done = false
		for obj in objectives:
			if obj["id"] == "hablar_vecino_mensaje" and obj["status"] == "completed":
				vecino_done = true
				break
		if vecino_done:
			return "entregar_recado"
		return "mision_activa"
	return "saludo_inicial"

func _on_dialogue_finished() -> void:
	if MissionManager.is_active("mision_02_favor"):
		var objectives = MissionManager.get_active_objectives("mision_02_favor")
		var all_done = true
		for obj in objectives:
			if obj["status"] == "pending":
				all_done = false
				break
		if all_done:
			MissionManager.complete_mission("mision_02_favor")
