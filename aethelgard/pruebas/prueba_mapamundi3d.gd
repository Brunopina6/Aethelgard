extends SceneTree
# V12, mapamundi 3D (15/11/2026): prueba de la primera región del mapamundi 3D (zonas3d/mapamundi_3d.gd; EN PRUEBAS,
# apagado por defecto) con «-- 3d mapamundi3d sin_prologo». Juega con las escenas de verdad (Recursos.cambiar_escena,
# Oakhaven 3D, Pastos Verdes 3D, la cueva provisional y el combate) y anda con el controlador real (destino → vista3d.gd):
#   1. interruptor: encendido con el argumento; la salida de Oakhaven y de Pastos lleva al mapamundi junto a su entrada;
#   2. Oakhaven → mapamundi: Kael fuera del círculo, sin reentrar solo; SOLO Kael (sin grupo_3d) y el grupo intacto;
#   3. por el camino hasta Pastos: descubre el campamento al pasar; entra pisando el círculo; en Pastos, el grupo sigue;
#      Pastos → mapamundi junto a su entrada;
#   4. la cueva: se descubre al acercarse, se entra, el frasco (1 Éter, una vez), se sale junto a su entrada;
#   5. el secreto por la senda casi borrada: se descubre y su premio sale una sola vez;
#   6. viaje rápido: solo destinos descubiertos (los desconocidos no salen), cancelar (Esc), al campamento y a Oakhaven,
#      «ya estás aquí», el mojón del campamento; llegada segura (pasos a cero, sin entrar solo);
#   7. bloqueos explicados: combate (en el encuentro y dentro del combate), escena, antes del prólogo, barrera de un hito
#      y destino desconocido; encuentro → combate → vuelta al mismo sitio;
#   8. guardar y cargar (Progreso.cargar) y una partida antigua sin la clave: nada revelado;
#   9. tres vueltas mapamundi → Oakhaven → mapamundi sin duplicar nodos, Kael ni conexiones;
#  10. una carga que falla (ruta que no existe y escena rota): se vuelve a ver el mapamundi, con control, sin negro.
# Partida propia (Engine «archivo_partida_prueba»). Espera las cargas por RELOJ. Imprime «FALLOS: n».

const MM := "res://zonas3d/mapamundi_3d.tscn"
const OAK := "res://zonas3d/oakhaven_3d.tscn"
const PASTOS := "res://zonas3d/pastos_verdes_3d.tscn"
const CUEVA := "res://zonas3d/cueva_provisional_3d.tscn"
const ARCHIVO := "user://prueba_mapamundi3d.save"
const ROTA := "user://mm3d_no_escena.tres"

var D = load("res://zonas3d/mapamundi/datos.gd")
var M = load("res://modo3d.gd")
var P = load("res://progreso.gd")
var Inv = load("res://inventario.gd")
var R
var v
var fallos := 0
var grupo_antes := ""
var activos_antes := ""


func _initialize() -> void:
	_correr()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(t: String) -> void:
	print("OK " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# Espera por RELOJ (no por fotogramas: con --fixed-fps los fotogramas no son tiempo real).
func _ms(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _hasta(cond: Callable, max_ms := 20000) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < max_ms:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _esperar_escena(ruta: String, max_ms := 40000) -> bool:
	var ok := await _hasta(func(): return _escena() == ruta and not R.cambiando and current_scene.get("kael") != null, max_ms)
	await _frames(6)
	v = current_scene
	if not ok:
		_mal("no se llega a «%s» (escena: «%s»)" % [ruta, _escena()])
	return ok


func _plano(n: Node3D) -> Vector2:
	return Vector2(n.global_position.x, n.global_position.z)


# Anda como un jugador: un destino por punto (el mismo camino que un toque: _ajustar_destino) y espera a llegar.
func _andar(ruta: Array, nombre: String, tolerancia := 0.8) -> bool:
	for c in ruta:
		if _escena() != MM and _escena() != CUEVA:
			return true                               # ya entró en otra escena (un círculo de entrada)
		var meta := Vector3(c.x, v.kael.global_position.y, c.y)
		v.destino = v._ajustar_destino(meta)
		await _hasta(func(): return not is_instance_valid(v) or v.destino == null or v.get("saliendo") == true, 15000)
		if not is_instance_valid(v) or v.get("saliendo") == true:
			return true
		if _plano(v.kael).distance_to(c) > tolerancia:
			_mal("ruta «%s»: no llega a %s (se queda en %s)" % [nombre, c, _plano(v.kael)])
			return false
	return true


func _sin_grupo_visible(donde: String) -> void:
	var g: Array = v.find_children("*", "", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://zonas3d/grupo_3d.gd")
	if not g.is_empty():
		_mal("%s: el grupo camina detrás de Kael (grupo_3d) en el mapamundi" % donde)
	if var_to_str(Engine.get_meta("grupo", {})) != grupo_antes or var_to_str(Engine.get_meta("grupo_activo", [])) != activos_antes:
		_mal("%s: los datos del grupo han cambiado" % donde)
	else:
		_ok("%s: solo Kael en el mapamundi; el grupo (%s) sigue con sus datos intactos" % [donde, Engine.get_meta("grupo_activo")])


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", D.LLEGADA, "mm3d_sin_prologo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _correr() -> void:
	R = root.get_node("Recursos")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_limpiar()
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true, "pv_06": true, "pv_07": true})
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("mm3d_sin_encuentros", true)     # los encuentros al azar, apagados (el 7 fuerza uno)
	load("res://grupo.gd").datos()
	grupo_antes = var_to_str(Engine.get_meta("grupo"))
	activos_antes = var_to_str(Engine.get_meta("grupo_activo"))
	await _paso1_interruptor()
	await _paso2_oakhaven()
	await _paso3_pastos()
	await _paso4_cueva()
	await _paso5_secreto()
	await _paso6_viaje()
	await _paso7_bloqueos()
	await _paso8_guardado()
	await _paso9_repeticion()
	await _paso10_fallo()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= 1

func _paso1_interruptor() -> void:
	if not M.activo() or not M.mapamundi_activo():
		_mal("el mapamundi 3D no está activo con «3d mapamundi3d»")
	if M.salida_al_mapa(0) != MM or Engine.get_meta(D.LLEGADA, "") != "oakhaven":
		_mal("la salida de Oakhaven no lleva al mapamundi junto a su entrada")
	if M.salida_al_mapa(10) != MM or Engine.get_meta(D.LLEGADA, "") != "pastos":
		_mal("la salida de Pastos no lleva al mapamundi junto a su entrada")
	if M.salida_al_mapa(2) != "res://mapa.tscn":
		_mal("la salida de otro lugar (la Garganta) no va al mapa de siempre")
	Engine.remove_meta(D.LLEGADA)
	if M.escena_equivalente(MM) != "" or M.escena_equivalente(CUEVA) != "":
		_mal("una partida del mapamundi encendido no se quedaría en él")
	_ok("1 interruptor: encendido con el argumento; Oakhaven y Pastos salen al mapamundi; los demás, al mapa de siempre")


# ================================================================= 2

func _paso2_oakhaven() -> void:
	change_scene_to_file(OAK)
	if not await _esperar_escena(OAK):
		return
	v._salir()
	if not await _esperar_escena(MM):
		return
	var lleg: Vector2 = D.SITIOS["oakhaven"]["llegada"]
	if v.llegada_id != "oakhaven" or _plano(v.kael).distance_to(lleg) > 0.3:
		_mal("al salir de Oakhaven, Kael no aparece junto a su entrada (%s, %s)" % [v.llegada_id, _plano(v.kael)])
	var e: Dictionary = v.entradas["oakhaven"]
	if _plano(v.kael).distance_to(Vector2(e["pos"].x, e["pos"].z)) <= v.RADIO_ENTRADA:
		_mal("Kael aparece dentro del círculo de entrada de Oakhaven")
	await _ms(1500)
	if _escena() != MM:
		_mal("reentrada automática en Oakhaven al volver al mapamundi")
	if not D.descubierto("oakhaven"):
		_mal("Oakhaven no queda descubierta tras visitarla")
	if not "oakhaven" in D.destinos_conocidos() or "campamento" in D.destinos_conocidos():
		_mal("destinos de viaje tras Oakhaven: %s (se esperaba solo oakhaven)" % [D.destinos_conocidos()])
	if v.rotulos["campamento"].visible or v.rotulos["cueva"].visible or v.rotulos["secreto"].visible:
		_mal("se ven los nombres de sitios sin descubrir")
	var guardada = P.leer(ARCHIVO)
	if not guardada is Dictionary or guardada.get("escena_guardada", "") != MM:
		_mal("al llegar al mapamundi no se guarda la partida en él")
	_sin_grupo_visible("Oakhaven → mapamundi")
	_ok("2 Oakhaven → mapamundi: junto a la entrada, sin reentrar en 1,5 s, Oakhaven descubierta y guardado (t _ready %d ms)" % v.t_preparar_ms)


# ================================================================= 3

func _paso3_pastos() -> void:
	if _escena() != MM:
		return
	var ruta: Array = []
	for p in D.CAMINO:
		if p.x > -9.0 and p.x < 22.5:
			ruta.append(p)
	if not await _andar(ruta, "Oakhaven → Pastos"):
		return
	if not D.descubierto("campamento") or not v.rotulos["campamento"].visible:
		_mal("al pasar junto al campamento no se descubre")
	else:
		_ok("3a campamento descubierto al pasar (nombre visible, destino de viaje: %s)" % [D.destinos_conocidos()])
	await _andar([D.SITIOS["pastos"]["entrada"]], "entrada de Pastos")
	if not await _esperar_escena(PASTOS):
		return
	var g = v.get("grupo")
	if g == null or g.nodos().size() < 2:
		_mal("en Pastos Verdes no camina el grupo detrás de Kael (la formación de dentro no debe cambiar)")
	else:
		_ok("3b Pastos Verdes 3D cargado al pisar su miniatura; el grupo le sigue dentro (%d)" % g.nodos().size())
	await _ms(800)
	v._salir()
	if not await _esperar_escena(MM):
		return
	var lleg: Vector2 = D.SITIOS["pastos"]["llegada"]
	if v.llegada_id != "pastos" or _plano(v.kael).distance_to(lleg) > 0.3:
		_mal("al salir de Pastos, Kael no aparece junto a su entrada")
	await _ms(1200)
	if _escena() != MM:
		_mal("reentrada automática en Pastos")
	_sin_grupo_visible("Pastos → mapamundi")
	_ok("3c Pastos → mapamundi junto a su entrada, sin reentrar")


# ================================================================= 4

func _paso4_cueva() -> void:
	if _escena() != MM:
		return
	var ruta: Array = []
	for i in range(D.CAMINO.size() - 1, -1, -1):
		var p: Vector2 = D.CAMINO[i]
		if p.x < 23.0 and p.x > D.BIFURCACION.x:
			ruta.append(p)
	ruta += D.SENDA_CUEVA
	if D.descubierto("cueva"):
		_mal("la cueva ya estaba descubierta antes de acercarse")
	if not await _andar(ruta, "Pastos → cueva"):
		return
	if not D.descubierto("cueva"):
		_mal("la cueva no se descubre al acercarse")
	await _andar([D.SITIOS["cueva"]["entrada"]], "entrada de la cueva")
	if not await _esperar_escena(CUEVA):
		return
	var g = v.get("grupo")
	_ok("4a cueva provisional cargada (grupo dentro: %d)" % (g.nodos().size() if g != null else 0))
	var eter0 := _cantidad("Éter")
	await _andar([Vector2(0, 3), Vector2(3.2, 0.0), Vector2(3.4, -3.6), Vector2(4.6, -4.6)], "al fondo de la cueva")
	await _frames(3)
	if v.cerca != "hallazgo":
		_mal("junto a los cristales no se ofrece «Examinar» (cerca=%s)" % v.cerca)
	v._pulsar()
	v._coger()
	if _cantidad("Éter") != eter0 + 1:
		_mal("el frasco de la cueva no da 1 Éter una sola vez (%d → %d)" % [eter0, _cantidad("Éter")])
	else:
		_ok("4b el frasco de la cueva: +1 Éter, una sola vez")
	await _andar([Vector2(3.4, -3.6), Vector2(3.2, 0.0), Vector2(0, 3), Vector2(0, 7.6)], "a la boca")
	await _andar([Vector2(0, 9.2)], "salida de la cueva", 2.0)
	if not await _esperar_escena(MM):
		return
	if v.llegada_id != "cueva" or _plano(v.kael).distance_to(D.SITIOS["cueva"]["llegada"]) > 0.3:
		_mal("al salir de la cueva, Kael no aparece junto a su entrada")
	await _ms(1000)
	if _escena() != MM:
		_mal("reentrada automática en la cueva")
	_ok("4c cueva: descubierta, entrada y salida junto a su entrada, sin reentrar")


func _cantidad(o: String) -> int:
	var inv: Dictionary = Engine.get_meta("inventario", {})
	return int(inv.get("objetos", {}).get(o, 0))


# ================================================================= 5

func _paso5_secreto() -> void:
	if _escena() != MM:
		return
	if D.descubierto("secreto") or v.rotulos["secreto"].visible:
		_mal("el secreto se ve antes de descubrirlo")
	var pociones := _cantidad("Poción")
	var eter := _cantidad("Éter")
	var ruta := [Vector2(-23.0, -4.2), Vector2(-17.6, -1.6), D.SENDA_SECRETA[0]]
	ruta += D.SENDA_SECRETA.slice(1)
	ruta.append(D.SITIOS["secreto"]["centro"] + Vector2(0.9, -0.9))
	if not await _andar(ruta, "senda del secreto"):
		return
	await _frames(3)
	if not D.descubierto("secreto") or not v.rotulos["secreto"].visible:
		_mal("el Corro de los Mirlos no se descubre al llegar")
	if _cantidad("Poción") != pociones + 2 or _cantidad("Éter") != eter + 1:
		_mal("el premio del secreto no es 2 Pociones y 1 Éter (%d→%d, %d→%d)" % [pociones, _cantidad("Poción"), eter, _cantidad("Éter")])
	await _andar([D.SENDA_SECRETA[3], D.SITIOS["secreto"]["centro"] + Vector2(0.9, -0.9)], "volver al corro")
	if _cantidad("Poción") != pociones + 2:
		_mal("el premio del secreto se repite")
	else:
		_ok("5 secreto: descubierto por su senda, premio una sola vez (+2 Pociones, +1 Éter)")


# ================================================================= 6

func _menu() -> Control:
	return v.menu_abierto


func _paso6_viaje() -> void:
	if _escena() != MM:
		return
	var desde := _plano(v.kael)
	if not v.abrir_viaje():
		_mal("no se abre el viaje rápido")
		return
	await _frames(3)
	var nombres: Array = []
	for b in _menu().botones:
		nombres.append(b.text.split("\n")[0])
	if nombres != ["Oakhaven", "Campamento de Pastos Verdes"]:
		_mal("destinos del menú: %s" % [nombres])
	for b in _menu().botones:
		if b.text.split("\n").size() < 2 or b.text.split("\n")[1].strip_edges() == "":
			_mal("el destino «%s» no enseña su región" % b.text)
	for oculto in ["Cueva", "Corro", "Portal", "Pastos Verdes\n"]:
		for b in _menu().botones:
			if b.text.begins_with(oculto):
				_mal("el menú enseña un destino que no lo es: %s" % b.text)
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	_menu()._input(ev)
	await _frames(3)
	if v.menu_abierto != null or _plano(v.kael).distance_to(desde) > 0.05 or v.viajes != 0:
		_mal("cancelar el menú (Esc) no lo cierra sin viajar")
	else:
		_ok("6a menú: %s con su región; Esc lo cierra sin viajar" % [nombres])
	# al campamento
	v.abrir_viaje()
	await _frames(3)
	_menu().botones[1].pressed.emit()
	await _hasta(func(): return v.viajes == 1 and not v.saliendo, 8000)
	var lleg: Vector2 = D.SITIOS["campamento"]["llegada"]
	if _plano(v.kael).distance_to(lleg) > 0.3 or v.pasos != 0 or _escena() != MM:
		_mal("el viaje al campamento no deja a Kael en su llegada con los pasos a cero")
	else:
		_ok("6b viaje rápido al campamento: llegada segura (pasos 0)")
	# el mojón del campamento (punto habilitado) y «ya estás aquí»
	await _frames(3)
	if v.cerca_id != "mojon" or v.boton_entrar.text != "Viaje rápido":
		_mal("junto al mojón del campamento no se ofrece «Viaje rápido» (cerca=%s)" % v.cerca_id)
	v._pulsar_entrar()
	await _frames(3)
	if v.menu_abierto == null or not _menu().botones[1].disabled:
		_mal("el mojón no abre el menú o el campamento no sale como «estás aquí»")
	# a Oakhaven
	_menu().botones[0].pressed.emit()
	await _hasta(func(): return v.viajes == 2 and not v.saliendo, 8000)
	lleg = D.SITIOS["oakhaven"]["llegada"]
	if _plano(v.kael).distance_to(lleg) > 0.3:
		_mal("el viaje a Oakhaven no deja a Kael en su llegada")
	await _ms(1200)
	if _escena() != MM:
		_mal("tras viajar a Oakhaven se entra sola en la ciudad")
	else:
		_ok("6c viaje rápido a Oakhaven (desde el mojón): junto a su entrada, sin entrar solo")
	var g = P.leer(ARCHIVO)
	if not g is Dictionary or Vector2(g["pos_3d"].x, g["pos_3d"].z).distance_to(lleg) > 0.3:
		_mal("tras el viaje no se guarda la nueva posición")


# ================================================================= 7

func _paso7_bloqueos() -> void:
	if _escena() != MM:
		return
	v.en_encuentro = true
	if v.abrir_viaje() or not v.aviso.text.contains("combate"):
		_mal("durante un encuentro el viaje no se bloquea con su motivo")
	v.en_encuentro = false
	v.cinematica = true
	if v.abrir_viaje() or not v.aviso.text.contains("escena"):
		_mal("durante una escena el viaje no se bloquea con su motivo")
	v.cinematica = false
	Engine.set_meta("prologo_visto", false)
	if v.abrir_viaje() or not v.aviso.text.contains("prólogo"):
		_mal("antes del prólogo el viaje no se bloquea con su motivo")
	Engine.set_meta("prologo_visto", true)
	var barrera := {"oakhaven": {"region": "x", "requiere": "hito_que_no_existe"}}
	if not D.motivo_destino("oakhaven", Vector2.INF, barrera).contains("historia"):
		_mal("un destino con barrera de progresión no se bloquea")
	if D.motivo_destino("cueva") == "" or D.motivo_destino("no_existe") == "":
		_mal("un destino que no es de viaje o no existe no se bloquea")
	if v.viajar("cueva"):
		_mal("viajar a un destino que no lo es funciona")
	_ok("7a bloqueos explicados: combate, escena, prólogo, barrera de hito y destino que no existe")
	# un encuentro de verdad: combate (bloqueado dentro) y vuelta al mismo sitio
	var p := Vector2(4.0, 4.2)
	v._colocar_kael(Vector3(p.x, v.T.altura(p.x, p.y), p.y))
	var antes := _plano(v.kael)
	v._encuentro()
	if not await _hasta(func(): return _escena() == "res://combate.tscn" and not R.cambiando, 30000):
		_mal("el encuentro del mapamundi no lleva al combate")
		return
	await _frames(5)
	if not D.motivo_bloqueo(null).contains("combate"):
		_mal("dentro del combate el viaje no está bloqueado")
	current_scene._volver_al_mapa()
	if not await _esperar_escena(MM):
		return
	if _plano(v.kael).distance_to(antes) > 0.5:
		_mal("tras el combate, Kael no vuelve al mismo sitio del mapamundi (%s)" % _plano(v.kael))
	else:
		_ok("7b encuentro → combate (viaje bloqueado dentro) → vuelta al mismo sitio")


# ================================================================= 8

func _paso8_guardado() -> void:
	if _escena() != MM:
		return
	v.guardar_posicion()
	P.guardar(MM)
	var pos := _plano(v.kael)
	var estado: Dictionary = D.estado_partida()
	for k in P.CLAVES + ["partida_lista"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var escena: String = P.cargar()
	if escena != MM:
		_mal("la partida guardada en el mapamundi no vuelve a él («%s»)" % escena)
	if D.estado_partida() != estado or D.destinos_conocidos() != ["oakhaven", "campamento"]:
		_mal("los descubrimientos no se conservan al cargar (%s)" % [D.estado_partida()])
	var errores: Array = P.errores_estructura(P.leer(ARCHIVO))
	if not errores.is_empty():
		_mal("la partida guardada tiene errores de estructura: %s" % [errores])
	change_scene_to_file(MM)
	if not await _esperar_escena(MM):
		return
	if _plano(v.kael).distance_to(pos) > 0.3:
		_mal("al cargar, Kael no aparece donde se guardó")
	if not v.rotulos["secreto"].visible or not v.rotulos["campamento"].visible:
		_mal("al cargar no se ven los sitios ya descubiertos")
	_ok("8a guardar y cargar: misma escena, mismo sitio, descubrimientos %s" % [estado.keys()])
	# partida antigua: sin «mazmorras» (ni el mapamundi): nada revelado
	var antigua := {"escena_guardada": "res://mapa.tscn", "prologo_visto": true, "pos_mapa": Vector2(560, 400), "pos_mapa_ok": true,
		"grupo_activo": ["Kael", "Lya", "Garon"], "hitos": {"pv_02": true}}
	P.restaurar(antigua)
	if not D.destinos_conocidos().is_empty() or not D.estado_partida().is_empty():
		_mal("una partida antigua revela destinos (%s)" % [D.destinos_conocidos()])
	change_scene_to_file(MM)
	if not await _esperar_escena(MM):
		return
	for id in ["campamento", "cueva", "secreto"]:
		if v.rotulos[id].visible:
			_mal("partida antigua: se ve el nombre de «%s»" % id)
	if _plano(v.kael).distance_to(D.a_3d(Vector2(560, 400))) > 0.5:
		_mal("partida antigua: Kael no aparece en su sitio del mapa 2D equivalente (%s)" % _plano(v.kael))
	v.abrir_viaje()
	await _frames(3)
	if v.menu_abierto == null or not _menu().botones.is_empty():
		_mal("partida antigua: el menú de viaje enseña destinos")
	else:
		_ok("8b partida antigua sin la clave: nada descubierto, menú vacío con su aviso, sin nombres de sitios ocultos")
	_menu().cerrar()
	await _frames(2)
	# se vuelve a la partida de la prueba
	P.cargar()
	change_scene_to_file(MM)
	await _esperar_escena(MM)


# ================================================================= 9

func _contar() -> Dictionary:
	await _frames(10)
	var kaels := current_scene.find_children("*", "", true, false).filter(func(n): return n == current_scene.get("kael"))
	var dg = root.get_node_or_null("Dialogic")
	return {"nodos": current_scene.find_children("*", "", true, false).size(),
		"raiz": root.get_child_count(),
		"huerfanos": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"kael": kaels.size(),
		"modelos_kael": current_scene.find_children("*", "", true, false).filter(func(n): return n.get_script() != null and String(n.get_script().resource_path).ends_with("kael_3d.gd")).size(),
		"conex_dialogic": dg.timeline_ended.get_connections().size() if dg != null else -1,
		"conex_arbol": get_signal_connection_list("process_frame").size()}


func _paso9_repeticion() -> void:
	if _escena() != MM:
		return
	var medidas: Array = []
	for vuelta in 3:
		v._colocar_kael(Vector3(-9.6, v.T.altura(-9.6, -5.6), -5.6))
		v.entradas["oakhaven"]["armada"] = true
		v._entrar("oakhaven")
		if not await _esperar_escena(OAK):
			return
		await _frames(10)
		v._salir()
		if not await _esperar_escena(MM):
			return
		medidas.append(await _contar())
	print("   vueltas: %s" % [medidas])
	var a: Dictionary = medidas[0]
	for m in medidas.slice(1):
		for k in ["nodos", "raiz", "kael", "modelos_kael", "conex_dialogic", "conex_arbol"]:
			if m[k] != a[k]:
				_mal("tras repetir mapamundi → Oakhaven → mapamundi, «%s» cambia: %s → %s" % [k, a[k], m[k]])
		if m["huerfanos"] > a["huerfanos"] + 2:
			_mal("crecen los nodos huérfanos: %d → %d" % [a["huerfanos"], m["huerfanos"]])
	if a["kael"] != 1:
		_mal("hay %d Kael en el mapamundi" % a["kael"])
	_ok("9 tres vueltas mapamundi → Oakhaven → mapamundi sin duplicar (nodos %d, Kael %d, conexiones de Dialogic %d)" % [a["nodos"], a["kael"], a["conex_dialogic"]])


# ================================================================= 10

func _paso10_fallo() -> void:
	if _escena() != MM:
		return
	v.ir_a("res://zonas3d/no_existe_mm3d.tscn", "Prueba")
	await _frames(3)
	if v.saliendo or v.fundido.color.a > 0.01 or v.ultimo_fallo == "" or _escena() != MM:
		_mal("una ruta que no existe deja el mapamundi bloqueado o en negro")
	else:
		_ok("10a ruta que no existe: sigue en el mapamundi, con control y sin negro")
	var f := FileAccess.open(ROTA, FileAccess.WRITE)
	f.store_string("[gd_resource type=\"Resource\" format=3]\n\n[resource]\n")   # existe y se lee, pero no es una escena
	f.close()
	v.ultimo_fallo = ""
	v.ir_a(ROTA, "Escena rota")
	await _hasta(func(): return v.ultimo_fallo != "" and not R.cambiando, 15000)
	await _frames(5)
	var negro = R.get("negro")
	if _escena() != MM or v.saliendo or v.fundido.color.a > 0.01 or root.gui_disable_input \
			or (negro != null and negro.visible):
		_mal("una escena rota deja pantalla negra o controles bloqueados (escena %s, saliendo %s, fundido %.2f, entrada %s)" % [
			_escena(), v.saliendo, v.fundido.color.a, root.gui_disable_input])
	else:
		var antes := _plano(v.kael)
		v.destino = v._ajustar_destino(v.kael.global_position + Vector3(2.0, 0, 0))
		await _ms(1000)
		if _plano(v.kael).distance_to(antes) < 0.5:
			_mal("tras la carga fallida Kael no se mueve")
		else:
			_ok("10b escena rota: Recursos avisa al mapamundi (carga_fallida), sin negro, con control y Kael anda")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROTA))
