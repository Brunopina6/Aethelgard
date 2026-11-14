extends SceneTree
# La capa ARTICULADA de Garon en MOVIMIENTO REAL (V12, 14/11/2026, revisión de la capa): Pastos Verdes 3D, Kael
# recorre de verdad un trayecto con el stick (como un mando) y Garon le sigue en la fila de siempre (zonas3d/grupo_3d.gd:
# su velocidad real, marcha(), sus giros con mirar(…, 0.12)). Con ventana y datos aislados:
#   --script res://pruebas/fotos_capa_garon_movimiento.gd --fixed-fps 30 -- salida=<carpeta> 3d sin_prologo
#       capa_articulada [version=v2|v3]
# Trayecto (por el prado, el tramo recto que ya recorre prueba_anim_pies.gd entre (-9, 9) y (2, -0,5)):
#   parado → arranque andando (stick poco inclinado: 1,26 m/s) → recto andando → recto corriendo (4,2 m/s) → giro de 90°
#   (al lado que tenga suelo libre, comprobado con _altura_suelo de la región) → giro de 180° → parada y asentamiento.
# Sin diálogos de llegada: los hitos PV-02, PV-03 y PV-05 ya hechos (Lya y Garon en el grupo) y sin encuentros.
# Cámara propia (una SubViewport con el mismo mundo: sin la interfaz del juego) cercana sobre Garon: sigue su pecho
# (Spine2) y su rumbo suavizado; dos vistas por fotograma, 3/4 trasera y lateral, a unos 3 m. Si un rayo de la cámara
# al cuerpo toca algo, se pasa al otro lado. Guarda un fotograma de cada 2 (<tramo>_<n>_<vista>.png), una hoja por
# variante con los instantes clave (hoja_movimiento_<variante>.png, celdas en indice_<variante>.txt) y, por captura, la medida:
# velocidad y clip de Garon, huesos del cuerpo y hojas que cruzan la tela, recolocaciones de la capa y qué parte del
# alto de la imagen ocupa Garon.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const INICIO := Vector3(-9, 0, 9)
const HACIA := Vector2(6, -4)                       # del inicio hacia (-3, 5) y (2, -0,5): el prado sin obstáculos
const TAM := Vector2i(420, 520)
const DIST := 3.0                                   # m de la cámara al pecho de Garon
const FOV := 40.0
const CADA := 2                                     # un fotograma de cada 2
const LENTO := 0.6                                  # inclinación del stick para andar (tras la zona muerta, 1,26 m/s)
# [tramo, fotogramas, stick: "" quieto, "lento", "rapido", "giro90", "giro180"]
const GUION := [
	["parado", 45, ""],
	["arranque_andar", 30, "lento"],
	["andar", 45, "lento"],
	["arranque_correr", 20, "rapido"],
	["correr", 25, "rapido"],
	["giro_90", 40, "giro90"],
	["giro_180", 45, "giro180"],
	["parada", 100, ""],
]
# Instantes de la hoja: [tramo, fotograma del tramo]
const HOJA := [["parado", 40], ["arranque_andar", 10], ["arranque_andar", 24], ["andar", 30], ["arranque_correr", 6],
	["arranque_correr", 16], ["correr", 20], ["giro_90", 6], ["giro_90", 14], ["giro_90", 26], ["giro_180", 6],
	["giro_180", 12], ["giro_180", 20], ["giro_180", 36], ["parada", 8], ["parada", 20], ["parada", 50], ["parada", 96]]
const PARES_CUERPO := [
	["cadera", "pecho"], ["pecho", "cuello"], ["cuello", "cabeza"],
	["muslo_i", "rodilla_i"], ["rodilla_i", "pie_i"], ["muslo_d", "rodilla_d"], ["rodilla_d", "pie_d"],
	["brazo_i", "antebrazo_i"], ["antebrazo_i", "mano_i"], ["brazo_d", "antebrazo_d"], ["antebrazo_d", "mano_d"],
]

var salida := ""
var version := "originales"
var r                                               # la región
var g: Node3D                                       # Garon
var vistas: Array = []                              # [SubViewport, Camera3D, ángulo]
var rumbo := Vector3.FORWARD
var lado_cam := 1.0
var dir := Vector2.ZERO
var paso := -1
var cuenta := 0
var n_tramo := 0
var celdas: Array = []                              # [nombre, [Image, Image]]
var indice: PackedStringArray = []
var pendiente := ""                                 # la imagen de un fotograma se lee en el siguiente (ya dibujada)
var medida_pendiente := ""
var fallos := 0
var alto_min := INF
var tapadas := 0
var antes_pos := Vector3.INF
var antes_f := 0
var antes_b := Basis()
var tela_idx := PackedInt32Array()
var perfiles := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("version="):
			version = a.substr(8)
	Engine.set_meta("heroes_version", version)
	Engine.set_meta("heroes_v2", version != "originales")
	Engine.set_meta("heroes_v3", version == "v3")
	if salida == "":
		salida = OS.get_user_data_dir().path_join("capa_garon_movimiento")
	DirAccess.make_dir_recursive_absolute(salida)
	_empezar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _empezar() -> void:
	await _esperar(3)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # sin escenas de llegada; Lya y Garon en el grupo
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	change_scene_to_file(REGION)
	for i in 900:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null \
				and current_scene.get("grupo") != null:
			break
	r = current_scene
	if r == null or r.scene_file_path != REGION:
		_fin("no se llega a Pastos Verdes")
		return
	for i in 300:
		await _paso_region(1)
		for m in r.grupo.miembros:
			if m["nombre"] == "Garon" and is_instance_valid(m["nodo"]):
				g = m["nodo"]
		if g != null:
			break
	if g == null:
		_fin("Garon no va en el grupo: " + str(r.grupo.miembros.map(func(x): return x["nombre"])))
		return
	var capa = g.get("capa")
	print("GARON %s: script %s, capa %s" % [version, g.get_script().resource_path, "articulada" if capa != null and capa.has_method("colocar") else "RÍGIDA"])
	if capa == null or not capa.has_method("colocar"):
		_fin("la capa no es la articulada (falta el argumento capa_articulada)")
		return
	# Al inicio del trayecto (corriendo) y que el grupo llegue y se pare
	await _stick_hacia(INICIO, 1.0, 20.0)
	_stick(Vector2.ZERO)
	await _paso_region(120)
	print("INICIO: Kael en %s, Garon en %s" % [str(r.kael.global_position), str(g.global_position)])
	_camaras()
	rumbo = _adelante_garon()
	dir = HACIA.normalized()
	_siguiente_tramo()


func _camaras() -> void:
	for ang in [35.0, 90.0]:                          # 3/4 trasera y lateral
		var vp := SubViewport.new()
		vp.size = TAM
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.msaa_3d = Viewport.MSAA_4X
		root.add_child(vp)
		vp.world_3d = r.get_viewport().world_3d
		var cam := Camera3D.new()
		cam.fov = FOV
		cam.near = 0.05
		vp.add_child(cam)
		cam.current = true
		vistas.append([vp, cam, ang])


func _siguiente_tramo() -> void:
	paso += 1
	if paso >= GUION.size():
		_terminar()
		return
	n_tramo = 0
	cuenta = GUION[paso][1]
	match GUION[paso][2]:
		"giro90":                                     # al lado con suelo libre
			var mejor := dir.rotated(PI * 0.5)
			for s in [1.0, -1.0]:
				var d2: Vector2 = dir.rotated(s * PI * 0.5)
				if _libre(d2, 5.0):
					mejor = d2
					break
			dir = mejor
		"giro180":
			dir = -dir
	print("TRAMO %s: stick %s, dirección %s, Kael en %s" % [GUION[paso][0], GUION[paso][2], str(dir), str(r.kael.global_position)])


# ¿Puede Kael andar «metros» en esa dirección? (las comprobaciones de suelo de la región: _altura_suelo)
func _libre(d: Vector2, metros: float) -> bool:
	var p: Vector3 = r.kael.global_position
	var y := p.y
	var paso_m := 0.3
	for i in int(metros / paso_m):
		var sig := p + Vector3(d.x, 0, d.y).normalized() * paso_m
		var guarda: Vector3 = r.kael.global_position
		r.kael.global_position = p                    # (_altura_suelo lanza el rayo desde Kael)
		var h: float = r._altura_suelo(sig, y)
		r.kael.global_position = guarda
		if is_nan(h):
			return false
		p = Vector3(sig.x, h, sig.z)
		y = h
	return true


func _process(_dt: float) -> bool:
	if pendiente != "":
		_guardar()
	if vistas.is_empty() or g == null or paso < 0 or paso >= GUION.size():
		return false
	r.pasos = 0                                       # sin encuentros
	var modo: String = GUION[paso][2]
	match modo:
		"":
			_stick(Vector2.ZERO)
		"lento":
			_stick(dir * LENTO)
		_:
			_stick(dir)
	_seguir_camaras()
	n_tramo += 1
	if n_tramo % CADA == 0 or _en_hoja():
		pendiente = "%s_%03d" % [GUION[paso][0], n_tramo]
		medida_pendiente = _medir()
	cuenta -= 1
	if cuenta <= 0:
		_siguiente_tramo()
	return false


func _en_hoja() -> bool:
	for h in HOJA:
		if h[0] == GUION[paso][0] and h[1] == n_tramo:
			return true
	return false


func _adelante_garon() -> Vector3:
	var sk: Skeleton3D = g.get("skel")
	var d: Vector3 = sk.global_transform.basis * g.get("gestos").adelante
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD


func _hueso(nombre: String) -> Vector3:
	var sk: Skeleton3D = g.get("skel")
	var i: int = g.get("gestos").idx.get(nombre, -1)
	return sk.global_transform * sk.get_bone_global_pose(i).origin if i >= 0 else g.global_position


# Sigue el pecho (Spine2) y el rumbo de Garon, suavizado (en un giro, la cámara le acompaña sin dar latigazos).
func _seguir_camaras() -> void:
	var meta := _adelante_garon()
	var a0 := atan2(rumbo.x, rumbo.z)
	var a1 := atan2(meta.x, meta.z)
	var a := lerp_angle(a0, a1, 0.12)
	rumbo = Vector3(sin(a), 0, cos(a))
	var pecho := _hueso("pecho")
	var cadera := _hueso("cadera")
	var mira := cadera.lerp(pecho, 0.4)
	var espacio = r.get_world_3d().direct_space_state
	for v in vistas:
		var cam: Camera3D = v[1]
		var pos := _pos_cam(mira, v[2] * lado_cam)
		var choque: Dictionary = espacio.intersect_ray(PhysicsRayQueryParameters3D.create(pos, mira))
		if not choque.is_empty():                     # algo delante: al otro lado
			var otra := _pos_cam(mira, -v[2] * lado_cam)
			if espacio.intersect_ray(PhysicsRayQueryParameters3D.create(otra, mira)).is_empty():
				lado_cam = -lado_cam
				pos = otra
			else:
				tapadas += 1
		cam.look_at_from_position(pos, mira)


func _pos_cam(mira: Vector3, grados: float) -> Vector3:
	var atras := -rumbo.rotated(Vector3.UP, deg_to_rad(grados))
	return mira + atras * DIST * 0.94 + Vector3.UP * DIST * 0.34


# ---------------------------------------------------------------- medidas de cada captura
func _medir() -> String:
	var capa = g.get("capa")
	var P: PackedVector3Array = capa.puntos_mundo()
	if tela_idx.is_empty():
		tela_idx = capa.malla.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var caja := AABB(P[0], Vector3.ZERO)
	for p in P:
		caja = caja.expand(p)
	var huesos: Array = []
	for par in PARES_CUERPO:
		if _corta(P, caja, _hueso(par[0]), _hueso(par[1])):
			huesos.append(par[0])
	var hojas: Array = []
	for lado in ["espada", "espada_izq"]:
		var n = g.get(lado)
		if n is Node3D and n.is_visible_in_tree():
			if not perfiles.has(lado):                # el perfil real de la hoja (como prueba_capa_garon_estados.gd)
				perfiles[lado] = _perfil_espada(n)
			var t: Transform3D = n.global_transform
			for s in perfiles[lado]:
				if _corta(P, caja, t * s[0], t * s[1]):
					hojas.append(lado)
					break
	var vel := 0.0
	var giro := 0.0
	var f := Engine.get_process_frames()
	var b: Basis = capa.global_transform.basis.orthonormalized()
	if antes_pos != Vector3.INF and f > antes_f:
		vel = Vector2(g.global_position.x - antes_pos.x, g.global_position.z - antes_pos.z).length() * 30.0 / (f - antes_f)
		giro = rad_to_deg((antes_b.inverse() * b).get_rotation_quaternion().get_angle()) / (f - antes_f)
	antes_pos = g.global_position
	antes_f = f
	antes_b = b
	# Qué parte del alto de la imagen ocupa Garon (de los pies a lo alto de la cabeza) en la vista trasera
	var cam: Camera3D = vistas[0][1]
	var arriba := cam.unproject_position(_hueso("cabeza_fin") + Vector3.UP * 0.12)
	var abajo := cam.unproject_position(g.global_position)
	var frac: float = absf(abajo.y - arriba.y) / TAM.y
	alto_min = minf(alto_min, frac)
	if not huesos.is_empty() or not hojas.is_empty():
		fallos += 1
	return "vel %.2f m/s  giro %.0f°/fotograma  clip %s  huesos %s  hojas %s  recolocaciones %d  alto %.0f %%" % [vel, giro,
		String(g.get("anim").current_animation), str(huesos), str(hojas), capa.reinicios, 100.0 * frac]


# Perfil de una espada en su espacio: eje largo, ancho y grueso medidos en su malla; filos, centro y travesaños.
func _perfil_espada(n: Node3D) -> Array:
	var inv := n.global_transform.affine_inverse()
	var pts: Array = []
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var xf: Transform3D = inv * mi.global_transform
		for s in mi.mesh.get_surface_count():
			for v in mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				pts.append(xf * v)
	if pts.is_empty():
		return []
	var caja := AABB(pts[0], Vector3.ZERO)
	for p in pts:
		caja = caja.expand(p)
	var ejes := [0, 1, 2]
	ejes.sort_custom(func(a, b): return caja.size[a] > caja.size[b])
	var largo: int = ejes[0]
	var ancho: int = ejes[1]
	var grueso: int = ejes[2]
	const NB := 12
	var mn: Array = []
	var mx: Array = []
	var gs: Array = []
	var cn: Array = []
	for i in NB:
		mn.append(INF)
		mx.append(-INF)
		gs.append(0.0)
		cn.append(0)
	for p in pts:
		var f: float = (p[largo] - caja.position[largo]) / maxf(caja.size[largo], 0.0001)
		var i := clampi(int(f * NB), 0, NB - 1)
		mn[i] = minf(mn[i], p[ancho])
		mx[i] = maxf(mx[i], p[ancho])
		gs[i] += p[grueso]
		cn[i] += 1
	var puntos: Array = []                       # [filo1, centro, filo2] por tramo
	for i in NB:
		if cn[i] == 0:
			continue
		var y: float = caja.position[largo] + (i + 0.5) / NB * caja.size[largo]
		var trio: Array = []
		for w in [mn[i], 0.5 * (mn[i] + mx[i]), mx[i]]:
			var q := Vector3.ZERO
			q[largo] = y
			q[ancho] = w
			q[grueso] = gs[i] / cn[i]
			trio.append(q)
		puntos.append(trio)
	var segs: Array = []
	for i in puntos.size():
		segs.append([puntos[i][0], puntos[i][2], float(i) / NB])            # travesaño
		if i > 0:
			for k in 3:
				segs.append([puntos[i - 1][k], puntos[i][k], float(i) / NB])    # filos y centro
	return segs


func _corta(P: PackedVector3Array, caja: AABB, a: Vector3, b: Vector3) -> bool:
	if not AABB(a, Vector3.ZERO).expand(b).grow(0.001).intersects(caja):
		return false
	for t in range(0, tela_idx.size(), 3):
		if Geometry3D.segment_intersects_triangle(a, b, P[tela_idx[t]], P[tela_idx[t + 1]], P[tela_idx[t + 2]]) != null:
			return true
	return false


func _guardar() -> void:
	var nombre := pendiente
	pendiente = ""
	var imgs: Array = []
	for i in vistas.size():
		var im: Image = vistas[i][0].get_texture().get_image()
		im.save_png(salida.path_join("%s_%s_%s.png" % [version, nombre, ["trasera", "lateral"][i]]))
		imgs.append(im)
	indice.append("%s  %s" % [nombre, medida_pendiente])
	for h in HOJA:
		if nombre == "%s_%03d" % [h[0], h[1]]:
			celdas.append([nombre, imgs])


# ---------------------------------------------------------------- fin
func _terminar() -> void:
	_stick(Vector2.ZERO)
	await process_frame
	if pendiente != "":
		_guardar()
	# Hoja: 3 instantes por fila, cada uno con sus dos vistas (trasera | lateral)
	var por_fila := 3
	var filas := ceili(float(celdas.size()) / por_fila)
	var hoja := Image.create(TAM.x * 2 * por_fila, TAM.y * filas, false, Image.FORMAT_RGBA8)
	hoja.fill(Color.WHITE)
	var leyenda: PackedStringArray = ["Hoja hoja_movimiento_%s.png: %d filas × %d instantes; en cada instante, a la izquierda la vista 3/4 trasera y a la derecha la lateral." % [version, filas, por_fila]]
	for k in celdas.size():
		var x := (k % por_fila) * TAM.x * 2
		var y := (k / por_fila) * TAM.y
		for v in 2:
			var im: Image = celdas[k][1][v]
			im.convert(Image.FORMAT_RGBA8)
			hoja.blit_rect(im, Rect2i(Vector2i.ZERO, TAM), Vector2i(x + v * TAM.x, y + 2))
		leyenda.append("fila %d, columna %d: %s" % [k / por_fila + 1, k % por_fila + 1, celdas[k][0]])
	hoja.save_png(salida.path_join("hoja_movimiento_%s.png" % version))
	var f := FileAccess.open(salida.path_join("indice_%s.txt" % version), FileAccess.WRITE)
	for l in leyenda:
		f.store_line(l)
	f.store_line("")
	for l in indice:
		f.store_line(l)
	f.close()
	print("GARON ocupa como poco el %.0f %% del alto de la imagen (vista trasera); vistas tapadas: %d; capturas con cruce: %d de %d" % [
		100.0 * alto_min, tapadas, fallos, indice.size()])
	for l in leyenda:
		print(l)
	_fin("")


func _fin(error: String) -> void:
	_stick(Vector2.ZERO)
	if error != "":
		print("FALLO: ", error)
	quit(1 if error != "" else 0)


# ---------------------------------------------------------------- el stick (como prueba_anim_pies.gd)
func _stick(d: Vector2) -> void:
	for par in [["ui_right", d.x], ["ui_left", -d.x], ["ui_down", d.y], ["ui_up", -d.y]]:
		if par[1] > 0.001:
			Input.action_press(par[0], par[1])
		else:
			Input.action_release(par[0])


func _stick_hacia(meta: Vector3, fuerza: float, segundos: float) -> void:
	for i in int(segundos * 30.0):
		var k: Vector3 = r.kael.global_position
		var falta := Vector2(meta.x - k.x, meta.z - k.z)
		if falta.length() < 0.5:
			return
		_stick(falta.normalized() * fuerza)
		await _paso_region(1)


func _paso_region(n: int) -> void:
	for i in n:
		if r != null and is_instance_valid(r):
			r.pasos = 0
		await process_frame
