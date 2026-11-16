extends SceneTree
# V12 (16/11): CIUDAD COMPLETA de Oakhaven, M0: EL CARGADOR Y LA ESCENA (zonas3d/ciudad/cargador.gd, sector.gd,
# ciudad.gd; docs/v12/CIUDAD_OAKHAVEN.md). Sin ventana, con la partida aislada del banco.
#   A. El cargador solo (bajo, medio y alto): Kael recorre la ciudad por el grafo global (todos los sectores); en cada paso,
#      el sector de Kael montado, como mucho MAXIMO[perfil] montados, nada montado más allá de RADIO_DESCARGA y nada se
#      desmonta a menos de RADIO_DESCARGA salvo por el límite; solo se piden rutas sectores/<id>/sector.tscn (nunca
#      interiores); al final, todo desmontado y el número de nodos vuelve al de antes (sin fugas).
#   B. Histéresis (alto): precarga en hilo a 40 m sin montar; monta a 25; sigue montado a 45; se desmonta a 65 y suelta su
#      escena. Límite: en el bajo, nunca más de 3, también en la plaza (5 vecinos).
#   C. La escena en el banco: se activa (ciudad_v12), Kael en la Puerta del Sur con su sector montado (blockout y choques),
#      la maqueta lejana de los no montados, API de región, guardar en el lugar 103; las puertas dicen «en obras» y la
#      Puerta del Sur no saca de la ciudad; cada CONEXIÓN se anda con los controles normales («destino», como un toque) en
#      los dos sentidos, sobre el suelo del plano; lo ocultable que tapa a Kael se aclara; al volver al inicio, los mismos
#      sectores montados y los mismos nodos (sin fugas).
#   D. Fuera del banco la escena no se construye ni se activa; al salir del banco no queda «ciudad_v12»; la carpeta está
#      APAGADA en recursos.gd y fuera de las APK sin banco.
# Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/ciudad/ciudad.tscn"
const P := preload("res://zonas3d/ciudad/plano.gd")
const Cargador := preload("res://zonas3d/ciudad/cargador.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
var fallos := 0
var v


func _initialize() -> void:
	_correr.call_deferred()


# (16/11, arreglos del recorrido: docs/v12/ciudad_sectores/RECORRIDO.md §7) el aclarado por varios puntos (cintura y pies
# de Kael y el grupo), su sostén de SOSTEN s y el toque que cae en el plano cuando los choques no dan suelo.
func _arreglos_recorrido(ps: Node3D) -> void:
	var claro: Material = load("res://zonas3d/ciudad/blockout.gd").material(true)
	var sec := ps as Node
	var casa := ps.get_node("Ocultable_casa_sur_e") as MeshInstance3D
	var caja: AABB = sec.ocultables.filter(func(o): return o[0] == casa)[0][1][0]
	var desde := Vector3(caja.get_center().x, caja.end.y + 8.0, caja.end.z + 10.0)      # al sur y por encima de la casa
	var detras := Vector3(caja.get_center().x, caja.position.y + 0.3, caja.position.z - 1.0)   # al norte, a ras de suelo
	var arriba := Vector3(caja.get_center().x, caja.end.y + 30.0, caja.position.z - 1.0)       # (este no la cruza)
	sec.olvidar_aclarados()
	sec.aclarar(desde, [arriba], 10.0)
	_ok(casa.material_override != claro, "C: un rayo que no cruza la casa no la aclara")
	sec.aclarar(desde, [arriba, detras], 10.0)
	_ok(casa.material_override == claro, "C: con varios puntos, basta uno tapado (los pies) para aclararla")
	sec.aclarar(desde, [arriba], 10.0 + sec.SOSTEN * 0.5)
	_ok(casa.material_override == claro, "C: sigue aclarada %.2f s después de dejar de tapar (sin parpadeo)" % (sec.SOSTEN * 0.5))
	sec.aclarar(desde, [arriba], 10.0 + sec.SOSTEN + 0.05)
	_ok(casa.material_override != claro, "C: y vuelve a opaca pasado el sostén (%.2f s)" % sec.SOSTEN)
	sec.aclarar(desde, [detras], 20.0)
	sec.olvidar_aclarados()
	sec.aclarar(desde, [arriba], 20.01)
	_ok(casa.material_override != claro, "C: al colocar a Kael de golpe, lo aclarado antes no se sostiene")
	sec.olvidar_aclarados()                     # (los tiempos de arriba van por delante del reloj de la escena)
	# el toque contra el plano (lo que se ve de un sector sin montar no tiene choques)
	var n := 0
	var bien := 0
	var malos: Array = []
	for w in [Vector3(-33.0, 2.0, 55.5), P.ancla("inicio"), P.ancla("ref_plaza_tapiz"), P.ancla("ref_terrazas"), P.ancla("ref_barrio_alto")]:
		if not P.andable(w.x, w.z):
			malos.append("%s no es andable" % w)
			continue
		var cam := Vector3(w.x, w.y + 10.8, w.z + 14.2)
		var r = v._punto_plano(cam, (w - cam).normalized())
		n += 1
		if r != null and (r as Vector3).distance_to(w) < 0.1:
			bien += 1
		else:
			malos.append("%s → %s" % [w, r])
	_ok(bien == n, "C: el toque contra el plano cae donde se toca (%d de %d) %s" % [bien, n, str(malos)])
	var cielo = v._punto_plano(Vector3(0.0, 20.0, 60.0), Vector3(0.0, 0.3, -1.0).normalized())
	var fuera = v._punto_plano(Vector3(0.0, 10.0, 110.0), Vector3(0.0, -0.5, 1.0).normalized())
	_ok(cielo == null and fuera == null, "C: el cielo y el campo de fuera de la ciudad no dan toque (%s, %s)" % [str(cielo), str(fuera)])
	await _frames(1)


func _ok(cond: bool, t: String) -> void:
	if cond:
		print("OK " + t)
	else:
		fallos += 1
		print("FALLO: " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _nodos() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


func _correr() -> void:
	for perfil in ["bajo", "medio", "alto"]:
		await _recorrido_solo(perfil)
	await _histeresis()
	await _escena()
	await _fuera_del_banco()
	load("res://zonas3d/ciudad/blockout.gd").soltar()     # (los materiales compartidos de A y B, fuera antes del cierre)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= A

# Una ruta por la ciudad: de nodo a nodo del grafo global (referencias y centros de las conexiones), cada 0,5 m.
func _ruta() -> Array:
	var orden := ["s_puerta_sur", "c_calle_mayor", "s_plaza_tapiz", "c_calle_cuervo", "s_cuervo", "c_escaleras_terrazas",
		"s_terrazas", "c_terrazas_altas", "s_barrio_alto", "c_subida_colina", "s_oficios", "c_escalera_molino", "s_ribera",
		"c_rampa_carros", "s_puerta_sur", "c_arco_pasajes", "s_pasajes", "c_paso_botica", "s_plaza_tapiz", "c_calle_mayor",
		"s_puerta_sur"]
	var r: Array = []
	for i in range(1, orden.size()):
		var a := P.nodo(orden[i - 1])
		var b := P.nodo(orden[i])
		var n := maxi(1, int(ceil(a.distance_to(b) / 0.5)))
		for k in n:
			r.append(a.lerp(b, float(k) / n))
	r.append(P.nodo(orden[-1]))
	return r


func _recorrido_solo(perfil: String) -> void:
	await _frames(2)
	var antes := _nodos()
	var c: Cargador = Cargador.new()
	root.add_child(c)
	c.preparar(perfil, false)
	var maximo: int = Cargador.MAXIMO[perfil]
	var mal: Array = []
	var desmontes_malos: Array = []
	var vistos := {}
	var max_montados := 0
	var cerca_desmontados: Array = []              # (los que se desmontan a menos de RADIO_DESCARGA en esta actualización)
	var desmontado := func(id: String):
		if float(c.distancias[id]) <= Cargador.RADIO_DESCARGA:
			cerca_desmontados.append("%s a %.1f m" % [id, c.distancias[id]])
	c.sector_desmontado.connect(desmontado)
	for p in _ruta():
		cerca_desmontados.clear()
		c.actualizar(p)
		if not cerca_desmontados.is_empty() and c.montados.size() < maximo:   # (solo vale si era para dejar sitio)
			desmontes_malos.append("%s con %d montados" % [str(cerca_desmontados), c.montados.size()])
		await process_frame
		max_montados = maxi(max_montados, c.montados.size())
		for id in c.montados:
			vistos[id] = true
		if c.actual != "" and not c.montados.has(c.actual):
			mal.append("%s sin montar con Kael dentro" % c.actual)
		if c.montados.size() > maximo:
			mal.append("%d montados en %s (máximo %d)" % [c.montados.size(), str(p), maximo])
		for id in c.montados:
			if float(c.distancias[id]) > Cargador.RADIO_DESCARGA:
				mal.append("%s montado a %.1f m" % [id, c.distancias[id]])
	_ok(mal.is_empty(), "A (%s): el sector de Kael siempre montado, ≤ %d montados, nada más allá de %.0f m %s" % [
		perfil, maximo, Cargador.RADIO_DESCARGA, str(mal.slice(0, 6))])
	_ok(desmontes_malos.is_empty(), "A (%s): nada se desmonta a menos de %.0f m salvo por el límite %s" % [
		perfil, Cargador.RADIO_DESCARGA, str(desmontes_malos.slice(0, 6))])
	_ok(vistos.size() == 8, "A (%s): la ruta monta los 8 sectores (%s); como mucho %d a la vez" % [perfil, str(vistos.keys()), max_montados])
	if perfil == "alto":
		_ok(max_montados >= 4, "A (alto): con el perfil alto llega a haber %d montados a la vez" % max_montados)
	var raro: Array = c.pedidos.filter(func(r): return not RegEx.create_from_string(
		"^res://zonas3d/ciudad/sectores/[a-z_]+/sector\\.tscn$").search(r) or "interior" in r)
	_ok(raro.is_empty() and not c.pedidos.is_empty(), "A (%s): solo se piden sectores (%d pedidos), nunca interiores %s" % [
		perfil, c.pedidos.size(), str(raro)])
	_ok(c.esperas <= 3, "A (%s): casi siempre la carga en hilo llega antes de hacer falta (esperas %d: la primera entrada y, según el hilo, alguna más)" % [perfil, c.esperas])
	c.desmontar_todo()
	await _frames(3)
	_ok(c.montados.is_empty() and c.get_child_count() == 0, "A (%s): todo desmontado (%d hijos)" % [perfil, c.get_child_count()])
	c.free()
	await _frames(3)
	_ok(_nodos() == antes, "A (%s): sin fugas de nodos (%d antes, %d después)" % [perfil, antes, _nodos()])


# ================================================================= B

func _histeresis() -> void:
	var c: Cargador = Cargador.new()
	root.add_child(c)
	c.preparar("alto", false)
	var z := 23.0                                          # la Calle del Cuervo; la caja de «cuervo» acaba en x −30
	c.actualizar(Vector3(40.0, 2.0, z))                   # a 70 m
	await _frames(2)
	_ok(c.estado["cuervo"] == "lejos" and not c.montados.has("cuervo"), "B: a 70 m, «cuervo» ni pedido ni montado (%s)" % c.estado["cuervo"])
	c.actualizar(Vector3(5.0, 2.0, z))                    # a 35 m: precarga
	_ok(c.estado["cuervo"] in ["cargando", "cargado"] and not c.montados.has("cuervo"),
		"B: a 35 m, pedido en hilo (%s) y sin montar" % c.estado["cuervo"])
	for i in 60:
		await process_frame
		c.actualizar(Vector3(5.0, 2.0, z))
		if c.estado["cuervo"] == "cargado":
			break
	_ok(c.estado["cuervo"] == "cargado" and not c.montados.has("cuervo"), "B: la carga en hilo termina sin montar (%s)" % c.estado["cuervo"])
	var e0: int = c.esperas
	c.actualizar(Vector3(-10.0, 2.0, z))                  # a 20 m: se monta
	_ok(c.montados.has("cuervo") and c.esperas == e0, "B: a 20 m se monta (sin esperar a la carga)")
	c.actualizar(Vector3(15.0, 2.0, z))                   # a 45 m: sigue (histéresis)
	_ok(c.montados.has("cuervo"), "B: a 45 m sigue montado (histéresis)")
	c.actualizar(Vector3(35.0, 2.0, z))                   # a 65 m: fuera
	_ok(not c.montados.has("cuervo") and not c.escenas.has("cuervo") and c.estado["cuervo"] == "lejos",
		"B: a 65 m se desmonta y suelta su escena (%s)" % c.estado["cuervo"])
	c.free()
	# el límite del bajo en la plaza, que tiene 5 vecinos
	var b: Cargador = Cargador.new()
	root.add_child(b)
	b.preparar("bajo", false)
	var peor := 0
	for x in range(-28, 44, 2):
		for zz in range(-12, 60, 4):
			b.actualizar(Vector3(x, 0.0, zz))
			peor = maxi(peor, b.montados.size())
			if b.actual != "" and not b.montados.has(b.actual):
				peor = 99
	_ok(peor <= 3, "B: en el bajo, por toda la plaza, como mucho %d montados (máx. 3) y siempre el de Kael" % peor)
	b.desmontar_todo()
	b.free()
	await _frames(3)


# ================================================================= C

func _escena() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(BP.EXPLORAR["ciudad"]["activos"])
	_ok(BP.EXPLORAR.has("ciudad") and BP.EXPLORAR["ciudad"]["escena"] == ESCENA
		and BP.EXPLORAR["ciudad"]["titulo"] == "Ciudad de Oakhaven (maqueta, en pruebas)", "C: el banco tiene el caso «ciudad»")
	_ok("ciudad_v12" in BP.METAS_SESION, "C: «ciudad_v12» es meta de sesión del banco")
	Engine.set_meta("calidad_proto", "bajo")
	change_scene_to_file(ESCENA)
	v = null
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			v = current_scene
			break
	await _frames(10)
	_ok(v != null, "C: la escena carga en el banco")
	if v == null:
		return
	_ok(Engine.get_meta("ciudad_v12", false), "C: dentro del banco se activa (ciudad_v12)")
	var c = v.cargador
	_ok(v.kael.global_position.distance_to(P.ancla("inicio")) < 0.3 and c.montados.has("puerta_sur"),
		"C: Kael en la Puerta del Sur (%s) con su sector montado (%s)" % [str(v.kael.global_position), str(c.ids_montados())])
	var sec: Node3D = c.montados.get("puerta_sur")
	var t = P.trazado("puerta_sur")
	var solidos: int = t.BLOQUES.filter(func(b): return b[6]).size()
	_ok(sec != null and sec.get_node_or_null("Blockout") != null and sec.choques == solidos + t.SUELOS.size()
		and sec.get_node_or_null("Rotulo_sector") != null,
		"C: el sector montado: blockout, un choque por caja y por suelo (%d), rótulo" % (sec.choques if sec != null else -1))
	var lej_ok := true
	for id in P.ORDEN:
		lej_ok = lej_ok and c.lejanas.has(id) and (c.lejanas[id] as Node3D).visible == not c.montados.has(id)
	_ok(lej_ok, "C: la maqueta lejana se ve justo en los sectores no montados")
	_ok(c.maximo() == 3 and c.montados.size() <= 3, "C: perfil bajo: como mucho 3 montados (%d)" % c.montados.size())
	for f in ["avisar", "guardar", "guardar_posicion", "ocupado", "sonda", "iniciar_dialogo", "ancla", "volver_al_banco"]:
		_ok(v.has_method(f), "C: la escena tiene %s()" % f)
	_ok(v.sonda(Vector3.ZERO) == Vector2(1.0, 0.7) and v.ancla("ref_plaza_tapiz") == P.ancla("ref_plaza_tapiz"),
		"C: sonda provisional y anclas del plano")
	_ok(not v.iniciar_dialogo("res://no_existe.dtl"), "C: iniciar_dialogo con una ruta que no existe devuelve false")
	v.guardar()
	_ok(int(Engine.get_meta("pos_3d_lugar", -1)) == 103 and FileAccess.file_exists(BP.ARCHIVO), "C: guardar pone el lugar 103 en el archivo del banco")
	# puertas previstas y la Puerta del Sur
	for pu in [["puerta_sur", "establo"], ["plaza_tapiz", "botica"]]:
		var d: Dictionary = P.trazado(pu[0]).PUERTAS[pu[1]]
		v._colocar_kael(d["fuera"])
		await _frames(2)
		v._bloqueo = 0.0
		v._comprobar_cerca()
		_ok(v.cerca == "entrar_%s/%s" % pu and v.boton_accion.visible and v.boton_accion.text == d["texto"],
			"C: junto a %s/%s, el botón «%s» (%s)" % [pu[0], pu[1], d["texto"], v.cerca])
		v._accion()
		_ok(v.ultimo_aviso == v.TEXTO_OBRAS, "C: %s: «%s»" % [pu[1], v.ultimo_aviso])
	v._colocar_kael(P.ancla("puerta_sur"))
	await _frames(2)
	v._bloqueo = 0.0
	v._comprobar_cerca()
	v._accion()
	_ok(v.cerca == "puerta_sur" and v.ultimo_aviso == v.TEXTO_SALIDA and v.get_tree().current_scene == v,
		"C: la Puerta del Sur no saca de la ciudad («%s»)" % v.ultimo_aviso)
	# lo ocultable se aclara: al norte de la casa del sur de la plaza baja
	v._colocar_kael(Vector3(15.0, 2.0, 29.6))
	await _frames(3)
	var ps: Node3D = c.montados.get("plaza_tapiz")
	var aclarada: bool = ps != null and ps.get_node_or_null("Ocultable_casa_sur_e") != null \
		and (ps.get_node("Ocultable_casa_sur_e") as MeshInstance3D).material_override == load("res://zonas3d/ciudad/blockout.gd").material(true)
	_ok(aclarada and v.aclarados >= 1, "C: la casa del sur de la plaza baja se aclara con Kael delante (%d aclaradas)" % v.aclarados)
	v._colocar_kael(Vector3(0.0, 2.0, 20.0))
	await _frames(3)
	_ok(ps != null and (ps.get_node("Ocultable_casa_sur_e") as MeshInstance3D).material_override == load("res://zonas3d/ciudad/blockout.gd").material(false),
		"C: y vuelve a opaca al apartarse")
	await _arreglos_recorrido(ps)
	await _conexiones_andadas()
	# vuelta al inicio: los mismos sectores y los mismos nodos que la vez anterior que se llegó igual (inicio → Árbol →
	# inicio, dos veces: la primera deja lo que la histéresis guarde de antes)
	for i in 2:
		v._colocar_kael(P.ancla("inicio"))
		await _frames(6)
		v._colocar_kael(P.ancla("ref_barrio_alto"))
		await _frames(6)
	v._colocar_kael(P.ancla("inicio"))
	await _frames(6)
	var montados0: Array = c.ids_montados()
	var nodos0 := _nodos()
	v._colocar_kael(P.ancla("ref_barrio_alto"))
	await _frames(6)
	v._colocar_kael(P.ancla("inicio"))
	await _frames(6)
	_ok(c.ids_montados() == montados0 and _nodos() == nodos0, "C: de vuelta al inicio, los mismos sectores (%s) y nodos (%d → %d)" % [
		str(c.ids_montados()), nodos0, _nodos()])


# Cada conexión, andada con «destino» (como un toque) de 3 m a un lado a 3 m al otro, y de vuelta.
func _conexiones_andadas() -> void:
	var peor_y := 0.0
	var giro := 0.0
	for con in P.CONEXIONES:
		for sentido in [["a", "b"], ["b", "a"]]:
			var desde := P.punto_conexion(con, sentido[0], 3.0)
			var hasta := P.punto_conexion(con, sentido[1], 3.0)
			v._colocar_kael(desde)
			await _frames(3)
			v.destino = v._ajustar_destino(hasta)
			var max_montados := 0
			for f in 400:
				await process_frame
				var k: Vector3 = v.kael.global_position
				peor_y = maxf(peor_y, absf(k.y - P.altura(k.x, k.z)))
				giro = maxf(giro, absf(v.cam.global_rotation_degrees.y))
				max_montados = maxi(max_montados, v.cargador.montados.size())
				if v.destino == null:
					break
			var k2: Vector3 = v.kael.global_position
			var falta := Vector2(k2.x - hasta.x, k2.z - hasta.z).length()
			_ok(falta < 0.6 and max_montados <= 3, "C: %s de %s a %s andando (a %.2f m; montados ≤ %d)" % [
				con["id"], con[sentido[0]], con[sentido[1]], falta, max_montados])
	_ok(peor_y < 0.12, "C: Kael va sobre el suelo del plano (diferencia máxima %.3f m)" % peor_y)
	_ok(giro < 0.001, "C: la cámara no gira")


# ================================================================= D

func _fuera_del_banco() -> void:
	var BP = load("res://banco_pruebas.gd")
	if current_scene != null:
		current_scene.queue_free()
		await _frames(3)
	BP.salir()
	for m in ["ciudad_v12", "banco_pruebas"]:
		_ok(not Engine.has_meta(m), "D: al salir del banco no queda «%s»" % m)
	var r = load(ESCENA).instantiate()
	root.add_child(r)
	_ok(r.fuera_del_banco and r.kael == null and r.get_node_or_null("Exterior") == null,
		"D: fuera del banco la escena no se construye (vuelve a la carga)")
	_ok(not Engine.has_meta("ciudad_v12"), "D: y no se activa")
	r.free()
	var R = load("res://recursos.gd")
	_ok(R.APAGADOS.get("res://zonas3d/ciudad/", "") == "ciudad_v12", "D: la carpeta está APAGADA en recursos.gd (ciudad_v12)")
	var cfg := ConfigFile.new()
	cfg.load("res://export_presets.cfg")
	_ok("zonas3d/*" in str(cfg.get_value("preset.0", "exclude_filter", "")), "D: la APK estable excluye zonas3d/*")
	for k in [1, 2]:
		var excl := str(cfg.get_value("preset.%d" % k, "exclude_filter", ""))
		_ok("zonas3d/ciudad/*" in excl, "D: la APK «%s» excluye zonas3d/ciudad/*" % cfg.get_value("preset.%d" % k, "name", "?"))
	_ok(not "zonas3d/ciudad" in str(cfg.get_value("preset.3", "exclude_filter", "")), "D: la APK de Auditoría (con el banco) la lleva")
