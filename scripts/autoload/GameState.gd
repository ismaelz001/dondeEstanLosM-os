extends Node

# ============================================================
# GameState — Autoload singleton
# REGLA DE ORO: nadie modifica variables directamente.
# Todo pasa por apply_consequences(c: Dictionary).
# ============================================================

# --- Señales ---
signal visible_stats_changed(variable: String, value: int)
signal path_stats_changed(variable: String, value: int)
signal time_changed(day: int, time_slot: String)
signal mission_relevant_state_changed()

# --- Variables visibles (HUD) ---
var money: int = 0
var family: int = 50
var respect: int = 25
var heat: int = 0
var day: int = 1
var time_slot: String = "MORNING"   # MORNING | AFTERNOON | NIGHT

# --- Variables de path (nunca en HUD) ---
var legal_path: int = 50
var street_path: int = 50
var family_trust: int = 50
var business_reputation: int = 0
var criminal_heat: int = 0
var neighborhood_respect: int = 25

# --- Variables de vehículo ---
var in_vehicle: bool = false
var current_vehicle_id: String = ""
var vehicle_state: int = 100
var vehicle_fuel: int = 100

# --- Estado de partida ---
var selected_character: String = ""

const TIME_SLOTS: Array[String] = ["MORNING", "AFTERNOON", "NIGHT"]

# ============================================================
# Único punto de entrada para modificar estado
# ============================================================
func apply_consequences(c: Dictionary) -> void:
	# Visibles
	if c.has("money"):
		money += c["money"]
		money = max(0, money)
		visible_stats_changed.emit("money", money)
	if c.has("family"):
		family = clampi(family + c["family"], 0, 100)
		visible_stats_changed.emit("family", family)
	if c.has("respect"):
		respect = clampi(respect + c["respect"], 0, 100)
		visible_stats_changed.emit("respect", respect)
	if c.has("heat"):
		heat = clampi(heat + c["heat"], 0, 100)
		visible_stats_changed.emit("heat", heat)

	# Path (ocultas)
	if c.has("legal_path"):
		legal_path = clampi(legal_path + c["legal_path"], 0, 100)
		path_stats_changed.emit("legal_path", legal_path)
	if c.has("street_path"):
		street_path = clampi(street_path + c["street_path"], 0, 100)
		path_stats_changed.emit("street_path", street_path)
	if c.has("family_trust"):
		family_trust = clampi(family_trust + c["family_trust"], 0, 100)
		path_stats_changed.emit("family_trust", family_trust)
	if c.has("business_reputation"):
		business_reputation = clampi(business_reputation + c["business_reputation"], 0, 100)
		path_stats_changed.emit("business_reputation", business_reputation)
	if c.has("criminal_heat"):
		criminal_heat = clampi(criminal_heat + c["criminal_heat"], 0, 100)
		path_stats_changed.emit("criminal_heat", criminal_heat)
	if c.has("neighborhood_respect"):
		neighborhood_respect = clampi(neighborhood_respect + c["neighborhood_respect"], 0, 100)
		path_stats_changed.emit("neighborhood_respect", neighborhood_respect)

	# Vehículo
	if c.has("in_vehicle"):
		in_vehicle = c["in_vehicle"]
	if c.has("current_vehicle_id"):
		current_vehicle_id = c["current_vehicle_id"]
	if c.has("vehicle_state"):
		vehicle_state = c["vehicle_state"]
	if c.has("vehicle_fuel"):
		vehicle_fuel = c["vehicle_fuel"]

	# Tiempo
	if c.has("advance_time") and c["advance_time"]:
		_advance_time()

	# Señal genérica para MissionManager
	mission_relevant_state_changed.emit()

# ============================================================
# Tiempo
# ============================================================
func _advance_time() -> void:
	var idx = TIME_SLOTS.find(time_slot)
	if idx == -1:
		idx = 0
	idx += 1
	if idx >= TIME_SLOTS.size():
		idx = 0
		day += 1
	time_slot = TIME_SLOTS[idx]
	time_changed.emit(day, time_slot)

# ============================================================
# Reset (nueva partida)
# ============================================================
func reset() -> void:
	money = 0
	family = 50
	respect = 25
	heat = 0
	day = 1
	time_slot = "MORNING"
	legal_path = 50
	street_path = 50
	family_trust = 50
	business_reputation = 0
	criminal_heat = 0
	neighborhood_respect = 25
	in_vehicle = false
	current_vehicle_id = ""
	vehicle_state = 100
	vehicle_fuel = 100
	selected_character = ""
