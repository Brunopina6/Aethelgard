extends SceneTree
# El distrito de los oficios de Oakhaven 3D (V10, hitos 2 y 10: zonas3d/oakhaven/distrito.gd y el kit de Blender
# modelos/distrito*.glb). Sin ventana:
#   0. Los dos GLB (alto y ligero) cargan, con colores de vértice, sus encargados, sus cajas de choque y sus anclas; con
#      «oakhaven_sin_distrito» no se monta (la ciudad de antes).
#   1. En Oakhaven 3D, perfiles alto y bajo: el distrito montado cabe en su presupuesto (≤ 20 000 triángulos en alto,
#      ≤ 10 000 con el kit ligero; pocas mallas), tiene choques y sus huellas en los bloqueos de la ciudad, ha quitado la
#      hierba de la ciudad de debajo y ningún punto de servicio cae en un bloqueo.
#   2. Kael anda desde la Calle Mayor hasta cada punto (la forja, las armaduras, el pozo y la botica) sin atascarse; en
#      cada uno aparece su botón («Hablar con Maese Ferro», «Hablar con Hilda», «Hablar con Mirta», «Examinar el pozo
#      viejo») y al pulsarlo pasa lo que toca: el diálogo de Dialogic si existe y, si no, el servicio (servicios.gd) o el
#      aviso «Servicio en preparación»; el pozo, su texto. Nada se rompe sin diálogos ni servicios.gd.
#   3. Los choques valen: Kael no entra en la herrería ni en los jardines; Ferro golpea el yunque (el brazo se mueve).
# Uso: --headless --path aethelgard --script res://pruebas/prueba_distrito_oakhaven.gd --fixed-fps 30 -- 3d oakhaven3d sin_prologo
# No toca ninguna partida: progreso.gd no guarda durante las pruebas.

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const Distrito := preload("res://zonas3d/oakhaven/distrito.gd")
const ANCLAS := ["ferro", "hilda", "mirta", "punto_forja", "punto_armaduras", "punto_botica", "punto_pozo", "humo",
	"fragua", "yunque", "pozo", "hombro_ferro"]
const TEXTOS := {"forja": "Hablar con Maese Ferro", "armaduras": "Hablar con Hilda", "botica": "Hablar con Mirta",
	"pozo": "Examinar el pozo viejo"}
const PERFILES := ["alto", "bajo"]
const MAX_TRAMO := 400

var fallos := 0
var frames := 0
var fase := ""
var f_fase := 0
var ip := 0
var v
var d
var ruta: Array = []
var i_ruta := 0
var atascos := 0
var punto := ""
var visitas: Array = []
var brazo_antes := 0.0
var brazo_vario := false


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _initialize() -> void:
	_comprobar_kits()
	Engine.set_meta("oakhaven_sin_distrito", true)
	if Distrito.crear(null, null, null, {}, "alto") != null:
		_mal("con «oakhaven_sin_distrito» el distrito se monta igual")
	Engine.remove_meta("oakhaven_sin_distrito")
	Engine.set_meta("oakhaven_sin_cache", true)
	_cargar()


# ================================================================= 0. los GLB

func _comprobar_kits() -> void:
	for ruta_kit in [Distrito.KIT, Distrito.KIT_LIGERO]:
		if not ResourceLoader.exists(ruta_kit):
			_mal("falta el kit %s" % ruta_kit)
			continue
		var raiz: Node = (load(ruta_kit) as PackedScene).instantiate()
		var tri := 0
		var cajas := 0
		var con_color := true
		var nombres: Array = []
		for mi in raiz.find_children("*", "MeshInstance3D", true, false):
			nombres.append(String(mi.name))
			var m: Mesh = (mi as MeshInstance3D).mesh
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				var idx = arr[Mesh.ARRAY_INDEX]
				tri += (idx.size() if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
				var col = arr[Mesh.ARRAY_COLOR]
				if col == null or (col as PackedColorArray).size() == 0:
					con_color = false
			for e in mi.get_children():
				if String(e.name).begins_with("caja_"):
					cajas += 1
		var faltan: Array = []
		for a in ANCLAS:
			if raiz.find_child("ancla_" + a, true, false) == null:
				faltan.append(a)
		for n in ["bajo", "edif_herreria", "edif_armeria", "edif_casa_a", "edif_casa_b", "pnj_ferro", "pnj_ferro_brazo", "pnj_hilda", "pnj_mirta"]:
			if not n in nombres:
				faltan.append(n)
		var tope := Distrito.PRESUPUESTO if ruta_kit == Distrito.KIT else Distrito.PRESUPUESTO / 2
		if not faltan.is_empty():
			_mal("%s: faltan %s" % [ruta_kit.get_file(), str(faltan)])
		if not con_color:
			_mal("%s: alguna malla sin colores de vértice" % ruta_kit.get_file())
		if cajas < 20:
			_mal("%s: solo %d cajas de choque" % [ruta_kit.get_file(), cajas])
		if tri > tope:
			_mal("%s: %d triángulos (tope %d)" % [ruta_kit.get_file(), tri, tope])
		print("OK 0: %s · %d triángulos · %d mallas · %d cajas · anclas completas: %s" % [ruta_kit.get_file(), tri, nombres.size(), cajas, str(faltan.is_empty())])
		raiz.free()


# ================================================================= 1-3. en la ciudad

func _cargar() -> void:
	Engine.set_meta("calidad_proto", PERFILES[ip])
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	v = null
	_fase("cargar")


func _fase(n: String) -> void:
	fase = n
	f_fase = frames


func _ir(p: Vector3) -> void:
	v.destino = v._ajustar_destino(p)


func _llego(p: Vector3) -> bool:
	return v.destino == null and Vector2(v.kael.global_position.x - p.x, v.kael.global_position.z - p.z).length() < 0.45


func _andar(puntos: Array, siguiente: String) -> void:
	ruta = puntos
	i_ruta = 0
	atascos = 0
	_ir(ruta[0])
	_fase("andar:" + siguiente)


func _punto(id: String) -> Vector3:
	for pz in d.piezas():
		if pz[0] == id:
			return pz[1]
	_mal("no hay punto «%s» en el distrito" % id)
	return Vector3(40, 0, 36)


func _process(_dt: float) -> bool:
	frames += 1
	if v != null and "pasos" in v:
		v.pasos = 0
	var dg = root.get_node_or_null("Dialogic")
	if fase.begins_with("andar:"):
		var meta: Vector3 = ruta[i_ruta]
		if _llego(meta):
			i_ruta += 1
			atascos = 0
			if i_ruta >= ruta.size():
				_fase(fase.substr(6))
			else:
				_ir(ruta[i_ruta])
		elif v.destino == null and frames - f_fase > 5 and not v.ocupado():
			atascos += 1
			if atascos > 3:
				_mal("%s: atascado camino de %s, en %s" % [PERFILES[ip], str(meta), str(v.kael.global_position.snapped(Vector3.ONE * 0.01))])
				return _terminar()
			_ir(meta)
			f_fase = frames
		elif frames - f_fase > MAX_TRAMO:
			_mal("%s: no llegó a %s (se quedó en %s)" % [PERFILES[ip], str(meta), str(v.kael.global_position.snapped(Vector3.ONE * 0.01))])
			return _terminar()
		return false
	match fase:
		"cargar":
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 20:
				v = current_scene
				d = v.get("distrito")
				if d == null:
					_mal("%s: Oakhaven 3D no tiene distrito" % PERFILES[ip])
					return _terminar()
				_comprobar_montaje()
				v._colocar_kael(Vector3(40.0, 0, 36.0))
				brazo_antes = d.brazo.rotation.x if d.brazo != null else 0.0
				visitas = ["forja", "armaduras", "pozo", "botica"]
				_siguiente()
		"llegado":
			if d.brazo != null and absf(d.brazo.rotation.x - brazo_antes) > 0.3:
				brazo_vario = true
			if frames - f_fase == 6:
				if v.cerca != punto:
					_mal("%s: en el punto «%s» se ofrece «%s»" % [PERFILES[ip], punto, v.cerca])
				elif not v.boton_accion.visible or v.boton_accion.text != TEXTOS[punto]:
					_mal("%s: el botón de «%s» no está o dice «%s»" % [PERFILES[ip], punto, v.boton_accion.text])
				else:
					print("OK 2a: %s · %s · botón «%s»" % [PERFILES[ip], punto, v.boton_accion.text])
				d.ultimo_aviso = ""
				d.servicio_abierto = ""
				v._accion()
			elif frames - f_fase == 14:
				_comprobar_accion(dg)
			elif frames - f_fase == 40:
				if dg != null and dg.current_timeline != null:
					# como al final del diálogo de quien atiende (su señal; V10, servicios.gd), y se cierra sin la despedida
					if punto in Distrito.OFICIOS:
						dg.signal_event.emit("oak:servicio_" + punto)
					dg.end_timeline(true)
			elif frames - f_fase == 60:
				if punto in Distrito.OFICIOS and d.servicio_abierto != punto and d.ultimo_aviso == "" and not _con_dialogo(punto):
					_mal("%s: tras «%s» no se abre el servicio ni se avisa" % [PERFILES[ip], punto])
				if punto in Distrito.OFICIOS and _con_dialogo(punto) and d.servicio_abierto != punto:
					_mal("%s: el diálogo de «%s» pide su servicio y no se abre" % [PERFILES[ip], punto])
				if v.ocupado() and d._ui == null:
					_mal("%s: tras «%s» la escena se queda ocupada" % [PERFILES[ip], punto])
				if d._ui != null and is_instance_valid(d._ui):        # se cierra, como haría quien juega
					d._ui.call("cerrar" if d._ui.has_method("cerrar") else "cerrar_menu")
				_siguiente()
		"choques":
			if frames - f_fase == 1:
				v._colocar_kael(Vector3(45.0, 0, 35.6))
				_ir(Vector3(45.0, 0, 32.0))                      # hacia dentro de la herrería
			elif frames - f_fase == 90:
				var z: float = v.kael.global_position.z
				if z < 33.45:                                    # (el patio de delante sí se pisa; el taller no)
					_mal("%s: Kael entra en la herrería (z %.2f)" % [PERFILES[ip], z])
				v._colocar_kael(Vector3(52.0, 0, 36.2))
				_ir(Vector3(52.0, 0, 39.0))                      # hacia dentro de un jardín
			elif frames - f_fase == 180:
				var z2: float = v.kael.global_position.z
				if z2 > 36.75 + 0.05:
					_mal("%s: Kael entra en un jardín (z %.2f)" % [PERFILES[ip], z2])
				else:
					print("OK 3a: %s · ni en la herrería ni en los jardines (se para en z %.2f)" % [PERFILES[ip], z2])
				if not brazo_vario:
					_mal("%s: el brazo de Ferro no se mueve" % PERFILES[ip])
				else:
					print("OK 3b: %s · Ferro golpea el yunque" % PERFILES[ip])
				ip += 1
				if ip >= PERFILES.size():
					return _terminar()
				_cargar()
	if frames > 20000:
		_mal("la prueba no terminó (fase «%s»)" % fase)
		return _terminar()
	return false


func _comprobar_montaje() -> void:
	var r: Dictionary = d.resumen()
	var tope := Distrito.PRESUPUESTO if not d.ligero else Distrito.PRESUPUESTO / 2
	if PERFILES[ip] == "bajo" and not d.ligero:
		_mal("bajo: el distrito no usa el kit ligero")
	if int(r["triangulos"]) > tope:
		_mal("%s: el distrito tiene %d triángulos (tope %d)" % [PERFILES[ip], r["triangulos"], tope])
	if int(r["mallas"]) > 30:
		_mal("%s: el distrito tiene %d mallas (llamadas de dibujo de más)" % [PERFILES[ip], r["mallas"]])
	if int(r["choques"]) < 20:
		_mal("%s: solo %d choques" % [PERFILES[ip], r["choques"]])
	var en_ciudad := 0
	for b in d.bloqueos:
		if b in v.ciudad.bloqueos:
			en_ciudad += 1
	if en_ciudad != d.bloqueos.size():
		_mal("%s: %d de %d huellas del distrito no están en los bloqueos de la ciudad" % [PERFILES[ip], d.bloqueos.size() - en_ciudad, d.bloqueos.size()])
	if int(r["limpiadas"]) <= 0:
		_mal("%s: no se quitó la hierba de la ciudad de debajo del distrito" % PERFILES[ip])
	for pz in d.piezas():
		var p: Vector3 = pz[1]
		if v.ciudad.bloqueado(p.x, p.z, 0.3) or v._prohibido(p):
			_mal("%s: el punto «%s» cae en un bloqueo (%s)" % [PERFILES[ip], pz[0], str(p)])
	if d.piezas().size() != 4:
		_mal("%s: el distrito ofrece %d puntos (4: forja, armaduras, botica y pozo)" % [PERFILES[ip], d.piezas().size()])
	for n in ["ferro", "hilda", "mirta"]:
		if not d.pnj.has(n):
			_mal("%s: falta el encargado «%s»" % [PERFILES[ip], n])
	print("OK 1: %s · %s" % [PERFILES[ip], str(r)])


# El siguiente punto: desde donde esté Kael, por la calle (y_ruta propia para el pozo y la botica).
func _siguiente() -> void:
	if visitas.is_empty():
		_fase("choques")
		return
	punto = visitas.pop_front()
	var p := _punto(punto)
	var camino: Array = []
	match punto:
		"pozo":
			camino = [Vector3(48.0, 0, 36.2), p]
		"botica":
			camino = [Vector3(48.0, 0, 36.2), Vector3(40.0, 0, 36.2), Vector3(40.0, 0, 41.6), Vector3(36.8, 0, 42.35), p]
		_:
			camino = [Vector3(v.kael.global_position.x, 0, 35.9), Vector3(p.x, 0, 35.9), p]
	_andar(camino, "llegado")


func _con_dialogo(id: String) -> bool:
	return d._ruta_dialogo(Distrito.OFICIOS[id]) != ""


func _comprobar_accion(dg) -> void:
	if punto == "pozo":
		if d.ultimo_aviso != Distrito.TEXTOS_POZO[0]:
			_mal("%s: el pozo no cuenta su texto («%s»)" % [PERFILES[ip], d.ultimo_aviso])
		else:
			print("OK 2b: %s · el pozo: «%s…»" % [PERFILES[ip], d.ultimo_aviso.left(50)])
		return
	if _con_dialogo(punto):
		if dg == null or dg.current_timeline == null:
			_mal("%s: «%s» tiene diálogo y no se abrió" % [PERFILES[ip], punto])
		else:
			print("OK 2b: %s · %s abre su diálogo (%s)" % [PERFILES[ip], punto, v.dialogo_actual])
		return
	var hay_servicios := ResourceLoader.exists(Distrito.SERVICIOS_GD)
	if d.servicio_abierto != punto:
		_mal("%s: «%s» sin diálogo no pide su servicio" % [PERFILES[ip], punto])
	elif not hay_servicios and d.ultimo_aviso != Distrito.AVISO_SIN_SERVICIO:
		_mal("%s: sin servicios.gd, «%s» no avisa «%s»" % [PERFILES[ip], punto, Distrito.AVISO_SIN_SERVICIO])
	else:
		print("OK 2b: %s · %s sin diálogo → servicio «%s» (%s)" % [PERFILES[ip], punto, punto,
			"servicios.gd" if hay_servicios else "aviso «%s»" % d.ultimo_aviso])


func _terminar() -> bool:
	Engine.remove_meta("calidad_proto")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
