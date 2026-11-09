extends RefCounted
# Equipo de T-092 (Godot 4.x): la ranura Accesorio, los 8 accesorios y las 6 armas especiales, dos por héroe
# (docs/diseno/combate_ampliaciones.md, §4). Datos y lógica sin escena. C1 enganchado el 09/11
# (docs/diseno/combate_enganches.md, §3): inventario.gd (la ranura y objeto()), combate.gd (ATB inicial, crítico,
# esquiva, PM por turno, regeneración y monedas), menus.gd y tienda.gd (lo que se vende en cada lugar). Las armas
# especiales (C2) y los efectos de M3 y M4 siguen fuera: HECHOS.
# Uso:  var Extra = load("res://equipo_extra.gd");  Extra.efectos_de("Kael")...
#
# Sin un objeto nuevo equipado, todo da lo mismo que hoy: los efectos solo suman, el equipo inicial no cambia y ningún
# gancho tira un dado de más si su efecto vale 0 (el único que tira, la esquiva, solo con una pluma puesta). Así la
# huella del combate (C0) no cambia. Los ids nuevos solo entran en «equipables» al conseguirlos: una partida antigua
# carga igual y empieza sin nada nuevo puesto. La ranura vive dentro de inventario.equipo[héroe]: ninguna clave nueva.
# Textos: los nombres de Lumi, Vex, la Arboleda y la Compañía del Águila son canon; los peregrinos con farol y la
# Guardia de la Muralla, propuesta de la biblia (no canon hasta que el usuario la apruebe).

const RANURA := "accesorio"
const NOMBRE_RANURA := "Accesorio"      # el nombre que eligió el coordinador el 09/11 («Reliquia» descartado)
const LARGO_EFECTO := 32                # la columna de la tienda mide 300 px y no parte las líneas

# Efectos: «num» se suman (con su tope); «si» basta con uno. «gancho»: el incremento que lo engancha en el combate;
# sin su gancho, llevar el objeto no hace nada.
const EFECTOS := {
	"atb_inicio": {"tipo": "num", "max": 60.0, "gancho": "C1"},          # ATB al empezar el combate
	"critico": {"tipo": "num", "max": 0.30, "gancho": "C1"},             # + probabilidad de crítico (misma tirada)
	"esquiva": {"tipo": "num", "max": 0.30, "gancho": "C1"},             # esquiva golpes físicos (solo tira si > 0)
	"oro_pct": {"tipo": "num", "max": 100.0, "gancho": "C1"},            # % más de monedas al ganar, una vez
	"pm_turno": {"tipo": "num", "max": 10.0, "gancho": "C1"},            # PM al acabar cada turno suyo
	"regen": {"tipo": "num", "max": 0.20, "gancho": "C1"},               # PV al empezar cada turno suyo (con M2)
	"barrera_inicio": {"tipo": "num", "max": 0.50, "gancho": "M3"},      # empieza con coraza
	"brasa": {"tipo": "si", "gancho": "M4"},                             # empieza con Brasa
	"robo_vida": {"tipo": "num", "max": 0.50, "gancho": "C2"},           # se cura parte del daño físico que hace
	"ataque_recuerdo": {"tipo": "num", "max": 12.0, "gancho": "C2"},     # +1 de ataque por detalle de lore visto
	"contra_defendiendo": {"tipo": "num", "max": 1.0, "gancho": "C2"},   # en guardia, devuelve el golpe (× ataque)
	"cubrir": {"tipo": "num", "max": 0.50, "gancho": "C2"},              # recibe el golpe de un aliado con poca vida
	"aliento_inicio": {"tipo": "num", "max": 3.0, "gancho": "C2"},       # Aliento al más herido al empezar (con M2)
	"apoyo_turnos": {"tipo": "num", "max": 2.0, "gancho": "C2"},         # el Aliento que lanza dura más (con M2)
}
# Incrementos ya enganchados en el juego (se añaden al enganchar: "C1", luego "M3", "C2" y "M4"). Lo que no está
# disponible no se vende ni se da. C1, desde el 09/11: la ranura Accesorio y los seis accesorios de C1.
const HECHOS: Array = ["C1"]

# Botín de las bestias (T-097, decisión del coordinador del 09/11): materiales que solo se venden (sin recetas). Al
# ganar, cada enemigo de esa clave que no haya huido deja uno (combate.gd _repartir_exp); se guardan en los objetos del
# inventario y la tienda los compra por «venta» monedas (tienda.gd, pestaña Objetos).
const BOTIN := {"zarzalin": "Corteza espinosa"}
const MATERIALES := {
	"Corteza espinosa": {"venta": 18, "desc": "Corteza de Zarzalín, llena de espinas. Se vende."},
}


static func botin_de(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		if not e.get("huido", false) and int(e.get("hp", 0)) <= 0 and BOTIN.has(str(e.get("clave", ""))):
			r.append(BOTIN[e["clave"]])
	return r

# Accesorios: sin atributos, solo su efecto. «efecto»: texto corto del menú (32 caracteres como mucho).
const ACCESORIOS := {
	"farol_peregrino": {"nombre": "Farol de peregrino", "efectos": {"atb_inicio": 35.0},
		"efecto": "Empieza con un tercio de barra.",
		"texto": "Latón abollado y cristal ahumado. Los peregrinos lo llevaban encendido a pleno día.",
		"donde": "Tienda de Oakhaven (220)"},
	"diente_grimfang": {"nombre": "Diente de Grimfang", "efectos": {"critico": 0.08},
		"efecto": "+8 % de golpe crítico.",
		"texto": "Los Grimfang se pasan sus dientes de padre a hijo. Este se perdió en una pelea.",
		"donde": "Cofre del campamento del Gran Bosque Verde; botín del Grimfang embestidor (5 %, una vez; E1)"},
	"moneda_aguila": {"nombre": "Moneda del Águila", "efectos": {"oro_pct": 25.0},
		"efecto": "+25 % de monedas al ganar.",
		"texto": "Plata con un águila acuñada. La Compañía cobraba en estas.",
		"donde": "Tienda de Sunken City (450)"},
	"gota_cascada": {"nombre": "Gota de la cascada alta", "efectos": {"pm_turno": 2.0},
		"efecto": "+2 PM al acabar cada turno.",
		"texto": "Agua de las cascadas que sostienen la isla, quieta dentro de un cristal.",
		"donde": "Arboleda Mítica, en la orilla (secreto; T-090)"},
	"cinta_lumi": {"nombre": "Cinta de Lumi", "efectos": {"regen": 0.05},
		"efecto": "Recupera un 5 % de PV por turno.",
		"texto": "Lumi la tejió para alguien de abajo. Huele a las flores de la isla.",
		"donde": "Regalo de Lumi en la Arboleda Mítica (T-090)"},
	"pluma_arpia": {"nombre": "Pluma de arpía", "efectos": {"esquiva": 0.12},
		"efecto": "12 % de esquivar golpes.",
		"texto": "Blanca, ligera y fría. Vex pagaría bien por ella.",
		"donde": "Cofre de las ruinas de Ciclópea; después, botín de la Arpía de las cumbres (E3)"},
	"lagrima_ambar": {"nombre": "Lágrima de ámbar", "efectos": {"barrera_inicio": 0.15},
		"efecto": "Empieza con coraza (15 % de PV).",
		"texto": "Ámbar tibio del gólem del nido. Dentro hay un insecto que nadie ha visto vivo.",
		"donde": "Primera victoria en el nido de la Garganta (combate fijo «garganta_nido»)"},
	"brasa_frasco": {"nombre": "Brasa en frasco", "efectos": {"brasa": true},
		"efecto": "Si cae, se levanta una vez.",
		"texto": "Una brasa que no se apaga, en un frasco tapado con cera.",
		"donde": "Cofre del Abismo de Ceniza; mientras no se llegue, el Valle de los Ecos"},
}

# Armas especiales: cambian ataque por un efecto. Reutilizan las mallas de las armas de hoy; «tinte» y «color_brillo»
# los leerá material_arma.gd cuando tenga esos parámetros (petición a gráficos; sin ellos, se ven como su malla).
# «solo»: nadie más puede llevarla, aunque sea de su tipo (las de Garon no las coge Kael).
const ARMAS := {
	"hoja_sin_nombre": {"nombre": "Hoja sin Nombre", "tipo": "espada", "solo": "Kael", "ataque": 8,
		"efectos": {"ataque_recuerdo": 12.0}, "efecto": "+1 Ataque por recuerdo visto.",
		"texto": "Alguien raspó el nombre de la hoja. Brilla más cuanto más recuerda quien la empuña.",
		"donde": "Gran Bosque Verde, al examinar la «Armadura del árbol»",
		"modelo": "res://espada2.obj", "color": "res://espada2_color.jpg", "normal": "res://espada2_normal.png",
		"metal": "res://espada2_metal.png", "rugosidad": "res://espada2_rugosidad.png", "brillo": "res://espada2_brillo.png",
		"largo": 1.45, "punta": 0.875, "tinte": Color("F3E2B0"), "color_brillo": Color("FFE9A8")},
	"guardiana_ambar": {"nombre": "Guardiana de Ámbar", "tipo": "espada", "solo": "Kael", "ataque": 12,
		"efectos": {"contra_defendiendo": 0.6}, "efecto": "En guardia, devuelve el golpe.",
		"texto": "Ámbar de los centinelas del camino. Lo que golpea a quien la sostiene en guardia, vuelve.",
		"donde": "Cumbres de Ciclópea, cerca de la «Estatua sin brazo»",
		"modelo": "res://diamante_azul.obj", "color": "res://diamante_azul_color.jpg", "normal": "res://diamante_azul_normal.png",
		"metal": "res://diamante_azul_metal.png", "rugosidad": "res://diamante_azul_rugosidad.png",
		"brillo": "res://diamante_azul_brillo.png", "largo": 1.45, "punta": 0.9,
		"tinte": Color("E8A33C"), "color_brillo": Color("FFC46A")},
	"baculo_peregrino": {"nombre": "Báculo del Peregrino", "tipo": "cetro", "solo": "Lya", "ataque": 2, "magia": 10,
		"efectos": {"apoyo_turnos": 1.0}, "efecto": "Su Aliento dura un turno más.",
		"texto": "Madera de la Vía, pulida por miles de manos que se apoyaron en él para no detenerse.",
		"donde": "Garganta del Diablo, junto al «Pilar del peregrino»",
		"modelo": "res://vara.obj", "color": "res://vara_color.jpg", "normal": "res://vara_normal.png",
		"metal": "res://vara_metal.png", "rugosidad": "res://vara_rugosidad.png", "brillo": "",
		"largo": 1.05, "punta": 0.55, "tinte": Color("D9C29A"), "color_brillo": Color("FFF1C8")},
	"rama_milenaria": {"nombre": "Rama del Árbol Milenario", "tipo": "cetro", "solo": "Lya", "ataque": 2, "magia": 12,
		"efectos": {"aliento_inicio": 2.0}, "efecto": "Empieza dando Aliento al herido.",
		"texto": "No se seca aunque pasen los inviernos.",
		"donde": "Oakhaven, al pie del Árbol Milenario (T-089/T-090)",
		"modelo": "res://vara.obj", "color": "res://vara_color.jpg", "normal": "res://vara_normal.png",
		"metal": "res://vara_metal.png", "rugosidad": "res://vara_rugosidad.png", "brillo": "",
		"largo": 1.05, "punta": 0.55, "tinte": Color("9CC48A"), "color_brillo": Color("C8F0A0")},
	"fauces_gorthor": {"nombre": "Fauces de Gorthor", "tipo": "espada", "solo": "Garon", "ataque": 30,
		"efectos": {"robo_vida": 0.15}, "efecto": "Se cura el 15 % del daño hecho.",
		"texto": "Forjadas con los colmillos del jefe de los Grimfang. Muerden.",
		"donde": "Al vencer a Gorthor (pendiente del usuario: la misma recompensa se le perdone o no)",
		"modelo": "res://hoja_infernal.obj", "color": "res://hoja_infernal_color.jpg", "normal": "res://hoja_infernal_normal.png",
		"metal": "res://hoja_infernal_metal.png", "rugosidad": "res://hoja_infernal_rugosidad.png",
		"brillo": "res://hoja_infernal_brillo.png", "largo": 1.1, "punta": 0.9,
		"tinte": Color("E8DCC4"), "color_brillo": Color("FF5A3C")},
	"gemelas_muralla": {"nombre": "Gemelas de la Muralla", "tipo": "espada", "solo": "Garon", "ataque": 28,
		"efectos": {"cubrir": 0.30}, "efecto": "Cubre al aliado con poca vida.",
		"texto": "Dos espadas cortas de la Guardia de la Muralla, melladas de no retroceder.",
		"donde": "Oakhaven, Taberna del Cuervo Oxidado (secreto; T-089)",
		"modelo": "res://espada2.obj", "color": "res://espada2_color.jpg", "normal": "res://espada2_normal.png",
		"metal": "res://espada2_metal.png", "rugosidad": "res://espada2_rugosidad.png", "brillo": "res://espada2_brillo.png",
		"largo": 1.45, "punta": 0.875, "tinte": Color("C8925A"), "color_brillo": Color("FFD08A")},
}

# Tiendas: lo que se suma a la lista común (tienda.gd, EQUIPO) en cada lugar (índice de mapa.gd: 0 Oakhaven, 5 Sunken).
const EN_TIENDA := {0: {"farol_peregrino": 220}, 5: {"moneda_aguila": 450}}


# ================================================================= datos

static func es_extra(id: String) -> bool:
	return ACCESORIOS.has(id) or ARMAS.has(id)


# Datos con la forma de inventario.gd objeto(id) («ranura» y «para»), o {} si no es un objeto de aquí.
static func objeto(id: String) -> Dictionary:
	if ACCESORIOS.has(id):
		var a: Dictionary = ACCESORIOS[id].duplicate(true)
		a["ranura"] = RANURA
		a["para"] = "todos"
		return a
	if ARMAS.has(id):
		var w: Dictionary = ARMAS[id].duplicate(true)
		w["ranura"] = "arma"
		w["para"] = w["tipo"]
		return w
	return {}


# Las ranuras de inventario.gd con la del accesorio al final (sin repetirla si ya está).
static func ranuras(ranuras_de_hoy: Array) -> Array:
	var r := ranuras_de_hoy.duplicate()
	if not RANURA in r:
		r.append(RANURA)
	return r


# ¿Puede llevarlo? Como inventario.gd puede_llevar, más «solo». «tipo_arma»: el de grupo.gd (espada o cetro).
static func puede_llevar(heroe: String, id: String, tipo_arma: String) -> bool:
	var o := objeto(id)
	if o.is_empty() or (o.has("solo") and o["solo"] != heroe):
		return false
	return o["para"] == "todos" or o["para"] == tipo_arma


# ¿Ya tiene enganchado lo que hace? (si no, no se vende ni se da)
static func disponible(id: String, hechos: Array = HECHOS) -> bool:
	var o := objeto(id)
	if o.is_empty():
		return false
	for k in o.get("efectos", {}):
		if not EFECTOS.has(k) or not EFECTOS[k]["gancho"] in hechos:
			return false
	return true


static func texto_efecto(id: String) -> String:
	return String(objeto(id).get("efecto", ""))


# Lo que se suma a la tienda de un lugar (solo lo disponible): id → precio.
static func en_tienda(lugar: int, hechos: Array = HECHOS) -> Dictionary:
	var r := {}
	var lista: Dictionary = EN_TIENDA.get(lugar, {})
	for id in lista:
		if disponible(id, hechos):
			r[id] = lista[id]
	return r


# ================================================================= efectos

# Efectos sumados de un equipo (ranura → id): los números se suman hasta su tope y los «sí» con uno basta. Los ids
# desconocidos (de una versión más nueva) y los objetos de hoy no aportan nada: el equipo inicial da {}.
static func efectos_de_equipo(equipo: Dictionary) -> Dictionary:
	var r := {}
	for ranura in equipo:
		var o := objeto(str(equipo[ranura]))
		var ef: Dictionary = o.get("efectos", {})
		for k in ef:
			if not EFECTOS.has(k):
				continue
			if EFECTOS[k]["tipo"] == "si":
				r[k] = bool(r.get(k, false)) or bool(ef[k])
			else:
				r[k] = minf(float(EFECTOS[k]["max"]), float(r.get(k, 0.0)) + float(ef[k]))
	return r


static func efectos_de(heroe: String) -> Dictionary:
	if not ResourceLoader.exists("res://inventario.gd"):
		return {}
	return efectos_de_equipo(load("res://inventario.gd").equipo_de(heroe))


# ATB al empezar el combate (combate.gd _ready): nunca 100, para que entre en la cola por el camino normal.
static func atb_inicial(ef: Dictionary, atb_max := 100.0) -> float:
	return clampf(float(ef.get("atb_inicio", 0.0)), 0.0, atb_max - 0.1)


# Umbral del crítico: la misma tirada de combate.gd (_animar_golpe) con otro umbral; no tira un dado de más.
static func prob_critico(base: float, ef: Dictionary) -> float:
	return base + float(ef.get("critico", 0.0))


# ¿Esquiva este golpe físico? Solo tira el dado si lleva esquiva: sin ella, el generador global no se toca.
static func esquiva(ef: Dictionary) -> bool:
	var p := float(ef.get("esquiva", 0.0))
	return p > 0.0 and randf() < p


# Monedas al ganar: el porcentaje más alto de los que lo llevan, una sola vez aunque lo lleven varios.
static func oro_con_extra(oro: int, efectos_presentes: Array) -> int:
	var pct := 0.0
	for ef in efectos_presentes:
		pct = maxf(pct, float(ef.get("oro_pct", 0.0)))
	return oro + int(round(oro * pct / 100.0))


# PM al acabar un turno suyo (combate.gd _terminar_turno). Los aplica y devuelve cuántos.
static func pm_al_terminar(f: Dictionary) -> int:
	var n := int(f.get("efectos", {}).get("pm_turno", 0.0))
	if n <= 0 or f["hp"] <= 0:
		return 0
	var sube := mini(n, f["mp_max"] - f["mp"])
	f["mp"] += sube
	return sube


static func regen(ef: Dictionary) -> float:
	return float(ef.get("regen", 0.0))


# Se cura parte del daño físico que acaba de hacer (impacto de _animar_golpe). Los aplica y devuelve cuántos.
static func robo_vida(f: Dictionary, dano: int) -> int:
	var frac := float(f.get("efectos", {}).get("robo_vida", 0.0))
	if frac <= 0.0 or dano <= 0 or f["hp"] <= 0:
		return 0
	var c := mini(maxi(1, int(dano * frac)), f["hp_max"] - f["hp"])
	f["hp"] += c
	return c


# Hoja sin Nombre: +1 de ataque por detalle de lore visto (Progreso «lore_visto»), hasta su tope.
static func ataque_recuerdo(ef: Dictionary, lore_visto: Dictionary) -> int:
	var tope := int(ef.get("ataque_recuerdo", 0.0))
	return mini(tope, lore_visto.size()) if tope > 0 else 0


# Guardiana de Ámbar: daño de la réplica si le golpean mientras defiende (0 si no toca).
static func replica(f: Dictionary, defendiendo: bool) -> int:
	var m := float(f.get("efectos", {}).get("contra_defendiendo", 0.0))
	if m <= 0.0 or not defendiendo or f["hp"] <= 0:
		return 0
	return maxi(1, int(f["atk"] * m))


# Gemelas de la Muralla: quién recibe un golpe dirigido a «objetivo» (un aliado en pie con «cubrir», si el objetivo va
# por debajo de su umbral de vida; si no, el objetivo).
static func quien_cubre(objetivo: Dictionary, heroes: Array) -> Dictionary:
	if not objetivo.get("hero", false):
		return objetivo
	for h in heroes:
		var umbral := float(h.get("efectos", {}).get("cubrir", 0.0))
		if umbral > 0.0 and not is_same(h, objetivo) and h["hp"] > 0 and objetivo["hp"] < objetivo["hp_max"] * umbral:
			return h
	return objetivo


# ================================================================= conseguirlo

# Lo apunta en «equipables» (como inventario.gd agregar) y devuelve el aviso; "" si no existe o ya lo tenía.
static func conseguir(id: String) -> String:
	if not es_extra(id) or not ResourceLoader.exists("res://inventario.gd"):
		return ""
	var lista: Array = load("res://inventario.gd").datos()["equipables"]
	if id in lista:
		return ""
	lista.append(id)
	return "Has conseguido %s." % objeto(id)["nombre"]
