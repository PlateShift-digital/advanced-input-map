@tool
extends Panel

signal binding_event_confirmed(binding: String, index: int, event: InputEvent)
signal binding_event_canceled()

@onready var input_preview: Label = $MarginContainer/VBoxContainer/InputPreview
@onready var shortcut_input: LineEdit = $MarginContainer/VBoxContainer/ShortcutInput
@onready var confirm: Button = $MarginContainer/VBoxContainer/HBoxContainer/Confirm
@onready var cancel: Button = $MarginContainer/VBoxContainer/HBoxContainer/Cancel

var _captured_input: InputEvent
var _binding: String
var _index: int


func _ready() -> void:
	set_process_input(false)
	shortcut_input.focus_entered.connect(func () -> void: set_process_input(true))
	shortcut_input.focus_exited.connect(func () -> void: set_process_input(false))
	confirm.pressed.connect(_on_confirm_pressed)
	cancel.pressed.connect(_on_cancel_pressed)

func show_binding_menu(binding: String, index: int, event: InputEvent) -> void:
	_binding = binding
	_index = index
	_captured_input = event
	_render_preview()
	show()
	shortcut_input.grab_focus()

func _process(_delta: float) -> void:
	set_process(false)
	input_preview.text = ''
	shortcut_input.text = ''

	if _captured_input is InputEvent:
		input_preview.text = _captured_input.as_text()
		shortcut_input.text = _captured_input.as_text()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		_captured_input = event

		set_process(true)

func _render_preview() -> void:
	input_preview.text = ''
	shortcut_input.text = ''

	if _captured_input is InputEvent:
		input_preview.text = _captured_input.as_text()
		shortcut_input.text = _captured_input.as_text()

func _on_confirm_pressed() -> void:
	binding_event_confirmed.emit(_binding, _index, _captured_input)

func _on_cancel_pressed() -> void:
	binding_event_canceled.emit()
