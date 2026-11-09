extends SceneTree
# Esperas de exploración (personalidad de los héroes), paso 3 de 3: del GLB de Blender a los huesos del héroe.
#   godot --headless --path aethelgard --script res://pruebas/herramientas/convertir_esperas.gd --
#         heroe=Kael glb=<kael_esperas.glb> captura=<reposo_kael.json> [fps=20]
# Escribe res://animaciones/esperas/<heroe>.res (una AnimationLibrary con un clip por espera), que el héroe carga al
# empezar (maga_3d.gd, _cargar_esperas).
#
# El GLB y el FBX del héroe son el mismo esqueleto, pero cada programa los importa con sus ejes. Por eso no se copian
# los giros locales tal cual: en cada fotograma se calcula cuánto ha girado cada hueso respecto a su reposo en el
# espacio del esqueleto del GLB, se lleva ese giro al espacio del esqueleto del héroe (Kabsch con las posiciones de
# reposo) y se vuelve a pasar a giros locales. La cadera lleva además su posición. Las demás posiciones son las del
# reposo del juego (la captura): una sola clave.
# Se muestrea a «fps» (30 por defecto, como Blender) y se quitan las claves que se deducen de sus vecinas (error menor
# que TOLERANCIA_GIRO); una pista que no cambia lleva una sola clave.

const SALIDA := "res://animaciones/esperas/%s.res"
const HEROES := {"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}
const QUIETO := 0.0015                      # radianes: por debajo, la pista no cambia
const TOLERANCIA_GIRO := 0.004              # radianes (0,23°): se quitan las claves que se deducen de sus vecinas
const TOLERANCIA_CADERA := 0.001            # metros

var args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var i := a.find("=")
		if i > 0:
			args[a.substr(0, i)] = a.substr(i + 1)
	_convertir.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _convertir() -> void:
	var heroe: String = args.get("heroe", "")
	var fps := float(args.get("fps", "30"))
	if not HEROES.has(heroe) or not args.has("glb") or not args.has("captura"):
		printerr("FALLO: faltan heroe=, glb= o captura=")
		quit(1)
		return
	# --- el GLB
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(args["glb"], st) != OK:
		printerr("FALLO: no se lee el GLB")
		quit(1)
		return
	var escena: Node = doc.generate_scene(st)
	root.add_child(escena)
	var sg: Skeleton3D = escena.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = escena.find_children("*", "AnimationPlayer", true, false)[0]
	# --- el héroe
	var h = load(HEROES[heroe]).new()
	root.add_child(h)
	await _esperar(3)
	var sh: Skeleton3D = h.skel
	var cap: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args["captura"]))
	var ruta: String = cap["ruta_esqueleto"]
	# huesos comunes (Blender «mixamorig:Hips» → «mixamorig_Hips»)
	var mapa := {}                          # índice en el héroe → índice en el GLB
	for i in sh.get_bone_count():
		var n := sh.get_bone_name(i)
		var j := sg.find_bone(n)
		if j < 0:
			j = sg.find_bone(n.replace("_", ":"))
		if j >= 0:
			mapa[i] = j
	var pg: Array = []
	var ph: Array = []
	for i in mapa:
		ph.append(sh.get_bone_global_rest(i).origin)
		pg.append(sg.get_bone_global_rest(mapa[i]).origin)
	var k := _kabsch(pg, ph)
	var s: float = k[0]
	var M: Basis = k[1]
	var t: Vector3 = k[2]
	print("KABSCH %s: %d huesos comunes de %d, escala %.4f, error máx %.5f" % [heroe, mapa.size(), sh.get_bone_count(), s, k[3]])
	# posiciones locales del reposo del juego (la captura), para las pistas de posición de una clave
	var cap_global := {}
	for b in cap["huesos"]:
		cap_global[b["nombre"]] = Transform3D(Basis(_quat(b["q"])), _vec(b["pos"]))
	var lib := AnimationLibrary.new()
	var peor_ini := 0.0
	var claves_total := 0
	var pistas_total := 0
	for nombre in ap.get_animation_list():
		if String(nombre) == "RESET":
			continue
		var ag := ap.get_animation(nombre)
		var a := Animation.new()
		a.length = ag.length
		a.loop_mode = Animation.LOOP_NONE
		var pistas_g := _pistas(ag, sg)                     # hueso del GLB → {rot, pos}
		var tiempos: Array = []
		var n_muestras := maxi(2, int(round(ag.length * fps)) + 1)
		for m in n_muestras:
			tiempos.append(minf(ag.length, m * ag.length / float(n_muestras - 1)))
		var rot_h := {}                                     # hueso del héroe → Array de Quaternion
		var pos_cadera: Array = []
		var cadera := sh.find_bone("mixamorig_Hips")
		for tt in tiempos:
			var gl := _globales(sg, ag, pistas_g, tt)       # poses globales del GLB
			var nuevas := {}                                # hueso del héroe → Transform3D global
			for i in sh.get_bone_count():
				var rest_h := sh.get_bone_global_rest(i)
				var B: Basis
				if mapa.has(i):
					var j: int = mapa[i]
					var q: Basis = gl[j].basis.orthonormalized() * sg.get_bone_global_rest(j).basis.orthonormalized().inverse()
					B = (M * q * M.inverse()) * rest_h.basis.orthonormalized()
				else:
					B = rest_h.basis.orthonormalized()
				var o := rest_h.origin
				if i == cadera and mapa.has(i):
					o = M * gl[mapa[i]].origin * s + t
				var p := sh.get_bone_parent(i)
				if p >= 0:
					o = nuevas[p] * (sh.get_bone_global_rest(p).affine_inverse() * rest_h).origin if i != cadera else o
				nuevas[i] = Transform3D(B, o)
			for i in sh.get_bone_count():
				var p := sh.get_bone_parent(i)
				var local: Transform3D = nuevas[i] if p < 0 else nuevas[p].affine_inverse() * nuevas[i]
				if not rot_h.has(i):
					rot_h[i] = []
				var qq := local.basis.orthonormalized().get_rotation_quaternion()
				if not rot_h[i].is_empty() and rot_h[i][-1].dot(qq) < 0.0:
					qq = -qq
				rot_h[i].append(qq)
				if i == cadera:
					pos_cadera.append(local.origin)
			if tt == 0.0:
				peor_ini = maxf(peor_ini, _comparar(sh, nuevas, cap_global))
		for i in sh.get_bone_count():
			var nb := sh.get_bone_name(i)
			var camino := NodePath("%s:%s" % [ruta, nb])
			var tr := a.add_track(Animation.TYPE_ROTATION_3D)
			a.track_set_path(tr, camino)
			var qs: Array = rot_h[i]
			var cambia := false
			for q in qs:
				if q.angle_to(qs[0]) > QUIETO:
					cambia = true
					break
			if cambia:
				for m in _reducir(tiempos, qs, TOLERANCIA_GIRO, true):
					a.rotation_track_insert_key(tr, tiempos[m], qs[m])
			else:
				a.rotation_track_insert_key(tr, 0.0, qs[0])
			claves_total += a.track_get_key_count(tr)
			pistas_total += 1
			var tp := a.add_track(Animation.TYPE_POSITION_3D)
			a.track_set_path(tp, camino)
			if i == cadera:
				for m in _reducir(tiempos, pos_cadera, TOLERANCIA_CADERA, false):
					a.position_track_insert_key(tp, tiempos[m], pos_cadera[m])
			else:
				var p := sh.get_bone_parent(i)
				var g: Transform3D = cap_global.get(nb, sh.get_bone_global_rest(i))
				var gp: Transform3D = cap_global.get(sh.get_bone_name(p), Transform3D()) if p >= 0 else Transform3D()
				a.position_track_insert_key(tp, 0.0, (gp.affine_inverse() * g).origin if p >= 0 else g.origin)
			claves_total += a.track_get_key_count(tp)
			pistas_total += 1
		lib.add_animation(nombre, a)
		print("CLIP %s %s: %.2f s, %d muestras" % [heroe, nombre, a.length, tiempos.size()])
	print("PRIMER FOTOGRAMA frente al reposo del juego: %.3f° como mucho" % rad_to_deg(peor_ini))
	print("TOTAL %s: %d clips, %d pistas, %d claves" % [heroe, lib.get_animation_list().size(), pistas_total, claves_total])
	DirAccess.make_dir_recursive_absolute("res://animaciones/esperas")
	var dest := SALIDA % heroe.to_lower()
	var err := ResourceSaver.save(lib, dest, ResourceSaver.FLAG_COMPRESS)
	print("GUARDADO %s (%s)" % [dest, error_string(err)])
	quit(0 if err == OK and peor_ini < deg_to_rad(1.0) else 1)


# pistas de huesos del GLB: índice de hueso → {"rot": pista, "pos": pista}
func _pistas(ag: Animation, sg: Skeleton3D) -> Dictionary:
	var r := {}
	for tr in ag.get_track_count():
		var camino := ag.track_get_path(tr)
		if camino.get_subname_count() == 0:
			continue
		var j := sg.find_bone(String(camino.get_subname(0)))
		if j < 0:
			continue
		if not r.has(j):
			r[j] = {}
		match ag.track_get_type(tr):
			Animation.TYPE_ROTATION_3D:
				r[j]["rot"] = tr
			Animation.TYPE_POSITION_3D:
				r[j]["pos"] = tr
	return r


func _globales(sg: Skeleton3D, ag: Animation, pistas: Dictionary, tt: float) -> Array:
	var gl: Array = []
	gl.resize(sg.get_bone_count())
	for j in sg.get_bone_count():
		var rest := sg.get_bone_rest(j)
		var q := rest.basis.get_rotation_quaternion()
		var o := rest.origin
		if pistas.has(j):
			if pistas[j].has("rot"):
				q = ag.rotation_track_interpolate(pistas[j]["rot"], tt)
			if pistas[j].has("pos"):
				o = ag.position_track_interpolate(pistas[j]["pos"], tt)
		var local := Transform3D(Basis(q), o)
		var p := sg.get_bone_parent(j)
		gl[j] = local if p < 0 else gl[p] * local
	return gl


# mayor diferencia de giro entre la pose calculada y la del juego (radianes)
func _comparar(sh: Skeleton3D, nuevas: Dictionary, cap_global: Dictionary) -> float:
	var peor := 0.0
	for i in sh.get_bone_count():
		var n := sh.get_bone_name(i)
		if not cap_global.has(n):
			continue
		var a: Quaternion = nuevas[i].basis.orthonormalized().get_rotation_quaternion()
		var b: Quaternion = cap_global[n].basis.get_rotation_quaternion()
		peor = maxf(peor, a.angle_to(b))
	return peor


# Kabsch con escala: ph ≈ s·M·pg + t. Devuelve [s, M, t, error máximo].
func _kabsch(pg: Array, ph: Array) -> Array:
	var n := pg.size()
	var cg := Vector3.ZERO
	var c_h := Vector3.ZERO
	for i in n:
		cg += pg[i]
		c_h += ph[i]
	cg /= n
	c_h /= n
	# H = Σ a·bᵀ ; R = factor ortogonal de Hᵀ (iteración polar)
	var hx := Vector3.ZERO
	var hy := Vector3.ZERO
	var hz := Vector3.ZERO
	for i in n:
		var a: Vector3 = pg[i] - cg
		var b: Vector3 = ph[i] - c_h
		hx += b * a.x          # columnas de Hᵀ: Hᵀ[:, k] = Σ b · a_k
		hy += b * a.y
		hz += b * a.z
	var R := Basis(hx, hy, hz)
	for it in 80:
		R = Basis((R.x + R.inverse().transposed().x) * 0.5, (R.y + R.inverse().transposed().y) * 0.5,
			(R.z + R.inverse().transposed().z) * 0.5)
	var var_g := 0.0
	var num := 0.0
	for i in n:
		var a: Vector3 = pg[i] - cg
		var_g += a.length_squared()
		num += (R * a).dot(ph[i] - c_h)
	var s := num / var_g
	var t := c_h - (R * cg) * s
	var err := 0.0
	for i in n:
		err = maxf(err, ((R * pg[i]) * s + t - ph[i]).length())
	return [s, R, t, err]


func _quat(a: Array) -> Quaternion:
	return Quaternion(a[0], a[1], a[2], a[3])


func _vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


# Quita las claves que se deducen de sus vecinas (interpolación lineal o esférica) con un error menor que «tol».
# Devuelve los índices que se quedan (siempre el primero y el último).
func _reducir(tiempos: Array, valores: Array, tol: float, giro: bool) -> Array:
	var quedan: Array = [0]
	var i := 0
	var n := valores.size()
	while i < n - 1:
		var j := i + 2
		while j < n:
			var vale := true
			for k in range(i + 1, j):
				var u: float = (tiempos[k] - tiempos[i]) / maxf(tiempos[j] - tiempos[i], 0.00001)
				var err: float
				if giro:
					err = (valores[i] as Quaternion).slerp(valores[j], u).angle_to(valores[k])
				else:
					err = (valores[i] as Vector3).lerp(valores[j], u).distance_to(valores[k])
				if err > tol:
					vale = false
					break
			if not vale:
				break
			j += 1
		i = j - 1
		quedan.append(i)
	return quedan
