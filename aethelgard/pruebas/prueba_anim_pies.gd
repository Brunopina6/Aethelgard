extends SceneTree
# Pies que patinan en la exploración 3D (T-084, tanda 2). Con «-- 3d sin_prologo», sin ventana; mide y no escribe nada
# salvo, con «salida=<carpeta>», un CSV por fotograma, y con «fotos=<carpeta>» (y ventana) los fotogramas JPG del
# recorrido para montar el vídeo.
#   1. Clips: cada clip de andar y correr de Kael, Lya y Garon, en el sitio y a 1,7 m de alto (escala 1). La velocidad a
#      la que va hacia atrás el pie apoyado es la velocidad a la que «anda» el clip sin patinar; también su ciclo, sus
#      pasos por segundo y en qué punto del ciclo apoya cada pie.
#   2. Región: Pastos Verdes 3D con Lya y Garon siguiendo a Kael. Kael anda con el stick (4,2 m/s) por el camino, gira y
#      cruza el puente; se para; da media vuelta; corre con un toque lejano (7,56 m/s) y llega andando; arranca y para a
#      golpes; hace eslalon; anda con el stick poco inclinado. En cada fotograma y para cada uno: la velocidad del pie
#      apoyado frente al suelo (sin patinar, casi 0) y la del cuerpo.
# Un pie está «apoyado» cuando el tobillo y los dedos están a menos de APOYO del suelo que tienen debajo (rayo), por
# encima de lo más bajo a lo que llegan con ese clip: el pie plano en el suelo. Su velocidad es la del punto medio entre
# tobillo y dedos, en horizontal.
# Imprime «CLIP …», «PIES …» (por personaje y tramo) y «RAPIDEZ …» (por personaje y velocidad del cuerpo). Con
# «limite=<m/s>» es una prueba de regresión: FALLO si, andando a 4,2 m/s con el stick, el pie de apoyo de alguno se
# adelanta más deprisa que eso (antes de T-084 tanda 2, unos 3 m/s), o si el pie apoyado de Kael se corre más de 10 cm
# por paso andando o corriendo hacia un toque.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const PERSONAJES := {"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}
const CLIPS := ["Walking", "Andar_normal", "Running"]
const APOYO := 0.03                  # m: el pie plano en el suelo (sobre lo más bajo de su recorrido)
const DT := 1.0 / 30.0               # --fixed-fps 30
# Recorrido con el stick (puntos del camino de sendero_puente.gd: SENDERO[0] a SENDERO[5], el final del puente).
const CAMINO := [Vector3(-9, 0, 9), Vector3(-3, 0, 5), Vector3(2, 0, -0.5), Vector3(4.7, 0, -2), Vector3(13.3, 0, -2)]

var salida := ""
var fotos := ""
var limite := -1.0
var fallos: Array = []
var r                                # la región
var tramo := ""
var muestras: Array = []             # [tramo, personaje, vel_cuerpo, vel_pie, anim, speed_scale]
var _ant := {}                       # nodo → {"p": raíz, "m": [medio izq, medio dcha]} del fotograma anterior
var _suelo_min := {}                 # personaje → [tobillo, dedos]: lo más bajo sobre el suelo en todo el recorrido
var _crudo: Array = []               # por fotograma: [tramo, personaje, vel_cuerpo, anim, ss, [pie...]]
var _csv: PackedStringArray = []
var _n_foto := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("fotos="):
			fotos = a.substr(6)
		elif a.begins_with("limite="):
			limite = float(a.substr(7))
	if fotos != "":
		DisplayServer.window_set_size(Vector2i(1280, 720))
		DirAccess.make_dir_recursive_absolute(fotos)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _probar() -> void:
	await _esperar(3)
	if "clips" in OS.get_cmdline_user_args() or not "solo_region" in OS.get_cmdline_user_args():
		await _clips()
	if not "solo_clips" in OS.get_cmdline_user_args():
		await _region()
	_fin()


# ================================================================= 1. clips en el sitio

func _clips() -> void:
	for n in PERSONAJES:
		var c = load(PERSONAJES[n]).new()
		c.name = "Banco_" + n
		root.add_child(c)
		await _esperar(4)
		if c.get("anim") == null or c.get("skel") == null:
			_fallo("%s no tiene modelo" % n)
			c.queue_free()
			continue
		var vistos := {}
		for logico in CLIPS:
			var real: String = c.nombres.get(logico, "")
			if real == "" or vistos.has(real):
				continue
			if logico == "Walking" and c.nombres.has("Andar_normal"):
				continue                                    # Kael: su «Walking» es el andar pesado (10 s), que no se usa
			vistos[real] = true
			await _clip(n, c, logico, real)
		c.queue_free()
		await _esperar(2)


const LENTO := 0.25                  # los clips se miden a cámara lenta: más muestras en cada apoyo (el de correr dura 0,15 s)
const CICLOS := 3.0


func _clip(n: String, c, logico: String, real: String) -> void:
	c.gestos.quitar_todos(0.0)
	c.gestos.respirar = 0.0
	c.anim.speed_scale = LENTO
	c.anim.play(real, 0.0)
	c.anim.seek(0.0, true)
	await _esperar(3)
	var largo: float = c.anim.current_animation_length
	var total := int(ceil(CICLOS * largo / (DT * LENTO))) + 2
	var adelante: Vector3 = c._adelante_mundo()
	var filas: Array = []                                   # [t, [tobillo_i, dedos_i, tobillo_d, dedos_d] relativos]
	for i in total:
		await process_frame
		var p0: Vector3 = c.global_position
		var huesos: Array = []
		for h in ["pie_i", "dedos_i", "pie_d", "dedos_d"]:
			huesos.append(c.skel.global_transform * c.skel.get_bone_global_pose(c.gestos.idx[h]).origin - p0)
		filas.append([c.anim.current_animation_position, huesos])
	# lo más bajo de tobillo y dedos (en el sitio, el suelo es la altura más baja a la que llegan)
	var bajo := [INF, INF]
	for f in filas:
		for k in 4:
			bajo[k % 2] = minf(bajo[k % 2], f[1][k].y)
	var velocidades: Array = []
	var apoya := {0: [], 1: []}                             # pie → fases del ciclo en que empieza a apoyar
	var antes := [true, true]                               # (si empieza apoyado, ese apoyo no cuenta: ya había empezado)
	for i in range(1, filas.size()):
		for pie in 2:
			var tob: Vector3 = filas[i][1][pie * 2]
			var ded: Vector3 = filas[i][1][pie * 2 + 1]
			var plano: bool = tob.y < bajo[0] + APOYO and ded.y < bajo[1] + APOYO
			if plano:
				var m1: Vector3 = (tob + ded) * 0.5
				var m0: Vector3 = (filas[i - 1][1][pie * 2] + filas[i - 1][1][pie * 2 + 1]) * 0.5
				var v: Vector3 = Vector3(m1.x - m0.x, 0.0, m1.z - m0.z) / (DT * c.anim.speed_scale)
				velocidades.append(-v.dot(adelante))        # hacia atrás: positiva
				if not antes[pie]:
					apoya[pie].append(fmod(filas[i][0], largo) / largo)
			antes[pie] = plano
	# El pie de apoyo aunque no esté plano (como en la región): el más bajo, con el otro 8 cm más alto y él a menos de
	# 6 cm de lo más bajo. Su velocidad hacia atrás en la parte central del apoyo.
	var de_apoyo: Array = []
	for i in range(1, filas.size()):
		var h := [minf(filas[i][1][0].y - bajo[0], filas[i][1][1].y - bajo[1]), minf(filas[i][1][2].y - bajo[0], filas[i][1][3].y - bajo[1])]
		var k := 0 if h[0] < h[1] else 1
		if h[k] < 0.06 and h[1 - k] > h[k] + 0.08:
			var m1: Vector3 = (filas[i][1][k * 2] + filas[i][1][k * 2 + 1]) * 0.5
			var m0: Vector3 = (filas[i - 1][1][k * 2] + filas[i - 1][1][k * 2 + 1]) * 0.5
			de_apoyo.append(-Vector3(m1.x - m0.x, 0.0, m1.z - m0.z).dot(adelante) / (DT * c.anim.speed_scale))
	velocidades.sort()
	var v0: float = velocidades[velocidades.size() / 2] if not velocidades.is_empty() else 0.0
	var pasos: float = (apoya[0].size() + apoya[1].size()) / CICLOS
	print("CLIP %s %s (%s): %.2f m/s sin patinar (p25 %.2f, p75 %.2f; pie de apoyo %.2f) · ciclo %.2f s · %.1f pasos por ciclo · %.1f pasos/s · apoya izq %s dcha %s · %d muestras" % [
		n, logico, real, v0, _percentil(velocidades, 0.25), _percentil(velocidades, 0.75), _mediana(de_apoyo), largo, pasos,
		pasos / largo if largo > 0.0 else 0.0,
		str(apoya[0].map(func(x): return snappedf(x, 0.01))), str(apoya[1].map(func(x): return snappedf(x, 0.01))),
		velocidades.size()])


# ================================================================= 2. región

func _region() -> void:
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # Lya y Garon en el grupo; sin escenas
	if Engine.has_meta("grupo_activo"):
		Engine.remove_meta("grupo_activo")
	if Engine.has_meta("calidad_extra"):
		Engine.remove_meta("calidad_extra")
	change_scene_to_file(REGION)
	for i in 600:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null:
			break
	r = current_scene
	if r == null or r.scene_file_path != REGION:
		_fallo("no se llega a Pastos Verdes")
		return
	await _esperar(20)
	if fotos != "":
		r.distancia = 9.0                                    # el zoom más cercano del juego (9 a 34 m): se ven los pies
		r.info.get_parent().visible = false                  # sin los botones del panel de pruebas (CAL, RND…)
		r.objetivo.get_parent().visible = false
	var nombres: Array = ["Kael"] + (r.grupo.nodos().map(func(x): return String(x.name)) if r.grupo != null else [])
	print("REGIÓN: personajes ", nombres)
	# a) con el stick por el camino: giros suaves, el puente de punta a punta
	tramo = "andar"
	for meta in CAMINO:
		await _stick_hacia(meta, 1.0, 12.0)
	_stick(Vector2.ZERO)
	tramo = "parada"
	await _paso(75)
	# b) media vuelta: vuelve por el puente hasta el camino
	tramo = "media_vuelta"
	await _stick_hacia(Vector3(4.7, 0, -2), 1.0, 4.0)
	await _stick_hacia(Vector3(2, 0, -0.5), 1.0, 2.0)
	_stick(Vector2.ZERO)
	tramo = "parada"
	await _paso(60)
	# c) un toque lejano por el prado: corre (7,56 m/s) y los últimos 3 m anda
	tramo = "correr"
	r.destino = r._ajustar_destino(Vector3(-9, 0, 9))
	for i in 600:
		await _paso(1)
		if r.destino == null:
			break
	tramo = "parada"
	await _paso(75)
	# d) arranca y para a golpes (0,4 s andando, 0,6 s quieto), camino adelante
	tramo = "arranques"
	var hacia := Vector2(6, -4).normalized()                  # de (-9, 9) hacia (-3, 5)
	for k in 5:
		_stick(hacia)
		await _paso(12)
		_stick(Vector2.ZERO)
		await _paso(18)
	# e) eslalon camino atrás: cambia de dirección (±35°) cada 0,7 s
	tramo = "eslalon"
	for k in 4:
		_stick((-hacia).rotated(deg_to_rad(35.0 if k % 2 == 0 else -35.0)))
		await _paso(21)
	_stick(Vector2.ZERO)
	tramo = "parada"
	await _paso(60)
	# f) el stick poco inclinado (mando), camino adelante: lo que dé el juego con un 60 % y un 80 % de inclinación
	tramo = "stick_suave"
	for fuerza in [0.6, 0.8]:
		_stick(hacia * fuerza)
		await _paso(45)
	_stick(Vector2.ZERO)
	tramo = "parada"
	await _paso(60)
	_resumen_region()


# Pone el stick (las cuatro acciones ui_*, con su fuerza) como lo haría un mando.
func _stick(d: Vector2) -> void:
	for par in [["ui_right", d.x], ["ui_left", -d.x], ["ui_down", d.y], ["ui_up", -d.y]]:
		if par[1] > 0.001:
			Input.action_press(par[0], par[1])
		else:
			Input.action_release(par[0])


# Anda con el stick hacia «meta» hasta llegar (o hasta «segundos»).
func _stick_hacia(meta: Vector3, fuerza: float, segundos: float) -> void:
	for i in int(segundos / DT):
		var k: Vector3 = r.kael.global_position
		var falta := Vector2(meta.x - k.x, meta.z - k.z)
		if falta.length() < 0.5:
			return
		_stick(falta.normalized() * fuerza)
		await _paso(1)


func _paso(n: int) -> void:
	for i in n:
		r.pasos = 0                                          # sin encuentros
		await process_frame
		_medir()
		if fotos != "":
			await RenderingServer.frame_post_draw
			_n_foto += 1
			r.get_viewport().get_texture().get_image().save_jpg("%s/f_%05d.jpg" % [fotos, _n_foto], 0.88)


func _medir() -> void:
	var actores := {"Kael": r.kael}
	if r.grupo != null:
		for m in r.grupo.miembros:
			actores[m["nombre"]] = m["nodo"]
	var espacio = r.get_world_3d().direct_space_state
	for n in actores:
		var c = actores[n]
		var p0: Vector3 = c.global_position
		var pies: Array = []
		for lado in ["i", "d"]:
			var tob: Vector3 = c.skel.global_transform * c.skel.get_bone_global_pose(c.gestos.idx["pie_" + lado]).origin
			var ded: Vector3 = c.skel.global_transform * c.skel.get_bone_global_pose(c.gestos.idx["dedos_" + lado]).origin
			var medio := (tob + ded) * 0.5
			var q := PhysicsRayQueryParameters3D.create(Vector3(medio.x, p0.y + 1.0, medio.z), Vector3(medio.x, p0.y - 2.0, medio.z))
			var hit: Dictionary = espacio.intersect_ray(q)
			var suelo: float = hit["position"].y if not hit.is_empty() else p0.y
			pies.append([tob.y - suelo, ded.y - suelo, medio])
		var ant: Dictionary = _ant.get(c, {})
		var vel := 0.0
		var vel_pies := [-1.0, -1.0]
		var adelante_pies := [0.0, 0.0]                      # hacia donde avanza el cuerpo: + el pie se adelanta
		if not ant.is_empty() and _plana(p0, ant["p"]) < 2.0:
			vel = _plana(p0, ant["p"]) / DT
			var marcha_dir := Vector3(p0.x - ant["p"].x, 0.0, p0.z - ant["p"].z).normalized()
			for k in 2:
				vel_pies[k] = _plana(pies[k][2], ant["m"][k]) / DT
				var dp: Vector3 = pies[k][2] - ant["m"][k]
				adelante_pies[k] = Vector3(dp.x, 0.0, dp.z).dot(marcha_dir) / DT
		_ant[c] = {"p": p0, "m": [pies[0][2], pies[1][2]]}
		var anim_n := String(c.anim.current_animation)
		_crudo.append([tramo, n, vel, anim_n, c.anim.speed_scale, [[pies[0][0], pies[0][1], vel_pies[0], pies[0][2], adelante_pies[0]],
			[pies[1][0], pies[1][1], vel_pies[1], pies[1][2], adelante_pies[1]]]])


func _mediana(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2]


func _percentil(a: Array, q: float) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return b[mini(b.size() - 1, int(b.size() * q))]


func _resumen_region() -> void:
	# Pies apoyados: tobillo y dedos a menos de APOYO por encima de lo más bajo a lo que llegan sobre el suelo con ese
	# mismo clip (cada clip apoya el pie a su altura: el reposo, unos centímetros más abajo que el de andar). «Lo más
	# bajo» es el percentil 3, para que un rayo raro no lo estropee.
	var alturas := {}
	for f in _crudo:
		var ka: String = f[1] + "|" + f[3]
		if not alturas.has(ka):
			alturas[ka] = [[], []]
		for k in 2:
			alturas[ka][0].append(f[5][k][0])
			alturas[ka][1].append(f[5][k][1])
	for ka in alturas:
		_suelo_min[ka] = [_percentil(alturas[ka][0], 0.03), _percentil(alturas[ka][1], 0.03)]
	var por_tramo := {}                    # personaje|tramo → pies apoyados MIENTRAS AVANZA (cuerpo a más de 0,3 m/s)
	var por_rapidez := {}
	var anims := {}                        # personaje|tramo → clip×ritmo → fotogramas avanzando
	var marcha := {}                       # personaje|tramo → [fotogramas, fotogramas avanzando, velocidades]
	var deriva := {}                       # personaje|tramo → velocidad hacia delante del pie de apoyo (m/s)
	_csv.append("tramo,personaje,vel_cuerpo,anim,speed_scale,pie,tobillo_m,dedos_m,apoyado,vel_pie,pie_adelante")
	for f in _crudo:
		var n: String = f[1]
		var mins: Array = _suelo_min[n + "|" + f[3]]
		var clave: String = n + "|" + f[0]
		var clave2: String = n + "|" + _cubo(f[2])
		if not marcha.has(clave):
			marcha[clave] = [0, 0, []]
		marcha[clave][0] += 1
		var avanza: bool = f[2] > 0.3
		if avanza:
			marcha[clave][1] += 1
			marcha[clave][2].append(f[2])
			# El pie de apoyo aunque no esté plano (Garon corre de puntillas): el más bajo, si el otro va 8 cm más alto
			# y él está a menos de 6 cm de su suelo. Su velocidad hacia delante: + el cuerpo va más deprisa que el clip.
			var bajo_k := 0 if minf(f[5][0][0], f[5][0][1]) < minf(f[5][1][0], f[5][1][1]) else 1
			var alto_k := 1 - bajo_k
			var h_bajo: float = minf(f[5][bajo_k][0] - mins[0], f[5][bajo_k][1] - mins[1])
			var h_alto: float = minf(f[5][alto_k][0] - mins[0], f[5][alto_k][1] - mins[1])
			if h_bajo < 0.06 and h_alto > h_bajo + 0.08 and f[5][bajo_k][2] >= 0.0:
				if not deriva.has(clave):
					deriva[clave] = []
				deriva[clave].append(f[5][bajo_k][4])
			if not anims.has(clave):
				anims[clave] = {}
			var nombre_anim: String = "%s×%.2f" % [f[3].left(10), snappedf(f[4], 0.05)]
			anims[clave][nombre_anim] = anims[clave].get(nombre_anim, 0) + 1
		for k in 2:
			var pie: Array = f[5][k]
			var apoyado: bool = pie[0] < mins[0] + APOYO and pie[1] < mins[1] + APOYO and pie[2] >= 0.0
			_csv.append("%s,%s,%.3f,%s,%.3f,%s,%.3f,%.3f,%d,%.3f,%.3f" % [f[0], n, f[2], f[3], f[4], "iz" if k == 0 else "de", pie[0] - mins[0], pie[1] - mins[1], 1 if apoyado else 0, pie[2], pie[4]])
			if not apoyado:
				continue
			var destinos: Array = [[por_rapidez, clave2]]
			if avanza:
				destinos.append([por_tramo, clave])
			for d in destinos:
				if not d[0].has(d[1]):
					d[0][d[1]] = {"pie": [], "cuerpo": []}
				d[0][d[1]]["pie"].append(pie[2])
				d[0][d[1]]["cuerpo"].append(f[2])
	# Cada apoyo (fotogramas seguidos con el mismo pie apoyado, el cuerpo avanzando): cuánto se ha corrido el pie por
	# el suelo desde que apoya hasta que despega (lo que se ve como «patinar»), y a qué velocidad media.
	var apoyos := {}                       # personaje|tramo → [[cm, m/s del pie, m/s del cuerpo], …]
	var abierto := {}                      # personaje|pie → [tramo, posición inicial, fotogramas, suma vel cuerpo, última]
	for f in _crudo:
		var n: String = f[1]
		var mins: Array = _suelo_min[n + "|" + f[3]]
		for k in 2:
			var pie: Array = f[5][k]
			var ka: String = n + "|" + str(k)
			var apoyado: bool = pie[0] < mins[0] + APOYO and pie[1] < mins[1] + APOYO and f[2] > 0.3
			if apoyado:
				if not abierto.has(ka):
					abierto[ka] = [f[0], pie[3], 0, 0.0, pie[3]]
				abierto[ka][2] += 1
				abierto[ka][3] += f[2]
				abierto[ka][4] = pie[3]
			elif abierto.has(ka):
				var a: Array = abierto[ka]
				abierto.erase(ka)
				if a[2] >= 3:
					var cm: float = _plana(a[1], a[4]) * 100.0
					var clave_a: String = n + "|" + a[0]
					if not apoyos.has(clave_a):
						apoyos[clave_a] = []
					apoyos[clave_a].append([cm, cm / 100.0 / ((a[2] - 1) * DT), a[3] / a[2]])
	var claves: Array = marcha.keys()
	claves.sort()
	for k in claves:
		var mm: Array = marcha[k]
		if mm[1] == 0:
			continue
		var d: Dictionary = por_tramo.get(k, {"pie": [], "cuerpo": []})
		var v_pie := _mediana(d["pie"])
		var ap: Array = apoyos.get(k, [])
		var cms: Array = ap.map(func(x): return x[0])
		var vels: Array = ap.map(func(x): return x[1])
		print("PIES %s · %s: avanza %d de %d fotogramas a %.2f m/s (mediana) · por apoyo, el pie se corre %.1f cm (p90 %.1f) a %.2f m/s, %d apoyos · pie de apoyo hacia delante %+.2f m/s (%d) · por fotograma, pie apoyado %.2f m/s (p90 %.2f) · clips %s" % [
			k.get_slice("|", 0), k.get_slice("|", 1), mm[1], mm[0], _mediana(mm[2]), _mediana(cms), _percentil(cms, 0.9),
			_mediana(vels), ap.size(), _mediana(deriva.get(k, [])), deriva.get(k, []).size(), v_pie, _percentil(d["pie"], 0.9), str(anims.get(k, {}))])
		# Regresión: a la marcha normal (el stick, 4,2 m/s) el pie de apoyo de cada uno no se adelanta más de «limite»
		# (antes de T-084 tanda 2, unos 3 m/s; después, unos 0,4); y el de Kael, apoyado, no se corre más de 10 cm por
		# paso ni andando ni corriendo hacia un toque (antes, 52 y 35 cm).
		var tramo_k: String = k.get_slice("|", 1)
		if limite > 0.0 and tramo_k == "andar" and _mediana(deriva.get(k, [])) > limite:
			_fallo("%s andando a 4,2 m/s: el pie de apoyo se adelanta a %.2f m/s (límite %.2f)" % [k.get_slice("|", 0), _mediana(deriva.get(k, [])), limite])
		if limite > 0.0 and k.get_slice("|", 0) == "Kael" and tramo_k in ["andar", "correr"] and _mediana(cms) > 10.0:
			_fallo("Kael en «%s»: el pie apoyado se corre %.1f cm por paso (límite 10)" % [tramo_k, _mediana(cms)])
	var claves2: Array = por_rapidez.keys()
	claves2.sort()
	for k in claves2:
		var d: Dictionary = por_rapidez[k]
		print("RAPIDEZ %s · cuerpo %s m/s: cuerpo %.2f · pie apoyado %.2f m/s (p90 %.2f) · %d muestras" % [
			k.get_slice("|", 0), k.get_slice("|", 1), _mediana(d["cuerpo"]), _mediana(d["pie"]), _percentil(d["pie"], 0.9), d["pie"].size()])
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("pies.csv"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(_csv))
			f.close()


func _cubo(v: float) -> String:
	if v < 0.3:
		return "0 quieto"
	if v < 2.0:
		return "1 <2"
	if v < 3.5:
		return "2 2-3,5"
	if v < 5.0:
		return "3 3,5-5"
	if v < 6.5:
		return "4 5-6,5"
	return "5 >6,5"


func _fin() -> void:
	_stick(Vector2.ZERO)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
