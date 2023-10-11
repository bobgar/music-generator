extends Node2D

class_name MelodyPlayer

class Note:
	var Pitch:int
	var Duration:int

const OCTAVE_RANGE = 2

#var BPM = 120  TODO parameterize speed!
var BPM = 120
var sixteenthsPerSecond = 60.0 / BPM / 8.0
var violin = preload("res://violin-c3.wav")
var piano = preload("res://piano-c3.wav")
var guitar = preload("res://guitar-c3.wav")
var duduk = preload("res://duduk-c3.wav")
var trombone = preload("res://trombone-c3.wav")
var chroma = preload("res://fender-chroma-c3.wav")
var pan_flute = preload("res://pan-flute-c3.wav")
var instruments = []
var instrument_names = []

var notes:Array = []

@onready var player = $MelodyPlayer
@onready var chord1 = $ChordPlayer1
@onready var chord2 = $ChordPlayer2
@onready var drum = $Drum
@onready var drum2 = $Drum2
@onready var drum3 = $Drum3
@onready var main_insturment = $Panel/VBoxContainer/Main/MainInstrument
@onready var chord_insturment = $Panel/VBoxContainer/Chords/ChordInstrument

var audio_players:Array

var allowed_durations:Array = [1,2,4,8, 16]

#probabilities
var chance_of_chord:Array = [.95, .01, .1, .01, .4, .01, .1, .01, .8, .01, .1, .01, .4, .01, .1, .01]
var chance_of_note_at_subbeat:Array = [.95, .01, .025, .01, .4, .01, .025, .01, .8, .01,  .025, .01, .4, .01,  .025, .01]
var chance_of_change_dir:Array = [.2, .4, .6, .6, .6, .6, .6]
var chance_of_step:Array = [.3, .9, .95, .975, .9825, 1.0]

#scales
var major:Array = [0,2,4,5,7,9,11]
var minor:Array = [0,2,3,5,7,8,10]
var pentatonic:Array = [0,2,4,7,9]

var speeds:Array = []

var cumulative_duration:float = 0
var cur_note_index:int = 0

var is_playing:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	instruments = [piano, violin, trombone, guitar, duduk, chroma, pan_flute ] 
	instrument_names = ["piano", "violin", "trombone", "guitar", "duduk",  "chroma", "pan_flute"]
	for i in range(len(instrument_names)):
		main_insturment.add_item(instrument_names[i])
		chord_insturment.add_item(instrument_names[i])
	main_insturment.select(0)
	chord_insturment.select(1)
	
	audio_players = [player, chord1, chord2]
	var j:float = .5
	for i in range(0, 100):
		speeds.push_back(j )
		j = j * 1.05946
	generate_verse()
	
	update_main_instrument(main_insturment.get_selected_id())
	update_chords_instrument(chord_insturment.get_selected_id())	

func update_bpm(changed:bool=true):
	BPM = $Panel/VBoxContainer/HBoxContainer/BPM.value
	sixteenthsPerSecond =  60 / BPM / 8.0

func update_main_instrument(ind:int):
	player.stream = instruments[ind]
	pass
	
func update_chords_instrument(ind:int):
	chord1.stream = instruments[ind]
	chord2.stream = instruments[ind]
	pass

var cur_beat = 0

func _process(delta):
	if !is_playing:
		return
	
	cumulative_duration += delta
	if cumulative_duration >= sixteenthsPerSecond:
		cumulative_duration -= sixteenthsPerSecond
		for i in range(len(notes[cur_beat])):
			#TODO play different notes on different channels!
			_play_sound(notes[cur_beat][i].Pitch, audio_players[i])
			
		if cur_beat % 8 == 0:
			drum.play()
		#if (cur_beat+8) % 32 == 0:
			#drum2.play()
		if (cur_beat+8) % 16 == 0 && cur_beat <= 224:
			drum3.play()
		if (cur_beat + 4) % 64  == 0 && cur_beat <= 224:
			drum3.play()
		cur_beat += 1
		if cur_beat >= len(notes):
			cur_beat = 0

func play():
	is_playing = true
	cur_beat = 0
	cumulative_duration = 0

func stop():
	is_playing = false
	for i in range(len(audio_players)):
		audio_players[i].stop()

func _play_sound(p:int, a:AudioStreamPlayer):
	a.set_pitch_scale (speeds[p])
	a.play()

func generate_verse():
	notes = []
	var motif = _create_parameterized_bar()
	notes += motif
	var variant = _create_parameterized_bar(pentatonic, major, motif.slice(0,32), 32)
	notes += variant
	var turn = _create_parameterized_bar(pentatonic, major, [], 64, false)
	notes += turn
	#var variant2 = _create_parameterized_bar(pentatonic, major, motif.slice(0,31), 32, true, true)
	var variant2 = make_basic_end(pentatonic, major, motif.slice(0,32), 31 )
	notes += variant2
	cur_beat = 0
	cumulative_duration = 0

func make_basic_end(scale, chord_scale, note_array, generation_length):
	var note = Note.new()
	var cur_octave = 1
	note.Pitch = 12
	var notes_at_loc = [note]
	_add_chord(notes_at_loc, 0, cur_octave, chord_scale )
	note_array.append(notes_at_loc)
	for i in range(generation_length):
		note_array.append([])
	return note_array

func find_note_in_scale(scale:Array, pitch:int):
	for i in range(len(scale)):
		if pitch <= scale[i]:
			return i
	#we should always find it in the scale, but if we don't, return the highest note
	return len(scale) - 1

#Offset represents how much of the input to use
func _create_parameterized_bar(scale = pentatonic, chord_scale = major, note_array = [], generation_length = 64, force_root = true, pull_root_toward:int=0, pull_root_steps:int=0):		
	var cur_octave = 1
	var last_note = 0
	var cur_note = 0
	var dir = randi() % 2
	var steps_in_a_row = 0
	
	#Figure out last note if starting motif was passed in
	if len(note_array) > 0:
		for i in range (len(note_array)-1, 0, -1):
			if len(note_array[i]) > 0 :
				var last_pitch = note_array[i][0].Pitch
				cur_octave = last_pitch / 12
				last_note = find_note_in_scale(scale, last_pitch%12)
				break
	
	for i in range(generation_length):
		var notes_at_loc = []
		if (len(note_array)==0)  or randf() < chance_of_note_at_subbeat[i % len(chance_of_note_at_subbeat)]:
			var note = Note.new()
			
			if len(chance_of_change_dir) >= steps_in_a_row || randf() <= chance_of_change_dir[steps_in_a_row] :
				if dir == 0:
					dir = 1
				elif dir == 1:
					dir = 0
				steps_in_a_row = 0
			else:
				steps_in_a_row += 1
			print("dir: "+ str(dir ))
			if i == 0 && force_root == true:
				note.Pitch = (cur_octave * 12)
			elif i == 0:
				note.Pitch = (cur_octave * 12) + 7
				cur_note = find_note_in_scale(scale, 7)
			else:
				cur_note = last_note
				var step_size = _get_step_size()
				print("step_size: "+ str(step_size ))
				if dir == 0:
					cur_note -= step_size
					if cur_note < 0:
						if cur_octave > 0:
							cur_octave -= 1
							cur_note += len(scale)
						else:
							cur_note = 0
				elif dir == 1:
					cur_note += step_size
					if cur_note >= len(scale):
						if cur_octave < OCTAVE_RANGE:
							cur_octave += 1
							cur_note -= len(scale)
						else:
							cur_note = len(scale) -1
				last_note = cur_note
				note.Pitch = scale[cur_note] + (cur_octave * 12)
				print("Note: "+ str(cur_note) + "  octave: "+ str(cur_octave))				
			notes_at_loc.push_back(note)
			
			if randf() < chance_of_chord[i % len(chance_of_chord)]:
				_add_chord(notes_at_loc, scale[cur_note], cur_octave, chord_scale )
		note_array.push_back(notes_at_loc)
		
	if pull_root_steps > 0:
		for i in range (len(note_array)-1, 0, -1):
			if len(note_array[i]) > 0:
				for j in range(len(note_array[i])):
					note_array[i][j].Pitch = 12 + scale[j]
				break;
	return note_array

func _add_chord(note_location, root_note, octave, scale):	
	var chord_note = find_note_in_scale(scale, root_note)
				
	var note = Note.new()
	if chord_note+2 >= len(scale):
		note.Pitch = scale[chord_note+2 - len(scale)] + ((octave+1) * 12)
	else:
		note.Pitch = scale[chord_note+2] + (octave * 12)
	note_location.push_back(note)
	note = Note.new()
	if chord_note+4 >= len(scale):
		note.Pitch = scale[chord_note+4 - len(scale)] + ((octave+1) * 12)
	else:
		note.Pitch = scale[chord_note+4] + (octave * 12)
	note_location.push_back(note)

func _check_flip_dir(dir, steps_in_a_row):
	if randf() < chance_of_change_dir[steps_in_a_row] :
		if dir == 0:
			return 1
		if dir == 1:
			return 0
	return dir

func _get_step_size():
	var p = randf()
	for i  in range(len(chance_of_step)):
		if p <= chance_of_step[i]:
			return i
	return len(chance_of_step) -1


func toggle_effect(toggle_state:bool, channel:String, type:String):
	var channel_idx = 1
	if channel == "Chord":
		channel_idx = 2
	var type_idx = 0
	if type == "Chorus":
		type_idx = 1
	AudioServer.set_bus_effect_enabled(channel_idx, type_idx, toggle_state)

func change_volume(value, channel:String):
	var channel_idx = 1
	if channel == "Chord":
		channel_idx = 2
	value = sqrt(value)
	AudioServer.set_bus_volume_db(channel_idx, value - 80)
