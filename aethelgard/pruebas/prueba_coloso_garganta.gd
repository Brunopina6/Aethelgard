extends SceneTree
# El Coloso de la Falla en la Garganta del Diablo 3D (V9, jefe 2; zonas3d/garganta_3d.gd y zonas3d/garganta/coloso.gd),
# con la exploración 3D y su argumento («-- 3d garganta3d sin_prologo»). Escenas de verdad (combate.tscn incluido) y
# Kael andando con la física y las zonas prohibidas de la región, como pruebas/prueba_garganta3d.gd.
#   1. Sitio: el Coloso duerme al fondo de la grieta; su disparo no alcanza el pilar del peregrino ni la vuelta, y la
#      vuelta se puede pisar.
#   2. Andando hacia él: Kael se para, el aviso (con la frase de Garon) y, después, su combate fijo («garganta_coloso»,
#      grupo 12, «jefe», vuelta fuera del disparo).
#   3. Se pierde: se vuelve a la vuelta, sin repetir el combate nada más volver ni apuntarlo; el Coloso sigue; el pilar
#      del peregrino se examina sin despertarle.
#   4. Se vuelve a él y se gana: premio (Mineral rúnico y Fragmento), el Coloso ya no está, andar hasta su sitio no
#      dispara nada (aviso de las placas caídas) y la partida guardada lo lleva ganado.
# Guarda de verdad, pero solo en su archivo (user://prueba_coloso_garganta.save, Engine «archivo_partida_prueba»).
# Termina con «FALLOS: n» y quit(1) si algo no se cumple.

const REGION := "res://zonas3d/garganta_3d.tscn"
const COMBATE := "res://combate.tscn"
const ARCHIVO := "user://prueba_coloso_garganta.save"
const ESPERA_MAX_MS := 45000
const TOL := 0.6
const K := preload("res://combate_coloso.gd")
const ALCANCE := Vector3(12.6, -8.0, -37.4)          # junto al Coloso, en la cornisa: se pisa y le despierta
const CASCADA_TRAMO := Vector3(11.4, -8.0, -36.0)    # donde prueba_garganta3d_tramo espera el comentario de la cascada

var frames := 0
var paso := 0
var t_paso := 0
var f_paso := 0
var R
var P
var T
var G3
var inv
var fallos: Array = []
var aviso_visto := false


func _initialize() -> void:
	R = root.get_node("Recursos")
	P = load("res://progreso.gd")
	T = load("res://zonas3d/garganta/trazado.gd")
	G3 = load("res://zonas3d/garganta_3d.gd")
	inv = load("res://inventario.gd")
	if not load("res://modo3d.gd").activo():
		fallos.append("la exploración 3D no está activa (falta «-- 3d»)")
		_terminar()
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("partida_lista", true)
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "lore_visto", "incienso", "inventario", "grupo_activo",
			"pos_3d", "pos_3d_ok", "pos_3d_lugar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	change_scene_to_file(REGION)
	_siguiente(1)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _siguiente(n: int) -> void:
	paso = n
	t_paso = Time.get_ticks_msec()
	f_paso = frames


func _lista(ruta: String, n := 8) -> bool:
	return _escena() == ruta and not R.cambiando and frames - f_paso >= n


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _poner(r, p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 2.0, 0), p - Vector3(0, 6.0, 0))
	var hit: Dictionary = r.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		p.y = hit["position"].y
	r._colocar_kael(p)
	r._ultima = p


func _andar(r, hacia: Vector3) -> void:
	r.destino = r._ajustar_destino(hacia)
	f_paso = frames


func _parado(r) -> bool:
	return r.destino == null and frames - f_paso > 3


func _terminar() -> void:
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		fallos.append("el paso %d no terminó en %d s (escena=%s)" % [paso, ESPERA_MAX_MS / 1000, _escena()])
		_terminar()
		return true
	var r = current_scene
	if r != null and _escena() == REGION and "pasos" in r:
		r.pasos = 0                                    # sin encuentros al azar (solo en la prueba)
	match paso:
		1:
			if _lista(REGION, 10):
				_sitio(r)
		2:
			if _escena() == REGION and r._coloso_hablando and not aviso_visto:
				aviso_visto = true
				if not G3.TEXTO_COLOSO in r.aviso.text or not G3.TEXTO_COLOSO_GARON in r.aviso.text:
					fallos.append("2: al llegar, el aviso no es el del Coloso con la frase de Garon («%s»)" % r.aviso.text)
				if r.destino != null:
					fallos.append("2: Kael sigue andando durante el aviso")
			elif _escena() == REGION and r.saliendo:
				if Engine.get_meta("combate_fijo", "") != K.COMBATE or Engine.get_meta("grupo_combate", -1) != K.GRUPO \
						or Engine.get_meta("tipo_combate", "") != "jefe" or Engine.get_meta("escena_retorno", "") != REGION:
					fallos.append("2: el combate del Coloso no lleva sus datos (%s, %s, %s)" % [Engine.get_meta("combate_fijo", "-"),
						Engine.get_meta("grupo_combate", -1), Engine.get_meta("tipo_combate", "-")])
				if _plana(Engine.get_meta("pos_3d"), G3.VUELTA_COLOSO) > 0.05:
					fallos.append("2: tras su combate no se volverá a la vuelta")
				_siguiente(3)
			elif _escena() == REGION and _parado(r) and not r._coloso_hablando and not aviso_visto and frames - f_paso > 120:
				fallos.append("2: Kael llegó junto al Coloso sin combate (%s)" % r.kael.global_position)
				_terminar()
		3:
			if _lista(COMBATE, 5):
				if not r.enemigos.any(func(e): return K.es_coloso(e)):
					fallos.append("3: en el combate no está el Coloso")
				print("OK 2: al llegar, aviso con la frase de Garon y el combate fijo del Coloso (grupo 12, jefe); se pierde")
				r._volver_al_mapa()
				_siguiente(4)
		4:
			if _lista(REGION, 30):
				_tras_perder(r)
		5:
			if _escena() == REGION and r.saliendo:
				_siguiente(6)
			elif _escena() == REGION and _parado(r) and not r._coloso_hablando and frames - f_paso > 120:
				fallos.append("4: al volver a por él, no hay combate (%s)" % r.kael.global_position)
				_terminar()
		6:
			if _lista(COMBATE, 5):
				r._fin_combate(true)
				_siguiente(7)
		7:
			if _lista(REGION, 30):
				_tras_ganar(r)
		8:
			if _parado(r):
				if r.saliendo or r._coloso_hablando:
					fallos.append("4: el Coloso despierta otra vez tras vencerle")
				if r.aviso.text != G3.TEXTO_COLOSO_VENCIDO:
					fallos.append("4: en su sitio no sale el aviso de las placas caídas («%s»)" % r.aviso.text)
				var guardada = P.leer(ARCHIVO)
				if guardada == null or not guardada.get("combates_ganados", {}).get(K.COMBATE, false):
					fallos.append("4: la partida guardada no lleva el Coloso vencido")
				print("OK 4b: vencido, no reaparece ni despierta; quedan sus placas y la partida lo guarda")
				_terminar()
	return false


func _sitio(r) -> void:
	if r.coloso == null:
		fallos.append("1: el Coloso no duerme en la grieta")
	if P.ganado(K.COMBATE):
		fallos.append("1: el combate del Coloso sale ganado en una partida nueva")
	if _plana(G3.COLOSO, T.PILAR_PEREGRINO) - G3.RADIO_COLOSO <= G3.RADIO_PIEZA:
		fallos.append("1: su disparo alcanza el sitio desde el que se examina el pilar")
	if _plana(G3.COLOSO, G3.VUELTA_COLOSO) <= G3.RADIO_COLOSO + 0.5:
		fallos.append("1: la vuelta queda dentro de su disparo")
	if not T.andable(G3.VUELTA_COLOSO, false) or not T.andable(ALCANCE, false) or not r._en_coloso(ALCANCE):
		fallos.append("1: la vuelta o el sitio junto al Coloso no se pueden pisar (o no despiertan)")
	if r._en_coloso(CASCADA_TRAMO):
		fallos.append("1: el sitio de la cascada de prueba_garganta3d_tramo despierta al Coloso")
	if fallos.is_empty():
		print("OK 1: el Coloso duerme al fondo de la grieta; su disparo no alcanza el pilar ni la vuelta")
	_poner(r, G3.VUELTA_COLOSO)
	_andar(r, ALCANCE)
	_siguiente(2)


func _tras_perder(r) -> void:
	var antes := fallos.size()
	if P.ganado(K.COMBATE):
		fallos.append("3: perder lo apunta como ganado")
	if _plana(r.kael.global_position, G3.VUELTA_COLOSO) > TOL:
		fallos.append("3: tras perder, Kael aparece a %.2f m de la vuelta" % _plana(r.kael.global_position, G3.VUELTA_COLOSO))
	if r.saliendo or r._coloso_hablando:
		fallos.append("3: el combate del Coloso se repite nada más volver")
	if r.coloso == null:
		fallos.append("3: tras perder, el Coloso ya no está")
	if inv.cantidad(K.MATERIAL) != 0:
		fallos.append("3: perder da el premio")
	_poner(r, T.PILAR_PEREGRINO + Vector3(-0.4, 0, 1.4))
	r._comprobar_cerca()
	if r.cerca != "detalle_p8":
		fallos.append("3: junto al pilar del peregrino no sale «Examinar» (cerca = «%s»)" % r.cerca)
	if fallos.size() == antes:
		print("OK 3: tras perder, vuelta fuera del disparo, sin repetir ni apuntar; el pilar se examina sin despertarle")
	_poner(r, G3.VUELTA_COLOSO)
	_andar(r, ALCANCE)
	_siguiente(5)


func _tras_ganar(r) -> void:
	var antes := fallos.size()
	if not P.ganado(K.COMBATE):
		fallos.append("4: ganar no lo apunta")
	if inv.cantidad(K.MATERIAL) != K.CANTIDAD_MATERIAL or not K.ACCESORIO in inv.datos()["equipables"]:
		fallos.append("4: el premio no llega (%s: %d)" % [K.MATERIAL, inv.cantidad(K.MATERIAL)])
	if r.coloso != null:
		fallos.append("4: el Coloso sigue dormido en la grieta tras vencerle")
	if _plana(r.kael.global_position, G3.VUELTA_COLOSO) > TOL:
		fallos.append("4: tras ganar, Kael aparece a %.2f m de la vuelta" % _plana(r.kael.global_position, G3.VUELTA_COLOSO))
	if fallos.size() == antes:
		print("OK 4a: se gana: +%d %s y el Fragmento; el Coloso ya no está" % [K.CANTIDAD_MATERIAL, K.MATERIAL])
	_andar(r, ALCANCE)
	_siguiente(8)
