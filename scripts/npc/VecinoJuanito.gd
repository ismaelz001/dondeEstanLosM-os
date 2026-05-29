extends "res://scripts/npc/NPCBase.gd"

func get_dialogue_entry_node() -> String:
	if MissionManager.is_active("mision_02_favor"):
		var objectives = MissionManager.get_active_objectives("mision_02_favor")
		for obj in objectives:
			if obj["id"] == "hablar_vecino_mensaje" and obj["status"] == "pending":
				return "mision_activa"
	return "saludo_inicial"
