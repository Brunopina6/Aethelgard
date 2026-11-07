extends SceneTree
# Prueba del plugin Posador (addons/posador) con Kael, sin abrir el editor.
# Uso (desde D:\Aethelgard):
#   "<ruta>\Godot_v4.7.2-stable_win64_console.exe" --headless --path aethelgard --script res://pruebas/prueba_posador.gd
# Comprueba: IK de manos y pies, polo del codo, objetivo inalcanzable, cadera con pies anclados,
# grabación de fotogramas, guardado en librería y que la animación reproduce la pose grabada.

const LIBRERIA := "user://prueba_posador.res"

var escena: Node
var sk: Skeleton3D
var ik: PosadorIK
var ap: AnimationPlayer
var fallos := 0
var paso := 0
var global := {}          # nombre de hueso corto -> posición final en el mundo (tras los modificadores)
var esperado := {}        # tiempo -> posición de la mano izquierda grabada
var anims_originales: PackedStringArray
var anim: Animation
var largo_brazo := 0.0
var largo_brazo_d := 0.0
var cadera_ini := Vector3.ZERO


const COMPROBACIONES := 17   # si falta alguna (p. ej. por un error de script) la prueba falla
var hechas := 0


func _initialize() -> void:
	escena = load("res://prototipos/posador_prueba.tscn").instantiate()
	root.add_child(escena)


# Se prepara en el primer fotograma, cuando la escena ya está dentro del árbol.
func _preparar() -> void:
	sk = escena.get_node("Kael/SmartRigArmature/Skeleton3D")
	ik = sk.get_node("PosadorIK")
	ap = escena.get_node("Kael/AnimationPlayer")
	anims_originales = ap.get_animation_list()
	sk.skeleton_updated.connect(_capturar)
	ik.crear_objetivos()

	var w := sk.global_transform
	var hombro: Vector3 = sk.get_bone_global_pose(ik.idx["brazo_i"]).origin
	var codo: Vector3 = sk.get_bone_global_pose(ik.idx["antebrazo_i"]).origin
	var mano: Vector3 = sk.get_bone_global_pose(ik.idx["mano_i"]).origin
	largo_brazo = hombro.distance_to(codo) + codo.distance_to(mano)
	var hombro_d: Vector3 = sk.get_bone_global_pose(ik.idx["brazo_d"]).origin
	largo_brazo_d = hombro_d.distance_to(sk.get_bone_global_pose(ik.idx["antebrazo_d"]).origin) \
		+ sk.get_bone_global_pose(ik.idx["antebrazo_d"]).origin.distance_to(sk.get_bone_global_pose(ik.idx["mano_d"]).origin)

	# mano izquierda: delante y abajo, al 80 % del largo del brazo
	var dir := Vector3(0.3, -0.6, 0.75).normalized()
	ik.objetivo("mano_i").global_position = w * (hombro + dir * largo_brazo * 0.8)
	ik.objetivo("codo_i").global_position = w * (codo + Vector3(0, -0.1, -0.3))
	# mano derecha: inalcanzable (2 m a la derecha del personaje)
	ik.objetivo("mano_d").global_position = w * (hombro_d + Vector3(-2.0, 0.0, 0.0))
	# cadera 15 cm más baja; los objetivos de los pies se quedan donde estaban
	cadera_ini = (w * sk.get_bone_global_pose(ik.idx["cadera"])).origin
	ik.objetivo("cadera").global_position = cadera_ini + Vector3(0, -0.15, 0)


func _capturar() -> void:
	var w := sk.global_transform
	for k in ["cadera", "brazo_i", "antebrazo_i", "mano_i", "brazo_d", "mano_d", "pie_i", "pie_d"]:
		global[k] = (w * sk.get_bone_global_pose(ik.idx[k])).origin


func _comprobar(nombre: String, ok: bool, detalle := "") -> void:
	hechas += 1
	print(("OK    " if ok else "FALLO ") + nombre + ("  " + detalle if detalle else ""))
	if not ok:
		fallos += 1


func _process(_d: float) -> bool:
	paso += 1
	match paso:
		1:
			_preparar()
		4:
			_comprobar_ik()
			anim = PosadorGrabador.nueva_animacion(0.0)
			var ruta := PosadorGrabador.ruta_esqueleto(ap, sk)
			_comprobar("ruta de pistas", ruta == "SmartRigArmature/Skeleton3D", ruta)
			var n := PosadorGrabador.grabar_fotograma(anim, ik, ruta, 0.0)
			_comprobar("claves del fotograma 0", n == sk.get_bone_count() + 1, str(n))
			esperado[0.0] = global["mano_i"]
			# segunda pose: mano izquierda arriba
			var hombro: Vector3 = sk.get_bone_global_pose(ik.idx["brazo_i"]).origin
			ik.objetivo("mano_i").global_position = sk.global_transform * (hombro + Vector3(0.2, 0.9, 0.3).normalized() * largo_brazo * 0.85)
		7:
			var ruta := PosadorGrabador.ruta_esqueleto(ap, sk)
			PosadorGrabador.grabar_fotograma(anim, ik, ruta, 0.5)
			esperado[0.5] = global["mano_i"]
			_comprobar("dos fotogramas", PosadorGrabador.tiempos(anim) == PackedFloat32Array([0.0, 0.5]), str(PosadorGrabador.tiempos(anim)))
			_comprobar("duración 0,5 s", is_equal_approx(anim.length, 0.5), str(anim.length))
			_comprobar("pistas (66 giros + cadera)", anim.get_track_count() == sk.get_bone_count() + 1, str(anim.get_track_count()))
			var err := PosadorGrabador.guardar(anim, "prueba", LIBRERIA)
			_comprobar("guardar librería", err == OK, error_string(err))
			var lib := ResourceLoader.load(LIBRERIA, "", ResourceLoader.CACHE_MODE_IGNORE) as AnimationLibrary
			_comprobar("librería recargada", lib != null and lib.has_animation("prueba"))
			# reproducir sin el posador
			ik.active = false
			ap.add_animation_library("posador", lib)
			ap.play("posador/prueba")
			ap.seek(0.5, true)
			ap.pause()
		10:
			var e: float = global["mano_i"].distance_to(esperado[0.5])
			_comprobar("reproducción t=0,5 igual a lo grabado", e < 0.01, "%.4f m" % e)
			ap.seek(0.0, true)
		13:
			var e: float = global["mano_i"].distance_to(esperado[0.0])
			_comprobar("reproducción t=0 igual a lo grabado", e < 0.01, "%.4f m" % e)
			var siguen := true
			for a in anims_originales:
				siguen = siguen and ap.has_animation(a)
			_comprobar("animaciones de Meshy intactas", siguen, str(anims_originales.size()) + " animaciones")
			_comprobar("todas las comprobaciones se ejecutaron", hechas + 1 == COMPROBACIONES, "%d de %d" % [hechas + 1, COMPROBACIONES])
			print("RESULTADO: ", "TODO OK" if fallos == 0 else "%d FALLOS" % fallos)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(LIBRERIA))
			escena.queue_free()
			return true
	return false


func _comprobar_ik() -> void:
	# mano izquierda en su objetivo
	var obj_i := ik.objetivo("mano_i").global_position
	var e_i: float = global["mano_i"].distance_to(obj_i)
	_comprobar("mano izquierda llega al objetivo", e_i < 0.01, "%.4f m" % e_i)
	# el codo se dobla hacia su polo
	var a: Vector3 = global["brazo_i"]
	var eje := (obj_i - a).normalized()
	var lado_codo: Vector3 = (global["antebrazo_i"] - a)
	lado_codo -= eje * lado_codo.dot(eje)
	var lado_polo := ik.objetivo("codo_i").global_position - a
	lado_polo -= eje * lado_polo.dot(eje)
	var c := lado_codo.normalized().dot(lado_polo.normalized())
	_comprobar("codo hacia el polo", c > 0.9, "coseno %.3f" % c)
	# mano derecha inalcanzable: brazo estirado hacia el objetivo, sin NaN
	var obj_d := ik.objetivo("mano_d").global_position
	var hd: Vector3 = global["mano_d"]
	var hombro_d: Vector3 = global["brazo_d"]
	var alineado := (hd - hombro_d).normalized().dot((obj_d - hombro_d).normalized())
	var estirado := hombro_d.distance_to(hd) / largo_brazo_d
	_comprobar("mano derecha inalcanzable: estirada hacia el objetivo",
		not is_nan(hd.x) and alineado > 0.999 and estirado > 0.99, "alineado %.4f, estirado %.3f" % [alineado, estirado])
	# cadera bajada y pies anclados
	var bajada: float = cadera_ini.y - global["cadera"].y
	_comprobar("cadera baja 15 cm", absf(bajada - 0.15) < 0.005, "%.3f m" % bajada)
	for p in ["pie_i", "pie_d"]:
		var e: float = global[p].distance_to(ik.objetivo(p).global_position)
		_comprobar("%s anclado" % p, e < 0.01, "%.4f m" % e)
