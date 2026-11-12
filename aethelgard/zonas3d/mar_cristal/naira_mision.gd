extends RefCounted
# «La única noche que cabe en un día»: la misión de incorporación de Naira (V12, 12/11; docs/v12/NAIRA.md §4).
# PROTOTIPO APAGADO: Naira es una PROPUESTA, NO CANON. Todo esto solo existe con el interruptor «naira_v12» (grupo.gd,
# naira_v12(): Engine o «-- naira_v12»; APAGADO por defecto). Sin él la región no crea este módulo y el juego y las
# partidas son los de siempre: ni observatorio, ni plomadas, ni diálogos, ni objetos.
#
# Pasos e hitos (progreso.gd, HITOS_NAIRA), después de «La caravana perdida» (mc_fin):
#   nr_rumor          en el campamento, Oren e Ismena hablan de la de la torre (nr_campamento_rumor)
#   nr_observatorio   en el Viejo Observatorio (al nordeste), Naira los echa; les pide las tres plomadas (nr_torre_puerta)
#   nr_plomada_1..3   con el buscador (buscador.gd, únicos «naira»): junto a la torre, en el cañón y en la arena que tiembla
#   nr_plomadas       las tres
#   nr_medicion       se las dan (nr_medicion): la luz empieza a bajar (clima.gd, eclipse) y la cámara mira al cielo
#   nr_eclipse        totalidad (nr_eclipse_antes): Garon guarda la puerta (la reserva) y Kael y Lya protegen a Naira en un
#                     combate fijo («nr_eclipse», GRUPOS[0] de combate.gd, dos Grimfang; sin huida). Ganado, el brazalete
#                     no se apagó (nr_eclipse_despues) y la luz vuelve. Perdido, se vuelve con el grupo curado, sigue la
#                     totalidad y se repite (nr_eclipse_reintento)
#   nr_eclipse_perfecto  opcional: Naira preparó su Eclipse y nadie la golpeó mientras preparaba → la Lente ahumada
#   nr_catalogo       el Almanaque, en el atril: «…me llamo Naira. Apúntalo» (nr_catalogo)
#   nr_union          se une (nr_union): poner_hito("nr_union") y Grupo.unir("Naira") → a la reserva (el grupo va lleno),
#                     y con la reserva aparece la Formación (menús, grupo.gd). El Almanaque, objeto clave
# En el combate Naira lucha «de invitada»: antes de su hito, la región le da sus datos (grupo.gd, _crear_recluta) y una
# formación de un combate (Kael, Lya y Naira; Garon en la reserva), y al volver la deja como estaba. La formación de
# antes se guarda en la partida (mazmorras["naira_mision"]) por si el juego se cierra a medias: al entrar en la región se
# repara SIEMPRE (reparar_formacion, también con el interruptor apagado). combate.gd no se toca: el combate es uno fijo
# con un grupo que ya existe; la preparación es la del Eclipse de Naira (magia_negra.gd) y la medición perfecta la mira
# un observador desde fuera (Medidor).
# Nunca se queda nadie atascado: si un diálogo no puede empezar o se corta sin su señal, su efecto se aplica igual.

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const Observatorio := preload("res://zonas3d/mar_cristal/observatorio.gd")
const COMBATE := "nr_eclipse"
const GRUPO_COMBATE := 0                   # combate.gd GRUPOS[0]: dos Grimfang (reutilizados; cazan de noche)
const TIPO_COMBATE := "evento"             # sin huida (combate.gd _orden_huir) y con la música de los especiales
const CLAVE := "naira_mision"              # progreso.gd mazmorras[CLAVE]: la formación de antes del combate
const PLOMADAS := ["nr_plomada_1", "nr_plomada_2", "nr_plomada_3"]
const DONDE := {"nr_plomada_1": "la de junto a la torre", "nr_plomada_2": "la del cañón del oeste",
	"nr_plomada_3": "la de la arena que tiembla"}
const OBJETO_PLOMADA := "Plomada de bronce"
const ALMANAQUE := "Almanaque de las Estrellas sin Nombre"
const LENTE := "Lente ahumada"
const PERSONAJES := {"naira": "res://dialogos/personajes/naira.dch"}
const BAJAR_LUZ := 9.0                     # segundos hasta la totalidad
const SUBIR_LUZ := 6.0                     # y de vuelta
const ESPERA_TOTALIDAD := 1.6              # el momento: cielo negro y estrellas antes de que nadie hable
# El momento: la cámara se acerca y baja un poco (sin meterse en las dunas de detrás: 20°) y mira hacia arriba
# MIRAR_ARRIBA grados, para que se vean el cielo, la torre y el sol tapado (mar_cristal_3d.gd, _colocar_camara).
const CAMARA_MOMENTO := Vector2(20.0, 12.0) # [inclinación, distancia]
const MIRAR_ARRIBA := 14.0
const TEXTOS := {
	"rumor_aviso": "Oren e Ismena discuten junto al fuego. Algo de una torre…",
	"rumor": "La torre está al nordeste, más allá de la arena que tiembla.",
	"oren_luego": "Oren: «Si te pregunta, yo no dije que estuviera loca. Lo dijo Ismena.»",
	"ismena_luego": "Ismena: «La torre, al nordeste. Si te tira una piedra, esquívala.»",
	"antes_de_tiempo": "Desde la puerta, sin mirarte: «Hoy no. Estoy midiendo.»",
	"observatorio": "Tres plomadas de bronce. Saca el buscador: el bronce canta distinto.",
	"plomada": "Una plomada de bronce, con una estrella grabada. ¡Una menos!",
	"plomadas": "Las tres plomadas. Vuelve con Naira antes de que empiece.",
	"medicion": "La luz empieza a bajar…",
	"combate": "¡Grimfangs! Garon guarda la puerta: lucháis Kael, Lya y Naira.",
	"derrota": "La umbra sigue ahí. Naira aún cuenta los segundos.",
	"luz": "La luz vuelve. El sol, entero, como si nada.",
	"perfecto": "Naira: «Ni un golpe. Tomad mi lente ahumada.» (+1 Lente ahumada)",
	"almanaque_antes": "Naira: «Ahí, en el atril. Mirad, pero no toquéis.»",
	"instrumento": "La esfera armilar sigue girando. Alguien la ha engrasado hace poco.",
}

var region: Node3D
var obs                                     # observatorio.gd
var eclipse := 0.0                          # 0 la luz de siempre, 1 totalidad (lo aplica clima.gd)
var estado := ""                            # "", «oscurece», «totalidad», «aclara»
var camara = null                           # Vector2(inclinación, distancia) del momento, o null
var mirar_arriba := 0.0                     # grados que la cámara mira por encima de Kael (sube y baja suave)
var _t := 0.0
var _pendiente := ""                        # diálogo que se abre en cuanto se pueda
var _t_pendiente := 0.0
var _combate_pedido := false
var _espera_vista := false                  # ya se oyó nr_plomadas_espera (luego, avisos)
var _rumor_avisado := false


static func activa() -> bool:
	return load("res://grupo.gd").naira_v12()


static func P():
	return load("res://progreso.gd")


static func hecho(h: String) -> bool:
	return P().hito(h)


# Naira en el directorio de personajes de Dialogic (solo con la misión activa; como mision.gd con Ismena y Oren).
static func registrar_dialogic() -> void:
	if Engine.is_editor_hint() or not ResourceLoader.exists("res://addons/dialogic/Core/DialogicResourceUtil.gd"):
		return
	var util = load("res://addons/dialogic/Core/DialogicResourceUtil.gd")
	var dir: Dictionary = util.get_directory("dch").duplicate()
	var cambia := false
	for id in PERSONAJES:
		if not dir.has(id) and ResourceLoader.exists(PERSONAJES[id]):
			dir[id] = PERSONAJES[id]
			cambia = true
	if cambia:
		util.set_directory("dch", dir)


# ================================================================= la formación del combate (siempre, sin interruptor)

static func _guardado() -> Dictionary:
	return Engine.get_meta("mazmorras", {}).get(CLAVE, {})


static func _poner_guardado(d: Dictionary) -> void:
	var m: Dictionary = Engine.get_meta("mazmorras", {})
	if d.is_empty():
		m.erase(CLAVE)
	else:
		m[CLAVE] = d
	Engine.set_meta("mazmorras", m)


# Naira lucha de invitada: sus datos (si aún no los tiene) y el grupo del combate. Garon, en la reserva.
static func invitar_naira() -> void:
	var G = load("res://grupo.gd")
	if not _guardado().has("formacion_previa"):
		_poner_guardado({"formacion_previa": {
			"activo": (Engine.get_meta("grupo_activo") as Array).duplicate() if Engine.has_meta("grupo_activo") else null,
			"miembros": (Engine.get_meta("grupo_miembros") as Array).duplicate() if Engine.has_meta("grupo_miembros") else null}})
	if not G.datos().has("Naira"):
		G._crear_recluta("Naira")
	var act: Array = G.activos().filter(func(n): return n != "Garon" and n != "Naira")
	act = act.slice(0, G.MAX_ACTIVOS - 1)
	act.append("Naira")
	var miem: Array = G.en_el_grupo()
	if not "Naira" in miem:
		miem.append("Naira")
	G._poner(act, miem)


# Deja el grupo como estaba antes del combate. Devuelve si había algo que reparar.
static func reparar_formacion() -> bool:
	var g := _guardado()
	if not g.has("formacion_previa"):
		return false
	var p: Dictionary = g["formacion_previa"]
	for par in [["grupo_activo", "activo"], ["grupo_miembros", "miembros"]]:
		if p.get(par[1]) == null:
			if Engine.has_meta(par[0]):
				Engine.remove_meta(par[0])
		else:
			Engine.set_meta(par[0], (p[par[1]] as Array).duplicate())
	_poner_guardado({})
	return true


# ================================================================= la región

func construir(r: Node3D, perfil: Dictionary) -> void:
	region = r
	registrar_dialogic()
	obs = Observatorio.new(r, perfil)
	obs.construir()
	if not hecho("nr_union"):
		obs.poner_naira()
	if hecho("nr_medicion"):
		obs.colgar(4)
	if region.terreno != null and region.terreno.sombras != null and obs.naira != null:
		region.terreno.sombras.mancha(obs.naira)


# Al entrar (también al volver del combate): el eclipse sigue si la medición está hecha y el eclipse no; y si se acaba
# de ganar, se apunta y se cuenta lo que pasó.
func al_entrar() -> void:
	if not hecho("nr_medicion") or hecho("nr_eclipse"):
		Engine.remove_meta("nr_medicion_eclipse")
		return
	eclipse = 1.0
	estado = "totalidad"
	obs.concentrar(true)
	if P().ganado(COMBATE):
		_tras_victoria()
	elif Engine.has_meta("nr_medicion_eclipse"):                 # vuelve de perder
		Engine.remove_meta("nr_medicion_eclipse")
		region._mostrar_aviso(TEXTOS["derrota"], 2.8)
	else:                                                        # se cargó la partida entre la medición y el combate
		camara = CAMARA_MOMENTO
		obs.poner_sol(region.kael.global_position)
		_pedir("nr_eclipse_antes", 1.0)


func _tras_victoria() -> void:
	P().poner_hito("nr_eclipse")
	var med: Dictionary = Engine.get_meta("nr_medicion_eclipse", {})
	Engine.remove_meta("nr_medicion_eclipse")
	if bool(med.get("preparo", false)) and int(med.get("golpes", 1)) == 0 and not hecho("nr_eclipse_perfecto"):
		P().poner_hito("nr_eclipse_perfecto")
		load("res://inventario.gd").agregar_objeto(LENTE, 1)
	_pedir("nr_eclipse_despues", 1.2)


func _pedir(dialogo: String, espera := 0.4) -> void:
	_pendiente = dialogo
	_t_pendiente = espera


# El momento (el cielo se apaga o se enciende): nadie se mueve y la cámara mira arriba.
func momento() -> bool:
	return estado == "oscurece" or estado == "aclara" or (estado == "totalidad" and _pendiente == "nr_eclipse_antes")


# Encuentros al azar: ninguno en la explanada; durante el momento, tampoco.
func ritmo(p: Vector3) -> float:
	if momento() or Vector2(p.x, p.z).distance_to(Observatorio.TORRE) < 16.0:
		return 0.0
	return 1.0


func prohibido(p: Vector3) -> bool:
	return Observatorio.prohibido(p)


# Cada fotograma (también con un diálogo abierto): la luz del eclipse y la torre.
func actualizar(delta: float, t: float) -> void:
	match estado:
		"oscurece":
			eclipse = minf(1.0, eclipse + delta / BAJAR_LUZ)
			if eclipse >= 1.0:
				estado = "totalidad"
				_pedir("nr_eclipse_antes", ESPERA_TOTALIDAD)
		"aclara":
			eclipse = maxf(0.0, eclipse - delta / SUBIR_LUZ)
			if eclipse <= 0.0:
				estado = ""
				camara = null
				region._mostrar_aviso(TEXTOS["luz"], 2.4)
				_guardar()
	if region.clima != null:
		region.clima.eclipse = eclipse
	mirar_arriba = lerpf(mirar_arriba, MIRAR_ARRIBA if camara != null else 0.0, 1.0 - exp(-1.8 * delta))
	if camara == null and mirar_arriba < 0.05:
		mirar_arriba = 0.0
	obs.animar(t, eclipse)
	if _pendiente != "" and not region.saliendo:             # el diálogo pendiente, en cuanto Dialogic esté libre
		_t_pendiente -= delta
		var dg = region.get_node_or_null("/root/Dialogic")
		var libre: bool = dg == null or dg.current_timeline == null
		if _t_pendiente <= 0.0 and libre and not (region.hud != null and region.hud.ocupado()):
			var d := _pendiente
			_pendiente = ""
			if not region.dialogo(d):
				dialogo_terminado(d)


# Cada fotograma sin diálogo: el aviso del campamento.
func vigilar(pos: Vector3, _delta: float) -> void:
	if not _rumor_avisado and hecho("mc_fin") and not hecho("nr_rumor") \
			and Vector2(pos.x, pos.z).distance_to(T.CAMPAMENTO) < 12.0:
		_rumor_avisado = true
		region._mostrar_aviso(TEXTOS["rumor_aviso"], 2.6)


# ================================================================= lo que se puede usar

func _quien() -> String:
	return "Hablar con Naira" if hecho("nr_observatorio") else "Hablar con la astrónoma"


func piezas() -> Array:
	var r: Array = []
	var puerta := Vector3(Observatorio.PUERTA.x, 0, Observatorio.PUERTA.y)
	if not hecho("nr_union"):
		var texto := _quien()
		if hecho("nr_plomadas") and not hecho("nr_medicion"):
			texto = "Darle las plomadas"
		r.append(["nr_naira", puerta, 2.6, texto])
	if hecho("nr_eclipse") and not hecho("nr_catalogo") and estado != "aclara":
		r.append(["nr_almanaque", Vector3(Observatorio.ATRIL.x, 0, Observatorio.ATRIL.y), 1.9, "Mirar el Almanaque"])
	if hecho("nr_union"):
		r.append(["nr_instrumento", puerta, 2.6, "Mirar la torre"])
	return r


# Devuelve true si la acción era de esta misión (la región ya no llama a mision.gd).
func accion(id: String) -> bool:
	match id:
		"oren", "cartografa":
			if not hecho("mc_fin") or hecho("nr_union"):
				return false
			if not hecho("nr_rumor"):
				if not region.dialogo("nr_campamento_rumor"):
					aplicar("nr:rumor")
			else:
				region._mostrar_aviso(TEXTOS["oren_luego" if id == "oren" else "ismena_luego"], 2.6)
			return true
		"nr_naira":
			_hablar_naira()
			return true
		"nr_almanaque":
			if not region.dialogo("nr_catalogo"):
				aplicar("nr:catalogo")
			return true
		"nr_instrumento":
			region._mostrar_aviso(TEXTOS["instrumento"], 2.4)
			return true
	return false


func _hablar_naira() -> void:
	if not hecho("mc_fin"):
		region._mostrar_aviso(TEXTOS["antes_de_tiempo"], 2.4)
	elif not hecho("nr_observatorio"):
		if not region.dialogo("nr_torre_puerta"):
			aplicar("nr:observatorio")
	elif not hecho("nr_plomadas"):
		if not _espera_vista and region.dialogo("nr_plomadas_espera"):
			_espera_vista = true
		else:
			region._mostrar_aviso(_faltan(), 2.6)
	elif not hecho("nr_medicion"):
		if not region.dialogo("nr_medicion"):
			aplicar("nr:medicion")
	elif not hecho("nr_eclipse"):
		if estado == "totalidad" and _pendiente == "" and not region.dialogo("nr_eclipse_reintento"):
			aplicar("nr:combate")
			_empezar_combate()
	elif not hecho("nr_catalogo"):
		region._mostrar_aviso(TEXTOS["almanaque_antes"], 2.2)
	elif not hecho("nr_union"):
		if not region.dialogo("nr_union"):
			aplicar("nr:union")


func _faltan() -> String:
	var f: Array = PLOMADAS.filter(func(p): return not hecho(p)).map(func(p): return DONDE[p])
	if f.size() == 1:
		return "Naira: «Falta %s. Una. Daos prisa.»" % f[0]
	return "Naira: «Faltan %s y %s.»" % [", ".join(f.slice(0, f.size() - 1)), f[f.size() - 1]]


# ================================================================= señales y efectos

func senal(arg: String) -> void:
	aplicar(arg)


# Lo que hace cada señal (de Dialogic o, si no hubo diálogo, directamente). Cada una, una sola vez.
func aplicar(arg: String) -> void:
	match arg:
		"nr:rumor":
			if hecho("nr_rumor"):
				return
			P().poner_hito("nr_rumor")
			region._mostrar_aviso(TEXTOS["rumor"], 2.6)
			_guardar()
		"nr:observatorio":
			if hecho("nr_observatorio"):
				return
			if not hecho("nr_rumor"):
				P().poner_hito("nr_rumor")                # quien llega sin el rumor no se lo salta: va en orden
			P().poner_hito("nr_observatorio")
			if region.hud != null:
				region.hud.refrescar()
			region._mostrar_aviso(TEXTOS["observatorio"], 2.8)
			_guardar()
		"nr:medicion":
			if hecho("nr_medicion") or not hecho("nr_plomadas"):
				return
			P().poner_hito("nr_medicion")
			var o: Dictionary = load("res://inventario.gd").datos()["objetos"]
			o.erase(OBJETO_PLOMADA)                       # se las queda Naira: cuelgan del trípode
			obs.colgar(4)
			obs.concentrar(true)
			obs.poner_sol(region.kael.global_position)
			estado = "oscurece"
			camara = CAMARA_MOMENTO
			region._mostrar_aviso(TEXTOS["medicion"], 2.2)
			_guardar()
		"nr:combate":
			_combate_pedido = true                        # empieza al cerrarse el diálogo (dialogo_terminado)
		"nr:eclipse":
			if estado != "totalidad":
				return
			estado = "aclara"
			camara = CAMARA_MOMENTO
			obs.poner_sol(region.kael.global_position)
			obs.concentrar(false)
		"nr:catalogo":
			if hecho("nr_catalogo") or not hecho("nr_eclipse"):
				return
			P().poner_hito("nr_catalogo")
			_guardar()
		"nr:union":
			_unir()


func dialogo_terminado(nombre: String) -> void:
	match nombre:
		"nr_campamento_rumor":
			aplicar("nr:rumor")
		"nr_torre_puerta":
			aplicar("nr:observatorio")
		"nr_medicion":
			aplicar("nr:medicion")
		"nr_eclipse_antes", "nr_eclipse_reintento":
			camara = null
			_empezar_combate()
		"nr_eclipse_despues":
			aplicar("nr:eclipse")
		"nr_catalogo":
			aplicar("nr:catalogo")
		"nr_union":
			aplicar("nr:union")


func _empezar_combate() -> void:
	if hecho("nr_eclipse") or region.saliendo:
		return
	_combate_pedido = false
	invitar_naira()
	var med := Medidor.new()
	Engine.set_meta("nr_medidor", med)                    # lo mantiene vivo hasta volver a la región
	med.empezar(region.get_tree())
	region._mostrar_aviso(TEXTOS["combate"], 2.4)
	region.encuentro(COMBATE, GRUPO_COMBATE, TIPO_COMBATE, "¡Grimfangs en la oscuridad!")


func hallazgo(_region: Node, r: Dictionary) -> void:
	var id := str(r.get("id", ""))
	if not id in PLOMADAS or hecho(id):
		return
	P().poner_hito(id)
	if PLOMADAS.all(func(p): return hecho(p)):
		P().poner_hito("nr_plomadas")
		region._mostrar_aviso(TEXTOS["plomadas"], 3.0)
	else:
		region._mostrar_aviso(TEXTOS["plomada"], 2.6)
	_guardar()


func _unir() -> void:
	if hecho("nr_union") or not hecho("nr_catalogo"):
		return
	P().poner_hito("nr_union")
	var donde: String = load("res://grupo.gd").unir("Naira")
	load("res://inventario.gd").agregar_objeto(ALMANAQUE, 1)
	obs.quitar_naira()
	var texto := "Naira se une al grupo. +1 %s." % ALMANAQUE
	if donde == "reserva":
		texto = "Naira se une al grupo, en la reserva: cámbialo en Grupo › Formación. +1 %s." % ALMANAQUE
	region._mostrar_aviso(texto, 3.6)
	var son = region.get_node_or_null("/root/Sonido")       # (por nombre: así las pruebas lo cargan sin el autoload)
	if son != null and not son.definicion("recompensa").is_empty():
		son.efecto("recompensa")
	_guardar()


func _guardar() -> void:
	if region.has_method("en_banco") and region.en_banco():
		return
	region.guardar_posicion()
	P().guardar(region.scene_file_path)


# ================================================================= la medición perfecta, vista desde fuera

# Mira el combate del eclipse sin tocar combate.gd: cada fotograma lee a Naira en la lista de héroes de la escena del
# combate. Un golpe que le quita vida mientras prepara (f["conjuro"], magia_negra.gd) cuenta; uno que para una barrera,
# no. Lo que ve lo deja en Engine «nr_medicion_eclipse» = {"golpes", "preparo"} (preparó su Eclipse al menos una vez).
# Se desengancha solo al volver a otra escena.
class Medidor extends RefCounted:
	var arbol: SceneTree
	var golpes := 0
	var preparo := false
	var visto := false
	var _hp := -1
	var _preparando := false

	func empezar(a: SceneTree) -> void:
		arbol = a
		Engine.set_meta("nr_medicion_eclipse", {"golpes": 0, "preparo": false})
		if not arbol.process_frame.is_connected(_mirar):
			arbol.process_frame.connect(_mirar)

	func _mirar() -> void:
		var c = arbol.current_scene
		if c == null or c.get("combate_fijo") == null or str(c.get("combate_fijo")) != "nr_eclipse":
			if visto and (c == null or c.scene_file_path != "res://combate.tscn"):
				terminar()
			return
		visto = true
		for h in c.get("heroes"):
			if str(h.get("nombre", "")) != "Naira":
				continue
			var hp := int(h.get("hp", 0))
			if _preparando and _hp >= 0 and hp < _hp:
				golpes += 1
			var conj = h.get("conjuro")
			_preparando = conj != null
			if conj is Dictionary and str(conj.get("familia", "")) == "naira_eclipse":
				preparo = true
			_hp = hp
		Engine.set_meta("nr_medicion_eclipse", {"golpes": golpes, "preparo": preparo})

	func terminar() -> void:
		if arbol != null and arbol.process_frame.is_connected(_mirar):
			arbol.process_frame.disconnect(_mirar)
		if Engine.has_meta("nr_medidor"):
			Engine.remove_meta("nr_medidor")
