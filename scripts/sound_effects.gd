class_name SoundEffects
extends Node

const PAPER_RUSTLE := preload("res://assets/audio/paper_rustle.wav")
const MOUSE_CLICK := preload("res://assets/audio/mouse_click.wav")
const ERROR_ALERT := preload("res://assets/audio/error_alert.wav")
const STAGE_SUCCESS := preload("res://assets/audio/stage_success.wav")
const STAGE_FAILURE := preload("res://assets/audio/stage_failure.wav")
const STAGE_ENTER := preload("res://assets/audio/stage_enter.wav")

var paper_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var error_player: AudioStreamPlayer
var result_player: AudioStreamPlayer
var transition_player: AudioStreamPlayer

func _ready() -> void:
	paper_player = make_player(PAPER_RUSTLE)
	click_player = make_player(MOUSE_CLICK, 6)
	error_player = make_player(ERROR_ALERT, 2)
	result_player = make_player(STAGE_SUCCESS, 2)
	transition_player = make_player(STAGE_ENTER, 2)

func make_player(stream: AudioStream, polyphony := 1) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	player.max_polyphony = polyphony
	add_child(player)
	return player

func play_paper() -> void:
	paper_player.play()

func play_click() -> void:
	click_player.play()

func play_error() -> void:
	error_player.play()

func play_success() -> void:
	result_player.stream = STAGE_SUCCESS
	result_player.play()

func play_failure() -> void:
	result_player.stream = STAGE_FAILURE
	result_player.play()

func play_stage_enter() -> void:
	transition_player.play()
