extends Node2D

# --- Constants ---
const HEAT_RATE: float = 8.0
const TARGET_MIN: float = 70.0
const TARGET_MAX: float = 80.0

# --- State ---
var current_temperature: float = 20.0
var is_heating: bool = false
var done: bool = false

# --- Node references ---
@onready var kettle: Sprite2D = $Kettle
@onready var temp_label: Label = $TempLabel
@onready var instruction_label: Label = $InstructionLabel
@onready var knob_button: TextureButton = $KnobButton

func _ready():
	temp_label.text = "20°C"
	instruction_label.text = "Press the knob to start heating. Stop between 70–80°C!"

func _process(delta):
	if done or not is_heating:
		return

	current_temperature += HEAT_RATE * delta
	current_temperature = min(current_temperature, 100.0)
	temp_label.text = "%.0f°C" % current_temperature

	if current_temperature >= 100.0:
		is_heating = false
		instruction_label.text = "Too hot! The water boiled. Try again."
		_reset()

func _on_knob_button_pressed():
	if done:
		return

	if not is_heating:
		is_heating = true
		instruction_label.text = "Heating... press again to stop!"
	else:
		is_heating = false
		if current_temperature >= TARGET_MIN and current_temperature <= TARGET_MAX:
			_on_complete()
		else:
			instruction_label.text = "%.0f°C is off! Target is 70–80°C. Try again." % current_temperature
			_reset()

func _reset():
	await get_tree().create_timer(1.5).timeout
	current_temperature = 20.0
	temp_label.text = "20°C"
	instruction_label.text = "Press the knob to start heating. Stop between 70–80°C!"

func _on_complete():
	done = true
	instruction_label.text = "%.0f°C — perfect! Moving on..." % current_temperature
	await get_tree().create_timer(1.5).timeout
	GameManager.complete_step(3)
	get_tree().change_scene_to_file("res://scenes/Step4_Pour_Water.tscn")
