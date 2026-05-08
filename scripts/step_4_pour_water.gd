extends Node2D

# --- Constants ---
const TARGET_ML: float = 40.0       # midpoint of 30-50ml range
const MIN_ML: float = 30.0
const MAX_ML: float = 50.0
const POUR_RATE: float = 12.0       # ml per second while pouring

# --- State ---
var current_ml: float = 0.0
var is_pouring: bool = false
var is_ml_mode: bool = false         # must switch to ml before pouring
var scale_on: bool = false
var tared: bool = false
var done: bool = false
var kettle_clicked: bool = false     # kettle has been picked up

# --- Node references ---
@onready var chawan: Sprite2D = $ChawanPour1
@onready var kettle: Sprite2D = $Kettle
@onready var kettle_pov: Sprite2D = $KettlePovWater      # tilted kettle POV when pouring
@onready var display_label: Label = $ScaleSprite/Screen/DisplayLabel
@onready var unit_label: Label = $ScaleSprite/Screen/UnitLabel
@onready var screen_dark: ColorRect = $ScaleSprite/Screen/ScreenDark
@onready var power_button: TextureButton = $ScaleSprite/PowerButton
@onready var unit_button: TextureButton = $ScaleSprite/UnitButton
@onready var tare_button: TextureButton = $ScaleSprite/TareButton
@onready var kettle_button: TextureButton = $KettleButton   # invisible button over kettle
@onready var pour_button: TextureButton = $PourButton       # hold to pour, visible after kettle clicked
@onready var instruction_label: Label = $InstructionLabel

# Chawan frames as water fills up
var chawan_frames: Array[Texture2D] = [
	preload("res://assets/chawan_pour1.png"),   # dry matcha, no water
	preload("res://assets/chawan_pour2.png"),   # a little water
	preload("res://assets/chawan_pour3.png"),   # half
	preload("res://assets/chawan_pour4.png"),   # almost full
]

func _ready():
	chawan.texture = chawan_frames[0]
	kettle_pov.visible = false
	pour_button.visible = false
	screen_dark.visible = true
	_update_display()
	instruction_label.text = "Tare the scale and switch to ml, then pick up the kettle."

func _process(delta):
	if done or not is_pouring:
		return

	current_ml += POUR_RATE * delta
	current_ml = min(current_ml, MAX_ML + 5.0)
	_update_display()
	_update_chawan()

	# Warn if going over
	if current_ml > MAX_ML:
		instruction_label.text = "Too much! You went over 50ml."
		is_pouring = false
		pour_button.visible = false
		kettle_pov.visible = false
		_reset_pour()

# -------------------------------------------------------
# SCALE BUTTONS (reused from Step 1)
# -------------------------------------------------------
func _on_power_button_pressed():
	scale_on = !scale_on
	screen_dark.visible = !scale_on
	tare_button.disabled = !scale_on
	unit_button.disabled = !scale_on
	if scale_on:
		instruction_label.text = "Switch to ml, then tare the scale."
	else:
		tared = false
		is_ml_mode = false
		instruction_label.text = "Turn on the scale first."
	_update_display()

func _on_unit_button_pressed():
	if not scale_on:
		return
	is_ml_mode = !is_ml_mode
	_update_display()
	if is_ml_mode:
		instruction_label.text = "Good! Now press Tare, then pick up the kettle."
	else:
		instruction_label.text = "⚠️ Switch to ml for water measurement!"

func _on_tare_button_pressed():
	if not scale_on:
		return
	tared = true
	current_ml = 0.0
	_update_display()
	instruction_label.text = "Tared! Now click the kettle to pick it up."

# -------------------------------------------------------
# KETTLE INTERACTION
# -------------------------------------------------------
func _on_kettle_button_pressed():
	if not scale_on or not is_ml_mode or not tared:
		if not scale_on:
			instruction_label.text = "Turn on the scale first!"
		elif not is_ml_mode:
			instruction_label.text = "Switch the scale to ml first!"
		elif not tared:
			instruction_label.text = "Tare the scale first!"
		return

	# Pick up kettle — show POV, hide side kettle
	kettle_clicked = true
	kettle.visible = false
	kettle_pov.visible = true
	pour_button.visible = true
	instruction_label.text = "Hold the pour button to pour. Stop between 30–50ml!"

func _on_pour_button_button_down():
	if kettle_clicked:
		is_pouring = true

func _on_pour_button_button_up():
	is_pouring = false
	if kettle_clicked and not done:
		_check_result()

# -------------------------------------------------------
# RESULT CHECK
# -------------------------------------------------------
func _check_result():
	if current_ml >= MIN_ML and current_ml <= MAX_ML:
		_on_complete()
	else:
		if current_ml < MIN_ML:
			instruction_label.text = "Only %.0fml! Need at least 30ml. Pour more." % current_ml
		else:
			instruction_label.text = "%.0fml is too much! Stay between 30–50ml." % current_ml

func _reset_pour():
	await get_tree().create_timer(1.5).timeout
	current_ml = 0.0
	kettle_clicked = false
	kettle.visible = true
	kettle_pov.visible = false
	pour_button.visible = false
	chawan.texture = chawan_frames[0]
	_update_display()
	instruction_label.text = "Tare the scale and try again."

func _on_complete():
	done = true
	kettle_pov.visible = false
	kettle.visible = true
	instruction_label.text = "%.0fml — perfect! Moving on..." % current_ml
	await get_tree().create_timer(1.5).timeout
	GameManager.complete_step(4)
	get_tree().change_scene_to_file("res://scenes/step_5_whisk.tscn")

# -------------------------------------------------------
# HELPERS
# -------------------------------------------------------
func _update_display():
	if not scale_on:
		display_label.text = ""
		unit_label.text = ""
		return
	display_label.text = "%.0f" % current_ml
	unit_label.text = "ml" if is_ml_mode else "g"

func _update_chawan():
	var progress = current_ml / MAX_ML
	var idx = min(int(progress * chawan_frames.size()), chawan_frames.size() - 1)
	chawan.texture = chawan_frames[idx]
