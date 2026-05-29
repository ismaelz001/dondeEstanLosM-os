extends StaticBody2D
class_name NPCBase

# ============================================================
# NPCBase — Script base para todos los NPCs
# Subclasear y sobreescribir get_dialogue_entry_node() para
# lógica contextual por NPC.
# ============================================================

@export var npc_id: String = ""
@export var display_name: String = "NPC"

@onready var label: Label = $Label if has_node("Label") else null

func _ready() -> void:
	if label:
		label.text = display_name

func interact(_player = null) -> void:
	var entry_node = get_dialogue_entry_node()
	DialogueManager.start_dialogue(npc_id, entry_node)

## Sobreescribir en subclases para lógica contextual.
## Por defecto devuelve "saludo_inicial" o "mision_activa" / "mision_completada"
## basándose en la misión asociada al NPC.
func get_dialogue_entry_node() -> String:
	# Buscar si este NPC tiene una misión activa o completada
	for mission_id in MissionManager.MISSION_IDS:
		if not MissionManager._mission_data.has(mission_id):
			continue
		var data = MissionManager._mission_data[mission_id]
		if data.get("giver_npc", "") != npc_id:
			continue
		if MissionManager.is_completed(mission_id):
			return "mision_completada"
		if MissionManager.is_active(mission_id):
			return "mision_activa"
	return "saludo_inicial"
