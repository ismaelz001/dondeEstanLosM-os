extends CharacterBody2D

# ============================================================
# VehicleBase — Vehículo conducible
# Se instancia en el mapa con @export var vehicle_id configurado.
# ============================================================

signal vehicle_entered(vehicle_id: String)
signal vehicle_exited(vehicle_id: String)
signal destination_reached(vehicle_id: String, marker_id: String)

@export var vehicle_id: String = "coche_tito"
@export var vehicle_name: String = "Renault 5"
@export var max_speed: float = 80.0
@export var acceleration: float = 200.0
@export var turn_speed: float = 120.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var entry_zone: Area2D = $EntryZone
@onready var exit_point: Marker2D = $ExitPoint

var is_occupied: bool = false
var _player_ref = null
var _speed: float = 0.0
var _destination_marker_id: String = ""
var _destination_position: Vector2 = Vector2.ZERO
var _destination_radius: float = 32.0
var _watching_destination: bool = false
var _player_nearby: bool = false
var _player_candidate = null

func _ready() -> void:
	entry_zone.body_entered.connect(_on_entry_zone_body_entered)
	entry_zone.body_exited.connect(_on_entry_zone_body_exited)

func _physics_process(delta: float) -> void:
	if not is_occupied:
		if _player_nearby and _player_candidate != null:
			if Input.is_action_just_pressed("interact"):
				try_enter(_player_candidate)
		return
	_handle_vehicle_input(delta)
	move_and_slide()
	if _watching_destination:
		_check_destination()

func _handle_vehicle_input(delta: float) -> void:
	var steer = Input.get_axis("move_left", "move_right")
	var throttle = Input.get_axis("move_up", "move_down")

	if throttle != 0.0:
		_speed = move_toward(_speed, -throttle * max_speed, acceleration * delta)
	else:
		_speed = move_toward(_speed, 0.0, acceleration * delta * 0.5)

	if abs(_speed) > 1.0:
		rotation_degrees += steer * turn_speed * delta * sign(_speed)

	velocity = Vector2(sin(rotation), -cos(rotation)) * _speed

	# Salir del vehículo
	if Input.is_action_just_pressed("interact"):
		_exit_vehicle()

func try_enter(player) -> void:
	if is_occupied:
		return
	is_occupied = true
	_player_ref = player
	player.visible = false
	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").disabled = true
	GameState.apply_consequences({
		"in_vehicle": true,
		"current_vehicle_id": vehicle_id,
		"vehicle_state": 100,
		"vehicle_fuel": 100
	})
	vehicle_entered.emit(vehicle_id)
	# Conectar con objetivos de misión
	MissionManager._on_vehicle_entered(vehicle_id)

func _exit_vehicle() -> void:
	if not is_occupied or _player_ref == null:
		return
	is_occupied = false
	_watching_destination = false
	_player_ref.global_position = exit_point.global_position
	_player_ref.visible = true
	if _player_ref.has_node("CollisionShape2D"):
		_player_ref.get_node("CollisionShape2D").disabled = false
	GameState.apply_consequences({
		"in_vehicle": false,
		"current_vehicle_id": ""
	})
	vehicle_exited.emit(vehicle_id)
	_player_ref = null
	_speed = 0.0

## Llamado por MissionManager para activar tracking de destino
func set_destination(marker_id: String, marker_pos: Vector2, radius: float) -> void:
	_destination_marker_id = marker_id
	_destination_position = marker_pos
	_destination_radius = radius
	_watching_destination = true

func _check_destination() -> void:
	if global_position.distance_to(_destination_position) <= _destination_radius:
		_watching_destination = false
		destination_reached.emit(vehicle_id, _destination_marker_id)
		MissionManager._on_destination_reached(vehicle_id, _destination_marker_id)

func _on_entry_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_occupied:
		_player_nearby = true
		_player_candidate = body

func _on_entry_zone_body_exited(body: Node) -> void:
	if body == _player_candidate:
		_player_nearby = false
		_player_candidate = null
