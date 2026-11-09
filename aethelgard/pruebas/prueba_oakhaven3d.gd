extends SceneTree
# Oakhaven 3D, primer tramo jugable (T-103): de la Puerta del Sur a la posada, por dentro y vuelta.
#   0. modo3d: Oakhaven 3D solo con la exploración 3D y «oakhaven3d»; una partida guardada en la ciudad 2D vuelve a la 3D
#      en la misma casilla (escena_equivalente → posicion_desde_2d).
#   1. Entra por la Puerta del Sur (el sitio de la 2D) y anda hasta Aldric: su diálogo de siempre se abre.
#   2. Calle Mayor → Plaza del Tapiz → Calle del Cuervo → la puerta de la taberna, sin atascarse.
#   3. Entra en la posada (fundido): Kael dentro de la sala; anda hasta la barra.
#   4. Servicios de la posadera (ciudades/oakhaven_posada.gd): la sopa (10 monedas), un rumor (queda oído) y dormir
#      (30 monedas, el grupo curado, amanece).
#   5. Sale a la calle, ante la taberna; guardar y volver deja a Kael donde estaba; y sale al mapa por la Puerta del Sur.
# Uso: --headless --path aethelgard --script res://pruebas/prueba_oakhaven3d.gd --fixed-fps 30 -- 3d oakhaven3d sin_prologo
# No toca ninguna partida: progreso.gd no guarda durante las pruebas.

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const MAX_TRAMO := 600
var M = load("res://modo3d.gd")
var P = load("res://progreso.gd")
var I = load("res://inventario.gd")
var G = load("res://grupo.gd")
var S = load("res://zonas3d/oakhaven/posada3d.gd")
var v
var frames := 0
var fase := ""
var f_fase := 0
var fallos := 0
var ruta: Array = []
var i_ruta := 0
var oro_antes := 0
var atascos := 0


func _initialize() -> void:
	Engine.set_meta("pos_3d_ok", false)
	_comprobar_modo3d()
	change_scene_to_file(REGION)
	set_meta("t0", Time.get_ticks_usec())
	_fase("cargar")


func _fase(n: String) -> void:
	fase = n
	f_fase = frames


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _comprobar_modo3d() -> void:
	if not M.region_activa_con(0, PackedStringArray(["3d", "oakhaven3d"]), false):
		_mal("Oakhaven 3D no está activa con «3d oakhaven3d»")
	if M.region_activa_con(0, PackedStringArray(["3d"]), false):
		_mal("Oakhaven 3D se usa sin «oakhaven3d» (debe seguir la 2D)")
	if M.region_activa_con(0, PackedStringArray([]), false):
		_mal("Oakhaven 3D se usa sin la exploración 3D")
	Engine.set_meta("pos_zona", Vector2(40.0 * 64.0, 29.0 * 64.0))      # una partida guardada en la plaza de la 2D
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	var e: String = M.escena_equivalente("res://ciudad_oakhaven.tscn")
	var p = Engine.get_meta("pos_3d", null)
	if e != REGION or not p is Vector3 or (p as Vector3).distance_to(Vector3(40, 0, 29)) > 0.01:
		_mal("la partida de la ciudad 2D no lleva a la 3D en la misma casilla (%s, %s)" % [e, str(p)])
	else:
		print("OK 0: modo3d con «oakhaven3d»; una partida de la plaza 2D vuelve a la plaza 3D %s" % str(p))
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("pos_zona_ok", false)


func _ir(p: Vector3) -> void:
	v.destino = v._ajustar_destino(p)


func _llego(p: Vector3) -> bool:
	return v.destino == null and Vector2(v.kael.global_position.x - p.x, v.kael.global_position.z - p.z).length() < 0.4


func _andar_ruta(puntos: Array, siguiente: String) -> void:
	ruta = puntos
	i_ruta = 0
	atascos = 0
	_ir(ruta[0])
	_fase("andar:" + siguiente)


func _process(_d: float) -> bool:
	frames += 1
	var dg = root.get_node_or_null("Dialogic")
	if fase.begins_with("andar:"):
		var meta: Vector3 = ruta[i_ruta]
		if _llego(meta):
			i_ruta += 1
			atascos = 0
			if i_ruta >= ruta.size():
				print("OK andar: llegó a %s en %d fotogramas" % [str(meta), frames - f_fase])
				_fase(fase.substr(6))
			else:
				_ir(ruta[i_ruta])
		elif v.destino == null and frames - f_fase > 5 and not v.ocupado():
			atascos += 1                            # (la primera parada de un tramo se reintenta: un diálogo que acaba)
			if atascos > 3:
				_mal("demasiados atascos: se deja la prueba")
				return _terminar()
			if atascos > 1:
				_mal("se paró camino de %s, en %s (atasco o paso cerrado)" % [str(meta), str(v.kael.global_position.snapped(Vector3.ONE * 0.01))])
			_ir(meta)
			f_fase = frames
		elif frames - f_fase > MAX_TRAMO:
			_mal("no llegó a %s (se quedó en %s)" % [str(meta), str(v.kael.global_position.snapped(Vector3.ONE * 0.01))])
			return _terminar()
		return false
	match fase:
		"cargar":
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 20:
				v = current_scene
				print("CARGA hasta el fotograma 20: %.0f ms · construcción de la ciudad: %s" % [(Time.get_ticks_usec() - int(get_meta("t0"))) / 1000.0, str(v.ciudad.tiempos)])
				if v.kael.global_position.distance_to(Vector3(40, 0, 53.2)) > 0.6:
					_mal("Kael no aparece en la Puerta del Sur (%s)" % str(v.kael.global_position))
				_andar_ruta([Vector3(39.7, 0, 48.6)], "aldric")
		"aldric":
			if frames - f_fase == 5:
				if v.cerca != "aldric":
					_mal("junto a Aldric no se ofrece hablar con él (cerca = «%s»)" % v.cerca)
				v._accion()
			elif frames - f_fase == 20:
				if dg == null or dg.current_timeline == null:
					_mal("el diálogo de Aldric no se abrió")
				else:
					print("OK 1: el diálogo de Aldric se abre (%s)" % v.dialogo_actual)
					dg.end_timeline()
			elif frames - f_fase == 70:
				_andar_ruta([Vector3(40, 0, 40), Vector3(40, 0, 31.5), Vector3(37, 0, 27.5), Vector3(30, 0, 26), Vector3(16, 0, 26.0)], "puerta")
		"puerta":
			if frames - f_fase == 5:
				if v.cerca != "posada":
					_mal("ante la taberna no se ofrece entrar en la posada (cerca = «%s»)" % v.cerca)
				print("OK 2: de la Puerta del Sur a la taberna, por la plaza")
				v._accion()
			elif frames - f_fase == 50:
				if not v.en_posada or not S.en_sala(v.kael.global_position):
					_mal("no entró en la posada (Kael en %s)" % str(v.kael.global_position))
				else:
					print("OK 3: dentro de la posada")
				_andar_ruta([S.ORIGEN + S.MOSTRADOR], "posadera")
		"posadera":
			if frames - f_fase == 5:
				if v.cerca != "posadera":
					_mal("ante la barra no se ofrece hablar con la posadera (cerca = «%s»)" % v.cerca)
				v._accion()
				if not v.panel_servicios.visible:
					_mal("no se abre el panel de la posadera")
				I.ganar_oro(200)
				oro_antes = I.oro()
				var r: Dictionary = v._servicio("comer")
				if not r.get("ok", false) or I.oro() != oro_antes - 10:
					_mal("la sopa no cobra 10 monedas (%s, %d → %d)" % [str(r), oro_antes, I.oro()])
				var rumor: Dictionary = v._servicio("rumores")
				if str(rumor.get("texto", "")) == "":
					_mal("la posadera no cuenta ningún rumor")
				else:
					print("OK 4a: sopa (−10) y un rumor: «%s»" % str(rumor["texto"]).left(60))
				for n in G.activos():
					G.guardar_vida(n, 1, 0)
				oro_antes = I.oro()
				v._servicio("dormir")
			elif frames - f_fase == 80:
				if dg != null and dg.current_timeline != null:
					dg.end_timeline()
				var curados := true
				for n in G.activos():
					if int(G.datos()[n]["pv"]) < int(G.estadisticas(n)["pv_max"]):
						curados = false
				if I.oro() != oro_antes - 30 and I.oro() != oro_antes:
					_mal("dormir no cobra la noche (%d → %d)" % [oro_antes, I.oro()])
				elif not curados:
					_mal("tras dormir, el grupo no está curado")
				elif v.franja != "manana":
					_mal("tras dormir no amanece (franja «%s»)" % v.franja)
				else:
					print("OK 4b: dormir (%d → %d), grupo curado y amanece" % [oro_antes, I.oro()])
			elif frames - f_fase == 100:
				if v.panel_servicios.visible:
					v._cerrar_servicios()
				_andar_ruta([S.ORIGEN + S.PUERTA - Vector3(0, 0, 0.6)], "salir_posada")
		"salir_posada":
			if frames - f_fase == 5:
				if v.cerca != "salir_posada":
					_mal("en la puerta de la sala no se ofrece salir (cerca = «%s»)" % v.cerca)
				v._accion()
			elif frames - f_fase == 50:
				if v.en_posada or v.kael.global_position.distance_to(v.PUERTA_TABERNA) > 1.5:
					_mal("al salir no aparece ante la taberna (%s)" % str(v.kael.global_position))
				else:
					print("OK 5a: fuera, ante la taberna")
				v.guardar_posicion()
				var p: Vector3 = Engine.get_meta("pos_3d")
				change_scene_to_file(REGION)
				_fase("volver")
				set_meta("guardada", p)
		"volver":
			if frames - f_fase == 30:
				v = current_scene
				var p: Vector3 = get_meta("guardada")
				if v.kael.global_position.distance_to(p) > 0.3:
					_mal("al volver, Kael no está donde se guardó (%s ≠ %s)" % [str(v.kael.global_position), str(p)])
				else:
					print("OK 5b: guardar y volver deja a Kael donde estaba")
				v._colocar_kael(Vector3(40, 0, 50.5))
				v.salida["armada"] = true
				_ir(Vector3(40, 0, 55.9))
				_fase("salida")
		"salida":
			if current_scene != null and current_scene.scene_file_path == P.MAPA:
				print("OK 5c: sale al mapa por la Puerta del Sur")
				return _terminar()
			if frames - f_fase > 300:
				_mal("no sale al mapa por la Puerta del Sur")
				return _terminar()
	if frames > 8000:
		_mal("la prueba no terminó (fase «%s»)" % fase)
		return _terminar()
	return false


func _terminar() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true
