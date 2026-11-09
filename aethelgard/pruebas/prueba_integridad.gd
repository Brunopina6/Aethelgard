extends SceneTree
# Prueba de integridad del proyecto (09/11), sin ejecutar el juego:
#   1. Todos los scripts (.gd) del juego compilan y cargan.
#   2. Todas las escenas (.tscn) y recursos (.tres) cargan con sus dependencias (nada que falte ni roto).
#   3. Cada señal conectada dentro de una escena apunta a un método que existe en el nodo de destino (su script, la
#      herencia de su script o la clase nativa).
# No instancia escenas, así que no hay _ready ni efectos: solo lee. Quedan fuera addons/ (de terceros), pruebas/,
# prototipos/ y vegetacion_prueba/ (pruebas aisladas), y .godot/.

const FUERA := ["res://addons", "res://pruebas", "res://prototipos", "res://vegetacion_prueba", "res://.godot"]

var fallos: Array = []
var cuenta := {"gd": 0, "tscn": 0, "tres": 0, "conexiones": 0}


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _archivos(dir: String, salida: Array) -> void:
	for f in FUERA:
		if dir == f:
			return
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		if not sub.begins_with("."):
			_archivos(dir.path_join(sub), salida)
	for f in d.get_files():
		var ext := f.get_extension()
		if ext in ["gd", "tscn", "tres"]:
			salida.append(dir.path_join(f))


func _tiene_metodo(objetivo_script: Script, tipo: String, metodo: String) -> bool:
	var s := objetivo_script
	while s != null:
		for m in s.get_script_method_list():
			if m.name == metodo:
				return true
		s = s.get_base_script()
	if objetivo_script != null:
		tipo = objetivo_script.get_instance_base_type()
	return tipo != "" and ClassDB.class_has_method(tipo, metodo)


# Script y tipo del nodo «ruta» dentro del estado de la escena (solo nodos de esta escena; los de escenas instanciadas
# dentro no se resuelven aquí y se cuentan aparte).
func _nodo(estado: SceneState, ruta: NodePath) -> Dictionary:
	for i in estado.get_node_count():
		if estado.get_node_path(i) == ruta:
			var info := {"tipo": String(estado.get_node_type(i)), "script": null, "instancia": estado.get_node_instance(i)}
			for p in estado.get_node_property_count(i):
				if estado.get_node_property_name(i, p) == "script":
					info.script = estado.get_node_property_value(i, p)
			return info
	return {}


func _probar() -> void:
	var lista: Array = []
	_archivos("res://", lista)
	lista.sort()
	var sin_resolver := 0
	for ruta in lista:
		var ext: String = ruta.get_extension()
		var r = ResourceLoader.load(ruta, "", ResourceLoader.CACHE_MODE_REUSE)
		if r == null:
			_fallo("no carga: %s" % ruta)
			continue
		cuenta[ext] += 1
		if ext == "gd":
			if not (r as GDScript).can_instantiate() and not (r.has_method("is_abstract") and r.is_abstract()):
				_fallo("el script no compila o no se puede usar: %s" % ruta)
			continue
		if ext != "tscn":
			continue
		var estado: SceneState = (r as PackedScene).get_state()
		for c in estado.get_connection_count():
			cuenta.conexiones += 1
			var destino := _nodo(estado, estado.get_connection_target(c))
			var metodo := String(estado.get_connection_method(c))
			if destino.is_empty() or destino.instancia != null and destino.script == null:
				sin_resolver += 1                      # el destino está dentro de otra escena instanciada
				continue
			var sc: Script = destino.script if destino.script is Script else null
			var tipo: String = destino.tipo
			if tipo == "" and sc == null:
				sin_resolver += 1
				continue
			if not _tiene_metodo(sc, tipo, metodo):
				_fallo("%s: la señal «%s» de %s va a «%s» en %s, y ese método no existe" % [ruta,
						estado.get_connection_signal(c), estado.get_connection_source(c), metodo,
						estado.get_connection_target(c)])
	print("Revisados: %d scripts, %d escenas, %d recursos y %d conexiones (%d sin resolver: destino en otra escena)" % [
			cuenta.gd, cuenta.tscn, cuenta.tres, cuenta.conexiones, sin_resolver])
	if cuenta.gd < 50 or cuenta.tscn < 10:
		_fallo("se han encontrado muy pocos archivos (%d scripts, %d escenas): ¿ruta mal?" % [cuenta.gd, cuenta.tscn])
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
