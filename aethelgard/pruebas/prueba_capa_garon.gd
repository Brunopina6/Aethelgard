extends SceneTree
# La capa de Garon (V12, fase 6 del encargo del 13/11; 14/11/2026). Sin ventana:
#   godot --headless --path aethelgard --script res://pruebas/prueba_capa_garon.gd --fixed-fps 30
#       [-- versiones=originales,v2,v3 modos=rigida,articulada]
# Para cada variante de Garon (original, v2 y v3) y cada capa (la rígida de siempre y la articulada, capa_garon.gd)
# hace el mismo guion con sus métodos de siempre: reposo, andar y correr desplazándose, media vuelta corriendo,
# pararse, Juicio, Giro, avanzar en guardia, la Guardia (defensa), victoria y derrota. En cada muestra mide con la piel
# del cuerpo calculada en la CPU:
#   - anclaje: distancia del centro de arriba de la capa a las clavículas (debe ser estable) y hueco con la espalda;
#   - penetración: vértices de la capa dentro del cuerpo (brazos incluidos) y dentro de las dos espadas;
#   - suelo: el vértice más bajo;
#   - movimiento progresivo: cuánto se aparta cada fila de donde estaría pegada al pecho (arriba casi nada, abajo más);
#   - estabilidad: velocidad máxima de un vértice (nada sale disparado).
# Además: una sola capa por Garon, nada que se quede al cambiar de versión, de escena o al teletransportarse, y que
# sin elegir nada la capa es la de siempre. Solo la ARTICULADA tiene que cumplir los límites (FALLO si no); la rígida
# se mide para comparar (antes y después, en el mismo guion).

const SCRIPTS := {
	"originales": "res://garon_3d.gd",
	"v2": "res://personajes/heroes_v2/garon_v2_3d.gd",
	"v3": "res://personajes/heroes_v3/garon_v3_3d.gd",
}
# [acción, fotogramas, nombre de la fase ("" = sin medir)]
const GUION := [
	["reposo", 45, "reposo"],
	["andar", 40, "andar"],
	["correr", 40, "correr"],
	["girar", 30, "media_vuelta"],
	["parar", 40, "parar"],
	["juicio", 70, "juicio"],
	["reposo", 30, ""],
	["giro", 57, "giro_doble"],
	["reposo", 30, ""],
	["avanzar", 30, "avanzar"],
	["cubrir", 40, "defensa"],
	["fin_cubrir", 25, ""],
	["victoria", 40, "victoria"],
	["morir", 75, "derrota"],
]
const CADA := 3                       # una muestra cada 3 fotogramas (después de los 6 primeros de cada fase)
# Límites de la capa articulada
const MAX_VARIACION_ANCLAJE := 0.03   # m: lo que puede variar la distancia capa-clavículas en todo el guion
const MAX_HUECO_ESPALDA := 0.07       # m: hueco entre el centro de arriba de la capa y el cuerpo, de pie
# (Dentro del cuerpo se mide con la piel en la CPU, 1 de cada 3-4 vértices del cuerpo y la normal del más cercano:
# unos pocos vértices sueltos de la tela salen «dentro» en el borde de una placa aunque no se vea. La rígida de antes,
# que flota a 18 cm de la espalda, da 2,8-3,2 % y 2,1 % en las espadas con este mismo guion.)
const MAX_DENTRO_CUERPO := 0.05       # fracción de vértices de la capa dentro del cuerpo en una muestra (14 de 285)
const MAX_MEDIA_DENTRO := 0.02        # y de media en todo el guion
const MAX_DENTRO_ESPADA := 0.03       # fracción de la tela libre dentro de una espada
const MIN_SUELO := -0.005             # m
const MAX_VEL := 15.0                 # m/s de un vértice
const FILA_SUJECION := 5              # filas 0 a 5 (de 18): la sujeción, pegada a la espalda
const CUERPO_HUNDIDO := -0.06         # m: en la derrota, si el propio cuerpo baja de aquí se cuenta aparte (clip)
const MAX_TUMBADO := 0.10             # fracción dentro del cuerpo o de una espada en la derrota (tumbado: la tela queda
                                      # atrapada entre el cuerpo, las espadas y el suelo; los v2/v3 además se hunden)

var versiones: PackedStringArray = ["originales", "v2", "v3"]
var modos: PackedStringArray = ["rigida", "articulada"]
var fallos := 0
var casos: Array = []                 # [version, modo]
var ci := -1
var g: Node3D
var paso := 0
var cuenta := 0
var fase := ""
var r := {}                           # resultados del caso en curso
var anterior := PackedVector3Array()
var tiempos: Array = []
var mover := Vector3.ZERO
var giro_restante := 0.0
var nodos_base := 0
var resumen: Array = []
var detalle := false                  # «detalle»: una línea por muestra
var medir_ahora := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("versiones="):
			versiones = a.substr(10).split(",")
		elif a.begins_with("modos="):
			modos = a.substr(6).split(",")
		elif a == "detalle":
			detalle = true
	for v in versiones:
		for m in modos:
			casos.append([v, m])
	_comprobar_por_defecto()


func _ok(cond: bool, txt: String) -> void:
	if cond:
		print("  ok    ", txt)
	else:
		fallos += 1
		print("  FALLO ", txt)


# Sin elegir nada, la capa es la de siempre (la rígida): la versión que se ve por defecto no cambia.
func _comprobar_por_defecto() -> void:
	print("== por defecto")
	for k in ["capa_garon", "heroes_version", "heroes_v2", "heroes_v3"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var gd = load("res://garon_3d.gd")
	_ok(not gd.capa_articulada(), "sin elegir nada, la capa articulada está apagada")
	Engine.set_meta("capa_garon", "articulada")
	_ok(gd.capa_articulada(), "con la meta «capa_garon» = articulada, encendida")
	Engine.set_meta("capa_garon", "rigida")
	_ok(not gd.capa_articulada(), "con «rigida», apagada")
	Engine.remove_meta("capa_garon")
	nodos_base = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_siguiente()


func _crear(version: String, modo: String, padre: Node) -> Node3D:
	Engine.set_meta("heroes_version", version)
	Engine.set_meta("heroes_v2", version != "originales")
	Engine.set_meta("heroes_v3", version == "v3")
	Engine.set_meta("capa_garon", modo)
	var n := Node3D.new()
	n.set_script(load(SCRIPTS[version]))
	padre.add_child(n)
	return n


func _siguiente() -> void:
	if g != null:
		_cerrar_caso()
		g.queue_free()
		g = null
	ci += 1
	if ci >= casos.size():
		_pruebas_de_vida.call_deferred()
		return
	var v: String = casos[ci][0]
	var m: String = casos[ci][1]
	print("== %s, capa %s" % [v, m])
	g = _crear(v, m, root)
	paso = -1
	medir_ahora = false
	cuenta = 20
	fase = ""
	anterior = PackedVector3Array()
	tiempos = []
	r = {"anclaje": [], "hueco": [], "dentro": [], "dentro_tumbado": [], "espada": [], "espada_tumbado": [], "hundido": [], "cuerpo_hundido": 0.0, "espada_sujecion": [],
		"suelo": INF, "suelo_tela": INF, "cuerpo_bajo": INF, "vel": 0.0, "dev": {}, "n": 0}


func _process(dt: float) -> bool:
	if g == null:
		return false
	if not g.has_meta("_enganchado") and g.get("gestos") != null:
		# Se mide DENTRO del paso de los gestos (justo después de colocar espadas y capa): fuera de él, el esqueleto
		# devuelve la pose del clip sin los gestos (la Guardia, el porte al correr) y la medida mezclaría dos poses.
		g.set_meta("_enganchado", true)
		var gs = g.get("gestos")
		var original: Callable = gs.al_terminar
		var este := g
		gs.al_terminar = func(sk):
			original.call(sk)
			if medir_ahora and g == este and fase != "":
				medir_ahora = false
				_medir()
	if mover != Vector3.ZERO:
		g.global_position += mover * dt
	if giro_restante != 0.0:
		var paso_giro := signf(giro_restante) * minf(absf(giro_restante), PI / 15.0)
		g.rotate_y(paso_giro)
		giro_restante -= paso_giro
	var capa = g.get("capa")
	if capa is Node3D and capa.has_method("colocar"):
		tiempos.append(capa.tiempo_ultimo_us)
	cuenta -= 1
	if fase != "" and cuenta >= 0:
		var hecho: int = GUION[paso][1] - cuenta
		if hecho > 6 and hecho % CADA == 0:
			medir_ahora = true
	if cuenta > 0:
		return false
	paso += 1
	if paso >= GUION.size():
		mover = Vector3.ZERO
		_siguiente()
		return false
	_accion(GUION[paso][0])
	cuenta = GUION[paso][1]
	fase = GUION[paso][2]
	return false


func _adelante() -> Vector3:
	var sk: Skeleton3D = g.get("skel")
	var d: Vector3 = sk.global_transform.basis * g.get("gestos").adelante
	d.y = 0.0
	return d.normalized()


func _accion(a: String) -> void:
	mover = Vector3.ZERO
	match a:
		"reposo":
			g.reposo()
		"andar":
			g.andar()
			mover = _adelante() * float(g.get("vel_andar"))
		"correr":
			g.correr()
			mover = _adelante() * float(g.get("vel_correr"))
		"girar":
			g.correr()
			giro_restante = PI
			mover = _adelante() * float(g.get("vel_correr"))
		"parar":
			g.reposo()
		"juicio":
			g.atacar_juicio(func(): pass)
		"giro":
			g.atacar_giro(func(): pass)
		"avanzar":
			g.avanzar()
			mover = _adelante() * 1.6
		"cubrir":
			g.cubrir(_adelante())
		"fin_cubrir":
			g.fin_cubrir()
		"victoria":
			g.victoria()
		"morir":
			g.morir()


# ---------------------------------------------------------------- medidas
func _cuerpo() -> Array:
	var sk: Skeleton3D = g.get("skel")
	var gsk := sk.global_transform
	var pts := PackedVector3Array()
	var nors := PackedVector3Array()
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		if mi.get_parent() != sk or mi.skin == null or mi.mesh == null:
			continue
		var skin: Skin = mi.skin
		var mats: Array = []
		for k in skin.get_bind_count():
			var bn := String(skin.get_bind_name(k))
			var b := sk.find_bone(bn) if bn != "" else skin.get_bind_bone(k)
			mats.append(gsk * sk.get_bone_global_pose(b) * skin.get_bind_pose(k) if b >= 0 else gsk)
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var N: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var B = arr[Mesh.ARRAY_BONES]
			var W = arr[Mesh.ARRAY_WEIGHTS]
			if B == null or W == null or V.is_empty():
				continue
			var por: int = B.size() / V.size()
			var salto := maxi(1, V.size() / 6000)
			for v in range(0, V.size(), salto):
				var p := Vector3.ZERO
				var n := Vector3.ZERO
				for j in por:
					var w: float = W[v * por + j]
					if w > 0.0:
						var m: Transform3D = mats[int(B[v * por + j])]
						p += w * (m * V[v])
						n += w * (m.basis * N[v])
				pts.append(p)
				nors.append(n.normalized())
	return [pts, nors]


func _puntos_capa() -> Array:
	var capa = g.get("capa")
	if capa == null:
		return []
	if capa.has_method("puntos_mundo"):
		return [capa.puntos_mundo(), 15, 19]
	for mi in capa.find_children("*", "MeshInstance3D", true, false):
		var V: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var out := PackedVector3Array()
		for v in V:
			out.append(mi.global_transform * v)
		return [out, 15, 19]
	return []


# Donde estaría cada vértice pegado al pecho (rígido con el sitio de la capa, que en las dos va con el pecho).
func _rigidos() -> PackedVector3Array:
	var capa = g.get("capa")
	var out := PackedVector3Array()
	if capa.has_method("puntos_mundo"):
		for v in capa._V:
			out.append(capa.global_transform * v)
	else:
		for mi in capa.find_children("*", "MeshInstance3D", true, false):
			for v in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				out.append(mi.global_transform * v)
	return out


func _medir() -> void:
	var pc := _puntos_capa()
	if pc.is_empty():
		return
	var P: PackedVector3Array = pc[0]
	var cols: int = pc[1]
	var cu := _cuerpo()
	var CP: PackedVector3Array = cu[0]
	var CN: PackedVector3Array = cu[1]
	var celda := 0.06
	var rejilla := {}
	for i in CP.size():
		var key := Vector3i((CP[i] / celda).floor())
		if not rejilla.has(key):
			rejilla[key] = []
		rejilla[key].append(i)
	var dentro := 0
	var filas_dentro := {}
	var hueco_arriba := INF
	var centro_arriba: int = cols / 2
	for vi in P.size():
		var p := P[vi]
		var key := Vector3i((p / celda).floor())
		var mejor := INF
		var mi := -1
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					for i in rejilla.get(key + Vector3i(dx, dy, dz), []):
						var d := p.distance_squared_to(CP[i])
						if d < mejor:
							mejor = d
							mi = i
		if mi >= 0:
			var prof := -(p - CP[mi]).dot(CN[mi])
			if prof > 0.015 and sqrt(mejor) < 0.09:
				dentro += 1
				filas_dentro[vi / cols] = filas_dentro.get(vi / cols, 0) + 1
		if vi == centro_arriba:
			hueco_arriba = sqrt(mejor) if mi >= 0 else 0.18
	# Espadas
	var en_espada := 0                    # en la tela libre (por debajo de la sujeción)
	var en_espada_sujecion := 0           # en la sujeción (filas 0 a 5: va pegada a la espalda y no se aparta)
	var filas_espada := {}
	for lado in ["espada", "espada_izq"]:
		var n = g.get(lado)
		if not (n is Node3D) or not n.visible:
			continue
		var caja: AABB = g._caja(n)
		var cx := caja.get_center()
		var t: Transform3D = n.global_transform
		var a := t * Vector3(cx.x, caja.position.y, cx.z)
		var b := t * Vector3(cx.x, caja.end.y, cx.z)
		var rad := 0.5 * minf(caja.size.x, caja.size.z) * t.basis.get_scale().x
		for vi in P.size():
			var p := P[vi]
			if p.distance_to(Geometry3D.get_closest_point_to_segment(p, a, b)) < rad:
				if vi / cols <= FILA_SUJECION:
					en_espada_sujecion += 1
				else:
					en_espada += 1
				filas_espada[vi / cols] = true
	# Anclaje: centro de arriba frente a las clavículas
	var sk: Skeleton3D = g.get("skel")
	var gs = g.get("gestos")
	var ci_: int = gs._buscar(sk, ["LeftShoulder"])
	var cd_: int = gs._buscar(sk, ["RightShoulder"])
	var clav: Vector3 = sk.global_transform * (0.5 * (sk.get_bone_global_pose(ci_).origin + sk.get_bone_global_pose(cd_).origin))
	r["anclaje"].append(P[centro_arriba].distance_to(clav))
	if fase in ["reposo", "andar", "correr", "parar", "defensa", "victoria"]:
		r["hueco"].append(hueco_arriba)
	var cuerpo_bajo := _bajo_cuerpo(CP)
	if fase == "derrota" and cuerpo_bajo < CUERPO_HUNDIDO:
		# El clip mete al propio Garon bajo el suelo (la derrota de los v2/v3 lo hunde hasta 0,3 m): la tela, que no
		# baja del suelo, queda dentro de un cuerpo que no está donde debe. Se apunta aparte (pendiente del clip).
		r["hundido"].append(float(dentro) / P.size())
		r["cuerpo_hundido"] = minf(r["cuerpo_hundido"], cuerpo_bajo)
	elif fase == "derrota":                # tumbado: la tela queda entre el cuerpo, las espadas y el suelo
		r["dentro_tumbado"].append([fase, float(dentro) / P.size()])
		r["espada_tumbado"].append([fase, float(en_espada) / P.size()])
	else:
		r["dentro"].append([fase, float(dentro) / P.size()])
		r["espada"].append([fase, float(en_espada) / P.size()])
	r["espada_sujecion"].append([fase, float(en_espada_sujecion) / P.size()])
	var bajo := INF
	for p in P:
		bajo = minf(bajo, p.y - g.global_position.y)
	r["suelo"] = minf(r["suelo"], bajo)
	r["cuerpo_bajo"] = minf(r["cuerpo_bajo"], cuerpo_bajo)
	# Bajo el suelo «por culpa de la tela»: la tela libre (por debajo de la sujeción) nunca baja del suelo; la sujeción
	# va pegada a la espalda y solo puede bajar del suelo si el propio cuerpo baja (los clips de los v2/v3 que lo hunden).
	var bajo_libre := INF
	var bajo_sujecion := INF
	for vi in P.size():
		var h: float = P[vi].y - g.global_position.y
		if vi / cols <= FILA_SUJECION:
			bajo_sujecion = minf(bajo_sujecion, h)
		else:
			bajo_libre = minf(bajo_libre, h)
	r["suelo_tela"] = minf(r["suelo_tela"], minf(bajo_libre, bajo_sujecion - minf(0.0, cuerpo_bajo)))
	# Velocidad de la tela respecto al pecho (la del propio Garon, que salta y corre, no cuenta)
	var R := _rigidos()
	var rel := PackedVector3Array()
	rel.resize(P.size())
	for i in P.size():
		rel[i] = P[i] - R[i]
	var vel := 0.0
	if anterior.size() == P.size():
		for i in P.size():
			vel = maxf(vel, rel[i].distance_to(anterior[i]) * 30.0 / CADA)
	r["vel"] = maxf(r["vel"], vel)
	anterior = rel
	if detalle:
		print("    %-12s anclaje %.3f  hueco %.3f  dentro %.1f %%  espada %.1f %%  suelo %+.3f  vel %.1f" % [fase,
			P[centro_arriba].distance_to(clav), hueco_arriba, 100.0 * dentro / P.size(), 100.0 * en_espada / P.size(), bajo, vel],
			"  filas en espada %s  dentro por filas %s" % [str(filas_espada.keys()), str(filas_dentro)] + "  cuerpo más bajo %+.3f  fila de arriba más baja %+.3f" % [cuerpo_bajo, _bajo_fila(P, cols, 0)])
	# Movimiento progresivo: separación de cada fila de la pose pegada al pecho (filas 0, 9 y 18; columnas centrales)
	if not r["dev"].has(fase):
		r["dev"][fase] = {"arriba": [], "medio": [], "abajo": []}
	for par in [["arriba", 0], ["medio", 9], ["abajo", 18]]:
		var s := 0.0
		for i in range(cols / 2 - 2, cols / 2 + 3):
			var v: int = par[1] * cols + i
			s += P[v].distance_to(R[v])
		r["dev"][fase][par[0]].append(s / 5.0)
	r["n"] += 1


func _bajo_cuerpo(CP: PackedVector3Array) -> float:
	var b := INF
	for p in CP:
		b = minf(b, p.y - g.global_position.y)
	return b


func _bajo_fila(P: PackedVector3Array, cols: int, fila: int) -> float:
	var b := INF
	for i in cols:
		b = minf(b, P[fila * cols + i].y - g.global_position.y)
	return b


static func _media(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for x in a:
		s += x
	return s / a.size()


func _cerrar_caso() -> void:
	var v: String = casos[ci][0]
	var m: String = casos[ci][1]
	var art := m == "articulada"
	var capa = g.get("capa")
	var n_capas := 0
	for n in g.find_children("Capa", "", true, false):
		n_capas += 1
	print("  muestras: %d" % r["n"])
	_ok(n_capas == 1, "%s/%s: una sola capa (%d)" % [v, m, n_capas])
	if art:
		_ok(capa != null and capa.has_method("colocar"), "%s: la capa es la articulada" % v)
		_ok(capa.find_children("*", "MeshInstance3D", true, false).size() == 1, "%s: una sola tela" % v)
	else:
		_ok(capa != null and not capa.has_method("colocar"), "%s: la capa es la rígida" % v)
	var an: Array = r["anclaje"]
	var var_an: float = an.max() - an.min() if not an.is_empty() else 0.0
	var hueco: float = r["hueco"].max() if not r["hueco"].is_empty() else 0.0
	var peor_dentro := ["", 0.0]
	var media_dentro := 0.0
	for x in r["dentro"]:
		media_dentro += x[1]
		if x[1] > peor_dentro[1]:
			peor_dentro = x
	media_dentro /= maxf(1.0, r["dentro"].size())
	var peor_espada := ["", 0.0]
	for x in r["espada"]:
		if x[1] > peor_espada[1]:
			peor_espada = x
	var peor_sujecion := ["", 0.0]
	for x in r["espada_sujecion"]:
		if x[1] > peor_sujecion[1]:
			peor_sujecion = x
	var peor_tumbado := 0.0
	for x in r["dentro_tumbado"] + r["espada_tumbado"]:
		peor_tumbado = maxf(peor_tumbado, x[1])
	var t_med := _media(tiempos)
	var linea := "%s/%s: anclaje %.3f–%.3f m (varía %.3f) · hueco espalda máx %.3f m · dentro del cuerpo media %.1f %% peor %.1f %% (%s) · tumbado (cuerpo o espadas) peor %.1f %% · con el cuerpo hundido por el clip (%d muestras, cuerpo hasta %+.2f m) peor %.1f %% · espadas en la tela libre peor %.1f %% (%s), en la sujeción peor %.1f %% (%s) · suelo %+.3f m (cuerpo %+.3f; por la tela %+.3f) · vel máx %.1f m/s · colocar() %.0f µs (PC)" % [
		v, m, an.min() if not an.is_empty() else 0.0, an.max() if not an.is_empty() else 0.0, var_an, hueco,
		media_dentro * 100.0, peor_dentro[1] * 100.0, peor_dentro[0], peor_tumbado * 100.0, r["hundido"].size(), r["cuerpo_hundido"],
		(r["hundido"].max() if not r["hundido"].is_empty() else 0.0) * 100.0,
		peor_espada[1] * 100.0, peor_espada[0], peor_sujecion[1] * 100.0, peor_sujecion[0],
		r["suelo"], r["cuerpo_bajo"], r["suelo_tela"], r["vel"], t_med]
	print("  ", linea)
	resumen.append(linea)
	var prog := ""
	for f in r["dev"]:
		var d: Dictionary = r["dev"][f]
		prog += "%s %.3f/%.3f/%.3f  " % [f, _media(d["arriba"]), _media(d["medio"]), _media(d["abajo"])]
	print("  separación del pecho (arriba/medio/abajo, m): ", prog)
	resumen.append("  separación del pecho (arriba/medio/abajo, m): " + prog)
	if not art:
		return
	_ok(var_an <= MAX_VARIACION_ANCLAJE, "%s: anclaje estable (varía %.3f ≤ %.3f m)" % [v, var_an, MAX_VARIACION_ANCLAJE])
	_ok(hueco <= MAX_HUECO_ESPALDA, "%s: pegada a la espalda (hueco %.3f ≤ %.3f m)" % [v, hueco, MAX_HUECO_ESPALDA])
	_ok(media_dentro <= MAX_MEDIA_DENTRO, "%s: de media, apenas toca el cuerpo (%.1f %% ≤ %.0f %%)" % [v, media_dentro * 100.0, MAX_MEDIA_DENTRO * 100.0])
	_ok(peor_dentro[1] <= MAX_DENTRO_CUERPO, "%s: no atraviesa el cuerpo (peor %.1f %% ≤ %.0f %%, %s)" % [v, peor_dentro[1] * 100.0, MAX_DENTRO_CUERPO * 100.0, peor_dentro[0]])
	_ok(peor_espada[1] <= MAX_DENTRO_ESPADA, "%s: no atraviesa las espadas con la tela libre (peor %.1f %% ≤ %.0f %%, %s)" % [v, peor_espada[1] * 100.0, MAX_DENTRO_ESPADA * 100.0, peor_espada[0]])
	_ok(peor_tumbado <= MAX_TUMBADO, "%s: tumbado, la tela apenas se mete en el cuerpo ni en las espadas (peor %.1f %% ≤ %.0f %%)" % [v, peor_tumbado * 100.0, MAX_TUMBADO * 100.0])
	_ok(r["suelo_tela"] >= MIN_SUELO, "%s: nunca bajo el suelo ni bajo el cuerpo (%+.3f m)" % [v, r["suelo_tela"]])
	_ok(r["vel"] <= MAX_VEL, "%s: nada sale disparado (%.1f ≤ %.0f m/s)" % [v, r["vel"], MAX_VEL])
	for f in ["correr", "media_vuelta", "parar", "giro_doble"]:
		if not r["dev"].has(f):
			continue
		var d: Dictionary = r["dev"][f]
		var arr := _media(d["arriba"])
		var aba := _media(d["abajo"])
		_ok(arr < 0.015 and aba > 2.0 * arr + 0.02, "%s, %s: sujeción estable y movimiento progresivo (arriba %.3f, abajo %.3f m)" % [v, f, arr, aba])
	if r["dev"].has("correr"):
		var ab: Array = r["dev"]["correr"]["abajo"]
		_ok(ab.max() - ab.min() > 0.01 or _media(ab) > 0.05, "%s: corriendo, el borde se mueve (no es un bloque)" % v)


# ---------------------------------------------------------------- cambios de versión, de escena y saltos
func _pruebas_de_vida() -> void:
	await process_frame
	await process_frame
	print("== cambios de versión, de escena y saltos")
	var base := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	# Versión tras versión en el mismo sitio (como al cambiar «Protagonistas» en Ajustes)
	for modo in ["articulada", "rigida"]:
		for v in versiones:
			var n := _crear(v, modo, root)
			for _i in 4:
				await process_frame
			var capas := n.find_children("Capa", "", true, false).size()
			_ok(capas == 1, "%s/%s: una capa al crearlo" % [v, modo])
			n.queue_free()
			await process_frame
			await process_frame
	var despues := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_ok(despues == base, "al quitar cada versión no queda ningún nodo (%d → %d)" % [base, despues])
	# Cambio de escena de verdad (change_scene_to_node) con Garon dentro, dos veces
	for v in versiones:
		var escena := Node3D.new()
		escena.name = "EscenaPrueba"
		var n := _crear(v, "articulada", escena)
		change_scene_to_node(escena)
		for _i in 5:
			await process_frame
		_ok(is_instance_valid(n) and n.find_children("Capa", "", true, false).size() == 1, "%s: una capa tras cambiar de escena" % v)
		var capa = n.get("capa")
		# Salto (teletransporte o recolocación en el combate): se recoloca sin estirarse ni salir disparada
		var antes: int = capa.reinicios
		var p0: PackedVector3Array = capa.puntos_mundo()
		n.global_position += Vector3(8.0, 0.0, -5.0)
		await process_frame
		await process_frame
		var p1: PackedVector3Array = capa.puntos_mundo()
		var max_vel := 0.0
		for _i in 3:
			await process_frame
			var p2: PackedVector3Array = capa.puntos_mundo()
			for k in p2.size():
				max_vel = maxf(max_vel, p2[k].distance_to(p1[k]) * 30.0)
			p1 = p2
		_ok(capa.reinicios > antes, "%s: tras un salto de 9 m la capa se recoloca (%d → %d)" % [v, antes, capa.reinicios])
		_ok(max_vel < 3.0, "%s: y queda quieta después (vel máx %.2f m/s)" % [v, max_vel])
		# Sacarlo y volverlo a meter en otro padre (como al pasar del combate a la exploración)
		var otro := Node3D.new()
		escena.add_child(otro)
		n.reparent(otro)
		for _i in 3:
			await process_frame
		_ok(n.find_children("Capa", "", true, false).size() == 1, "%s: una capa tras cambiar de padre" % v)
	var vacia := Node3D.new()
	change_scene_to_node(vacia)
	for _i in 5:
		await process_frame
	var final := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_ok(final <= base + 1, "tras salir de la escena no queda nada de Garon ni de su capa (%d → %d)" % [base, final])
	for k in ["capa_garon", "heroes_version", "heroes_v2", "heroes_v3"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	print("== resumen")
	for l in resumen:
		print(l)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
