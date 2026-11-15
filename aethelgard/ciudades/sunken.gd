extends RefCounted
# Sunken City 3D (V12, 15/11), sector «Popa Rota → Cubierta Mayor»: datos y lógica de la ciudad (sin nodos). La escena
# es zonas3d/sunken_3d.gd (EN PRUEBAS y APAGADA: modo3d.gd, «sunken3d»). TODO lo narrativo de aquí es PROPUESTA [P] del
# diseño (docs/diseno/ciudades_y_lugares.md §2.2) sin aprobar: docs/v12/SUNKEN_3D_V12.md, «Propuestas de canon».
#   - Vecinos: la contramaestre Ulla (Archivo del Águila) y la capitana Brea (Cubierta Mayor), con diálogos breves
#     (dialogos/sunken/*.dtl; personajes dialogos/personajes/sunken/*.dch).
#   - Misión «El sello de la capitana» (datos/encargos_sunken.gd, en el Diario): Ulla necesita el sello de Brea para el
#     contrato de amarre; Brea dice dónde lo dejó con una adivinanza; está atado a la driza de la bandera del Águila (se
#     examina el palo mayor); se le lleva a Ulla. Sin combate (la ciudad no tiene). Premio UNA vez: el Bronce del Águila
#     (material de la forja de Kael: datos/materiales/bronce_aguila.tres → investigación kael_bronce_aguila → receta
#     kael_guarda_aguila, +2 de vitalidad para siempre; talleres.gd lo reserva mientras no se ha estudiado).
#   - Secreto «la costilla que no alumbra»: un grabado junto a la brecha de la popa dice que una paga duerme bajo la
#     costilla que no alumbra; de las tres que cruzan la Quilla, la del medio no tiene farol; al pie, una tabla suelta
#     (cofre «sunk_cofre_paga», una vez).
#   - El detalle de canon «sunken_contratos» (progreso.gd, DETALLES[5]) en el atril del Archivo, con su mismo id.
#   - Comentarios del grupo (Lya y Garon, si están) al llegar, ante la lona del dique y tras el secreto.
# Estado SOLO en claves que ya existen: «mazmorras»["sunken"] (sello_pedido, sello_pista, sello_hallado, sello_fin,
# grabado_visto), «cofres_abiertos» (sunk_cofre_paga), «lore_visto» (sunken_contratos, por progreso.gd) y el inventario.
# Una partida antigua no trae nada de esto y empieza de cero.
#
# Restricciones de canon (encargo del coordinador, 15/11): nada de Érebo, corazones ni recuerdos; la Astraea solo se VE
# bajo su lona (no se nombra ni se usa); nada de que Garon sirviera en la Compañía; nada con forma de brazalete; la
# escotilla al Casco está atrancada (el Casco, pendiente).

const INDICE := 5                        # en LUGARES de mapa.gd
const NOMBRE := "sunken"                 # su diccionario en «mazmorras»
const NOMBRE_LUGAR := "Sunken City"
const ID_DETALLE := "sunken_contratos"   # progreso.gd, DETALLES[5] (el mismo id que en la zona 2D)
const COFRE_PAGA := "sunk_cofre_paga"
const RUTA := "res://dialogos/sunken/"
const MATERIAL := "Bronce del Águila"    # datos/materiales/bronce_aguila.tres (clave de inventario)
const PREMIO_PAGA := {"oro": 80, "objetos": {"Éter": 1}}
const PREMIO_SELLO := {"objetos": {MATERIAL: 1}}

const PERSONAJES := {
	"ulla": "res://dialogos/personajes/sunken/ulla.dch",
	"brea": "res://dialogos/personajes/sunken/brea.dch",
}

# Vecinos: su figura chibi (personajes/npc_v12: oficio y persona), su nombre en el botón y lo que dicen sin diálogo.
const NPCS := {
	"ulla": {"nombre": "Contramaestre Ulla", "corto": "Ulla", "boton": "Hablar con Ulla", "chibi": ["alquimista", "ulla"],
		"tinte": Color(0.20, 0.28, 0.38),
		"frases": ["Cada cosa en su cajón. Los contratos, en el suyo.", "El archivo cierra al ponerse el sol."]},
	"brea": {"nombre": "Capitana Brea", "corto": "Brea", "boton": "Hablar con Brea", "chibi": ["viajero", "brea"],
		"tinte": Color(0.62, 0.17, 0.17),
		"frases": ["¿Lo encontraste? Pues corre al Archivo antes de que Ulla me escriba una carta.",
			"Le debo dinero a media ciudad. A la otra media, todavía no."]},
}

# Textos de lo que se examina (PROPUESTA; la popa y la bandera, de las notas del diseño: nota_sunk_popa y nota_sunk_bandera).
const TEXTO_POPA := "Alguien raspó el nombre del barco. Solo quedan los clavos de las letras."
const TEXTO_BANDERA := "La bandera del Águila, remendada mil veces. El águila siempre, intacta."
const TEXTO_SELLO := "Atado a la driza de la bandera, junto a la cornamusa: un sello de bronce con un águila. Lo coges."
const TEXTO_GRABADO := "Grabado a punta de navaja, junto a un ancla: «Mi paga duerme bajo la costilla que no alumbra»."
const TEXTO_TABLA_LEIDO := "La costilla que no alumbra… Bajo la tabla suelta, envuelta en lona embreada: la paga de un marinero."
const TEXTO_TABLA_SIN := "Una tabla suelta. Debajo, envuelta en lona embreada, una bolsa olvidada: la paga de un marinero."
const TEXTO_TABLA_VACIA := "Bajo la tabla suelta ya no queda nada."
const TEXTO_ESCOTILLA := "La escotilla al Casco, atrancada con una barra. Con tiza: «Cerrado hasta la marea baja»."
const TEXTO_PROA := "Cuerdas tendidas y un letrero: «Proa en obras. Orden de la capitana». Al fondo, el águila dorada."
const TEXTO_LONA := "Una lona enorme, atada con cabos nuevos. Debajo, algo con forma de barco. Brea no deja pasar."

# Comentarios del grupo (como dialogos/comentarios.gd: quien, texto, intencion, gesto, espera, respuesta). Salen solo si
# quien habla está en el grupo activo, una vez por sesión cada momento. PROPUESTA.
const COMENTARIOS := {
	"llegar": [
		{"quien": "Lya", "texto": "Cuelgan la ropa de las costillas… Aquí nadie se pregunta qué fue este barco.",
			"intencion": "Asombro tranquilo; lo apunta para sí", "gesto": "duda", "espera": "espera_pelo",
			"respuesta": {"quien": "Garon", "texto": "Mientras aguante, es una casa.", "intencion": "Práctico; zanja",
				"gesto": "firme", "espera": "espera_hombros"}},
		{"quien": "Kael", "texto": "Una ciudad dentro de un barco. Y el barco, dentro de una laguna.",
			"intencion": "Asombro que disfraza de broma", "gesto": "sorpresa", "espera": "espera_vigilar"}],
	"lona": [
		{"quien": "Lya", "texto": "Tiene forma de barco… pero no de los que se quedan en el agua.",
			"intencion": "Curiosidad de estudiosa; no se atreve a decir más", "gesto": "duda", "espera": "espera_cetro",
			"respuesta": {"quien": "Garon", "texto": "Lo que no se enseña, no se pregunta. Todavía.",
				"intencion": "Prudente; respeta lo ajeno", "gesto": "firme", "espera": "espera_hombros"}},
		{"quien": "Kael", "texto": "Esa lona es más grande que la plaza de Oakhaven.",
			"intencion": "Medida a ojo, de chico de pueblo", "gesto": "ligero", "espera": "espera_vigilar"}],
	"secreto": [
		{"quien": "Garon", "texto": "Paga de marinero. Alguien no volvió a por ella.",
			"intencion": "Respeto seco por el ausente", "gesto": "firme", "espera": "espera_apoyarse",
			"respuesta": {"quien": "Lya", "texto": "O no pudo. Guárdala bien, Kael.", "intencion": "Cariño serio",
				"gesto": "", "espera": "espera_cetro"}},
		{"quien": "Kael", "texto": "Bajo la costilla que no alumbra. Me lo apunto para la próxima.",
			"intencion": "Orgullo de haberlo deducido", "gesto": "ligero", "espera": "espera_brazalete"}],
}
const COMENTARIOS_META := "comentarios_dichos"    # el mismo de dialogos/comentarios.gd (no va a la partida)


static func _p():
	return load("res://progreso.gd")


static func estado(clave: String) -> bool:
	return _p().estado(NOMBRE, clave)


static func poner(clave: String) -> void:
	_p().poner_estado(NOMBRE, clave)


static func paga_encontrada() -> bool:
	return Engine.get_meta("cofres_abiertos", {}).has(COFRE_PAGA)


# Los personajes nuevos de Dialogic (como ciudades/oakhaven.gd, registrar_dialogic): el editor los apunta en
# project.godot; mientras tanto, se dan a conocer en tiempo de juego, sin escribir nada.
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


# El diálogo que toca con un vecino (lo de la misión primero). "" si no hay (entonces dice una frase).
static func dialogo_de(id: String) -> String:
	var n := ""
	match id:
		"ulla":
			if estado("sello_fin"):
				n = "sunk_ulla_despues"
			elif estado("sello_hallado"):
				n = "sunk_ulla_fin"
			elif estado("sello_pedido"):
				n = "sunk_ulla_pendiente"
			else:
				n = "sunk_ulla_pedido"
		"brea":
			if estado("sello_fin"):
				n = "sunk_brea_despues"
			elif estado("sello_hallado"):
				n = ""                                      # (una frase: que corra al Archivo)
			elif estado("sello_pedido") and not estado("sello_pista"):
				n = "sunk_brea_sello"
			elif estado("sello_pista"):
				n = ""
			else:
				n = "sunk_brea"
	return RUTA + n + ".dtl" if n != "" else ""


# La frase de un vecino sin diálogo (la escena la enseña como aviso).
static func frase(id: String, veces := 0) -> String:
	var fr: Array = NPCS.get(id, {}).get("frases", [""])
	if id == "brea":
		if estado("sello_pista") and not estado("sello_hallado"):
			return "Ya te lo dije, grumete: con la única de este barco que nunca se arría."
		if estado("sello_hallado") and not estado("sello_fin"):
			return fr[0]
		return fr[1]
	return fr[veces % fr.size()]


# Una señal «sunk:» de un diálogo. Devuelve el aviso que enseñar ("" si no hay).
static func aplicar_senal(s: String) -> String:
	match s:
		"sunk:sello_pedido":
			if estado("sello_pedido"):
				return ""
			poner("sello_pedido")
			return "Nueva misión en el Diario: «El sello de la capitana»."
		"sunk:sello_pista":
			if estado("sello_pista"):
				return ""
			poner("sello_pista")
			return "Diario: Brea dejó el sello «con la única de este barco que nunca se arría»."
		"sunk:sello_fin":
			if estado("sello_fin") or not estado("sello_hallado"):
				return ""
			poner("sello_fin")
			return "Ulla te da %s (material de la forja de Kael). Misión cumplida: «El sello de la capitana»." % _dar(PREMIO_SELLO)
	return ""


# El palo mayor: la nota de la bandera o, si Brea ya dio la pista, el sello (una vez). Devuelve [texto, ¿cambió algo?].
static func examinar_palo() -> Array:
	if estado("sello_pista") and not estado("sello_hallado"):
		poner("sello_hallado")
		return [TEXTO_SELLO, true]
	return [TEXTO_BANDERA, false]


# El grabado de la popa (la pista del secreto): se apunta que se ha leído (solo cambia el texto de la tabla).
static func leer_grabado() -> bool:
	if estado("grabado_visto"):
		return false
	poner("grabado_visto")
	return true


# La tabla suelta de la costilla que no alumbra: la paga UNA vez. Devuelve [texto, lo que se da ("" si nada)].
static func abrir_tabla() -> Array:
	if paga_encontrada():
		return [TEXTO_TABLA_VACIA, ""]
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[COFRE_PAGA] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	return [TEXTO_TABLA_LEIDO if estado("grabado_visto") else TEXTO_TABLA_SIN, _dar(PREMIO_PAGA)]


# Da un premio y lo dice en una frase («80 monedas y 1 Éter»).
static func _dar(premio: Dictionary) -> String:
	var inv = load("res://inventario.gd")
	var partes: Array = []
	var oro := int(premio.get("oro", 0))
	if oro > 0:
		inv.ganar_oro(oro)
		partes.append("%d monedas" % oro)
	var objetos: Dictionary = premio.get("objetos", {})
	for o in objetos:
		inv.agregar_objeto(o, int(objetos[o]))
		partes.append("%d %s" % [int(objetos[o]), o] if int(objetos[o]) != 1 or o == "Éter" else "una plancha de %s" % o)
	return " y ".join(partes)


# Un comentario del grupo para el momento (o {} si no toca: nadie presente, o ya dicho en esta sesión).
static func comentario(momento: String, presentes: Array = []) -> Dictionary:
	if not COMENTARIOS.has(momento):
		return {}
	if presentes.is_empty():
		presentes = load("res://grupo.gd").activos()
	var d: Dictionary = Engine.get_meta(COMENTARIOS_META, {})
	if d.has("@sunk:" + momento):
		return {}
	for f in COMENTARIOS[momento]:
		if f["quien"] in presentes and not d.has(f["texto"]):
			var c: Dictionary = (f as Dictionary).duplicate(true)
			var r = c.get("respuesta")
			if r is Dictionary and not r["quien"] in presentes:
				c.erase("respuesta")
			var d2: Dictionary = d.duplicate(true)
			d2["@sunk:" + momento] = true
			Engine.set_meta(COMENTARIOS_META, d2)
			return c
	return {}
