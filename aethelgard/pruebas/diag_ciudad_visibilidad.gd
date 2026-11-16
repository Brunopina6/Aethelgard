extends "res://pruebas/recorrido_ciudad.gd"
# V12 (16/11): DIAGNÓSTICO de VISIBILIDAD y CÁMARA en el recorrido de la maqueta de la ciudad (verificación independiente
# de area-ciudad-recorrido). Herramienta de diagnóstico, no prueba: no está en lista_pruebas.txt.
# Anda el MISMO recorrido que recorrido_ciudad.gd (clics, teclas y botones normales) y, además, vigila cada 2 fotogramas:
#   - Kael: rayos de la cámara a los PIES (0,2 m), la CINTURA (0,8 m) y la CABEZA (1,5 m) contra las cajas de los ocho
#     trazados (las mismas que dibuja la escena; lo aclarado no tapa; la maqueta lejana sí). «solo cabeza»: pies y cintura
#     tapados con la cabeza a la vista; «tapado»: la cabeza tapada. Y su sitio en el cuadro (alto de los pies, 0-1).
#   - el grupo (Lya, Garon): cintura (0,8) y cabeza (1,4): «tapado» si las dos lo están; «fuera del cuadro» si las dos
#     caen fuera de la vista.
#   - la cámara: lo que se mueve en un fotograma sin que Kael salte (salto de foco).
#   - los aclarados: cada malla «Ocultable_*» montada que cambia de opaca a clara (o al revés) 3 veces o más en 1 s
#     (parpadeo); y lo ocultable que tapa la cintura de Kael sin estar aclarado (el aclarado no llega: la escena solo mira
#     la cabeza).
# Cada caso que dura al menos 1 s de juego se anota (sector, sitio, tramo, qué tapa) con captura (la primera de cada
# clave). Al final, extra=1 anda además a la ronda (adarve de la Ribera), al pie del Árbol y a lo largo de la muralla sur.
# Uso (con ventana):
#   Godot --path aethelgard --script res://pruebas/diag_ciudad_visibilidad.gd --fixed-fps 30 --resolution 1600x720 --
#     salida=<carpeta fuera del proyecto> [perfil=bajo] [video=0] [solo_extra=1]
# Escribe <salida>/visibilidad.txt además de lo de recorrido_ciudad.gd.

const CADA := 2
const MIN_SEG := 1.0
const MAX_FOTOS_DIAG := 160

var solo_extra := false
var solo_sitios := false
var filtro_sitio := ""
var _ctx := "(entrada)"
var _paso := 0
var _ep := {}                  # clave → {n, inicio, sitio, ctx, que, foto}
var _resumen := {}             # clave → {veces, seg, sitios:[]}
var _eventos: PackedStringArray = []
var _cam_prev = null
var _k_prev = null
var _foco_prev = null
var _mats := {}                # id de malla → [estado, [fotogramas de cambio], nombre]
var _parpadeo_visto := {}
var n_fotos_diag := 0
var _fotos_clave := {}
var _pies_y := {}              # sector → [suma, n, n_abajo (>0,9), min, max]
var _saltos_cam := 0
var _max_cam := 0.0
var _max_cam_txt := ""
var _max_foco := 0.0
var _max_foco_txt := ""
var _extra_hecho := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "solo_extra=1":
			solo_extra = true
		elif a == "sitios=1":
			solo_sitios = true
			solo_extra = true
		elif a.begins_with("sitio="):
			filtro_sitio = a.trim_prefix("sitio=")
			solo_sitios = true
			solo_extra = true
	super()


func _tramo(sector: String, tipo: String, nombre: String, meta: Vector3, foto := false, cerca := LLEGA, foto_en = null) -> bool:
	_ctx = "%s %s «%s»" % [sector, tipo, nombre]
	return await super(sector, tipo, nombre, meta, foto, cerca, foto_en)


func _cerrar_tramo(sector: String, tipo: String, nombre: String, r: Dictionary, foto := false, extra_mal := "") -> bool:
	if not _ctx.contains(nombre):
		_ctx = "%s %s «%s»" % [sector, tipo, nombre]
	return await super(sector, tipo, nombre, r, foto, extra_mal)


# ================================================================= cada fotograma

func _cada_cuadro() -> void:
	super()
	if not _vivo() or v.cam == null:
		_cam_prev = null
		_k_prev = null
		_foco_prev = null
		_cerrar_todos()
		return
	_paso += 1
	_camara()
	if _paso % CADA != 0:
		return
	_aclarados()
	_cuerpos()


func _sitio() -> String:
	var k := _kael()
	return "%s (%.1f, %.1f, %.1f)" % [P.sector_de(k.x, k.z), k.x, k.y, k.z]


# Lo opaco que corta el rayo de la cámara a «p»: [] si se ve.
func _tapa(desde: Vector3, p: Vector3) -> Array:
	var r: Array = []
	for s in P.ORDEN:
		var t = P.trazado(s)
		var montado = v.cargador.montados.get(s)
		for x in Comun.tapan(t.BLOQUES, t.OCULTABLES, desde, p):
			var id: String = x[0]
			if montado != null:
				if x[1]:
					if not montado.aclarado(id):
						r.append("%s/%s (ocultable sin aclarar)" % [s, id])
				else:
					r.append("%s/%s" % [s, id])
			else:
				for b in t.BLOQUES:
					if b[0] == id and float(b[4]) >= v.cargador.ALTO_LEJANA and String(b[5]) != "puerta":
						r.append("%s/%s (maqueta lejana)" % [s, id])
	return r


func _en_cuadro(p: Vector3) -> bool:
	var cam: Camera3D = v.cam
	if cam.is_position_behind(p):
		return false
	return Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(cam.unproject_position(p))


func _cuerpos() -> void:
	var cam: Camera3D = v.cam
	var desde := cam.global_position
	var k := _kael()
	var pies := _tapa(desde, k + Vector3(0, 0.2, 0))
	var cintura := _tapa(desde, k + Vector3(0, 0.8, 0))
	var cabeza := _tapa(desde, k + Vector3(0, 1.5, 0))
	_caso("kael_tapado", not cabeza.is_empty(), cabeza)
	_caso("kael_solo_cabeza", cabeza.is_empty() and not pies.is_empty() and not cintura.is_empty(), cintura)
	var sin_aclarar: Array = cintura.filter(func(x): return String(x).contains("sin aclarar"))
	_caso("aclarado_no_llega_cintura", cabeza.is_empty() and not sin_aclarar.is_empty(), sin_aclarar)
	# medio cuerpo tapado de lado (la cámara no gira: el ancho de Kael va en x, ±0,25 m a la cintura y a la cabeza)
	var lados := 0
	var que_lado: Array = []
	for dx in [-0.25, 0.25]:
		var a1 := _tapa(desde, k + Vector3(dx, 0.8, 0))
		var a2 := _tapa(desde, k + Vector3(dx, 1.4, 0))
		if not a1.is_empty() and not a2.is_empty():
			lados += 1
			que_lado = a1
	_caso("kael_medio_de_lado", cabeza.is_empty() and cintura.is_empty() and lados > 0, que_lado)
	_caso("kael_fuera_cuadro", not (_en_cuadro(k + Vector3(0, 1.5, 0)) and _en_cuadro(k + Vector3(0, 0.05, 0))), [])
	# sitio de Kael en el cuadro
	var alto := root.get_visible_rect().size.y
	if not cam.is_position_behind(k):
		var y := cam.unproject_position(k).y / alto
		var s := P.sector_de(k.x, k.z)
		var e: Array = _pies_y.get(s, [0.0, 0, 0, 9.0, -9.0])
		e[0] += y
		e[1] += 1
		if y > 0.9:
			e[2] += 1
		e[3] = minf(e[3], y)
		e[4] = maxf(e[4], y)
		_pies_y[s] = e
	if v.grupo == null:
		return
	for n in v.grupo.nodos():
		var g: Vector3 = (n as Node3D).global_position
		var a := _tapa(desde, g + Vector3(0, 0.8, 0))
		var b := _tapa(desde, g + Vector3(0, 1.4, 0))
		var tap := not a.is_empty() and not b.is_empty()
		var fuera := not _en_cuadro(g + Vector3(0, 0.8, 0)) and not _en_cuadro(g + Vector3(0, 1.4, 0))
		_caso("grupo_tapado_" + str(n.name), tap and not fuera, b, g)
		_caso("grupo_fuera_cuadro_" + str(n.name), fuera, [], g)


# Un caso que puede durar: se anota (y se fotografía) al cumplir MIN_SEG; al acabar, su duración.
func _caso(tipo: String, activo: bool, que: Array, donde = null) -> void:
	if activo:
		var clave_q := tipo + "|" + (", ".join(que.slice(0, 3)) if not que.is_empty() else "")
		if not _ep.has(tipo):
			_ep[tipo] = {"n": 0, "sitio": _sitio(), "ctx": _ctx, "que": clave_q, "anotado": false,
				"donde": _txt(donde) if donde != null else ""}
		var e: Dictionary = _ep[tipo]
		e["n"] += CADA
		if not e["anotado"] and e["n"] >= int(MIN_SEG * FPS):
			e["anotado"] = true
			var foto := ""
			if not _fotos_clave.has(e["que"]) and n_fotos_diag < MAX_FOTOS_DIAG:
				_fotos_clave[e["que"]] = true
				foto = _foto_ya("%s_%s" % [tipo, _limpio(String(e["que"]).get_slice("|", 1))])
			e["foto"] = foto
	else:
		if _ep.has(tipo):
			_fin_caso(tipo)


func _fin_caso(tipo: String) -> void:
	var e: Dictionary = _ep[tipo]
	_ep.erase(tipo)
	if not e["anotado"]:
		return
	var seg := float(e["n"]) / FPS
	var linea := "%s: %.1f s en %s%s · tramo %s · tapa: %s%s" % [tipo, seg, e["sitio"],
		(" (él en %s)" % e["donde"]) if e["donde"] != "" else "", e["ctx"],
		String(e["que"]).get_slice("|", 1) if String(e["que"]).get_slice("|", 1) != "" else "-",
		(" · foto " + e["foto"]) if e.get("foto", "") != "" else ""]
	_eventos.append(linea)
	var r: Dictionary = _resumen.get(e["que"], {"veces": 0, "seg": 0.0, "sitios": []})
	r["veces"] += 1
	r["seg"] += seg
	if (r["sitios"] as Array).size() < 4:
		r["sitios"].append(e["sitio"])
	_resumen[e["que"]] = r


func _cerrar_todos() -> void:
	for t in _ep.keys():
		_fin_caso(t)


func _foto_ya(nombre: String) -> String:
	if not con_fotos:
		return ""
	n_fotos_diag += 1
	var dir := salida.path_join("visibilidad")
	DirAccess.make_dir_recursive_absolute(dir)
	var ruta := dir.path_join("%03d_%s.jpg" % [n_fotos_diag, nombre.substr(0, 70)])
	var img := root.get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_jpg(ruta, 0.9)
	return "visibilidad/" + ruta.get_file()


# Saltos de la cámara (sin que Kael salte) y del foco que piden las zonas.
func _camara() -> void:
	var c: Vector3 = v.cam.global_position
	var k := _kael()
	var f: Vector3 = P.foco_camara(k)
	if _cam_prev != null and _k_prev != null:
		var dk := (k - (_k_prev as Vector3)).length()
		var dc := (c - (_cam_prev as Vector3)).length()
		var df := Vector2(f.x - (_foco_prev as Vector3).x, f.z - (_foco_prev as Vector3).z).length()
		if dk < 1.0:
			if dc > _max_cam:
				_max_cam = dc
				_max_cam_txt = "%.2f m en un fotograma (Kael %.2f m) en %s · %s" % [dc, dk, _sitio(), _ctx]
			if dc > 0.6:
				_saltos_cam += 1
				_eventos.append("salto_camara: %.2f m en un fotograma (Kael %.2f m) en %s · %s" % [dc, dk, _sitio(), _ctx])
			var dkp := Vector2(k.x - (_k_prev as Vector3).x, k.z - (_k_prev as Vector3).z).length()
			if df - dkp > _max_foco:
				_max_foco = df - dkp
				_max_foco_txt = "foco +%.2f m sobre lo que anda Kael (%.2f m) en %s · %s" % [df - dkp, dkp, _sitio(), _ctx]
	_cam_prev = c
	_k_prev = k
	_foco_prev = f


# Parpadeo de los aclarados: cambios de opaco a claro (o al revés) de cada pieza ocultable montada (16/11, optimización:
# las piezas ya no son mallas sueltas; sector.gd, aclarado(id), por pieza y por montaje del sector).
func _aclarados() -> void:
	var fr := Engine.get_process_frames()
	for s in v.cargador.montados:
		var nodo: Node = v.cargador.montados[s]
		for o in nodo.ocultables:
			var nombre := String(o[0])
			var idm := "%d/%s" % [nodo.get_instance_id(), nombre]
			var est: bool = nodo.aclarado(nombre)
			if not _mats.has(idm):
				_mats[idm] = [est, [], "%s/%s" % [s, nombre]]
				continue
			var m: Array = _mats[idm]
			if m[0] != est:
				m[0] = est
				var cambios: Array = m[1]
				cambios.append(fr)
				while not cambios.is_empty() and fr - int(cambios[0]) > int(FPS):
					cambios.pop_front()
				if cambios.size() >= 3:
					var clave := "%s@%d" % [m[2], int(fr / (FPS * 3))]
					if not _parpadeo_visto.has(clave):
						_parpadeo_visto[clave] = true
						var foto := ""
						if not _fotos_clave.has("parpadeo|" + String(m[2])) and n_fotos_diag < MAX_FOTOS_DIAG:
							_fotos_clave["parpadeo|" + String(m[2])] = true
							foto = _foto_ya("parpadeo_" + _limpio(String(m[2])))
						_eventos.append("parpadeo_aclarado: %s cambia %d veces en 1 s en %s · %s%s" % [m[2], cambios.size(),
							_sitio(), _ctx, (" · foto " + foto) if foto != "" else ""])
						var r: Dictionary = _resumen.get("parpadeo|" + String(m[2]), {"veces": 0, "seg": 0.0, "sitios": []})
						r["veces"] += 1
						if (r["sitios"] as Array).size() < 4:
							r["sitios"].append(_sitio())
						_resumen["parpadeo|" + String(m[2])] = r


# ================================================================= sitios de más y final

func _jugar() -> void:
	if not solo_extra:
		await super()
		return
	await _frames(3)
	_preparar_rejilla()
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(BANCO)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == BANCO and current_scene.get("marco") != null:
			break
	await _segundos(1.0)
	var mal := await _entrar_desde_el_banco()
	if mal != "":
		_nota("FALLO: " + mal)
	_terminar()


func _terminar() -> void:
	if not _extra_hecho and solo_sitios:
		_extra_hecho = true
		if _vivo():
			await _sitios()
	if not _extra_hecho:
		_extra_hecho = true
		if not _vivo() and current_scene != null and current_scene.scene_file_path == BANCO:
			await _segundos(1.0)
			var mal := await _entrar_desde_el_banco()
			if mal != "":
				_nota("extra: no se entra: " + mal)
		if _vivo():
			await _extras()
	_cerrar_todos()
	var l: PackedStringArray = ["VISIBILIDAD (diag_ciudad_visibilidad.gd), ventana %s, viewport %s, perfil %s" % [root.size,
		root.get_visible_rect().size, perfil], ""]
	l.append("== RESUMEN por clave (veces, segundos, primeros sitios)")
	var claves := _resumen.keys()
	claves.sort_custom(func(a, b): return float(_resumen[a]["seg"]) + float(_resumen[a]["veces"]) > float(_resumen[b]["seg"]) + float(_resumen[b]["veces"]))
	for c in claves:
		var r: Dictionary = _resumen[c]
		l.append("%s: %d veces, %.1f s · %s" % [c, r["veces"], r["seg"], " | ".join(r["sitios"])])
	l.append("")
	l.append("== CÁMARA: saltos > 0,6 m en un fotograma: %d; el mayor: %s" % [_saltos_cam, _max_cam_txt])
	l.append("== FOCO: lo más que el foco de las zonas se adelanta a Kael en un fotograma: %s" % _max_foco_txt)
	l.append("== Kael en el cuadro (alto de los pies, 0 arriba, 1 abajo): por sector media, mín, máx, % del tiempo por debajo de 0,9")
	for s in _pies_y:
		var e: Array = _pies_y[s]
		l.append("  %s: media %.2f, %.2f-%.2f, abajo %.1f %%" % [s, e[0] / maxf(1, e[1]), e[3], e[4], 100.0 * e[2] / maxf(1, e[1])])
	l.append("")
	l.append("== EVENTOS (%d)" % _eventos.size())
	l.append_array(_eventos)
	var f := FileAccess.open(salida.path_join("visibilidad.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(l) + "\n")
		f.close()
	print("\n".join(l.slice(0, 60)))
	super()


# La ronda (adarve de la Ribera), el pie del Árbol y la muralla sur (Puerta del Sur), andando con clics.
func _extras() -> void:
	var sitios := [
		["puerta_sur", "extra", "junto a la muralla sur (Puerta del Sur)", P.ancla("puerta_sur")],
		["ribera", "extra", "pie de la ronda", _ancla("ribera", "n_pie_ronda")],
		["ribera", "extra", "la ronda (adarve)", _ancla("ribera", "n_ronda")],
		["ribera", "extra", "mirador de la ronda", _ancla("ribera", "mirador")],
		["ribera", "extra", "cofre al final de la ronda", _ancla("ribera", "cofre_ronda")],
		["ribera", "extra", "farol 1 de la ronda", _ancla("ribera", "farol_1")],
		["ribera", "extra", "pie de la ronda (vuelta)", _ancla("ribera", "n_pie_ronda")],
		["barrio_alto", "extra", "pie del Árbol", _ancla("barrio_alto", "referencia")],
	]
	for x in sitios:
		await _tramo(x[0], x[1], x[2], x[3], true)


# sitios=1: solo los sitios donde la pasada completa encontró algo (andando con clics de uno a otro), parada de 2,5 s.
const SITIOS := [
	["puerta_sur", "Puerta del Sur, bajo el dintel", Vector3(0.1, 0.0, 90.6)],
	["puerta_sur", "caravanas, junto al toldo de lonas", Vector3(24.6, 0.0, 80.3)],
	["plaza_tapiz", "puesto de fruta, bajo su toldo", Vector3(4.2, 2.0, 13.4)],
	["plaza_tapiz", "puesto 2, bajo su toldo", Vector3(-6.0, 2.0, 21.8)],
	["plaza_tapiz", "puerta de la casa de la lonja", Vector3(15.6, 2.0, 25.5)],
	["plaza_tapiz", "copa de la plaza alta (noreste)", Vector3(12.4, 4.0, -8.9)],
	["oficios", "puerta del soportal 1", Vector3(66.3, 4.6, 27.6)],
	["oficios", "puerta del soportal 2", Vector3(73.3, 5.3, 27.6)],
	["oficios", "puerta del soportal 3", Vector3(83.3, 6.3, 27.6)],
	["pasajes", "Escalerilla de la Botica, bajo su cubierta", Vector3(-33.4, 2.0, 58.1)],
	["pasajes", "corredor cubierto, junto a la esquina de la escalerilla", Vector3(-33.95, 2.0, 55.6)],
	["pasajes", "entrada del Callejón de Pip", Vector3(-59.9, 2.0, 57.0)],
	["pasajes", "entrada del Huerto de la Muralla", Vector3(-52.9, 1.0, 80.4)],
	["pasajes", "puerta de la casa del huertano", Vector3(-70.4, 1.0, 80.7)],
	["cuervo", "Callejón del Corro, bajo la copa", Vector3(-73.1, 2.0, 34.0)],
	["terrazas", "Escaleras de las Terrazas, pasado el arco", Vector3(-60.0, 3.5, -8.7)],
	["terrazas", "lavadero, bajo el tendedero", Vector3(-59.1, 12.0, -70.8)],
]


func _sitios() -> void:
	for x in SITIOS:
		if filtro_sitio != "" and not String(x[1]).contains(filtro_sitio):
			continue
		_ctx = "%s sitio «%s»" % [x[0], x[1]]
		await _tramo(x[0], "sitio", x[1], x[2], true)
		await _segundos(2.5)
