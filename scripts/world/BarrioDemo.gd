extends Node2D

# ============================================================
# BarrioDemo — Escena principal del barrio demo
# Conecta señales entre Player, HUD y VehicleBase
# ============================================================

@onready var player = $Player
@onready var hud = $HUD
@onready var coche_tito: CharacterBody2D = $Vehicles/CocheTito
@onready var taller_marker: Marker2D = $Markers/TallerEntrada

func _ready() -> void:
	# Conectar prompt de interacción Player → HUD
	if player.has_signal("interaction_target_changed"):
		player.interaction_target_changed.connect(hud.show_interact_prompt)

	# Configurar destino del coche de Tito cuando se active la misión
	MissionManager.mission_started.connect(_on_mission_started)

func _on_mission_started(mission_id: String) -> void:
	if mission_id == "mision_03_coche":
		coche_tito.set_destination(
			"taller_entrada",
			taller_marker.global_position,
			32.0
		)
