extends SceneTree
# La capa de Garon en las regiones 3D (Pastos Verdes, Oakhaven y Gran Bosque), con su luz y su cámara de juego, y en
# un primer plano desde atrás. Con ventana y datos aislados:
#   --script res://pruebas/fotos_capa_garon_regiones.gd --fixed-fps 30 -- salida=<carpeta> 3d sin_prologo [version=v2]
# En cada región: espera a que Garon (que sigue a Kael) esté en su sitio y lo fotografía quieto, andando y corriendo
# en el sitio (sus clips de siempre), con la cámara del juego y con un primer plano de espaldas a 3/4.

const REGIONES := ["res://zonas3d/pastos_verdes_3d.tscn", "res://zonas3d/oakhaven_3d.tscn", "res://zonas3d/gran_bosque_3d.tscn"]
const POSES := [["reposo", 60], ["andar", 25], ["correr", 25]]

var salida := ""
var version := ""
var ri := -1
var fase := 0
var espera := 0
var g: Node3D
var vp: SubViewport
var cam: Camera3D
var intentos := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("version="):
			version = a.substr(8)
	if version != "":
		Engine.set_meta("heroes_version", version)
		Engine.set_meta("heroes_v2", version != "originales")
		Engine.set_meta("heroes_v3", version == "v3")
	if salida == "":
		salida = OS.get_user_data_dir().path_join("capa_garon_regiones")
	DirAccess.make_dir_recursive_absolute(salida)
	_siguiente.call_deferred()


func _siguiente() -> void:
	ri += 1
	if ri >= REGIONES.size():
		quit(0)
		return
	g = null
	intentos = 0
	fase = -1
	espera = 150
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])   # (Pastos lo deja en «Kael solo»: inicio de su misión)
	change_scene_to_file(REGIONES[ri])


func _process(_d: float) -> bool:
	if current_scene == null:
		return false
	if current_scene.get("pasos") != null:
		current_scene.pasos = 0                        # (sin encuentros)
	if g != null and is_instance_valid(g) and cam != null:
		_seguir()
	if espera > 0:
		espera -= 1
		return false
	if g == null:
		var cands := current_scene.find_children("Garon", "Node3D", true, false)
		var gr = current_scene.get("grupo")
		if cands.is_empty() and gr != null and gr.get("miembros") != null:
			for m in gr.miembros:
				if m.get("nombre", "") == "Garon" and is_instance_valid(m["nodo"]):
					cands = [m["nodo"]]
		if cands.is_empty():
			intentos += 1
			if intentos < 20:                        # (las regiones grandes tardan en poner al grupo)
				espera = 30
				return false
			print("SIN GARON en ", REGIONES[ri], " (", current_scene.name, ") miembros: ", (gr.miembros.map(func(x): return x["nombre"]) if gr != null else []), " activos: ", load("res://grupo.gd").activos())
			_siguiente()
			return false
		g = cands[0]
		_primer_plano()
		fase = 0
		_pose()
		return false
	_foto()
	fase += 1
	if fase >= POSES.size():
		vp.queue_free()
		_siguiente()
	else:
		_pose()
	return false


func _pose() -> void:
	var p: Array = POSES[fase]
	match p[0]:
		"reposo":
			g.reposo()
		"andar":
			g.andar()
		"correr":
			g.correr()
	espera = p[1]


func _primer_plano() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(420, 520)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	vp.world_3d = current_scene.get_viewport().world_3d
	cam = Camera3D.new()
	cam.fov = 35.0
	vp.add_child(cam)


func _foto() -> void:
	var nombre: String = "%s_%s_%s" % [version if version != "" else "por_defecto", REGIONES[ri].get_file().get_basename(), POSES[fase][0]]
	root.get_viewport().get_texture().get_image().save_png(salida.path_join(nombre + "_juego.png"))
	vp.get_texture().get_image().save_png(salida.path_join(nombre + "_espalda.png"))
	print("FOTO ", nombre)


# El primer plano sigue a Garon cada fotograma (de espaldas a 3/4, a su altura).
func _seguir() -> void:
	var pie: Vector3 = g.global_position
	var adelante: Vector3 = g.get("ajuste").global_transform.basis.z.normalized() if g.get("ajuste") != null else Vector3.FORWARD
	adelante.y = 0.0
	if adelante.length() < 0.01:
		adelante = Vector3.FORWARD
	adelante = adelante.normalized()
	var lado := adelante.cross(Vector3.UP).normalized()
	var alto: float = 1.7 * g.global_transform.basis.get_scale().y
	cam.look_at_from_position(pie - adelante * 2.6 * alto + lado * 1.2 * alto + Vector3.UP * 1.4 * alto, pie + Vector3.UP * 0.55 * alto)
