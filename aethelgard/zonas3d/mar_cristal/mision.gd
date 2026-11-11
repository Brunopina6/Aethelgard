extends RefCounted
# La misión «La caravana perdida» del primer sector del Mar de Cristal (V12; docs/v12/DISENO_V12.md §2 y
# docs/v12/NARRATIVA_DESIERTO.md). Nombres aprobados por el usuario el 11/11: Ismena (la cartógrafa) y Oren (su
# hermano); el mural deja leer «…de los Espejismos»; la recompensa es la Aguja de Resonancia (equipo_extra.gd).
#
# Hitos (progreso.gd, se guardan en la partida), en orden:
#   mc_inicio         Ismena presta el buscador a Kael (buscador.gd, dar)
#   mc_caravana       Kael examina los restos del carro (50, 60): las huellas se las ha llevado el viento
#   mc_sello          con el buscador, junto a los restos, sale el Sello de la caravana (único): marca el norte
#   mc_tormenta       al ir hacia el norte se levanta la tormenta (narrativa, clima.gd): hay que llegar al cobijo
#   mc_ruinas         la tormenta amaina y ha destapado el arco de las ruinas
#   mc_llave          con el buscador, en las ruinas, sale la Llave de vidrio (único)
#   mc_superviviente  la llave abre la trampilla: el mural y Oren, vivo
#   mc_fin            de vuelta con Ismena: 150 monedas, el buscador para Kael (nivel 2) y la Aguja de Resonancia
#
# Nunca se queda nadie atascado: si un diálogo no puede empezar (Dialogic ocupado o ausente) o termina sin su señal,
# su efecto se aplica igual (aplicar), y la tormenta de la misión vuelve a levantarse si se recarga a medias.
# La región (mar_cristal_3d.gd) llama a: piezas, accion, senal, dialogo_terminado, hallazgo, vigilar, ruinas_reveladas.

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const Buscador := preload("res://buscador.gd")
const HITOS := ["mc_inicio", "mc_caravana", "mc_sello", "mc_tormenta", "mc_ruinas", "mc_llave", "mc_superviviente", "mc_fin"]
const PAGO := 150
const AGUJA := "aguja_resonancia"
const ID_COFRE := "mc_cofre_espejismo"
const PERSONAJES := {"ismena": "res://dialogos/personajes/mar_cristal/ismena.dch",
	"oren": "res://dialogos/personajes/mar_cristal/oren.dch"}
# Los textos de la región (NARRATIVA_DESIERTO.md §3).
const TEXTOS := {
	"esqueleto": "Un viajero de otro tiempo. Su nota dice: «Si la arena tiembla, roca. Si ves agua, no corras.»",
	"espejismo_antes": "Una palmera junto al agua… Al acercarte, tiembla y se deshace en aire caliente.",
	"espejismo_cofre": "Con el aire en calma, el espejismo se apaga. Debajo había un cofre de verdad.",
	"cobijo": "Bajo la roca, el viento ruge pero no entra. Toca esperar a que amaine.",
	"tormenta_fin": "La tormenta amaina. Al norte, la arena ha dejado un arco al descubierto.",
	"sello": "El sello de la caravana: un disco de bronce con una flecha. Alguien lo dejó mirando al norte.",
	"llave": "Una llave de vidrio con el ojo de bronce. Por eso cantaba el buscador.",
	"trampilla": "Una trampilla de vidrio con cerradura. Desde abajo llega un golpe… ¿o es el viento?",
	"restos_antes": "Un carro volcado con un toldo rojo, medio enterrado. Alguien lo estará buscando.",
	"restos_despues": "El carro de Oren. El sello faltaba porque él lo dejó mirando al norte.",
	"buscador": "Ismena te presta el buscador. Pulsa BUSCADOR para sacarlo.",
	"caravana": "Busca con el buscador junto al carro: algo de metal habrá quedado.",
	"tormenta_vuelve": "¡Otra vez la pared de arena! Al cobijo del cañón, al oeste.",
	"ismena_luego": "Ismena: «Oren ya está dibujando mapas al revés. Gracias, Kael.»",
}

var _conectado := false
var _aviso_cobijo := false
var _espejismo_visto := false


static func P():
	return load("res://progreso.gd")


static func hecho(h: String) -> bool:
	return P().hito(h)


func ruinas_reveladas() -> bool:
	return hecho("mc_ruinas")


# La timeline según quién va en el grupo (NARRATIVA_DESIERTO.md §2.1): base con Lya y Garon, «_lya» o «_solo».
static func dialogo_mc(base: String) -> String:
	var g: Array = load("res://grupo.gd").activos()
	if g.has("Lya") and g.has("Garon"):
		return base
	return base + ("_lya" if g.has("Lya") else "_solo")


# La espera de Ismena según por dónde va la misión (§2.2).
static func espera_ismena() -> String:
	if hecho("mc_llave"):
		return "mc_cartografa_espera_llave"
	if hecho("mc_ruinas"):
		return "mc_cartografa_espera_ruinas"
	if hecho("mc_sello"):
		return "mc_cartografa_espera_sello"
	if hecho("mc_caravana"):
		return "mc_cartografa_espera_restos"
	return "mc_cartografa_espera"


# Ismena y Oren en el directorio de personajes de Dialogic (como ciudades/oakhaven.gd, registrar_dialogic).
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


# ================================================================= lo que se puede usar

# [id, sitio, radio, texto del botón]: lo que sale según el hito (la cartógrafa, el esqueleto y el espejismo los pone
# la región).
func piezas() -> Array:
	var r: Array = []
	r.append(["restos", Vector3(T.CARAVANA.x, 0, T.CARAVANA.y + 1.5), 3.4, "Examinar los restos"])
	if ruinas_reveladas():
		var abrir := hecho("mc_llave") and not hecho("mc_superviviente")
		r.append(["trampilla", Vector3(T.TRAMPILLA.x, 0, T.TRAMPILLA.y), 2.4,
			"Abrir la trampilla" if abrir else "Examinar la trampilla"])
		if hecho("mc_superviviente"):
			r.append(["mural", Vector3(T.RUINAS.x, 0, T.RUINAS.y + 1.8), 2.2, "Mirar el arco"])
	if hecho("mc_superviviente"):
		r.append(["oren", Vector3(T.CARTOGRAFA.x - 1.6, 0, T.CARTOGRAFA.y + 0.4), 1.6, "Hablar con Oren"])
	if _espejismo_visto and not Engine.get_meta("cofres_abiertos", {}).has(ID_COFRE):
		r.append(["cofre_espejismo", Vector3(T.ESPEJISMO.x + 0.6, 0, T.ESPEJISMO.y + 0.6), 1.8, "Abrir el cofre"])
	return r


func accion(region: Node, id: String) -> void:
	match id:
		"cartografa":
			_hablar_ismena(region)
		"oren":
			region._mostrar_aviso("Oren: «La próxima vez me pierdo cerca de una fuente. Prometido.»", 2.4)
		"restos":
			if not hecho("mc_inicio"):
				region._mostrar_aviso(TEXTOS["restos_antes"], 2.4)
			elif not hecho("mc_caravana"):
				if not region.dialogo(dialogo_mc("mc_caravana_restos")):
					aplicar(region, "mc:caravana")
			else:
				region._mostrar_aviso(TEXTOS["restos_despues"] if hecho("mc_sello") else TEXTOS["caravana"], 2.4)
		"trampilla":
			if hecho("mc_llave") and not hecho("mc_superviviente"):
				Sonido.efecto("trampilla_abrir") if not Sonido.definicion("trampilla_abrir").is_empty() else null
				if region.terreno != null and region.terreno.has_method("abrir_trampilla"):
					region.terreno.abrir_trampilla()
				if not region.dialogo(dialogo_mc("mc_ruinas_mural")):
					_tras_mural(region)
			elif hecho("mc_superviviente"):
				region._mostrar_aviso("La trampilla, abierta. Abajo solo queda el mural… y su mirada.", 2.2)
			else:
				region._mostrar_aviso(TEXTOS["trampilla"], 2.4)
		"mural":
			region.dialogo(dialogo_mc("mc_ruinas_mural"))
		"esqueleto":
			region._mostrar_aviso(TEXTOS["esqueleto"], 3.2)
		"espejismo":
			_espejismo(region)
		"cofre_espejismo":
			_abrir_cofre(region)


func _hablar_ismena(region: Node) -> void:
	if not hecho("mc_inicio"):
		if not region.dialogo("mc_cartografa_inicio"):
			aplicar(region, "mc:buscador")
	elif not hecho("mc_superviviente"):
		region.dialogo(espera_ismena())
	elif not hecho("mc_fin"):
		if not region.dialogo("mc_cartografa_fin"):
			aplicar(region, "mc:fin")
	else:
		region._mostrar_aviso(TEXTOS["ismena_luego"], 2.4)


# ================================================================= señales y efectos

func senal(region: Node, arg: String) -> void:
	aplicar(region, arg)


# Lo que hace cada señal (de Dialogic o, si no hubo diálogo, directamente). Cada una una sola vez.
func aplicar(region: Node, arg: String) -> void:
	match arg:
		"mc:buscador":
			if hecho("mc_inicio"):
				return
			Buscador.dar()
			P().poner_hito("mc_inicio")
			if region.hud != null:
				region.hud.refrescar()
			region._mostrar_aviso(TEXTOS["buscador"], 2.6)
			_guardar(region)
		"mc:caravana":
			if hecho("mc_caravana") or not hecho("mc_inicio"):
				return
			P().poner_hito("mc_caravana")
			region._mostrar_aviso(TEXTOS["caravana"], 2.6)
			_guardar(region)
		"mc:superviviente":
			if hecho("mc_superviviente") or not hecho("mc_llave"):
				return
			P().poner_hito("mc_superviviente")
			if region.has_method("poner_oren"):
				region.poner_oren(true)
			region._mostrar_aviso("Oren vuelve con vosotros al campamento.", 2.2)
			_guardar(region)
		"mc:fin":
			_premio(region)


# Las timelines que acaban sin su señal (cortadas, o en una prueba) hacen lo mismo que la señal.
func dialogo_terminado(region: Node, nombre: String) -> void:
	if nombre == "mc_cartografa_inicio":
		aplicar(region, "mc:buscador")
	elif nombre.begins_with("mc_caravana_restos"):
		aplicar(region, "mc:caravana")
	elif nombre.begins_with("mc_ruinas_mural") and hecho("mc_llave") and not hecho("mc_superviviente"):
		_tras_mural(region)
	elif nombre.begins_with("mc_superviviente"):
		aplicar(region, "mc:superviviente")
	elif nombre == "mc_cartografa_fin":
		aplicar(region, "mc:fin")


func _tras_mural(region: Node) -> void:
	if not region.dialogo(dialogo_mc("mc_superviviente")):
		aplicar(region, "mc:superviviente")


# La recompensa, una sola vez: primero el hito, luego el premio y se guarda.
func _premio(region: Node) -> void:
	if hecho("mc_fin") or not hecho("mc_superviviente"):
		return
	P().poner_hito("mc_fin")
	var Inv = load("res://inventario.gd")
	Inv.ganar_oro(PAGO)
	Buscador.dar()
	if Buscador.nivel() < 2:
		Buscador.mejorar(2)
	var aguja: String = load("res://equipo_extra.gd").conseguir(AGUJA)
	var texto := "+%d monedas. El buscador es tuyo (nivel %d)." % [PAGO, Buscador.nivel()]
	if aguja != "":
		texto += " " + aguja
	region._mostrar_aviso(texto, 3.4)
	if not Sonido.definicion("recompensa").is_empty():
		Sonido.efecto("recompensa")
	if region.hud != null:
		region.hud.refrescar()
	_guardar(region)


func hallazgo(region: Node, r: Dictionary) -> void:
	match str(r.get("id", "")):
		"sello_caravana":
			if not hecho("mc_sello"):
				P().poner_hito("mc_sello")
				region._mostrar_aviso(TEXTOS["sello"], 3.2)
		"llave_vidrio":
			if not hecho("mc_llave"):
				P().poner_hito("mc_llave")
				region._mostrar_aviso(TEXTOS["llave"], 3.0)


# ================================================================= la tormenta de la misión

# Cada fotograma: con el sello y sin las ruinas, al ir hacia el norte de los restos se levanta la tormenta. Si se
# recarga a medias, vuelve a levantarse (sin repetir el diálogo). En el cobijo, el aviso de esperar.
func vigilar(region: Node, pos: Vector3) -> void:
	var clima = region.clima
	if clima == null:
		return
	if not _conectado:
		_conectado = true
		clima.amaino.connect(_al_amainar.bind(region))
	if hecho("mc_sello") and not hecho("mc_ruinas") and not clima.en_tormenta() and pos.z < T.CARAVANA.y - 6.0:
		clima.empezar_tormenta(true)
		if not hecho("mc_tormenta"):
			P().poner_hito("mc_tormenta")
			region.dialogo(dialogo_mc("mc_tormenta"))
		else:
			region._mostrar_aviso(TEXTOS["tormenta_vuelve"], 2.4)
	if clima.en_tormenta() and T.en_cobijo(pos.x, pos.z):
		if not _aviso_cobijo:
			_aviso_cobijo = true
			region._mostrar_aviso(TEXTOS["cobijo"], 2.6)
	else:
		_aviso_cobijo = false


func _al_amainar(era_narrativa: bool, region: Node) -> void:
	if not era_narrativa or hecho("mc_ruinas") or not hecho("mc_sello"):
		return
	P().poner_hito("mc_ruinas")
	if region.terreno != null:
		if region.terreno.has_method("destapar_ruinas"):
			region.terreno.destapar_ruinas()
		else:
			region.terreno.poner_ruinas(true)
	region._mostrar_aviso(TEXTOS["tormenta_fin"], 3.0)
	_guardar(region)


# ================================================================= el espejismo y su cofre

func _espejismo(region: Node) -> void:
	if region.clima != null and region.clima.en_tormenta():
		region._mostrar_aviso("Con esta arena no se ve ni el espejismo.", 2.0)
		return
	if Engine.get_meta("cofres_abiertos", {}).has(ID_COFRE):
		region._mostrar_aviso("Aquí solo queda aire caliente… y un cofre vacío.", 2.0)
		return
	_espejismo_visto = true
	region._mostrar_aviso(TEXTOS["espejismo_antes"] + " " + TEXTOS["espejismo_cofre"], 3.6)
	if region.terreno != null and region.terreno.has_method("revelar_cofre"):
		region.terreno.revelar_cofre()


# Una sola vez en la partida («cofres_abiertos»): primero se apunta, luego el premio, y se guarda.
func _abrir_cofre(region: Node) -> void:
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	if abiertos.has(ID_COFRE):
		return
	abiertos[ID_COFRE] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	var Inv = load("res://inventario.gd")
	Inv.ganar_oro(80)
	Inv.agregar_objeto("Reliquia de vidrio", 1)
	Inv.agregar_objeto("Éter", 1)
	if not Sonido.definicion("cofre").is_empty():
		Sonido.efecto("cofre")
	region._mostrar_aviso("Dentro: 80 monedas, una Reliquia de vidrio y un Éter.", 2.8)
	if region.terreno != null and region.terreno.has_method("abrir_cofre"):
		region.terreno.abrir_cofre()
	_guardar(region)


func _guardar(region: Node) -> void:
	if region.has_method("en_banco") and region.en_banco():
		return
	region.guardar_posicion()
	P().guardar(region.scene_file_path)
