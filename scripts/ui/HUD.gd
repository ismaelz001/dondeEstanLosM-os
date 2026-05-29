extends CanvasLayer

# ============================================================
# HUD - Interfaz de usuario en juego
# ============================================================

@onready var label_money: Label = $StatsPanel/HBoxContainer/LabelMoney
@onready var label_family: Label = $StatsPanel/HBoxContainer/LabelFamily
@onready var label_respect: Label = $StatsPanel/HBoxContainer/LabelRespect
@onready var label_heat: Label = $StatsPanel/HBoxContainer/LabelHeat
@onready var label_time: Label = $StatsPanel/LabelTime

@onready var mission_panel: PanelContainer = $MissionPanel
@onready var mission_title: Label = $MissionPanel/VBoxContainer/MissionTitle
@onready var mission_objectives: VBoxContainer = $MissionPanel/VBoxContainer/Objectives

@onready var vehicle_panel: PanelContainer = $VehiclePanel
@onready var vehicle_name_label: Label = $VehiclePanel/LabelVehicle

@onready var interact_prompt: Label = $InteractPrompt

func _ready() -> void:
	GameState.visible_stats_changed.connect(_on_stat_changed)
	GameState.time_changed.connect(_on_time_changed)

	MissionManager.active_mission_changed.connect(_on_active_mission_changed)
	MissionManager.mission_objective_updated.connect(_on_objective_updated)

	_refresh_all_stats()
	mission_panel.visible = false
	vehicle_panel.visible = false
	interact_prompt.visible = false

func _refresh_all_stats() -> void:
	label_money.text = "EUR%d" % GameState.money
	label_family.text = "F%d" % GameState.family
	label_respect.text = "R%d" % GameState.respect
	label_heat.text = "C%d" % GameState.heat
	label_time.text = "D%d %s" % [GameState.day, GameState.time_slot]

func _on_stat_changed(variable: String, value: int) -> void:
	match variable:
		"money": label_money.text = "EUR%d" % value
		"family": label_family.text = "F%d" % value
		"respect": label_respect.text = "R%d" % value
		"heat": label_heat.text = "C%d" % value

func _on_time_changed(day: int, slot: String) -> void:
	label_time.text = "D%d %s" % [day, slot]

func _on_active_mission_changed(mission_id: String) -> void:
	if mission_id == "":
		mission_panel.visible = false
		return
	if not MissionManager._mission_data.has(mission_id):
		return
	var data = MissionManager._mission_data[mission_id]
	mission_title.text = data.get("title", "")
	_refresh_objectives(mission_id)
	mission_panel.visible = true

func _refresh_objectives(mission_id: String) -> void:
	for child in mission_objectives.get_children():
		child.queue_free()
	var objectives = MissionManager.get_active_objectives(mission_id)
	for obj in objectives:
		var lbl = Label.new()
		var prefix = "OK " if obj["status"] == "completed" else "- "
		lbl.text = prefix + obj.get("description", "")
		lbl.add_theme_font_size_override("font_size", 6)
		mission_objectives.add_child(lbl)

func _on_objective_updated(mission_id: String, _objective_id: String) -> void:
	_refresh_objectives(mission_id)

func show_interact_prompt(target) -> void:
	interact_prompt.visible = target != null
	if target != null and target.has_method("interact"):
		interact_prompt.text = "E  " + target.get("display_name", "Hablar")

func _process(_delta: float) -> void:
	vehicle_panel.visible = GameState.in_vehicle
	if GameState.in_vehicle:
		vehicle_name_label.text = GameState.current_vehicle_id
