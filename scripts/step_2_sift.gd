extends Node2D

# --- Constants ---
const HOVER_RADIUS: float = 80.0
const REQUIRED_STROKES: int = 12
const MIN_MOVE_DISTANCE: float = 8.0

# --- State ---
var strokes: int = 0
var last_y: float = 0.0
var moving_down: bool = true
var is_over_sifter: bool = false

# --- Node references ---
@onready var chashaku: Sprite2D = $Chashaku
@onready var sifter: Sprite2D = $Sift1
@onready var chawan: Sprite2D = $Chawan
@onready var instruction_label: Label = $InstructionLabel

# Sifter frames during sifting (matcha building up on sifter)
var sifter_frames: Array[Texture2D] = [
	preload("res://assets/sift1.png"),
	preload("res://assets/sift2.png"),
	preload("res://assets/sift3.png"),
]

# Shown only when all strokes are done
var sifter_empty: Texture2D = preload("res://assets/sift_empty.png")

# Chawan frames: empty → building up
var chawan_frames: Array[Texture2D] = [
	preload("res://assets/chawan_empty.png"),
	preload("res://assets/chawan_sift1.png"),
	preload("res://assets/chawan_sift2.png"),
	preload("res://assets/chawan_sift3.png"),
]

func _ready():
	MusicManager.play_bgm(preload("res://assets/audios/cafe.mp3"))
	chashaku.texture = preload("res://assets/chashaku.png")
	sifter.texture = sifter_frames[0]
	chawan.texture = chawan_frames[0]
	instruction_label.text = "Hover over the sifter and move up and down to sift the matcha."

func _process(_delta):
	chashaku.global_position = get_global_mouse_position()
	is_over_sifter = get_global_mouse_position().distance_to(sifter.global_position) < HOVER_RADIUS

func _input(event):
	if event is InputEventMouseMotion and is_over_sifter:
		var current_y = event.position.y
		var delta_y = current_y - last_y

		if delta_y > MIN_MOVE_DISTANCE and not moving_down:
			moving_down = true
			_register_stroke()
		elif delta_y < -MIN_MOVE_DISTANCE and moving_down:
			moving_down = false
			_register_stroke()

		last_y = current_y

func _register_stroke():
	strokes = min(strokes + 1, REQUIRED_STROKES)

	var progress = float(strokes) / float(REQUIRED_STROKES)

	# Sifter: only cycle through sift1/2/3, NOT the empty one yet
	var sifter_index = min(int(progress * sifter_frames.size()), sifter_frames.size() - 1)
	sifter.texture = sifter_frames[sifter_index]

	# Chawan: fill up as strokes increase
	var chawan_index = min(int(progress * chawan_frames.size()), chawan_frames.size() - 1)
	chawan.texture = chawan_frames[chawan_index]

	var remaining = REQUIRED_STROKES - strokes
	if remaining > 0:
		instruction_label.text = "Keep sifting! %d strokes left." % remaining
	else:
		_on_complete()

func _on_complete():
	# Now show the empty sifter — all matcha has passed through
	sifter.texture = sifter_empty
	chawan.texture = chawan_frames[chawan_frames.size() - 1]
	instruction_label.text = "Matcha sifted! Moving on..."
	chashaku.visible = false
	await get_tree().create_timer(1.5).timeout
	GameManager.complete_step(2)
	get_tree().change_scene_to_file("res://scenes/step_3_heat_water.tscn")
