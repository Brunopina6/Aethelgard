extends RefCounted
# DUEÑO: agente C. BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11): la VIDA, la MISIÓN y el CONOCIMIENTO, como datos.
# TODO ES PROPUESTA [P] y está APAGADO: solo existe en el banco de pruebas de Auditoría (zonas3d/barrio/). Fuera del banco
# activado() es FALSO, las señales no hacen nada y la misión no sale en el Diario (encargos.gd la lista, pero oculta).
# Plan: docs/v12/BARRIO_OAKHAVEN_PLAN.md §4-§7 y §11; lo hecho: docs/v12/BARRIO_OAKHAVEN.md, sección C.
#
# «Antes de que se enfríe» (misión secundaria, patrón del cantero: ciudades/oakhaven_propuestas.gd):
#   Al carro del reparto del horno de Maela se le ha partido el pasador del eje. Damián, el carretero, lo corta, pero no a
#   ojo: necesita su galga (una tablilla con muescas para medir el agujero del eje), que se dejó en casa, en la repisa
#   del hogar. Con la galga se mide el eje, Damián corta el pasador en la trastienda, se pone en el carro, Maela da una
#   cesta de pan caliente para Odila (la mujer de Damián) y, al volver con Maela, su premio UNA vez: «Éter» ×2.
#   SIN CUENTA ATRÁS (Maela vuelve a meter el pan al horno: el título es tono, no un temporizador) y FUERA DE ORDEN:
#     - la galga antes de empezar se guarda y NO empieza la misión (como las marcas sueltas del cantero);
#     - el taller antes que el carro: Damián ha OÍDO que el carro se paró y la misión empieza;
#     - medir antes del taller vale si hay galga (quien mide ya ha visto el carro);
#     - el pasador solo con la medida; la cesta solo con el carro arreglado; el premio solo tras la entrega.
#   Cada señal es idempotente: salir a mitad de un diálogo, repetirlo o cargar una partida no rompe nada.
#   La galga es un ESTADO (enf_galga), no un objeto de inventario (menus.gd lo enseñaría y la tienda lo vendería).
#   Sin el prólogo visto y el hito pv_02 (puede_pasar()) no empieza nada: ninguna señal ni pieza cambia la partida.
#
# SABE / HA OÍDO / CREE (plan §6), como datos: AFIRMACIONES (verdad o no) y SABER (quién, qué, cómo; gana la ÚLTIMA regla
# cuyo «si» se cumple). Cada diálogo de NPCS declara lo que dice («dice»: {afirmación: modo}) y lo apunta con señales
# «bar:<modo>:<afirmación>:<npc>», que guardan bools DEL JUGADOR: j_<modo>_<af> y j_<modo>_<af>_<npc>. Solo lo que se
# SABE de primera mano hace avanzar la misión; lo oído o creído va al Diario con su fuente. Lo falso (Brena cree que Avena
# dio una coz al carro) se desmiente examinando a Avena (j_sabe_no_culpa_caballo) y Brena cambia de frase.
# Rumores ambientales: solo caravanas, caminos, precios y guardia. Ningún texto nombra lo reservado (prueba_barrio_datos).
#
# Estado: SOLO bool en «mazmorras»["oak_barrio"] (ninguna clave nueva de partida; una partida antigua: todo false y la
# misión oculta). El premio va al inventario («Éter»).
#
# CONTRATO con la región (zonas3d/barrio/barrio.gd, dueño A):
#   - PIEZAS: id → {"ancla", "radio", "boton", "si", "senal", "texto", "texto_sin"}. La región enseña las de la zona de
#     Kael («int_<id>_…» solo dentro de ese interior) y, al pulsar, llama a accion(pid) → {texto, efecto, dialogo, guardar}.
#     El botón es FIJO (la región lee «boton»): el carro hace lo que toca según el estado (examinar, medir o poner el
#     pasador) y el aviso lo dice. PETICIÓN DE CONTRATO a A: si existe Barrio.boton(pid), usarlo (el texto cambiaría a
#     «Medir el eje con la galga» y «Poner el pasador»); boton() ya está aquí.
#   - puerta(id): "" = se puede pasar; si no, el aviso. Lleva la guardia del prólogo y, en la vivienda, la primera vez
#     «llamar a la puerta» (Odila abre; pone viv_llamado) sin entrar.
#   - paso_interno(nombre): la trastienda del taller, cerrada hasta hablar con Damián (enf_taller); la cortina del horno y
#     la alcoba, siempre abiertas. (Lo pregunta interiores.gd, de B.)
#   - aplicar(señal «bar:…») → aviso; registrar_dialogic(); dialogo_de(npc, veces); frase(npc, veces); programa(npc).

const NOMBRE := "oak_barrio"                         # su diccionario en «mazmorras» (solo bool)
const NOMBRE_LUGAR := "Oakhaven (barrio de prueba)"
const ACTIVO_POR_DEFECTO := false
const META := "barrio_v12"                           # meta de SESIÓN que pone la región en el banco
const TEXTO_PROLOGO := "Todavía no: termina el prólogo."
const PREFIJO := "bar:"
const RUTA := "res://dialogos/oakhaven/barrio/"
const MISION := "bar_enfria"
const PREMIO := {"objetos": {"Éter": 2}}             # decisión del coordinador (16/11): catálogo real, sin el Farol

const PERSONAJES := {
	"maela": "res://dialogos/personajes/oakhaven/barrio/maela.dch",
	"tobias": "res://dialogos/personajes/oakhaven/barrio/tobias.dch",
	"brena": "res://dialogos/personajes/oakhaven/barrio/brena.dch",
	"damian": "res://dialogos/personajes/oakhaven/barrio/damian.dch",
	"odila": "res://dialogos/personajes/oakhaven/barrio/odila.dch",
	"nela": "res://dialogos/personajes/oakhaven/barrio/nela.dch",
}

# Las claves de la misión (todas bool en mazmorras["oak_barrio"]).
const ESTADOS := ["enf_carro_visto", "enf_taller", "enf_galga", "enf_medida", "enf_pasador", "enf_reparado", "enf_cesta",
	"enf_entrega", "enf_fin", "viv_llamado", "j_visto_carro", "j_visto_clavo", "j_sabe_no_culpa_caballo"]

# ---------------------------------------------------------------------------------------------------- vecinos
# «chibi»: [oficio, persona] de personajes/npc_v12 (fuente/crear_npc_chibi.py; sin el modelo, una cápsula de su «tinte»).
# «oficio»: lo que hace, para su perspectiva. «dialogos»: {dialogo, si, prioridad, dice}: la primera con prioridad que se
# cumple gana; las demás se turnan con «veces». «frases»: lo que dice al pasar o sin diálogo (≤ 48 letras).
const NPCS := {
	"maela": {"nombre": "Maela", "corto": "Maela", "oficio": "panadera", "boton": "Hablar con Maela",
		"chibi": ["panadera", "maela"], "tinte": Color(0.86, 0.62, 0.42),
		"dialogos": [
			{"dialogo": "bar_maela_fin", "si": ["estado:enf_entrega", "!estado:enf_fin"], "prioridad": true, "dice": {}},
			{"dialogo": "bar_maela_cesta", "si": ["estado:enf_reparado", "!estado:enf_cesta"], "prioridad": true, "dice": {}},
			{"dialogo": "bar_maela_espera", "si": ["estado:enf_cesta", "!estado:enf_entrega"], "prioridad": true, "dice": {}},
			{"dialogo": "bar_maela_carro", "si": ["!estado:enf_carro_visto", "!estado:enf_fin"], "prioridad": true,
				"dice": {"pasador_roto": "sabe"}},
			{"dialogo": "bar_maela_pendiente", "si": ["estado:enf_carro_visto", "!estado:enf_reparado"], "prioridad": true,
				"dice": {"pasador_roto": "sabe"}},
			{"dialogo": "bar_maela_despues", "si": "estado:enf_fin", "dice": {}}],
		"frases": ["El pan no espera a nadie.", "Masa, horno, mostrador. Y otra vez.", "¡Hogazas recién hechas!"]},
	"tobias": {"nombre": "Tobías", "corto": "Tobías", "oficio": "porteador", "boton": "Hablar con Tobías",
		"chibi": ["porteador", "tobias"], "tinte": Color(0.46, 0.52, 0.66),
		"dialogos": [
			{"dialogo": "bar_tobias_reparto", "si": "estado:enf_reparado", "prioridad": true, "dice": {"pasador_roto": "sabe"}},
			{"dialogo": "bar_tobias_rumor", "si": "!estado:enf_reparado", "dice": {"pasador_roto": "oido"}},
			{"dialogo": "bar_tobias_caravanas", "si": "", "dice": {"caravana_retraso": "sabe"}}],
		"frases": ["Esta caja pesa como un buey.", "Del carro al patio y del patio al carro.", "Paso, que llevo carga."]},
	"brena": {"nombre": "Brena", "corto": "Brena", "oficio": "encargada del establo", "boton": "Hablar con Brena",
		"chibi": ["encargada_establo", "brena"], "tinte": Color(0.42, 0.58, 0.36),
		"dialogos": [
			{"dialogo": "bar_brena_avena", "si": "estado:j_sabe_no_culpa_caballo", "prioridad": true, "dice": {}},
			{"dialogo": "bar_brena_coz", "si": ["!estado:j_sabe_no_culpa_caballo", "!estado:enf_reparado"],
				"dice": {"culpa_caballo": "cree"}},
			{"dialogo": "bar_brena_caminos", "si": "", "dice": {"ronda_doble": "oido"}}],
		"frases": ["Quieta, Avena, que te dejo brillante.", "Un cubo más y el abrevadero lleno.", "Heno, agua y paciencia."]},
	"damian": {"nombre": "Damián", "corto": "Damián", "oficio": "carretero", "boton": "Hablar con Damián",
		"chibi": ["herrero", "damian"], "tinte": Color(0.52, 0.36, 0.24),
		"dialogos": [
			{"dialogo": "bar_damian_pasador", "si": ["estado:enf_medida", "!estado:enf_pasador"], "prioridad": true,
				"dice": {"pasador_roto": "sabe"}},
			{"dialogo": "bar_damian_galga_traida", "si": ["estado:enf_galga", "!estado:enf_medida"], "prioridad": true,
				"dice": {}},
			{"dialogo": "bar_damian_oido", "si": ["!estado:enf_taller", "!estado:enf_carro_visto", "!estado:enf_galga",
				"!estado:enf_medida"], "prioridad": true, "dice": {"pasador_roto": "oido", "galga_en_casa": "sabe"}},
			{"dialogo": "bar_damian_encargo", "si": ["!estado:enf_taller", "estado:enf_carro_visto", "!estado:enf_galga",
				"!estado:enf_medida"], "prioridad": true, "dice": {"pasador_roto": "oido", "galga_en_casa": "sabe"}},
			{"dialogo": "bar_damian_galga", "si": ["estado:enf_taller", "!estado:enf_galga", "!estado:enf_medida"],
				"prioridad": true, "dice": {"galga_en_casa": "sabe"}},
			{"dialogo": "bar_damian_despues", "si": "estado:enf_pasador", "dice": {}}],
		"frases": ["Radio a radio se hace una rueda.", "El fresno, seco; la mano, firme.", "Cuidado con las virutas."]},
	"odila": {"nombre": "Odila", "corto": "Odila", "oficio": "costurera", "boton": "Hablar con Odila",
		"chibi": ["campesina", "odila"], "tinte": Color(0.70, 0.40, 0.46),
		"dialogos": [
			{"dialogo": "bar_odila_entrega", "si": ["estado:enf_cesta", "!estado:enf_entrega"], "prioridad": true, "dice": {}},
			{"dialogo": "bar_odila_galga_puerta", "si": ["!estado:enf_galga", "!estado:enf_medida", "cond:vivienda_cerrada"],
				"prioridad": true, "dice": {"galga_en_casa": "sabe"}},
			{"dialogo": "bar_odila_galga", "si": ["!estado:enf_galga", "!estado:enf_medida", "!cond:vivienda_cerrada"],
				"prioridad": true, "dice": {"galga_en_casa": "sabe"}},
			{"dialogo": "bar_odila_despues", "si": "estado:enf_entrega", "prioridad": true, "dice": {}},
			{"dialogo": "bar_odila_precios", "si": "", "dice": {"peaje_sube": "oido"}}],
		"frases": ["Puntada a puntada.", "Nela, no te alejes de la puerta.", "Este hilo ha costado un ojo."]},
	"nela": {"nombre": "Nela", "corto": "Nela", "oficio": "hija de Damián y Odila", "boton": "Hablar con Nela",
		"chibi": ["nina", "nela"], "tinte": Color(0.92, 0.72, 0.36),
		"dialogos": [{"dialogo": "bar_nela", "si": "", "dice": {}}],
		"frases": ["¡Rueda, rueda!", "¡Papá me hizo una rueda!", "¿Juegas a las carreras de ruedas?"]},
}

# Dónde trabaja cada uno «por dentro» (las anclas de B) y, mientras el interior no exista, su puesto FUERA, cerca de su
# puerta pero a 3 m o más de su botón (los dos botones no se pisan), fuera de su umbral y de los caminos (la prueba lo
# comprueba). El caballo no habla: se examina.
const PUESTOS := {
	"damian": {"interior": "taller", "ancla": "int_taller_potro", "tarea": "tarea",
		"fuera": Vector3(-2.0, 1.4, -22.6), "mira": Vector3(-4.6, 1.4, -20.6)},
	"odila": {"interior": "vivienda", "ancla": "int_vivienda_odila", "tarea": "tarea",
		"fuera": Vector3(-25.0, 1.4, -28.9), "mira": Vector3(-23.0, 1.4, -27.4)},
	"nela": {"interior": "vivienda", "ancla": "int_vivienda_nela", "tarea": "tarea",
		"fuera": Vector3(-19.0, 1.4, -29.2), "mira": Vector3(-20.4, 1.4, -27.8)},
}

# ---------------------------------------------------------------------------------------------------- piezas
# Lo que se examina. «ancla» del contrato (exterior de trazado.gd o «int_*» de los interiores de B). «si»: si no se
# cumple, se enseña «texto_sin». «senal»: la que se aplica al usarla (además de lo que haga accion()).
const PIEZAS := {
	"carro_horno": {"ancla": "carro_horno", "radio": 1.5, "boton": "Examinar el carro", "si": "", "senal": "",
		"texto": "Al eje le falta el pasador: partido en dos, gastado, no roto de un golpe.",
		"texto_sin": ""},
	"avena": {"ancla": "establo_caballo", "radio": 1.9, "boton": "Examinar a Avena", "si": "", "senal": "bar:no_culpa",
		"texto": "Avena tiene los cascos limpios y las herraduras enteras. No ha dado ninguna coz.", "texto_sin": ""},
	"clavo_galga": {"ancla": "int_taller_clavo", "radio": 1.3, "boton": "Examinar el clavo", "si": "", "senal": "bar:clavo",
		"texto": "Un clavo con la silueta de una galga pintada alrededor. Vacío.", "texto_sin": ""},
	"galga": {"ancla": "int_vivienda_repisa", "radio": 1.3, "boton": "Coger la galga", "si": "!estado:enf_galga",
		"senal": "bar:galga", "texto": "En la repisa, junto al cántaro: una tablilla con muescas. La galga del carretero.",
		"texto_sin": "La repisa, junto al cántaro. Ahí estaba la galga."},
	"rueda_nela": {"ancla": "int_vivienda_rincon", "radio": 1.2, "boton": "Examinar la rueda", "si": "", "senal": "",
		"texto": "Una rueda de juguete, tallada con mimo. Sus radios llevan las muescas del taller.", "texto_sin": ""},
	"estante_horno": {"ancla": "int_horno_estante", "radio": 1.3, "boton": "Examinar el estante", "si": "", "senal": "",
		"texto": "Hogazas enfriándose en fila. Huele a corteza recién hecha.", "texto_sin": ""},
}

# Los textos del carro según el estado (accion("carro_horno")).
const CARRO := {
	"medir": "Mides el eje con la galga: tres muescas y media.",
	"medido": "Ya tienes la medida del eje. Damián cortará el pasador.",
	"poner": "Encajas el pasador nuevo de un golpe seco. La rueda gira sin juego.",
	"arreglado": "El carro del horno, con su pasador nuevo. Listo para el reparto.",
	"sin_prologo": "Un carro de reparto parado. Lleva cestas vacías.",
}
const LLAMAR := "Llamas a la puerta. Odila abre: «Pasa, pasa, que se escapa el calor del hogar.»"

# ---------------------------------------------------------------------------------------------------- misión
const MISIONES := [
	{"id": MISION, "nombre": "Antes de que se enfríe", "quien": "maela", "tipo": "secundaria",
		"resumen": "Al carro del reparto del horno se le ha partido el pasador del eje, y el pan espera.",
		"empieza": "cond:enf_empieza",
		"fin": "cond:enf_terminada",
		"pasos": [
			{"id": "carro", "texto": "Mira qué le pasa al carro del horno, parado en la calle comercial.",
				"hecho": "estado_de:oak_barrio/enf_carro_visto"},
			{"id": "taller", "texto": "Pregunta en el taller del carretero, en el patio de talleres.",
				"hecho": "cond:enf_taller_o_mas"},
			{"id": "galga", "texto": "Busca la galga del carretero.",
				"hecho": "cond:enf_galga_o_mas", "saltado_si": "cond:enf_galga_saltada"},
			{"id": "medir", "texto": "Mide el eje del carro con la galga.", "hecho": "cond:enf_medida_o_mas"},
			{"id": "pasador", "texto": "Lleva la medida a Damián, el carretero.", "hecho": "cond:enf_pasador_o_mas"},
			{"id": "reparar", "texto": "Pon el pasador nuevo en el carro del horno.", "hecho": "cond:enf_reparado_o_mas"},
			{"id": "entrega", "texto": "Recoge la cesta de Maela y llévala a casa de Odila, todavía caliente.",
				"hecho": "estado_de:oak_barrio/enf_entrega"},
			{"id": "volver", "texto": "Vuelve con Maela, al horno.", "hecho": "estado_de:oak_barrio/enf_fin"}],
		# Lo que el jugador sabe, ha oído o cree, con su fuente (≤ 15 palabras).
		"pistas": [
			{"texto": "Maela vio partirse el pasador del eje del carro.", "si": "estado_de:oak_barrio/j_sabe_pasador_roto_maela"},
			{"texto": "El carro: pasador gastado y partido, no roto de un golpe.", "si": "estado_de:oak_barrio/j_visto_carro"},
			{"texto": "Tobías (se lo oyó a Maela): al carro se le partió una pieza.",
				"si": "estado_de:oak_barrio/j_oido_pasador_roto_tobias"},
			{"texto": "Brena cree que Avena dio una coz al carro.", "si": "estado_de:oak_barrio/j_cree_culpa_caballo_brena"},
			{"texto": "Avena tiene los cascos limpios: no fue ella.", "si": "estado_de:oak_barrio/j_sabe_no_culpa_caballo"},
			{"texto": "Damián no corta a ojo: su galga está en casa, en la repisa.",
				"si": "estado_de:oak_barrio/j_sabe_galga_en_casa_damian"},
			{"texto": "Odila: la galga de Damián está en la repisa, junto al cántaro.",
				"si": "estado_de:oak_barrio/j_sabe_galga_en_casa_odila"},
			{"texto": "En el taller, un clavo vacío con la silueta de una galga.", "si": "estado_de:oak_barrio/j_visto_clavo"},
			{"texto": "Tienes la galga del carretero.", "si": "estado_de:oak_barrio/enf_galga"},
			{"texto": "La medida del eje: tres muescas y media.", "si": "estado_de:oak_barrio/enf_medida"},
			{"texto": "Maela da una cesta de pan caliente para Odila.", "si": "estado_de:oak_barrio/enf_cesta"}],
		"recompensa": {}, "pago": "Maela te da 2 Éter, y el reparto del horno vuelve a la calle."},
]

# ---------------------------------------------------------------------------------------------------- conocimiento
const MODOS := ["sabe", "oido", "cree"]
# Lo que se puede saber (verdad o no). Las cuatro últimas son los rumores ambientales (solo caravanas, caminos, precios y
# guardia).
const AFIRMACIONES := {
	"pasador_roto": {"verdad": true, "texto": "Al carro del horno se le partió el pasador del eje."},
	"galga_en_casa": {"verdad": true, "texto": "La galga del carretero está en su casa, en la repisa."},
	"culpa_caballo": {"verdad": false, "texto": "Avena, la yegua del establo, dañó el carro de una coz."},
	"caravana_retraso": {"verdad": true, "texto": "La caravana del sur llegó con tres días de retraso."},
	"ronda_doble": {"verdad": true, "texto": "La guardia dobla la ronda del camino del este."},
	"peaje_sube": {"verdad": true, "texto": "Los peajes del camino del sur han subido."},
}
# Quién sabe, ha oído o cree qué. «de»: de quién lo oyó (un vecino, «kael», «guardia», «caravaneros» o «rumor»). Gana la
# ÚLTIMA regla cuyo «si» se cumple (el conocimiento cambia con lo que pasa).
const FUENTES_OIDO := ["kael", "rumor", "guardia", "caravaneros"]
const SABER := [
	{"npc": "maela", "af": "pasador_roto", "modo": "sabe"},
	{"npc": "tobias", "af": "pasador_roto", "modo": "oido", "de": "maela"},
	{"npc": "tobias", "af": "pasador_roto", "modo": "sabe", "si": "estado:enf_reparado"},
	{"npc": "tobias", "af": "caravana_retraso", "modo": "sabe"},
	{"npc": "brena", "af": "culpa_caballo", "modo": "cree", "si": "!estado:j_sabe_no_culpa_caballo"},
	{"npc": "brena", "af": "ronda_doble", "modo": "oido", "de": "guardia"},
	{"npc": "damian", "af": "galga_en_casa", "modo": "sabe"},
	{"npc": "damian", "af": "pasador_roto", "modo": "oido", "de": "rumor"},
	{"npc": "damian", "af": "pasador_roto", "modo": "oido", "de": "kael", "si": "estado:enf_carro_visto"},
	{"npc": "damian", "af": "pasador_roto", "modo": "sabe", "si": "estado:enf_medida"},
	{"npc": "odila", "af": "galga_en_casa", "modo": "sabe"},
	{"npc": "odila", "af": "peaje_sube", "modo": "oido", "de": "caravaneros"},
	{"npc": "nela", "af": "galga_en_casa", "modo": "sabe"},
]

# Condiciones con nombre (cond:…), para error_condicion().
const CONDICIONES := ["enf_empieza", "enf_terminada", "enf_taller_o_mas", "enf_galga_o_mas", "enf_galga_saltada",
	"enf_medida_o_mas", "enf_pasador_o_mas", "enf_reparado_o_mas", "vivienda_cerrada", "taller_cerrado", "mision_activa"]
const TIPOS_CONDICION := ["estado", "cond", "hito", "estado_de"]


static func _p():
	return load("res://progreso.gd")


# Solo en Auditoría o en el editor, dentro del banco y con la región puesta. Fuera del banco, nunca.
static func activado() -> bool:
	if not (OS.has_feature("auditoria") or OS.has_feature("editor")):
		return ACTIVO_POR_DEFECTO
	return bool(Engine.get_meta("banco_pruebas", false)) and bool(Engine.get_meta(META, false))


# Kael ya salió de Oakhaven: el mismo criterio que «cond:kael_salio» (ciudades/oakhaven.gd) y que el viaje del
# mapamundi (zonas3d/mapamundi/datos.gd, motivo_bloqueo).
static func puede_pasar() -> bool:
	return bool(Engine.get_meta("prologo_visto", false)) and _p().hito("pv_02")


static func estado(clave: String) -> bool:
	return _p().estado(NOMBRE, clave)


static func poner(clave: String) -> void:
	_p().poner_estado(NOMBRE, clave)


# ¿Está construido el interior (agente B)? Sin él, los vecinos de dentro esperan junto a su puerta.
static func interior_hecho(id: String) -> bool:
	var ruta := "res://zonas3d/barrio/interiores.gd"
	return ResourceLoader.exists(ruta) and load(ruta).ORIGEN.has(id)


# Condiciones: «estado:<clave>» de oak_barrio, «cond:<nombre>»; lo demás (hito:, estado_de:…) lo entiende encargos.gd.
static func cumple(c: Variant) -> bool:
	if c is Array:
		for x in c:
			if not cumple(x):
				return false
		return true
	var s := str(c).strip_edges()
	if s == "":
		return true
	if s.begins_with("!"):
		return not cumple(s.substr(1))
	if s.begins_with("estado:"):
		return estado(s.trim_prefix("estado:"))
	if s.begins_with("cond:"):
		return _cond(s.trim_prefix("cond:"))
	return load("res://encargos.gd").cumple(s)       # (sin fuente: encargos no vuelve aquí)


static func _cond(n: String) -> bool:
	match n:
		"enf_empieza":
			return activado() and puede_pasar() and (estado("enf_carro_visto") or estado("enf_taller")
				or estado("enf_medida") or estado("enf_pasador"))
		"enf_terminada":
			return activado() and estado("enf_fin")
		"mision_activa":
			return _cond("enf_empieza") and not estado("enf_fin")
		"enf_taller_o_mas":
			return estado("enf_taller") or estado("enf_pasador")
		"enf_galga_o_mas":
			return estado("enf_galga") or estado("enf_medida") or estado("enf_pasador")
		"enf_galga_saltada":                         # (solo para las pruebas: hoy no se puede cortar sin galga)
			return estado("enf_pasador") and not estado("enf_galga")
		"enf_medida_o_mas":
			return estado("enf_medida") or estado("enf_pasador")
		"enf_pasador_o_mas":
			return estado("enf_pasador") or estado("enf_reparado")
		"enf_reparado_o_mas":
			return estado("enf_reparado")
		"vivienda_cerrada":
			return not interior_hecho("vivienda")
		"taller_cerrado":
			return not interior_hecho("taller")
	push_warning("Barrio: condición desconocida «%s»" % n)
	return false


# "" si la condición está bien escrita; si no, qué falla (para las pruebas).
static func error_condicion(cond: Variant) -> String:
	if cond is Array:
		for c in cond:
			var e := error_condicion(c)
			if e != "":
				return e
		return ""
	var c := str(cond).strip_edges().trim_prefix("!")
	if c == "":
		return ""
	var tipo := c.get_slice(":", 0)
	var valor := c.substr(tipo.length() + 1)
	if not tipo in TIPOS_CONDICION or valor == "" or not c.contains(":"):
		return "condición desconocida «%s»" % c
	if tipo == "cond" and not valor in CONDICIONES:
		return "condición con nombre desconocida «%s»" % valor
	if tipo == "estado" and not (valor in ESTADOS or valor.begins_with("j_")):
		return "estado desconocido «%s»" % valor
	if tipo == "estado_de" and valor.get_slice_count("/") != 2:
		return "estado_de sin «lugar/clave»: «%s»" % c
	return ""


# ================================================================= vecinos y diálogos

static func npc(id: String) -> Dictionary:
	return NPCS.get(id, {})


static func ruta_dialogo(n: String) -> String:
	return RUTA + n + ".dtl"


# Todos los diálogos del barrio (para las pruebas: cada uno existe y nadie más los usa).
static func dialogos() -> Array:
	var r: Array = []
	for id in NPCS:
		for d in NPCS[id]["dialogos"]:
			r.append(d["dialogo"])
	return r


# El diálogo que toca con un vecino ("" = ninguno: dice una frase). Sin el prólogo, ninguno (solo frases).
static func dialogo_de(id: String, veces := 0) -> String:
	var n := npc(id)
	if n.is_empty() or not activado() or not puede_pasar():
		return ""
	var normales: Array = []
	for d in n["dialogos"]:
		if not cumple(d.get("si", "")):
			continue
		if d.get("prioridad", false):
			return ruta_dialogo(d["dialogo"])
		normales.append(d["dialogo"])
	if normales.is_empty():
		return ""
	return ruta_dialogo(normales[posmod(veces, normales.size())])


static func frase(id: String, veces := 0) -> String:
	var n := npc(id)
	if n.is_empty():
		return ""
	var f: Array = n["frases"]
	return str(f[posmod(veces, f.size())])


# Los personajes nuevos de Dialogic (como ciudades/sunken.gd): se dan a conocer en tiempo de juego, sin tocar
# project.godot.
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


# El programa de la rutina según la misión (barrio_vivo.gd lo cambia al acabar un ciclo, o al instante si no se ve):
#   maela/tobias: «normal»; «carro_parado» con la misión empezada y el carro sin arreglar; «reparto» con él arreglado.
#   brena: «normal». Damián, Odila y Nela: «puesto» (su tarea, sin ruta).
static func programa(id: String) -> String:
	match id:
		"maela", "tobias":
			if estado("enf_reparado"):
				return "reparto"
			if _cond("enf_empieza"):
				return "carro_parado"
			return "normal"
		"brena":
			return "normal"
	return "puesto" if NPCS.has(id) else ""


# Cómo conoce un vecino una afirmación ("" = no la conoce): la ÚLTIMA regla de SABER que se cumple.
static func modo_de(id: String, af: String) -> String:
	var r := ""
	for s in SABER:
		if s["npc"] == id and s["af"] == af and cumple(s.get("si", "")):
			r = s["modo"]
	return r


# De quién lo oyó ("" si no lo oyó o no lo conoce).
static func fuente_de(id: String, af: String) -> String:
	var r := ""
	for s in SABER:
		if s["npc"] == id and s["af"] == af and cumple(s.get("si", "")):
			r = str(s.get("de", ""))
	return r


# ================================================================= piezas y puertas

# "" = se puede pasar; si no, el aviso. La guardia del prólogo va primero; en la vivienda, la primera vez se llama (solo
# con el interior construido por B: mientras no, Odila está fuera, en su puerta, y la región dice «en obras»).
static func puerta(id: String) -> String:
	if not puede_pasar():
		return TEXTO_PROLOGO
	if id == "vivienda" and activado() and interior_hecho("vivienda") and not estado("viv_llamado"):
		poner("viv_llamado")
		return LLAMAR
	return ""


# Pasos internos de los interiores (B pregunta aquí): la trastienda del taller se abre al hablar con Damián.
static func paso_interno(nombre: String) -> bool:
	match nombre:
		"trastienda":
			return estado("enf_taller") or estado("enf_pasador")
		"cortina_horno", "alcoba":
			return true
	return false


# El texto del botón de una pieza según el estado (PETICIÓN DE CONTRATO: la región aún usa PIEZAS[pid]["boton"]).
static func boton(pid: String) -> String:
	if pid == "carro_horno" and activado() and puede_pasar():
		if estado("enf_pasador") and not estado("enf_reparado"):
			return "Poner el pasador"
		if estado("enf_galga") and not estado("enf_medida"):
			return "Medir el eje con la galga"
	return str(PIEZAS.get(pid, {}).get("boton", "Examinar"))


# Usar una pieza: {texto, efecto, dialogo, guardar}. {} si no existe.
static func accion(pid: String) -> Dictionary:
	if not PIEZAS.has(pid):
		return {}
	var d: Dictionary = PIEZAS[pid]
	if not activado() or not puede_pasar():
		return {"texto": CARRO["sin_prologo"] if pid == "carro_horno" else str(d["texto"]), "efecto": "", "dialogo": "",
			"guardar": false}
	if pid == "carro_horno":
		return _usar_carro()
	if not cumple(d.get("si", "")):
		return {"texto": str(d["texto_sin"]), "efecto": "", "dialogo": "", "guardar": false}
	var t := str(d["texto"])
	var cambia := false
	if str(d.get("senal", "")) != "":
		var a := aplicar(str(d["senal"]))
		if a != "":
			cambia = true
			t = (t + " " + a) if pid != "galga" else a
	return {"texto": t, "efecto": "examinar", "dialogo": "", "guardar": cambia}


static func _usar_carro() -> Dictionary:
	var t := ""
	if estado("enf_pasador") and not estado("enf_reparado"):
		t = CARRO["poner"] + _sufijo(aplicar("bar:reparado"))
	elif estado("enf_reparado"):
		t = CARRO["arreglado"]
	elif estado("enf_galga") and not estado("enf_medida"):
		t = CARRO["medir"] + _sufijo(aplicar("bar:medida"))
	elif estado("enf_medida"):
		t = CARRO["medido"]
	else:
		t = str(PIEZAS["carro_horno"]["texto"]) + _sufijo(aplicar("bar:carro"))
	return {"texto": t, "efecto": "examinar", "dialogo": "", "guardar": true}


static func _sufijo(a: String) -> String:
	return " " + a if a != "" else ""


# ================================================================= señales («bar:…»)

# Aplica una señal «bar:…» (de un diálogo o de una pieza) y devuelve el aviso ("" si no hace nada). Idempotentes: cada
# efecto se aplica una vez; el premio, una sola vez (enf_fin se pone ANTES de darlo). Sin activar o sin el prólogo, nada.
static func aplicar(senal: Variant) -> String:
	var s := str(senal)
	if not s.begins_with(PREFIJO) or not activado() or not puede_pasar():
		return ""
	var k := s.trim_prefix(PREFIJO)
	var antes := _cond("enf_empieza")
	var t := ""
	var partes := k.split(":")
	if partes.size() == 3 and partes[0] in MODOS:
		t = _apuntar(partes[0], partes[1], partes[2])
	else:
		match k:
			"carro":                                  # examinar el carro: se ve el pasador partido
				var nuevo := not estado("j_visto_carro")
				poner("j_visto_carro")
				_saber("sabe", "pasador_roto", "")
				poner("enf_carro_visto")
				t = "Diario: lo que le pasa al carro, apuntado." if nuevo and antes else ""
			"no_culpa":
				if estado("j_sabe_no_culpa_caballo"):
					return ""
				poner("j_sabe_no_culpa_caballo")
				t = "Diario: Avena no fue." if _cond("mision_activa") else ""
			"clavo":
				if estado("j_visto_clavo"):
					return ""
				poner("j_visto_clavo")
				t = "Diario: el clavo vacío del taller." if _cond("mision_activa") else ""
			"taller":
				if estado("enf_taller"):
					return ""
				poner("enf_taller")                   # (la trastienda se abre: paso_interno)
			"galga":
				if estado("enf_galga"):
					return ""
				poner("enf_galga")
				t = "Coges la galga: una tablilla con muescas." + (" Diario: apuntado." if antes else "")
			"medida":
				if estado("enf_medida") or not estado("enf_galga"):
					return ""
				poner("enf_medida")
				poner("enf_carro_visto")              # quien mide el eje ya ha visto el carro
				t = "Diario: la medida del eje."
			"pasador":
				if estado("enf_pasador") or not estado("enf_medida"):
					return ""
				poner("enf_pasador")
				poner("enf_taller")
				t = "Damián te da un pasador de fresno nuevo."
			"reparado":
				if estado("enf_reparado") or not estado("enf_pasador"):
					return ""
				poner("enf_reparado")
				t = "El carro del horno vuelve a rodar."
			"cesta":
				if estado("enf_cesta") or not estado("enf_reparado"):
					return ""
				poner("enf_cesta")
				t = "Maela te da una cesta de pan caliente para Odila."
			"entrega":
				if estado("enf_entrega") or not estado("enf_cesta"):
					return ""
				poner("enf_entrega")
				t = "Odila recibe la cesta, todavía caliente."
			"fin":
				if estado("enf_fin") or not estado("enf_entrega"):
					return ""
				poner("enf_fin")                       # ANTES del premio: nunca dos veces
				return "Maela te da %s. Misión cumplida: %s." % [_dar(PREMIO), MISIONES[0]["nombre"]]
			_:
				push_warning("Barrio: señal desconocida «%s»" % s)
				return ""
	if not antes and _cond("enf_empieza"):
		t = "Misión: %s." % MISIONES[0]["nombre"]       # (empieza aquí: el resto ya va al Diario con ella)
	return t


# «bar:<modo>:<af>:<npc>»: lo que el jugador ha oído a alguien que lo sabe, lo ha oído o lo cree.
static func _apuntar(modo: String, af: String, quien: String) -> String:
	if not AFIRMACIONES.has(af) or not (NPCS.has(quien)):
		push_warning("Barrio: señal de conocimiento desconocida «%s:%s:%s»" % [modo, af, quien])
		return ""
	var clave := "j_%s_%s_%s" % [modo, af, quien]
	if estado(clave):
		return ""
	poner(clave)
	_saber(modo, af, quien)
	if modo == "sabe" and af == "pasador_roto":
		poner("enf_carro_visto")                     # quien lo vio te lo cuenta: el paso del carro, hecho
	if af == "pasador_roto" and quien == "damian" and not estado("enf_taller"):
		pass                                          # (el taller lo pone «bar:taller», al final del diálogo)
	return ""


static func _saber(modo: String, af: String, _quien: String) -> void:
	poner("j_%s_%s" % [modo, af])


static func _dar(premio: Dictionary) -> String:
	var inv = load("res://inventario.gd")
	var partes := PackedStringArray()
	var objetos: Dictionary = premio.get("objetos", {})
	for o in objetos:
		inv.agregar_objeto(o, objetos[o])
		partes.append("%d %s" % [objetos[o], o])
	return " y ".join(partes)
