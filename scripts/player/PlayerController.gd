extends CharacterBody2D

# ============================================================
# PlayerController — Movimiento e interacción del jugador
# ============================================================

const SPEED: float = 60.0  # px/s a resolución 320×180

# Mapa personaje ID → sprite
const CHARACTER_SPRITES: Dictionary = {
	"el_paco":     "res://assets/characters/spriteA1_spritesheet.png",
	"la_jefa":     "res://assets/characters/spriteA2_spritesheet.png",
	"el_chispa":   "res://assets/characters/spriteA3_spritesheet.png",
	"dona_concha": "res://assets/characters/spriteA4_spritesheet.png",
	"el_rober":    "res://assets/characters/spriteA5_spritesheet.png",
	"la_fati":     "res://assets/characters/spriteA6_spritesheet.png",
}

signal interaction_target_changed(target)

@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera2D

var _sprite: Node = null   # Sprite2D o AnimatedSprite2D
var interaction_target = null
var last_direction: String = "S"

func _ready() -> void:
	add_to_group("player")
	_setup_sprite()
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _setup_sprite() -> void:
	if has_node("AnimatedSprite2D"):
		_sprite = $AnimatedSprite2D
	elif has_node("Sprite2D"):
		_sprite = $Sprite2D
		var char_id: String = GameState.selected_character
		var path: String = CHARACTER_SPRITES.get(char_id, "res://assets/characters/spriteA1_spritesheet.png")
		if ResourceLoader.exists(path):
			_sprite.texture = load(path)
			_sprite.hframes = 4
			_sprite.vframes = 1
			_sprite.frame = 0

func _physics_process(_delta: float) -> void:
	if DialogueManager.is_active or GameState.in_vehicle:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_handle_movement()
	_handle_interaction_input()
	move_and_slide()

func _handle_movement() -> void:
	var dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * SPEED
		_update_direction(dir)
	else:
		velocity = Vector2.ZERO

func _handle_interaction_input() -> void:
	if Input.is_action_just_pressed("interact"):
		if interaction_target != null and interaction_target.has_method("interact"):
			interaction_target.interact(self)

func _update_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		last_direction = "E" if dir.x > 0 else "W"
	else:
		last_direction = "S" if dir.y > 0 else "N"

func _on_body_entered(body: Node) -> void:
	if body.has_method("interact"):
		interaction_target = body
		interaction_target_changed.emit(interaction_target)

func _on_body_exited(body: Node) -> void:
	if body == interaction_target:
		interaction_target = null
		interaction_target_changed.emit(null)

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			GameState.apply_consequences({"money": 50})
			print("[DEBUG] money:", GameState.money)
		if event.keycode == KEY_F2:
			GameState.apply_consequences({"advance_time": true})
			print("[DEBUG] dia:", GameState.day, " slot:", GameState.time_slot)
