extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var timer = $LetterDisplayTimer


const MAX_WIDTH = 256

var text = ""
var letter_index = 0

var letter_time = 0.03
var space_time = 0.06
var punctuation_time = 0.2

signal finished_displaying()

func display_text(speaker: String, text_to_display: String):
	timer.stop()  # Stop any leftover timer
	label.text = ""  # Clear text before typing starts
	text = text_to_display
	letter_index = 0

	_display_letter()

	
func _display_letter():
	# Make sure we don't go out of bounds
	if letter_index >= text.length():
		finished_displaying.emit()
		return

	# Add the current character
	label.text += text[letter_index]
	letter_index += 1

	# If we're now at the end, we're done
	if letter_index >= text.length():
		finished_displaying.emit()
		return

	# Now decide delay based on the NEXT character (but it's safe now)
	match text[letter_index]:
		".", ",", "!", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)


func _on_letter_display_timer_timeout() -> void:
	_display_letter()
	
func skip_to_end():
	if label.text == text:
		return  # Already done
	timer.stop()
	label.text = text
	finished_displaying.emit()
