extends Control
# V12 (14/11/2026): BANCO DE PRUEBAS de la APK de Auditoría (y del editor). Nunca sale en las versiones normales.
#
# Para probar en el teléfono, sin comandos, lo de la noche del 13 al 14/11: Érebo original o con el orbe experimental,
# Agua original o mejorada, Nix (la antigua o la del FBX), la capa original o articulada de Garon, los protagonistas
# originales, v2 o v3, el Custodio de Porcelana (meshy_e01, que solo sale en combates internos) y Oakhaven (vecinos,
# Puerta del Sur, cerradura del arcón y la misión propuesta del cantero).
#
# AISLAMIENTO (lo comprueba pruebas/prueba_banco_pruebas.gd):
#   - Mientras dura, la partida va a su propio archivo (Engine «archivo_partida_prueba» = ARCHIVO, progreso.gd): la de
#     siempre no se lee ni se escribe.
#   - Cada vez que se entra en esta pantalla (también al volver de un combate), la partida del banco se rehace desde
#     BASE: lo ganado en un combate de prueba (experiencia, monedas, botín, contratos) desaparece. No hay recompensas
#     permanentes ni desbloqueos.
#   - «Salir del banco» quita todo lo de la sesión (la partida en memoria, los interruptores de sesión y el archivo de
#     prueba) y vuelve a la pantalla de carga: al tocar, se carga la partida de siempre, intacta.
#   - Los selectores de variantes escriben en user://ajustes.cfg, como los de Ajustes: son preferencias de Auditoría,
#     no partida.
#   - V12 (15/11, encargo del usuario): la CALIDAD es de la sesión. El regulador adaptable, la detección y Ajustes >
#     Calidad trabajan sobre una copia en memoria de [calidad] (prototipos/calidad_auto.gd, aislada()): ni ajustes.cfg
#     ni calidad.log cambian. CAL, el selector «Calidad 3D» y los bancos de medida de vista3d (metas de METAS_CALIDAD) se
#     quitan al salir, y las medidas de RND/PRUEBA van a user://banco_pruebas_*.csv, que también se borran al salir.

const ARCHIVO := "user://banco_pruebas.save"
const META := "banco_pruebas"
const ESCENA := "res://banco_pruebas.tscn"
const CARGA := "res://carga.tscn"
const NIVEL_COMBATE := 12                         # con todas las magias (grupo.gd, NIVEL_MAGIA 1, 5 y 10)
# Interruptores que el banco enciende solo para su sesión (Engine): se quitan al salir.
const METAS_SESION := ["meshy_e01", "banco_caso", "nix_v12", "oakhaven_propuestas_v12",
	"oak_franja", "oak_franja_t", "comentarios_dichos",   # (y la hora de Oakhaven y los comentarios ya dichos: de la sesión)
	"banco_grupo4",                                   # (15/11: el permiso de cuatro activos, grupo.gd max_activos)
	"calidad_sesion", "banco_proto",                  # (15/11: [calidad] de la sesión rehecha en cada caso; un banco de medida a medias no sigue)
	"barrio_v12", "barrio_interior", "barrio_reloj",  # (16/11: el barrio experimental: activado, su interior tras CAL y su reloj)
	"arboleda_flor",                                 # (16/11: «Llevar una flor de abajo», tramo de la Arboleda)
	"ciudad_v12",                                    # (16/11: la ciudad completa de Oakhaven, maqueta: activada)
	"naira_v12",                                     # (18/11: Naira, solo en el caso de las derrotas de Naira y Nix)
	"velaria_v12",                                   # (19/11: Velaria, la polilla del bestiario, solo en su caso)
	"cencerrante_v12"]                               # (19/11: el Cencerrante, la campana del bestiario, solo en su caso)
# Calidad elegida en la sesión (CAL, el selector «Calidad 3D», los bancos A/B de vista3d): sigue entre los casos de la
# sesión y se quita SOLO al salir.
const METAS_CALIDAD := ["calidad_proto", "calidad_extra", "muestra_precalentar",
	"sunken_quilla_v12"]   # (16/11: la Quilla horneada de Sunken, EXPERIMENTAL; aquí y no en METAS_SESION, que se borran en cada caso)
const Estilo := preload("res://estilo.gd")

# La partida de partida del banco: el grupo recién llegado a Oakhaven (la del Redmi del 11/11, cmp_oakhaven).
const BASE := {
	"escena_guardada": "res://zonas3d/oakhaven_3d.tscn",
	"formato": 2,
	"grupo": {
		"Garon": {"atributos": {"defensa": 12, "espiritu": 2, "fuerza": 16, "magia": 2, "velocidad": 16, "vitalidad": 16},
			"exp": 0, "nivel": 2, "pm": -1, "puntos": 3, "pv": -1},
		"Kael": {"atributos": {"defensa": 6, "espiritu": 4, "fuerza": 18, "magia": 4, "velocidad": 22, "vitalidad": 10},
			"exp": 18, "nivel": 2, "pm": -1, "puntos": 3, "pv": -1},
		"Lya": {"atributos": {"defensa": 4, "espiritu": 12, "fuerza": 8, "magia": 14, "velocidad": 26, "vitalidad": 5},
			"exp": 18, "nivel": 2, "pm": -1, "puntos": 3, "pv": -1}},
	"grupo_activo": ["Kael", "Lya", "Garon"],
	"hitos": {"pv_02": true, "pv_03": true, "pv_05": true},
	"inventario": {
		"equipables": ["frostfang", "cetro_loto", "ropa_viaje", "tunica_lino", "botas_cuero", "cota_malla", "hoja_infernal"],
		"equipo": {"Garon": {"arma": "hoja_infernal", "cuerpo": "cota_malla"},
			"Kael": {"arma": "frostfang", "cuerpo": "ropa_viaje", "pies": "botas_cuero"},
			"Lya": {"arma": "cetro_loto", "cuerpo": "tunica_lino"}},
		"objetos": {"Poción": 5, "Éter": 3},
		"oro": 168},
	"lugar": {"indice": 0, "nombre": "Oakhaven", "texto": "", "tipo": "ciudad", "zona": "llanura"},
	"pos_3d": Vector3(0, 0, 0), "pos_3d_lugar": 99, "pos_3d_ok": true,
	"pos_mapa": Vector2(646.25146, 459.43585), "pos_mapa_ok": true, "pos_zona_ok": true,
	"prologo_visto": true, "buscador": {"nivel": 1}, "incienso": 0}

# Combates de prueba: grupo de enemigos (combate.gd, GRUPOS), quién combate, vida de los enemigos ×, Armonía llena.
const COMBATES := {
	"erebo": {"titulo": "Érebo: Lya con la Armonía llena", "grupo": 1, "activos": ["Kael", "Lya", "Garon"],
		"vida": 6.0, "armonia": true,
		"nota": "La Armonía empieza llena: Lya puede invocar en su primer turno. Compara «Érebo» Original y Experimental."},
	"agua": {"titulo": "Magia Agua: Lya contra enemigos resistentes", "grupo": 1, "activos": ["Kael", "Lya", "Garon"],
		"vida": 6.0, "armonia": false, "nota": "Agua, Torrente y Maremoto. Compara «Agua» en Original y en Mejorada."},
	"garon": {"titulo": "Garon: ataques y defensa con su capa", "grupo": 0, "activos": ["Kael", "Lya", "Garon"],
		"vida": 4.0, "armonia": false, "nota": "Ataca y defiende con Garon. Compara la capa Original y la Articulada."},
	"nix": {"titulo": "Nix en combate (canalizar)", "grupo": 1, "activos": ["Kael", "Garon", "Nix"],
		"vida": 6.0, "armonia": false, "nota": "Nix entra en el grupo solo aquí. Elige arriba «Nix» Antigua o Desde el FBX."},
	# 15/11 (pedido del usuario): el equilibrio se juzga con la vida NORMAL; la rotación entera, en un caso aparte ×8
	"custodio": {"titulo": "Custodio de Porcelana (equilibrio normal)", "grupo": 28, "activos": ["Kael", "Lya", "Garon"],
		"vida": 1.0, "armonia": false, "custodio": true,
		"nota": "Vida de siempre: para juzgar el equilibrio. Cifras PROPUESTAS, sin aprobar."},
	"custodio_rotacion": {"titulo": "Custodio: ver la rotación (vida ×8)", "grupo": 28, "activos": ["Kael", "Lya", "Garon"],
		"vida": 8.0, "armonia": false, "custodio": true,
		"nota": "Solo para VER Prensa, Avance y Sello seguidos (el Sello llega a los ~7 turnos suyos: 2-3 min; con un menú abierto no actúa). Vida ×8: NO sirve para juzgar el equilibrio."},
	# 15/11: el combate con CUATRO, solo aquí. El juego sigue con tres en el grupo activo (grupo.gd, MAX_ACTIVOS) y nadie
	# ha decidido desde cuándo lucha Nix: docs/v12/NIX_GRUPO_CUATRO.md.
	"grupo4": {"titulo": "Grupo de cuatro: Kael, Lya, Garon y Nix (prueba)", "grupo": 1,
		"activos": ["Kael", "Lya", "Garon", "Nix"], "vida": 6.0, "armonia": false,
		"nota": "SOLO en el banco: el juego sigue con tres. Para ver sitios, barras, menús y turnos con cuatro."},
	# 18/11 (Redmi, REDMI_18_11.md): para VER las derrotas de los héroes en el teléfono. Los héroes empiezan con 1 PV y los
	# enemigos con su barra de turno casi llena: los tres slimes golpean antes de que se abra ningún menú y cada golpe
	# derriba a uno (morir(), su animación de derrota). Frostfang no cuenta: Kael no llega a atacar (D-017 intacta).
	# Al caer todos, la derrota de siempre («Derrota...») y se vuelve aquí con la vida llena (en la partida del banco).
	# «casi_sin_vida» solo lo lee preparar_combate (abajo); las fórmulas y reglas del combate no cambian.
	"derrotas": {"titulo": "Derrotas: los héroes empiezan casi sin vida", "grupo": 1, "activos": ["Kael", "Lya", "Garon"],
		"vida": 1.0, "armonia": false, "casi_sin_vida": true,
		"nota": "No toques nada: los slimes atacan primero y cada golpe derriba a un héroe. Compara arriba «Protagonistas» Originales, v2 y v3."},
	"derrotas_reclutas": {"titulo": "Derrotas de Naira y Nix (casi sin vida)", "grupo": 1,
		"activos": ["Kael", "Naira", "Nix"], "vida": 1.0, "armonia": false, "casi_sin_vida": true,
		"nota": "Naira y Nix (prototipos, solo aquí) con Kael, a 1 PV: se ven caer los tres. Sin tocar nada."},
	# 19/11: Velaria (bestiario T-097, combate_velaria.gd), APAGADA fuera de aquí: su interruptor «velaria_v12» solo en
	# este caso. Modelo de Meshy con licencia sin confirmar: solo APK de prueba privadas (D-075).
	"velaria": {"titulo": "Velaria: destello de velo y corte de ala (prueba)", "grupo": 30,
		"activos": ["Kael", "Lya", "Garon"], "vida": 1.0, "armonia": false, "velaria": true,
		"nota": "Avisa el destello un turno antes (alas replegadas, «⚠»): Defender lo deja a la mitad. Cifras PROPUESTAS."},
	# 19/11: el Cencerrante (bestiario T-097, combate_cencerrante.gd), APAGADO fuera de aquí: su interruptor
	# «cencerrante_v12» solo en este caso. Con un Zarzalín (GRUPOS[31]): al caer el Zarzalín se queda solo.
	"cencerrante": {"titulo": "Cencerrante: toque de alarma y campanada (prueba)", "grupo": 31,
		"activos": ["Kael", "Lya", "Garon"], "vida": 1.0, "armonia": false, "cencerrante": true,
		"nota": "Su toque (una vez) refuerza el siguiente golpe del Zarzalín («▲»); solo, prepara su campanada («⚠»). Cifras PROPUESTAS."},
}
const EXPLORAR := {
	"oakhaven": {"titulo": "Oakhaven con Kael, Lya y Garon", "activos": ["Kael", "Lya", "Garon"],
		"nota": "Puerta del Sur y vecinos, el arcón del Concejo (casilla 50,5; 22) y, si está activa, la misión del cantero."},
	"oakhaven_nix": {"titulo": "Oakhaven con Nix en el grupo", "activos": ["Kael", "Garon", "Nix"],
		"nota": "Nix andando y girando con el grupo. Para canalizar, el combate de Nix."},
	# 15/11: la siguiente ubicación 3D (EN PRUEBAS, apagada fuera de aquí y de Ajustes): se entra por el muelle, sin
	# tener que llegar a Sunken City en el mapa. Al salir al mapa, «Volver al banco de pruebas» en Ajustes.
	"sunken": {"titulo": "Sunken City 3D (en pruebas)", "activos": ["Kael", "Lya", "Garon"],
		"escena": "res://zonas3d/sunken_3d.tscn",
		"nota": "Popa Rota → Cubierta Mayor: Ulla y Brea, «El sello de la capitana», la costilla sin farol y la forja."},
	# 15/11: MUESTRA GRÁFICA EXPERIMENTAL (zonas3d/muestra_calle/, docs/v12/MUESTRA_CALLE_OAKHAVEN.md): una calle de
	# Oakhaven con luz horneada, para juzgar el salto de calidad antes de renovar nada. SOLO aquí: ninguna otra escena la
	# enlaza y Oakhaven 3D no cambia. Solo Kael (sin vecinos ni misiones); «Volver al banco», arriba a la izquierda.
	"muestra_calle": {"titulo": "Muestra gráfica: una calle de Oakhaven (en pruebas)", "activos": ["Kael"],
		"escena": "res://zonas3d/muestra_calle/muestra_calle.tscn",
		"nota": "Kael andando por una calle hecha de nuevo (tarde dorada horneada). CAL cambia el perfil; RND mide."},
	# 16/11: BARRIO EXPERIMENTAL de Oakhaven (zonas3d/barrio/, docs/v12/BARRIO_OAKHAVEN.md): la calle ampliada a un
	# bucle jugable. SOLO aquí (se activa a sí mismo con la meta de sesión «barrio_v12»); fase 0: bloques provisionales,
	# sin interiores, vecinos ni misión todavía.
	"barrio": {"titulo": "Barrio de Oakhaven (en pruebas)", "activos": ["Kael", "Lya", "Garon"],
		"escena": "res://zonas3d/barrio/barrio.tscn",
		"nota": "Bloques provisionales: caravanas, calle comercial, plaza, talleres, casas y atajo. Horno, taller y vivienda visitables; la misión «Antes de que se enfríe»."},
	# 16/11: ARBOLEDA MÍTICA, tramo «La escalera de la Hospedería» (zonas3d/arboleda_tramo/, docs/v12/ARBOLEDA_HOSPEDERIA.md):
	# la isla 2D pintada con la escalera unida a la terraza, la Hospedería del Peregrino y «Una flor para Lumi». SOLO aquí.
	"arboleda": {"titulo": "Arboleda Mítica: la escalera de la Hospedería (en pruebas)", "activos": ["Kael", "Lya", "Garon"],
		"escena": "res://zonas3d/arboleda_tramo/arboleda_tramo.tscn",
		"nota": "Escalera → terraza → Hospedería (dormir 20, Yedra). Con «Llevar una flor de abajo», la flor para Lumi."},
	# 16/11: CIUDAD COMPLETA de Oakhaven, MAQUETA (zonas3d/ciudad/, docs/v12/CIUDAD_OAKHAVEN.md): los 8 sectores en bloques,
	# cargados por cercanía. SOLO aquí (se activa a sí misma con la meta de sesión «ciudad_v12»); sin interiores ni vecinos.
	"ciudad": {"titulo": "Ciudad de Oakhaven (maqueta, en pruebas)", "activos": ["Kael", "Lya", "Garon"],
		"escena": "res://zonas3d/ciudad/ciudad.tscn",
		"nota": "Bloques provisionales de los 8 sectores, de la Puerta del Sur al Árbol Milenario. Sin interiores ni vecinos."},
}

var cuerpo: VBoxContainer
var marco: ScrollContainer
var saliendo := false
var escena_base := ""                             # adonde lleva la partida del banco (Oakhaven 3D, por su entrada)


# ¿Puede existir el banco en esta versión? Solo en la APK de Auditoría o en el editor.
static func permitido() -> bool:
	return OS.has_feature("auditoria") or OS.has_feature("editor")   # (sin cargar prototipos/: la versión normal no lo lleva)


static func en_banco() -> bool:
	return permitido() and bool(Engine.get_meta(META, false))


# Entra en el banco: la partida pasa al archivo de prueba (la de siempre ya no se toca) y se rehace desde BASE.
static func preparar_partida() -> String:
	Engine.set_meta(META, true)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	var cantero = Engine.get_meta("oakhaven_propuestas_v12") if Engine.has_meta("oakhaven_propuestas_v12") else null   # (sigue)
	if Engine.has_meta("banco_proto"):             # (15/11) un banco de medida A/B cortado a medias deja el perfil y el
		for m in ["calidad_proto", "calidad_extra"]:   # cambio de su caso: se quitan (vuelve el regulador normal)
			if Engine.has_meta(m):
				Engine.remove_meta(m)
	for k in METAS_SESION:                         # cada caso empieza sin los interruptores del anterior
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if cantero != null:
		Engine.set_meta("oakhaven_propuestas_v12", cantero)
	return load("res://progreso.gd").restaurar(BASE.duplicate(true))


# Fija el grupo de un caso. Nix solo existe con su interruptor: el banco lo enciende para su sesión. Con más de
# MAX_ACTIVOS (el caso «Grupo de cuatro»), el permiso de cuatro activos, también solo de la sesión (grupo.gd).
static func poner_grupo(activos: Array, nivel := 0) -> void:
	var G = load("res://grupo.gd")
	if "Nix" in activos:
		Engine.set_meta("nix_v12", true)
		G.unir("Nix")
	if "Naira" in activos:                         # (18/11) como Nix: su interruptor, solo de la sesión del banco
		Engine.set_meta("naira_v12", true)
		G.unir("Naira")
	if activos.size() > G.MAX_ACTIVOS:
		Engine.set_meta(G.META_GRUPO4, true)
	elif Engine.has_meta(G.META_GRUPO4):
		Engine.remove_meta(G.META_GRUPO4)
	G._poner(activos, activos)
	if nivel > 0:
		for n in G.datos():
			G.datos()[n]["nivel"] = nivel
			G.datos()[n]["pv"] = -1
			G.datos()[n]["pm"] = -1


# Gancho de combate.gd (_ready, tras las entradas): vida de los enemigos y Armonía del caso. Fuera del banco, nada.
static func preparar_combate(c) -> void:
	if not en_banco():
		return
	var caso: Dictionary = COMBATES.get(str(Engine.get_meta("banco_caso", "")), {})
	if caso.is_empty():
		return
	var mult: float = float(caso.get("vida", 1.0))
	if mult != 1.0:
		for e in c.enemigos:
			e["hp_max"] = int(round(e["hp_max"] * mult))
			e["hp"] = e["hp_max"]
	if caso.get("armonia", false):
		c.armonia = 1.0
	if caso.get("casi_sin_vida", false):           # (18/11) el caso de las derrotas: 1 PV y los enemigos actúan primero
		for h in c.heroes:                         # (y los héroes casi sin velocidad: el Slime a veces se encoge un turno
			h["hp"] = 1                            # antes de su Rebote, y sin esto se abría el menú de un héroe; así
			h["atb"] = 0.0                         # caen todos sin tocar nada: su barra tardaría 100 s en llenarse)
			h["vel"] = 1.0
		for e in c.enemigos:
			e["atb"] = 99.0                        # (ATB_MAX = 100 en combate.gd: actúan en el primer instante)


# Sale del banco: quita la partida de la sesión, los interruptores que puso y el archivo de prueba. Lo siguiente que
# se cargue es la partida de siempre.
static func salir() -> void:
	var P = load("res://progreso.gd")
	for k in P.CLAVES + METAS_SESION + METAS_CALIDAD + [META, "archivo_partida_prueba", "partida_lista", "grupo_combate",
			"combate_fijo", "tipo_combate", "desde_mapa", "escena_retorno", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if ResourceLoader.has_cached("res://zonas3d/muestra_calle/muestra_calle.gd"):   # (15/11) sus cachés, fuera
		load("res://zonas3d/muestra_calle/muestra_calle.gd").soltar_caches()
	for r in ["res://zonas3d/barrio/barrio.gd", "res://zonas3d/barrio/interiores.gd", "res://zonas3d/barrio/barrio_vivo.gd"]:
		if ResourceLoader.has_cached(r):           # (16/11) las del barrio experimental, igual
			load(r).soltar_caches()
	var d := DirAccess.open("user://")             # (15/11) las medidas de RND y PRUEBA de la sesión (vista3d._ruta_medida)
	if d != null:
		for f in d.get_files():
			if f.begins_with("banco_pruebas_") and f.ends_with(".csv"):
				d.remove(f)
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _ready() -> void:
	if not permitido():
		Recursos.cambiar_escena(CARGA)
		return
	escena_base = preparar_partida()
	Recursos.marcar_partida_prueba()
	size = Vector2(1280, 720)
	var fondo := ColorRect.new()
	fondo.color = Estilo.SOMBRA
	fondo.size = size
	add_child(fondo)
	var panel := PanelContainer.new()
	panel.position = Vector2(60, 30)
	panel.custom_minimum_size = Vector2(1160, 660)
	panel.add_theme_stylebox_override("panel", Estilo.ventana(0.92))
	add_child(panel)
	var todo := VBoxContainer.new()
	todo.add_theme_constant_override("separation", 10)
	panel.add_child(todo)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 12)
	todo.add_child(arriba)
	var titulo := _texto("Banco de pruebas · Auditoría", 30, Estilo.ORO)
	titulo.add_theme_font_override("font", Estilo.cursiva())
	arriba.add_child(titulo)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(hueco)
	var b_salir := _boton("Salir del banco", 22, Vector2(230, 52), "salir")
	b_salir.pressed.connect(_salir)
	arriba.add_child(b_salir)
	todo.add_child(_texto("Partida aislada: tu partida de siempre no se lee ni se escribe, y aquí no se gana nada "
		+ "permanente (al volver, todo empieza de nuevo).", 17, Estilo.GRIS))
	marco = ScrollContainer.new()
	marco.custom_minimum_size = Vector2(1140, 560)
	marco.follow_focus = true
	todo.add_child(marco)
	cuerpo = VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 8)
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.add_child(cuerpo)
	_pintar()
	Entrada.enfocar(Entrada.primero(cuerpo) if Entrada.primero(cuerpo) != null else b_salir)


func _pintar() -> void:
	cuerpo.add_child(_texto("Variantes (se guardan en Ajustes de Auditoría)", 24, Estilo.ORO))
	var HV = load("res://personajes/heroes_v2/heroes_v2.gd")
	_selector("Protagonistas", "heroes", HV.version(),
		[["originales", "Originales"], ["v2", "v2"], ["v3", "v3"]], func(v): HV.elegir_version(v))
	var EO = load("res://erebo_orbe_v12.gd")
	_selector("Érebo", "erebo", EO.activo(), [[false, "Original"], [true, "Orbe experimental"]], func(v): EO.elegir(v))
	var EH = load("res://invocacion_erebo_hibrida.gd")   # V12, Érebo híbrida (15/11): la invocación (de siempre, vídeo o híbrida)
	_selector("Érebo: invocación", "erebo_cine", EH.valor_selector(), [["no", "De siempre"], ["abreviada", "Vídeo"],
		["hibrida", "Híbrida"], ["hibrida_breve", "Híbrida abreviada"]], func(v): EH.elegir_modo(v))
	var AGV = load("res://vfx/agua_v12.gd")
	_selector("Magia Agua", "agua", AGV.activo(), [[false, "Original"], [true, "Mejorada (v12)"]], func(v): AGV.elegir(v))
	var NF = load("res://personajes/nix/fbx/nix_fbx.gd")
	_selector("Nix", "nix_fbx", NF.activo(), [[false, "Antigua"], [true, "Desde el FBX"]],
		_elegir_nix_fbx)
	var GA = load("res://garon_3d.gd")
	_selector("Capa de Garon", "capa", GA.capa_articulada(), [[false, "Original"], [true, "Articulada"]],
		_elegir_capa)
	var OP = load("res://ciudades/oakhaven_propuestas.gd")
	_selector("Misión del cantero (solo en el banco)", "cantero", OP.activado(), [[false, "Apagada"], [true, "Activa"]],
		func(v): Engine.set_meta("oakhaven_propuestas_v12", v))   # solo de sesión: al salir del banco se quita
	# V12 (15/11): calidad 3D de la sesión, para medir en el teléfono con la resolución FIJA (el perfil en uso tal cual,
	# sin regulador ni recortes; en «bajo», 3D ×0,75) o con el regulador normal (que puede bajarla). Solo de sesión.
	var CP = load("res://prototipos/calidad_proto.gd")
	var fija := Engine.has_meta("calidad_proto")
	var pf: String = str(Engine.get_meta("calidad_proto")) if fija else CP.actual()
	_selector("Calidad 3D (solo en el banco)", "regulador", fija, [[false, "Regulador normal"],
		[true, "Fija: %s · 3D ×%.2f" % [pf, float(CP.PERFILES.get(pf, CP.PERFILES["bajo"])["escala_3d"])]]], _elegir_calidad_fija)
	# (15/11) Precalentar el recorrido de la muestra de la calle en su primera entrada (candidato a remedio de los
	# tirones de la primera vuelta; solo de sesión, para medir con y sin él).
	_selector("Muestra: precalentar (solo en el banco)", "precalentar", bool(Engine.get_meta("muestra_precalentar", false)),
		[[false, "No"], [true, "Sí"]], func(v): Engine.set_meta("muestra_precalentar", v))
	# (16/11) Sunken City 3D con la Quilla horneada (zonas3d/sunken/quilla/, EXPERIMENTAL; docs/v12/SUNKEN_QUILLA.md)
	_selector("Sunken: Quilla horneada (solo en el banco)", "sunken_quilla", bool(Engine.get_meta("sunken_quilla_v12", false)),
		[[false, "No"], [true, "Sí"]], func(v): Engine.set_meta("sunken_quilla_v12", v))
	# (16/11) Arboleda, «Una flor para Lumi» (zonas3d/arboleda_tramo/lumi_flor.gd): llevar la flor de abajo, solo de sesión
	_selector("Llevar una flor de abajo (Arboleda)", "arboleda_flor", bool(Engine.get_meta("arboleda_flor", false)),
		[[false, "No"], [true, "Sí"]], func(v): Engine.set_meta("arboleda_flor", v))
	cuerpo.add_child(_texto("Combates de prueba (al terminar se vuelve aquí)", 24, Estilo.ORO))
	for k in COMBATES:
		_caso(k, COMBATES[k], _combate.bind(k))
	cuerpo.add_child(_texto("Exploración de prueba (para volver: el botón «Volver al banco», arriba a la izquierda)", 24, Estilo.ORO))
	for k in EXPLORAR:
		_caso(k, EXPLORAR[k], _explorar.bind(k))


# «Fija»: el perfil que usaría el regulador, tal cual, sin recortes ni regulador (como CAL). «Regulador normal»: sin meta.
func _elegir_calidad_fija(fija: bool) -> void:
	var perfil: String = load("res://prototipos/calidad_proto.gd").actual()
	for m in ["calidad_proto", "calidad_extra"]:   # (no «muestra_precalentar»: es otro interruptor)
		if Engine.has_meta(m):
			Engine.remove_meta(m)
	if fija:
		Engine.set_meta("calidad_proto", perfil)


func _selector(nombre: String, clave: String, actual, opciones: Array, elegir: Callable) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var l := _texto(nombre, 19, Estilo.LUZ_CLARA)
	l.custom_minimum_size = Vector2(330, 0)
	fila.add_child(l)
	for op in opciones:
		var v = op[0]
		var b := _boton(("● " if str(v) == str(actual) else "○ ") + op[1], 19, Vector2(200, 50), "%s:%s" % [clave, str(v)])
		b.pressed.connect(func():
			elegir.call(v)
			Sonido.efecto("ui_tic")
			_pintar_de_nuevo())
		fila.add_child(b)
	cuerpo.add_child(fila)


func _caso(clave: String, d: Dictionary, accion: Callable) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var b := _boton(d["titulo"], 20, Vector2(520, 56), "caso:" + clave)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(accion)
	fila.add_child(b)
	var n := _texto(d["nota"], 16, Estilo.GRIS)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(560, 0)
	fila.add_child(n)
	cuerpo.add_child(fila)


func _combate(clave: String) -> void:
	if saliendo or Recursos.cambiando:             # (durante el fundido de entrada, el cambio se ignoraría)
		return
	saliendo = true
	var d: Dictionary = COMBATES[clave]
	poner_grupo(d["activos"], NIVEL_COMBATE)
	Engine.set_meta("banco_caso", clave)
	if d.get("custodio", false):
		Engine.set_meta("meshy_e01", true)
	if d.get("velaria", false):                    # (19/11) Velaria, solo en su caso
		Engine.set_meta("velaria_v12", true)
	if d.get("cencerrante", false):                # (19/11) el Cencerrante, solo en su caso
		Engine.set_meta("cencerrante_v12", true)
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", int(d["grupo"]))
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("escena_retorno", ESCENA)
	Sonido.efecto("ui_tic")
	Recursos.cambiar_escena("res://combate.tscn")


func _explorar(clave: String) -> void:
	if saliendo or Recursos.cambiando:
		return
	saliendo = true
	poner_grupo(EXPLORAR[clave]["activos"])
	Sonido.efecto("ui_tic")
	Recursos.cambiar_escena(str(EXPLORAR[clave].get("escena", escena_base)))


func _salir() -> void:
	if saliendo or Recursos.cambiando:
		return
	saliendo = true
	salir()
	Recursos.desmarcar_partida_prueba()
	Sonido.efecto("ui_cerrar")
	Recursos.cambiar_escena(CARGA)


func _elegir_nix_fbx(v: bool) -> void:
	_ajuste("calidad_pruebas", "nix_fbx", v)
	Engine.set_meta("nix_fbx", v)                 # (como en Ajustes: la meta manda sobre el archivo en esta sesión)


func _elegir_capa(v: bool) -> void:
	_ajuste("garon", "capa", "articulada" if v else "rigida")
	if Engine.has_meta("capa_garon"):
		Engine.remove_meta("capa_garon")


func _ajuste(seccion: String, clave: String, valor) -> void:
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		c.load("user://ajustes.cfg")
	c.set_value(seccion, clave, valor)
	c.save("user://ajustes.cfg")


func _pintar_de_nuevo() -> void:
	var clave := Entrada.clave_enfocada(self)
	for c in cuerpo.get_children():
		cuerpo.remove_child(c)
		c.queue_free()
	_pintar()
	Entrada.restaurar(self, clave, Entrada.primero(cuerpo))


func _texto(t: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


func _boton(t: String, tam: int, minimo: Vector2, clave := "") -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = minimo
	b.add_theme_font_size_override("font_size", tam)
	if clave != "":
		b.set_meta("clave", clave)
	return b
