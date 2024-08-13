extends Node

# Saving system.
# Nodes should be part of the `persistable` group, and implement save_state() and load_state() methods
# that save/load a dictionary with the relevant data.
# Note, nodes must already be instanced before loading.

signal saved
signal loaded

const SAVE_GROUP = "persistable"
const SAVE_FILE = "user://global-game-jam-2024.json"

func save_game():
	var save_data = {}
	var save_nodes = get_tree().get_nodes_in_group(SAVE_GROUP)
	for node in save_nodes:
		assert(node.has_method("save_state"))

		save_data[node.get_path()] = node.save_state()

	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)

	save_file.store_line(JSON.stringify(save_data))
	save_file.close()

	emit_signal("saved")

func load_game():
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not FileAccess.file_exists(SAVE_FILE):
		return # Nothing to load

	var save_data = JSON.parse_string(save_file.get_as_text())
	save_file.close()

	# In case it didn't parse well.
	if !save_data:
		return
	for node_path in save_data.keys():
		var node = get_node(node_path)
		assert(node.has_method("load_state"))
		node.load_state(save_data[node_path])

	emit_signal("loaded")
