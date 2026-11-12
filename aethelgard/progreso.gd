extends RefCounted
# Progreso de la partida (Godot 4.x), según el documento «Diseño de juego de Aethelgard»:
#   Ritmo sin grinding: nivel de cada zona, encuentros que suben despacio, experiencia que se
#     ajusta al nivel (ponerse al día / sin regalo por pasarse / los jefes dan mucho) e Incienso de Ceniza.
#   Lore ambiental: detalles que se examinan en cada lugar; el Diario los recoge y, con todos los de un
#     acto, se desbloquea una escena extra.
#   Guardado automático en user://partida.save: al entrar en cada zona, al volver al mapa, tras cada
#     combate y al cerrar la app. Al abrir el juego se vuelve justo donde estabas.
# Uso:  var Progreso = load("res://progreso.gd");  Progreso.mult_exp(...)

# Nivel recomendado de cada zona (tabla de actos: I 1→8, II 8→20, III 20→30, IV 30→38).
const NIVEL_ZONA := {"llanura": 2, "bosque": 4, "montana": 7, "garganta": 7, "desierto": 10, "nieve": 15,
	"yermo": 18, "ceniza": 34, "ciudad": 0}
const PASOS_SUBIDA := 60        # tras los pasos seguros, la probabilidad de encuentro sube despacio
const DIF_LIMPIA := 5           # niveles por encima de la zona: «zona limpia» y casi sin experiencia
const PROB_LIMPIA := 0.15       # en zona limpia salen muchos menos encuentros
const EXP_POR_ENCIMA := 0.1     # experiencia con 5 niveles o más por encima de la zona
const MULT_JEFE := 10.0         # un jefe da como unos 10 combates normales
const PASOS_INCIENSO := 150     # pasos sin encuentros con el Incienso de Ceniza
const INCIENSO := "Incienso de Ceniza"

# Detalles de lore de cada lugar (índice de LUGARES de mapa.gd). Una frase al examinar, 15 palabras o menos.
# "donde": en qué rincón de la zona se pone (ruinas, campamento, claro o plaza en las ciudades).
const DETALLES := {
	0: [{"id": "oak_sello", "nombre": "Sello del crematorio", "donde": "plaza",
			"texto": "Un sello rúnico roto con un anillo partido. Alguien raspó los nombres."},
		{"id": "oak_tapiz", "nombre": "Tapiz de los reyes", "donde": "plaza2",
			"texto": "Un tapiz viejo de la familia real. Han recortado a un niño de la tela."}],
	1: [{"id": "bosque_armadura", "nombre": "Armadura del árbol", "donde": "ruinas",
			"texto": "Un árbol abraza una armadura antigua. Su brazo izquierdo es de oro."}],
	2: [{"id": "garganta_puentes", "nombre": "Pilares de los puentes", "donde": "p2",
			"texto": "Cada pilar del puente lleva el anillo partido, más gastado cuanto más lejos."},
		{"id": "garganta_pilar", "nombre": "Pilar del peregrino", "donde": "p8",
			"texto": "El anillo partido, grabado en el pilar, gastado por miles de manos."}],
	3: [{"id": "ciclopea_estatua", "nombre": "Estatua sin brazo", "donde": "ruinas",
			"texto": "Un caballero de piedra sin brazo izquierdo. Mira hacia el pico."}],
	4: [{"id": "calid_maquina", "nombre": "Máquina enterrada", "donde": "ruinas",
			"texto": "Tubos de una máquina antigua que acaban en un hueco con forma de brazalete."}],
	5: [{"id": "sunken_contratos", "nombre": "Contratos del Águila", "donde": "plaza",
			"texto": "Contratos de la Compañía del Águila, firmados con el sello de la corona."}],
	7: [{"id": "templo_mural", "nombre": "Mural del Templo", "donde": "ruinas",
			"texto": "Una sacerdotisa con un bebé. Los reyes le ciñen un anillo al niño."}],
	# Pastos Verdes (región 3D de la rama experimental; texto propuesto en la biblia v3 §6.3, PV-04, no canon).
	10: [{"id": "pastos_estela", "nombre": "Estela del camino", "donde": "ruinas",
			"texto": "El anillo partido y nombres raspados. Uno de los raspados es reciente."}],
}
# Actos: qué lugares entran y la escena extra que se desbloquea con todos sus detalles.
const ACTOS := [
	{"nombre": "Acto I · Las Cenizas", "lugares": [0, 1, 2], "escena": "El primer portador",
		"texto": "Un caballero de brazo dorado cruzó la Garganta con el Sello. El bosque guardó lo que quedó de él. En Oakhaven, alguien se aseguró de que nadie recordara su nombre."},
	{"nombre": "Acto II · Las Reliquias", "lugares": [4, 5, 3, 7], "escena": "El niño del anillo",
		"texto": "El Sello alimentaba las máquinas de los reyes y devoraba a quien lo llevaba. Para la última pieza no buscaron un caballero: buscaron un niño."},
]
const GUARDADO := "user://partida.save"
# La versión experimental (exploración 3D, modo3d.gd) guarda en otro archivo: nunca toca la partida estable,
# ni siquiera en el PC, donde las dos comparten la carpeta user:// (el proyecto se llama igual).
const GUARDADO_EXP := "user://partida_exp.save"
# Datos de Engine que forman la partida. Las claves nuevas solo se añaden: una partida antigua carga igual
# (faltan y se usan los valores por defecto) y una nueva en una versión antigua deja esas claves sin leer.
const CLAVES := ["grupo", "inventario", "cofres_abiertos", "prologo_visto", "lugar", "pos_mapa", "pos_mapa_ok",
	"pos_zona", "pos_zona_ok", "pos_zona_lugar", "lore_visto", "incienso", "escena_guardada",
	"mazmorras", "combates_ganados", "decisiones", "pos_isla", "pos_isla_ok",
	"hitos", "pos_3d", "pos_3d_ok", "pos_3d_lugar", "grupo_activo",
	"investigaciones", "gremio", "encuentros_azar", "taberna", "buscador",
	"grupo_miembros", "firmamento"]   # firmamento: Orbes Cristalinos y nodos (firmamento/orbes.gd, V12; solo si se usó). grupo_miembros: la reserva (grupo.gd, V12; solo si hay alguien en ella). investigaciones: investigacion.gd (fase 2); gremio: gremio.gd, encuentros_azar: los élites , taberna: ciudades/taberna_juegos.gd y buscador: buscador.gd (V11). Las
	# partidas antiguas no las traen
const MAPA := "res://mapa.tscn"


# Archivo de la partida: el de la versión experimental si la exploración 3D está activa. Las pruebas pueden pedir
# uno propio con Engine «archivo_partida_prueba» (siempre en user:// y nunca el de una partida de verdad).
# Opción de desarrollo (solo en la versión experimental): «Probar la misión desde el principio» en la pantalla de
# carga (carga.gd) juega en otra ranura, GUARDADO_EXP_PRUEBA, y deja intacta la partida experimental de siempre. Dura
# lo que dure la sesión (Engine «ranura_prueba», que no se guarda).
const GUARDADO_EXP_PRUEBA := "user://partida_exp_prueba.save"


static func archivo() -> String:
	if Engine.has_meta("archivo_partida_prueba"):
		var a: String = Engine.get_meta("archivo_partida_prueba")
		if a.begins_with("user://") and a != GUARDADO and a != GUARDADO_EXP:
			return a
	if not load("res://modo3d.gd").activo():
		return GUARDADO
	return GUARDADO_EXP_PRUEBA if Engine.get_meta("ranura_prueba", false) else GUARDADO_EXP


# Empieza la ranura de prueba desde cero (opción de desarrollo): borra solo los archivos de esa ranura.
static func empezar_ranura_prueba() -> void:
	Engine.set_meta("ranura_prueba", true)
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(GUARDADO_EXP_PRUEBA + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(GUARDADO_EXP_PRUEBA + extra))


# ================================================================= ritmo

static func nivel_grupo() -> int:                 # el de los que están ahora en el grupo (grupo.gd, activos)
	var gr = load("res://grupo.gd")
	var total := 0
	var activos: Array = gr.activos()
	for n in activos:
		total += int(gr.datos()[n]["nivel"])
	return maxi(1, roundi(float(total) / maxi(1, activos.size())))


static func nivel_zona(zona: String) -> int:
	return NIVEL_ZONA.get(zona, 1)


# «Zona limpia»: el grupo va 5 niveles o más por encima. Los enemigos débiles huyen solos.
static func zona_limpia(zona: String) -> bool:
	return nivel_grupo() >= nivel_zona(zona) + DIF_LIMPIA


# Probabilidad de encuentro en este paso: nada en los pasos seguros, luego sube despacio.
static func prob_encuentro(base: float, pasos: int, pasos_min: int, zona: String) -> float:
	if pasos < pasos_min or incienso_activo():
		return 0.0
	var p := base * clampf(float(pasos - pasos_min) / PASOS_SUBIDA, 0.2, 1.0)
	if zona_limpia(zona):
		p *= PROB_LIMPIA
	return p


# Experiencia: hasta el doble si el héroe va por debajo de la zona, muy poca si va 5 o más por
# encima, y los jefes dan como unos 10 combates.
static func mult_exp(zona: String, tipo_combate: String, nivel_heroe: int) -> float:
	var m := MULT_JEFE if tipo_combate in ["jefe", "superjefe"] else 1.0
	var nz := nivel_zona(zona)
	if nivel_heroe < nz:
		m *= 1.0 + minf(1.0, (nz - nivel_heroe) * 0.25)
	elif nivel_heroe >= nz + DIF_LIMPIA:
		m *= EXP_POR_ENCIMA
	return m


# ---------------------------------------------------------------- Incienso de Ceniza

static func usar_incienso() -> void:
	Engine.set_meta("incienso", PASOS_INCIENSO)


static func incienso_activo() -> bool:
	return int(Engine.get_meta("incienso", 0)) > 0


# Lo llaman el mapa y las zonas en cada paso. Devuelve true el paso en que se acaba.
static func paso_incienso() -> bool:
	var n := int(Engine.get_meta("incienso", 0))
	if n <= 0:
		return false
	Engine.set_meta("incienso", n - 1)
	return n == 1


# ================================================================= lore

static func detalles_de(lugar: int) -> Array:
	return DETALLES.get(lugar, [])


static func visto(id: String) -> bool:
	return Engine.get_meta("lore_visto", {}).has(id)


# Apunta un detalle. Devuelve el acto completado con él (o {} si no completa ninguno).
static func ver_detalle(id: String) -> Dictionary:
	var v: Dictionary = Engine.get_meta("lore_visto", {})
	if v.has(id):
		return {}
	v[id] = true
	Engine.set_meta("lore_visto", v)
	for a in ACTOS:
		var ids := _ids_acto(a)
		if id in ids and ids.all(func(x): return v.has(x)):
			return a
	return {}


static func acto_completo(a: Dictionary) -> bool:
	return _ids_acto(a).all(func(x): return visto(x))


static func _ids_acto(a: Dictionary) -> Array:
	var ids: Array = []
	for l in a["lugares"]:
		for d in detalles_de(l):
			ids.append(d["id"])
	return ids


# ---------------------------------------------------------------- notas de las ciudades (T-089)
# Las ciudades hechas a mano tienen notas que se leen al examinarlas (un bando, un letrero, un libro...). El Diario las
# enseña aparte, en «Notas»: no son detalles, no cuentan para las páginas de los actos y no hay ninguna que completar.
# Se apuntan en «lore_visto» con su id («nota_…»): ninguna clave nueva en la partida.
# También los lugares con notas para encontrar (narrativa, 09/11): la Garganta (2) y Pastos Verdes (10, LUGAR_PASTOS).
const CIUDADES := {0: "res://ciudades/oakhaven.gd", 2: "res://dialogos/notas/garganta.gd",
	10: "res://dialogos/notas/pastos_verdes.gd"}   # índice del lugar (mapa.gd) → módulo con sus NOTAS


static func notas_de(lugar: int) -> Array:
	return load(CIUDADES[lugar]).NOTAS if CIUDADES.has(lugar) else []


# Apunta una nota. Devuelve true si es nueva. Nunca completa un acto.
static func ver_nota(id: String) -> bool:
	var es_nota := false
	for l in CIUDADES:
		for n in notas_de(l):
			es_nota = es_nota or n["id"] == id
	var v: Dictionary = Engine.get_meta("lore_visto", {})
	if not es_nota or v.has(id):
		return false
	v[id] = true
	Engine.set_meta("lore_visto", v)
	return true


# ================================================================= mazmorras y combates fijos

# Estado de una mazmorra (palancas, puertas...): Engine.get_meta("mazmorras")[nombre][clave].
static func estado(mazmorra: String, clave: String) -> bool:
	return Engine.get_meta("mazmorras", {}).get(mazmorra, {}).get(clave, false)


static func poner_estado(mazmorra: String, clave: String, valor := true) -> void:
	var m: Dictionary = Engine.get_meta("mazmorras", {})
	if not m.has(mazmorra):
		m[mazmorra] = {}
	m[mazmorra][clave] = valor
	Engine.set_meta("mazmorras", m)


# Combates fijos (jefes, nidos...) ya ganados: no se repiten.
static func ganado(id: String) -> bool:
	return Engine.get_meta("combates_ganados", {}).has(id)


# ================================================================= hitos de la historia

# Hitos de la historia (biblia v3: «hitos.<id>»). Se guardan en la partida; los que faltan valen false.
# V12 (12/11), PROTOTIPO APAGADO (interruptor «naira_v12», grupo.gd): los de la misión de incorporación de Naira, «La
# única noche que cabe en un día» (docs/v12/NAIRA.md §4; zonas3d/mar_cristal/naira_mision.gd), en orden. Sin el
# interruptor nadie los pone. nr_eclipse_perfecto es opcional (nadie golpeó a Naira mientras preparaba).
const HITOS_NAIRA := ["nr_rumor", "nr_observatorio", "nr_plomada_1", "nr_plomada_2", "nr_plomada_3", "nr_plomadas",
	"nr_medicion", "nr_eclipse", "nr_eclipse_perfecto", "nr_catalogo", "nr_union"]
# V12 (12/11), rincones opcionales del Mar de Cristal (zonas3d/mar_cristal/rincones.gd), fuera de «La caravana perdida»:
# mc_rin_hito, la bolsa del hito del cobijo (dos Pociones, una sola vez). Sin él (partidas antiguas), está por descubrir.
const HITOS_MC_RINCONES := ["mc_rin_hito"]


static func hito(id: String) -> bool:
	return Engine.get_meta("hitos", {}).get(id, false)


static func poner_hito(id: String) -> void:
	var h: Dictionary = Engine.get_meta("hitos", {})
	h[id] = true
	Engine.set_meta("hitos", h)


# ================================================================= guardado
# Protecciones (TASKS.md, T-076 y T-077):
#   - Solo se guarda encima de una partida si en esta sesión se cargó o no había ninguna (Engine «partida_lista», que
#     no se guarda). Una escena abierta directamente (F6 en el editor) tiene solo parte de los datos y algunos por
#     defecto (grupo.gd crea el grupo a nivel 1): guardar ahí pisaría la partida completa con datos a medias.
#   - La partida se escribe primero en «<archivo>.tmp», se comprueba leyéndola y solo entonces sustituye a la anterior.
#     La anterior, si se podía leer, queda en «<archivo>.bak».
#   - Al cargar, si la partida no se puede leer, se usa «.tmp» (escrito y comprobado, pero sin llegar a sustituirla)
#     o «.bak». La que no se podía leer se aparta en «<archivo>.danada» (y una copia «.bak» dañada, en
#     «<archivo>.bak.danada»): no se borra nada que pudiera recuperarse a mano.
#   - Cualquier fallo se le dice al jugador (Recursos.avisar): no se pudo guardar, se recuperó una copia o no se pudo
#     leer nada y empieza una partida nueva.
#   - Las pruebas no guardan, salvo en su propio archivo (archivo()).
# Lo comprobado (pruebas/prueba_partida.gd, en el PC y con datos aislados) reduce el riesgo de perder la partida; no es
# una garantía: un fallo del disco o del sistema en el peor momento puede seguir costando el último guardado.


# Le dice al jugador algo que tiene que saber de su partida (abajo, encima de todo, unos segundos).
static func _avisar(texto: String) -> void:
	Engine.set_meta("ultimo_aviso_partida", texto)   # no se guarda; lo leen las pruebas
	var arbol := Engine.get_main_loop() as SceneTree
	var r = arbol.root.get_node_or_null("Recursos") if arbol != null else null
	if r != null and r.has_method("avisar"):
		r.avisar(texto)
	else:
		push_warning(texto)

static func hay_partida() -> bool:
	var a := archivo()
	return FileAccess.file_exists(a) or FileAccess.file_exists(a + ".bak") or FileAccess.file_exists(a + ".tmp")


static func _en_prueba() -> bool:
	return "--script" in OS.get_cmdline_args() or not OS.get_cmdline_user_args().is_empty()


# Lee una partida: el diccionario, o null si no existe o no se puede leer.
static func leer(ruta: String):
	if not FileAccess.file_exists(ruta):
		return null
	var d = str_to_var(FileAccess.get_file_as_string(ruta))
	return d if d is Dictionary else null


# Escribe la partida en «.tmp», la comprueba y sustituye la anterior. Devuelve false si no se pudo: en las pruebas, la
# partida anterior queda intacta y el jugador recibe un aviso.
const AVISO_NO_GUARDA := "No se pudo guardar la partida. Se volverá a intentar en el próximo guardado."


# Solo para las pruebas (prueba_guardado_fallos): simulan fallos del disco. En el juego valen 0 y false.
static var fallos_renombrar := 0                  # cuántos de los próximos renombrados fallan
static var falla_copia := false                   # la copia «.bak» falla
static var falla_escritura := false               # no se puede abrir el «.tmp»


# Garantías (10/11): la partida principal solo se quita cuando su copia «.bak» está escrita y se lee bien, y si el
# guardado falla después de quitarla, se restaura desde esa copia. Un «.tmp» bueno que quedó de un intento fallido (la
# copia más reciente si falta la principal) se guarda en «.bak» antes de reescribir el «.tmp».
static func escribir(d: Dictionary, ruta: String) -> bool:
	var texto := var_to_str(d)
	var tmp := ruta + ".tmp"
	var real := ProjectSettings.globalize_path(ruta)
	var tmp_real := ProjectSettings.globalize_path(tmp)
	if leer(ruta) == null and leer(tmp) != null:
		DirAccess.copy_absolute(tmp_real, real + ".bak")
	var f: FileAccess = null if falla_escritura else FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar la partida (%s)" % ("simulado" if falla_escritura else error_string(FileAccess.get_open_error())))
		_avisar(AVISO_NO_GUARDA)
		return false
	f.store_string(texto)
	f.close()
	if FileAccess.get_file_as_string(tmp) != texto:
		push_warning("No se pudo guardar la partida: lo escrito no coincide")
		DirAccess.remove_absolute(tmp_real)
		_avisar(AVISO_NO_GUARDA)
		return false
	var habia_principal := leer(ruta) != null
	if habia_principal:
		var e: Error = ERR_CANT_CREATE if falla_copia else DirAccess.copy_absolute(real, real + ".bak")
		if e != OK or leer(ruta + ".bak") == null:  # sin copia comprobada no se toca la principal
			push_warning("No se pudo guardar la partida: no se pudo hacer la copia de seguridad")
			_avisar(AVISO_NO_GUARDA)
			return false
	var err := _renombrar(tmp_real, real)
	if err != OK and FileAccess.file_exists(ruta): # (en algunos sistemas no se puede renombrar encima de un archivo)
		if not habia_principal and not FileAccess.file_exists(ruta + ".danada"):
			DirAccess.copy_absolute(real, real + ".danada")   # una principal que no se lee se aparta, no se pierde
		DirAccess.remove_absolute(real)
		err = _renombrar(tmp_real, real)
		if err != OK and habia_principal:          # no se borra nada: vuelve la principal desde su copia comprobada
			DirAccess.copy_absolute(real + ".bak", real)
	if err != OK:
		push_warning("No se pudo guardar la partida (%s)" % error_string(err))
		_avisar(AVISO_NO_GUARDA)
		return false
	return true


static func _renombrar(de: String, a: String) -> Error:
	if fallos_renombrar > 0:
		fallos_renombrar -= 1
		return ERR_CANT_CREATE
	return DirAccess.rename_absolute(de, a)


# Lo que se guarda: las CLAVES que haya en Engine. Lo usan guardar() y las pruebas (que no escriben archivos).
static func volcar(escena := "") -> Dictionary:
	if escena != "":
		Engine.set_meta("escena_guardada", escena)
	var d := {}
	for k in CLAVES:
		if Engine.has_meta(k):
			d[k] = Engine.get_meta(k)
	d["formato"] = FORMATO
	return d


# Versión del formato de la partida (10/11): se escribe al guardar para que una migración futura sepa de dónde parte.
# Las partidas de antes no la llevan: son el formato 1, y cargan igual (restaurar() no la necesita).
const FORMATO := 3                 # 3 (V12, 12/11): puede traer «grupo_miembros» (la reserva); sin ella carga igual


static func formato_de(d: Dictionary) -> int:
	return int(d.get("formato", 1))


# Guarda la partida. "escena" = dónde se vuelve al abrir el juego (el mapa o la zona). Devuelve si se guardó.
static func guardar(escena := "") -> bool:
	if _en_prueba() and not Engine.has_meta("archivo_partida_prueba"):
		return false                               # las pruebas no tocan la partida de verdad
	if not Engine.get_meta("partida_lista", false) and hay_partida():
		push_warning("Esta sesión no cargó la partida: no se guarda para no pisarla con datos a medias")
		return false
	return escribir(volcar(escena), archivo())


# Pone en Engine una partida ya leída y devuelve la escena a la que volver. Si esa escena no existe en esta
# versión (por ejemplo, una región 3D en una versión sin exploración 3D), se vuelve al mapa sin error.
static func restaurar(d: Dictionary) -> String:
	Engine.set_meta("partida_lista", true)
	for k in CLAVES:                               # lo de la sesión que la partida no trae no se mezcla con ella
		if not d.has(k) and Engine.has_meta(k):
			Engine.remove_meta(k)
	for k in d:
		Engine.set_meta(k, d[k])
	# Partidas experimentales de antes de «grupo_activo» que ya habían empezado la misión de Pastos Verdes: el grupo
	# sale de sus hitos (grupo.gd). Las demás, sin la clave, siguen con todo el grupo, como antes.
	if not d.has("grupo_activo") and load("res://modo3d.gd").activo() and hito("pv_02"):
		Engine.set_meta("grupo_activo", load("res://grupo.gd").segun_mision())
	var escena: String = d.get("escena_guardada", MAPA)
	if not ResourceLoader.exists(escena) or (escena.begins_with("res://zonas3d/") and not load("res://modo3d.gd").activo()):
		escena = MAPA
	# Escenas que ya tienen una versión nueva:
	# - Oakhaven: una partida guardada en la ciudad generada (zona.tscn con el lugar 0) abre la ciudad hecha a mano
	#   (T-089), por su entrada, porque el trazado es otro;
	# - la Garganta: si su versión 3D está en uso (modo3d.gd), una partida guardada en la 2D sigue en la 3D, en el sitio
	#   equivalente (T-095; escena_equivalente deja la posición en Engine).
	var lugar = d.get("lugar", {})                 # en la partida, «lugar» es un diccionario con su «indice»
	var indice_lugar: int = int(lugar.get("indice", -1)) if lugar is Dictionary else -1
	if escena == "res://zona.tscn" and indice_lugar == 0 and ResourceLoader.exists("res://ciudad_oakhaven.tscn"):
		Engine.set_meta("pos_zona_ok", false)
		# V12: con Oakhaven 3D en uso (por defecto desde el 12/11), esa versión, por la Puerta del Sur
		var oak3d: String = load("res://modo3d.gd").escena_equivalente("res://ciudad_oakhaven.tscn")
		return oak3d if oak3d != "" else "res://ciudad_oakhaven.tscn"
	# V12, Gran Bosque Verde: la zona generada de un lugar con versión 3D (zona.tscn y el lugar 1) también (modo3d.gd)
	var en_3d: String = load("res://modo3d.gd").escena_equivalente(escena, indice_lugar)
	if en_3d != "":
		return en_3d
	if escena != MAPA:
		Engine.set_meta("pos_zona_ok", true)        # vuelve al mismo sitio de la zona o la mazmorra
	return escena


# Carga la partida guardada. Devuelve la escena donde estabas ("" si no hay partida). Después ya se puede guardar.
static func cargar() -> String:
	var ruta := archivo()
	var d = leer(ruta)
	if d == null:
		var copia = leer(ruta + ".tmp")
		if copia == null:
			copia = leer(ruta + ".bak")
		var danada := false
		for extra in ["", ".bak"]:                 # no se podían leer: se apartan, no se borran
			if FileAccess.file_exists(ruta + extra) and leer(ruta + extra) == null:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(ruta + extra), ProjectSettings.globalize_path(ruta + extra + ".danada"))
				push_warning("La partida %s no se pudo leer: se aparta en %s" % [ruta + extra, ruta + extra + ".danada"])
				danada = true
		if copia != null:
			_avisar("La partida guardada estaba dañada. Se ha recuperado la última copia que se podía leer.")
			d = copia
		elif danada:
			_avisar("No se pudo leer la partida guardada. Se ha apartado una copia y empieza una partida nueva.")
	Engine.set_meta("partida_lista", true)
	if d == null:                                  # partida nueva
		for k in CLAVES:
			if Engine.has_meta(k):
				Engine.remove_meta(k)
		if load("res://modo3d.gd").activo():        # la versión experimental empieza con la misión: Kael, solo
			load("res://grupo.gd").empezar_solo()
		return ""
	return restaurar(d)
