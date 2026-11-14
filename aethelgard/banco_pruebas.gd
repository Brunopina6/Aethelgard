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

const ARCHIVO := "user://banco_pruebas.save"
const META := "banco_pruebas"
const ESCENA := "res://banco_pruebas.tscn"
const CARGA := "res://carga.tscn"
const NIVEL_COMBATE := 12                         # con todas las magias (grupo.gd, NIVEL_MAGIA 1, 5 y 10)
# Interruptores que el banco enciende solo para su sesión (Engine): se quitan al salir.
const METAS_SESION := ["meshy_e01", "banco_caso", "nix_v12", "oakhaven_propuestas_v12",
	"oak_franja", "oak_franja_t", "comentarios_dichos"]   # (y la hora de Oakhaven y los comentarios ya dichos: de la sesión)
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
	"custodio": {"titulo": "Custodio de Porcelana (meshy_e01)", "grupo": 28, "activos": ["Kael", "Lya", "Garon"],
		"vida": 1.0, "armonia": false, "custodio": true,
		"nota": "Piloto: reposo, andar y Prensa del Umbral. Afinidades neutras provisionales."},
}
const EXPLORAR := {
	"oakhaven": {"titulo": "Oakhaven con Kael, Lya y Garon", "activos": ["Kael", "Lya", "Garon"],
		"nota": "Puerta del Sur y vecinos, el arcón del Concejo (casilla 50,5; 22) y, si está activa, la misión del cantero."},
	"oakhaven_nix": {"titulo": "Oakhaven con Nix en el grupo", "activos": ["Kael", "Garon", "Nix"],
		"nota": "Nix andando y girando con el grupo. Para canalizar, el combate de Nix."},
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
	for k in METAS_SESION:                         # cada caso empieza sin los interruptores del anterior
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	if cantero != null:
		Engine.set_meta("oakhaven_propuestas_v12", cantero)
	return load("res://progreso.gd").restaurar(BASE.duplicate(true))


# Fija el grupo de un caso. Nix solo existe con su interruptor: el banco lo enciende para su sesión.
static func poner_grupo(activos: Array, nivel := 0) -> void:
	var G = load("res://grupo.gd")
	if "Nix" in activos:
		Engine.set_meta("nix_v12", true)
		G.unir("Nix")
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


# Sale del banco: quita la partida de la sesión, los interruptores que puso y el archivo de prueba. Lo siguiente que
# se cargue es la partida de siempre.
static func salir() -> void:
	var P = load("res://progreso.gd")
	for k in P.CLAVES + METAS_SESION + [META, "archivo_partida_prueba", "partida_lista", "grupo_combate", "combate_fijo",
			"tipo_combate", "desde_mapa", "escena_retorno", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
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
	cuerpo.add_child(_texto("Combates de prueba (al terminar se vuelve aquí)", 24, Estilo.ORO))
	for k in COMBATES:
		_caso(k, COMBATES[k], _combate.bind(k))
	cuerpo.add_child(_texto("Exploración de prueba (para volver: el botón «Volver al banco», arriba a la izquierda)", 24, Estilo.ORO))
	for k in EXPLORAR:
		_caso(k, EXPLORAR[k], _explorar.bind(k))


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
	Recursos.cambiar_escena(escena_base)


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
