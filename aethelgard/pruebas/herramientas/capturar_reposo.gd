extends SceneTree
# Esperas de exploración (personalidad de los héroes), paso 1 de 3: la pose de reposo TAL COMO SE VE en la exploración
# 3D (el clip de reposo más los gestos de gestos_3d.gd: brazos relajados, sable al hombro…), para que Blender parta de
# ella y las esperas empiecen y acaben exactamente ahí (sin saltos al mezclar).
#   godot --headless --path aethelgard --script res://pruebas/herramientas/capturar_reposo.gd -- salida=<carpeta>
# Escribe <carpeta>/reposo_<heroe>.json con, por hueso y en el espacio del esqueleto: el reposo global (rest) y la pose
# global ya con los gestos aplicados (posición y giro). Blender (animaciones/esperas/fuentes/esperas.py) lo lee.
# Sin respiración (va encima en el juego) y con el clip de reposo parado en su segundo 0.

const HEROES := {"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}

const CAPTURA := """
extends SkeletonModifier3D
var pose := []
func _process_modification() -> void:
	var sk := get_skeleton()
	pose.clear()
	for i in sk.get_bone_count():
		pose.append(sk.get_bone_global_pose(i))
"""

var salida := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	if salida == "":
		printerr("Falta salida=<carpeta>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(salida)
	_capturar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _capturar() -> void:
	var fallos := 0
	for h in HEROES:
		var c = load(HEROES[h]).new()
		c.name = h
		root.add_child(c)
		await _esperar(4)
		if c.get("skel") == null:
			printerr("FALLO: %s sin esqueleto" % h)
			fallos += 1
			continue
		if h == "Garon":                       # su reposo de exploración (grupo_3d.gd): la guardia tranquila
			var lib: AnimationLibrary = c.anim.get_animation_library("")
			if not lib.has_animation("Calma"):
				var calma: Animation = c._guardia_viva("Juicio")
				calma.loop_mode = Animation.LOOP_LINEAR
				lib.add_animation("Calma", calma)
			c.play("Calma", 0.0)
		await _esperar(40)                     # que los gestos lleguen a su peso (0,3 s) y el sable se calibre
		c.gestos.respirar = 0.0
		c.anim.seek(0.0, true)
		c.anim.speed_scale = 0.0
		var cap := SkeletonModifier3D.new()
		var s := GDScript.new()
		s.source_code = CAPTURA
		s.reload()
		cap.set_script(s)
		c.skel.add_child(cap)                  # el último: después de gestos_3d.gd
		await _esperar(6)
		var sk: Skeleton3D = c.skel
		var huesos := []
		for i in sk.get_bone_count():
			var r := sk.get_bone_global_rest(i)
			var p: Transform3D = cap.get("pose")[i]
			huesos.append({"nombre": sk.get_bone_name(i), "padre": sk.get_bone_parent(i),
				"rest_pos": _v(r.origin), "rest_q": _q(r.basis), "pos": _v(p.origin), "q": _q(p.basis),
				"local_rest_pos": _v(sk.get_bone_rest(i).origin), "local_rest_q": _q(sk.get_bone_rest(i).basis)})
		var datos := {"heroe": h, "clip": String(c.anim.current_animation), "huesos": huesos,
			"adelante": _v(c.gestos.adelante), "arriba": _v(c.gestos.arriba), "derecha": _v(c.gestos.derecha),
			"escala": c.gestos.escala, "ruta_esqueleto": str(c.anim.get_node(c.anim.root_node).get_path_to(sk))}
		var f := FileAccess.open(salida.path_join("reposo_%s.json" % h.to_lower()), FileAccess.WRITE)
		f.store_string(JSON.stringify(datos, " "))
		f.close()
		print("CAPTURA %s: %d huesos, clip «%s», esqueleto «%s»" % [h, huesos.size(), datos["clip"], datos["ruta_esqueleto"]])
		c.queue_free()
		await _esperar(2)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _q(b: Basis) -> Array:
	var q := b.orthonormalized().get_rotation_quaternion()
	return [q.x, q.y, q.z, q.w]
