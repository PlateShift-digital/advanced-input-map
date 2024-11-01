@tool
extends VBoxContainer

signal list_changed()
signal group_removed(group_name: String)
signal group_renamed(old_name: String, new_name: String)

@onready var aim_tree_parent: PanelContainer = $PanelContainer
@onready var new_input: LineEdit = $HBoxContainer/AddNew
@onready var new_button: Button = $HBoxContainer/AddNewButton

var data: Dictionary
var remove_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Remove.svg')
var aim_tree: Tree
var root: TreeItem


func _ready() -> void:
	new_input.text_changed.connect(_on_new_input_text_changed)
	new_input.text_submitted.connect(_on_new_input_text_submitted)
	new_button.pressed.connect(_on_new_button_pressed)

	render()

func get_data() -> Dictionary:
	var new_data: Dictionary = {}

	root = aim_tree.get_root()
	for group: TreeItem in root.get_children():
		new_data[group.get_text(1)] = {
			'enabled': group.is_checked(0),
		}

	return new_data

#region: tree rendering
func render() -> void:
	if aim_tree:
		aim_tree.queue_free()
	aim_tree = Tree.new()
	aim_tree.item_edited.connect(_on_item_edited)
	aim_tree.button_clicked.connect(_on_button_clicked)

	aim_tree.column_titles_visible = true
	aim_tree.hide_root = true
	aim_tree.columns = 3
	aim_tree.set_column_title(0, 'Enabled')
	aim_tree.set_column_expand(0, false)
	aim_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	aim_tree.set_column_title(1, 'Group Name')
	aim_tree.set_column_expand(1, true)
	aim_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	aim_tree.set_column_expand(2, false)

	var root: TreeItem = aim_tree.create_item()

	for key in data:
		add_group_item(root, key, data[key])

	aim_tree_parent.add_child(aim_tree)

func add_group_item(parent: TreeItem, key: String, group: Dictionary) -> void:
	var item: TreeItem = aim_tree.create_item(parent)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_checked(0, group.enabled)
	item.set_editable(0, true)

	item.set_text(1, key)
	item.set_metadata(1, key)
	item.set_editable(1, true)

	item.add_button(2, remove_texture)
#endregion

#region: tree events
func get_key_sorted_dict(dictionary: Dictionary) -> Dictionary:
	var new_dict: Dictionary = {}
	var keys: Array = dictionary.keys()
	keys.sort()
	for key in keys:
		new_dict[key] = dictionary[key]
	return new_dict

func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if column == 2:
		var group_name: String = item.get_text(1)
		data.erase(item.get_text(1))
		render()
		group_removed.emit(group_name)

func _on_item_edited() -> void:
	var item: TreeItem = aim_tree.get_edited()
	var column: int = aim_tree.get_edited_column()

	if column == 0:
		data[item.get_text(1)].enabled = item.is_checked(column)
		render()
		list_changed.emit()
	if column == 1:
		if data.has(item.get_text(column)):
			render()
			return

		data[item.get_text(1)] = data[item.get_metadata(1)]
		data.erase(item.get_metadata(1))
		data = get_key_sorted_dict(data)
		render()
		group_renamed.emit(item.get_metadata(1), item.get_text(1))
#endregion

#region: input form events
func _on_new_input_text_changed(new_text: String) -> void:
	if new_text != '' and not data.has(new_text):
		new_button.disabled = false
	else:
		new_button.disabled = true

func _on_new_input_text_submitted(new_text: String) -> void:
	if new_text != '' and not data.has(new_text):
		_on_new_button_pressed()

func _on_new_button_pressed() -> void:
	if data.has(new_input.text):
		new_input.text = ''
		new_input.text_changed.emit('')
		return

	data[new_input.text] = {
		'enabled': false
	}
	new_input.text = ''
	new_input.text_changed.emit('')
	render()
	list_changed.emit()
#endregion
