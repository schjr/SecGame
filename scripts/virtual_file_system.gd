class_name VirtualFileSystem
extends RefCounted

var items: Dictionary = {
	"C:\\": {"name":"Local Disk (C:)", "type":"Disk", "kind":"disk", "path":"C:\\", "deletable":true, "children":["C:\\System", "C:\\Profiles"]},
	"C:\\System": {"name":"System", "type":"Folder", "kind":"folder", "path":"C:\\System", "deletable":true, "children":["C:\\System\\kernel32.sys", "C:\\System\\svchost.exe", "C:\\System\\netservice.dll", "C:\\System\\securityd.exe"]},
	"C:\\System\\kernel32.sys": {"name":"kernel32.sys", "type":"System file", "kind":"file", "path":"C:\\System\\kernel32.sys", "deletable":true},
	"C:\\System\\svchost.exe": {"name":"svchost.exe", "type":"Executable", "kind":"executable", "path":"C:\\System\\svchost.exe", "deletable":true},
	"C:\\System\\netservice.dll": {"name":"netservice.dll", "type":"Program library", "kind":"program", "path":"C:\\System\\netservice.dll", "deletable":true},
	"C:\\System\\securityd.exe": {"name":"securityd.exe", "type":"Executable", "kind":"executable", "path":"C:\\System\\securityd.exe", "deletable":true},
	"C:\\Profiles": {"name":"Profiles", "type":"Folder", "kind":"folder", "path":"C:\\Profiles", "deletable":true, "children":["C:\\Profiles\\User"]},
	"C:\\Profiles\\User": {"name":"User", "type":"Folder", "kind":"folder", "path":"C:\\Profiles\\User", "deletable":true, "children":["C:\\Profiles\\User\\user.dat", "C:\\Profiles\\User\\settings.ini", "C:\\Profiles\\User\\login_helper.exe"]},
	"C:\\Profiles\\User\\user.dat": {"name":"user.dat", "type":"Profile data", "kind":"file", "path":"C:\\Profiles\\User\\user.dat", "deletable":true},
	"C:\\Profiles\\User\\settings.ini": {"name":"settings.ini", "type":"Text configuration", "kind":"text", "path":"C:\\Profiles\\User\\settings.ini", "deletable":true},
	"C:\\Profiles\\User\\login_helper.exe": {"name":"login_helper.exe", "type":"Executable", "kind":"executable", "path":"C:\\Profiles\\User\\login_helper.exe", "deletable":true},
	"D:\\": {"name":"Data Disk (D:)", "type":"Disk", "kind":"disk", "path":"D:\\", "deletable":true, "children":["D:\\Photos", "D:\\Documents"]},
	"D:\\Photos": {"name":"Photos", "type":"Folder", "kind":"folder", "path":"D:\\Photos", "deletable":true, "children":["D:\\Photos\\beach.jpg", "D:\\Photos\\family.png", "D:\\Photos\\cat.jpg"]},
	"D:\\Photos\\beach.jpg": {"name":"beach.jpg", "type":"JPEG photo", "kind":"photo", "path":"D:\\Photos\\beach.jpg", "deletable":true},
	"D:\\Photos\\family.png": {"name":"family.png", "type":"PNG photo", "kind":"photo", "path":"D:\\Photos\\family.png", "deletable":true},
	"D:\\Photos\\cat.jpg": {"name":"cat.jpg", "type":"JPEG photo", "kind":"photo", "path":"D:\\Photos\\cat.jpg", "deletable":true},
	"D:\\Documents": {"name":"Documents", "type":"Folder", "kind":"folder", "path":"D:\\Documents", "deletable":true, "children":["D:\\Documents\\project_notes.txt", "D:\\Documents\\budget.pdf", "D:\\Documents\\meeting.docx"]},
	"D:\\Documents\\project_notes.txt": {"name":"project_notes.txt", "type":"Text document", "kind":"text", "path":"D:\\Documents\\project_notes.txt", "deletable":true},
	"D:\\Documents\\budget.pdf": {"name":"budget.pdf", "type":"PDF document", "kind":"document", "path":"D:\\Documents\\budget.pdf", "deletable":true},
	"D:\\Documents\\meeting.docx": {"name":"meeting.docx", "type":"Word document", "kind":"document", "path":"D:\\Documents\\meeting.docx", "deletable":true}
}

func ensure_folder(parent_path: String, folder_path: String, folder_name: String) -> void:
	if not items.has(folder_path):
		items[folder_path] = {
			"name": folder_name,
			"type": "Folder",
			"kind": "folder",
			"path": folder_path,
			"deletable": true,
			"children": []
		}
	if items.has(parent_path) and folder_path not in items[parent_path]["children"]:
		items[parent_path]["children"].append(folder_path)

func remove_recursive(path: String) -> void:
	if not items.has(path):
		return
	var children: Array = items[path].get("children", []).duplicate()
	for child_path in children:
		remove_recursive(child_path)
	items.erase(path)
	for item in items.values():
		if item.has("children"):
			item.children.erase(path)

func collect_subtree(path: String) -> Dictionary:
	var snapshot: Dictionary = {}
	if not items.has(path):
		return snapshot
	snapshot[path] = items[path].duplicate(true)
	for child_path in items[path].get("children", []):
		snapshot.merge(collect_subtree(child_path), true)
	return snapshot

func find_non_deletable(path: String) -> String:
	if not items.has(path):
		return ""
	if not items[path].get("deletable", false):
		return path
	for child_path in items[path].get("children", []):
		var protected_path := find_non_deletable(child_path)
		if not protected_path.is_empty():
			return protected_path
	return ""

func find_parent(path: String) -> String:
	for candidate_path in items:
		if path in items[candidate_path].get("children", []):
			return candidate_path
	return ""

func restore_subtree(snapshot: Dictionary, parent_path: String, root_path: String) -> void:
	for path in snapshot:
		items[path] = snapshot[path].duplicate(true)
	if items.has(parent_path) and root_path not in items[parent_path].get("children", []):
		items[parent_path]["children"].append(root_path)
