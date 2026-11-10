extends SceneTree
# Auditoría de recursos (10/11, fases 5 y 7 de la auditoría): sin ventana y sin cambiar nada.
#   1. HUÉRFANOS: archivos de recursos (imágenes, modelos, audio, escenas…) de los que no depende ningún otro recurso
#      (ResourceLoader.get_dependencies) ni aparecen por su ruta o nombre en ningún script, escena, recurso o diálogo.
#      Son candidatos a no precargarse ni exportarse (no se borran: se revisan a mano).
#   2. REFERENCIAS ROTAS: rutas «res://…» que no existen. En escenas y recursos (.tscn, .tres) son roturas de verdad
#      (la escena no cargaría). En scripts suelen ser alternativas opcionales (se prueban con ResourceLoader.exists):
#      se listan aparte para revisarlas.
# Uso: Godot --headless --path aethelgard -s res://pruebas/auditar_recursos.gd [-- salida=<archivo.txt>]
# Código de salida: 1 si alguna escena o recurso apunta a un archivo que no existe.

const EXT_RECURSO := ["png", "jpg", "jpeg", "webp", "svg", "fbx", "glb", "gltf", "obj", "tscn", "scn", "mp3", "ogg",
	"wav", "gdshader", "tres", "res", "ttf", "otf", "dtl", "dch"]
const EXT_TEXTO := ["gd", "tscn", "tres", "dtl", "dch", "cfg", "godot", "json", "import"]
const IGNORAR := ["res://.godot", "res://addons", "res://pruebas", "res://para_meshy"]

var todos: PackedStringArray = []                    # recursos
var textos: PackedStringArray = []                   # archivos de texto donde buscar rutas


func _initialize() -> void:
	_recorrer("res://")
	var usados := {}
	for r in todos:                                  # dependencias reales de Godot
		for dep in ResourceLoader.get_dependencies(r):
			var p := String(dep).get_slice("::", 2) if "::" in String(dep) else String(dep)
			if p.begins_with("uid://"):
				var id := ResourceUID.text_to_id(p)
				p = ResourceUID.get_id_path(id) if ResourceUID.has_id(id) else p
			usados[p] = true
	var texto_total := ""
	for t in textos:
		texto_total += FileAccess.get_file_as_string(t) + "\n"
	var huerfanos: Array = []
	for r in todos:
		if usados.has(r) or r in texto_total or r.get_file() in texto_total or r.get_file().get_basename() + "." in texto_total:
			continue
		huerfanos.append(r)
	var rotas: Array = []
	var revisar: Array = []
	var re := RegEx.create_from_string("res://[A-Za-z0-9_./ áéíóúñÁÉÍÓÚÑ-]+\\.[A-Za-z0-9]+")
	for t in textos:
		if t.ends_with(".import"):
			continue
		for m in re.search_all(FileAccess.get_file_as_string(t)):
			var ruta := m.get_string()
			if not ResourceLoader.exists(ruta) and not FileAccess.file_exists(ruta) and not DirAccess.dir_exists_absolute(ruta):
				if t.get_extension() in ["tscn", "tres"]:
					rotas.append("%s → %s" % [t, ruta])
				elif not "%s → %s" % [t, ruta] in revisar:
					revisar.append("%s → %s" % [t, ruta])
	var lineas: Array = []
	lineas.append("AUDITORÍA DE RECURSOS: %d recursos, %d archivos de texto" % [todos.size(), textos.size()])
	lineas.append("HUÉRFANOS (nadie los carga ni los nombra): %d" % huerfanos.size())
	for h in huerfanos:
		var f := FileAccess.open(h, FileAccess.READ)
		lineas.append("  %7.1f KB  %s" % [(f.get_length() if f != null else 0) / 1024.0, h])
	lineas.append("REFERENCIAS ROTAS en escenas y recursos: %d" % rotas.size())
	for r in rotas:
		lineas.append("  " + r)
	lineas.append("RUTAS QUE NO EXISTEN en scripts (revisar: suelen ser alternativas opcionales): %d" % revisar.size())
	for r in revisar:
		lineas.append("  " + r)
	var salida := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	for l in lineas:
		print(l)
	if salida != "":
		var f := FileAccess.open(salida, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lineas) + "\n")
	quit(1 if not rotas.is_empty() else 0)


func _recorrer(carpeta: String) -> void:
	for i in IGNORAR:
		if carpeta.begins_with(i):
			return
	var d := DirAccess.open(carpeta)
	if d == null:
		return
	for sub in d.get_directories():
		if not sub.begins_with(".") and not FileAccess.file_exists(carpeta.path_join(sub).path_join(".gdignore")):
			_recorrer(carpeta.path_join(sub))
	for f in d.get_files():
		var ext := f.get_extension().to_lower()
		var ruta := carpeta.path_join(f)
		if ext in EXT_RECURSO:
			todos.append(ruta)
		if ext in EXT_TEXTO:
			textos.append(ruta)
