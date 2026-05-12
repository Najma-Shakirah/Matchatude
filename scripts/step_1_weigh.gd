extends Node2D

# --- State Machine ---
enum ScaleState { OFF, READY, WEIGHING, DONE }
var state: ScaleState = ScaleState.OFF

# --- Constants ---
const SCOOP_AMOUNT: float = 1.0
const TARGET_WEIGHT: float = 3.0
const HOVER_RADIUS: float = 40.0

# --- Values ---
var matcha_weight: float = 0.0      # weight of matcha in bowl
var tare_done: bool = false
var is_metric_grams: bool = true
var chashaku_has_matcha: bool = false

# --- Node references ---
@onready var display_label: Label = $ScaleSprite/Screen/DisplayLabel
@onready var unit_label: Label = $ScaleSprite/Screen/UnitLabel
@onready var power_button: TextureButton = $ScaleSprite/PowerButton
@onready var unit_button: TextureButton = $ScaleSprite/UnitButton
@onready var tare_button: TextureButton = $ScaleSprite/TareButton
@onready var screen_dark: ColorRect = $ScaleSprite/Screen/ScreenDark
@onready var instruction_label: Label = $InstructionLabel
@onready var chashaku: Sprite2D = $Chashaku
@onready var matcha_tin: Sprite2D = $MatchaTin
@onready var bowl: Sprite2D = $Bowl

var chashaku_empty: Texture2D = preload("res://assets/chashaku.png")
var chashaku_full: Texture2D = preload("res://assets/chashaku with matcha.png")
var bowl_frames: Array[Texture2D] = [
	preload("res://assets/small bowl 0g matcha.png"),
	preload("res://assets/small bowl 1g matcha.png"),
	preload("res://assets/small bowl 3g matcha.png"),
]

func _ready():
	MusicManager.play_bgm(preload("res://assets/audios/cafe.mp3"))
	chashaku.texture = chashaku_empty
	chashaku.visible = false        # hide until scale is on and tared
	bowl.texture = bowl_frames[0]
	_set_state(ScaleState.OFF)

# -------------------------------------------------------
# STATE MACHINE
# -------------------------------------------------------
func _set_state(new_state: ScaleState):
	state = new_state
	match state:

		ScaleState.OFF:
			screen_dark.visible = true
			tare_button.disabled = true
			unit_button.disabled = true
			instruction_label.text = "Turn on the scale first."

		ScaleState.READY:
			screen_dark.visible = false
			matcha_weight = 0.0
			tare_done = false
			_update_display()
			tare_button.disabled = false
			unit_button.disabled = false
			instruction_label.text = "Switch to g, then press Tare to zero the scale."

		ScaleState.WEIGHING:
			chashaku.visible = true     # show chashaku only now
			_update_display()
			instruction_label.text = "Scoop matcha into the bowl. Target: %.0fg" % TARGET_WEIGHT

		ScaleState.DONE:
			instruction_label.text = "Perfect! Moving on..."
			chashaku.visible = false
			await get_tree().create_timer(1.5).timeout
			GameManager.complete_step(1)
			get_tree().change_scene_to_file("res://scenes/step_2_sift.tscn")

# -------------------------------------------------------
# BUTTONS
# -------------------------------------------------------
func _on_power_button_pressed():
	if state == ScaleState.OFF:
		_set_state(ScaleState.READY)
	else:
		_set_state(ScaleState.OFF)

func _on_unit_button_pressed():
	if state == ScaleState.OFF:
		return
	is_metric_grams = !is_metric_grams
	_update_display()
	if not is_metric_grams:
		instruction_label.text = "⚠️ Switch to g for matcha powder!"
	else:
		instruction_label.text = "Good! Now press Tare to zero the scale."

func _on_tare_button_pressed():
	if state == ScaleState.OFF:
		return
	tare_done = true
	_update_display()
	instruction_label.text = "Scale zeroed! Now scoop matcha into the bowl."
	_set_state(ScaleState.WEIGHING)

# -------------------------------------------------------
# CHASHAKU + SCOOPING (only works when scale is on)
# -------------------------------------------------------
func _process(_delta):
	# Offset so the tip of the chashaku aligns with the cursor
	# Adjust this Vector2 until it feels right for your sprite
	chashaku.global_position = get_global_mouse_position() + Vector2(-20, -10)

	# Scooping only works after scale is on and tared
	if state != ScaleState.WEIGHING:
		return

	var mouse_pos = get_global_mouse_position()
	if not chashaku_has_matcha:
		if mouse_pos.distance_to(matcha_tin.global_position) < HOVER_RADIUS:
			_scoop_matcha()
	else:
		if mouse_pos.distance_to(bowl.global_position) < HOVER_RADIUS:
			_drop_matcha()

func _scoop_matcha():
	if matcha_weight >= TARGET_WEIGHT:
		return
	chashaku_has_matcha = true
	chashaku.texture = chashaku_full
	instruction_label.text = "Now hover over the bowl to drop the matcha."

func _drop_matcha():
	chashaku_has_matcha = false
	chashaku.texture = chashaku_empty
	matcha_weight = min(matcha_weight + SCOOP_AMOUNT, TARGET_WEIGHT)

	_update_display()
	bowl.texture = bowl_frames[_get_bowl_frame()]

	if matcha_weight >= TARGET_WEIGHT:
		_set_state(ScaleState.DONE)
	else:
		instruction_label.text = "%.0fg more needed." % (TARGET_WEIGHT - matcha_weight)

# -------------------------------------------------------
# HELPERS
# -------------------------------------------------------
func _update_display():
	display_label.text = "%.1f" % matcha_weight
	unit_label.text = "g" if is_metric_grams else "ml"

func _get_bowl_frame() -> int:
	if matcha_weight <= 0:
		return 0
	elif matcha_weight <= 1.0:
		return 1
	else:
		return 2
