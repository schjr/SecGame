class_name ProcessManager
extends RefCounted

var processes: Dictionary = {}
var next_pid := 2400

func start(
	name: String,
	path: String,
	app_paths: Dictionary,
	killable := true,
	path_visible := true,
	cpu := -1.0,
	window_id := ""
) -> int:
	for process in processes.values():
		if not window_id.is_empty() and process.window_id == window_id:
			return int(process.pid)
		if window_id.is_empty() and process.name == name:
			return int(process.pid)
	next_pid += randi_range(7, 31)
	var app_id := ""
	for id in app_paths:
		if app_paths[id] == path:
			app_id = id
	processes[next_pid] = {
		"pid": next_pid,
		"name": name,
		"path": path,
		"killable": killable,
		"path_visible": path_visible,
		"cpu": cpu if cpu >= 0 else randf_range(0.5, 6.0),
		"app_id": app_id,
		"window_id": window_id
	}
	return next_pid

func remove_for_window(window_id: String) -> void:
	for pid in processes.keys():
		if processes[pid].window_id == window_id:
			processes.erase(pid)

func remove_for_path(path: String) -> void:
	for pid in processes.keys():
		if processes[pid].path == path:
			processes.erase(pid)

func has_path(path: String, include_descendants := false) -> bool:
	var folder_prefix := path.trim_suffix("\\") + "\\"
	for process in processes.values():
		if process.path == path:
			return true
		if include_descendants and String(process.path).begins_with(folder_prefix):
			return true
	return false

func total_cpu() -> float:
	var total := 0.0
	for process in processes.values():
		total += float(process.cpu)
	return total
