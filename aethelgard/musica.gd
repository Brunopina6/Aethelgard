extends Node
# Musica (autoload): la música y el ambiente de cada lugar (T-030, D-067).
# - Dos capas, cada una con dos reproductores para fundir una pista con la siguiente: «musica» (bus Musica) y
#   «ambiente» (bus Ambiente). Respetan los volúmenes y el «Sin sonido» de los ajustes (sonido.gd).
# - Cada fotograma mira qué escena hay. Si cambia, pide su contexto (CONTEXTOS): si la pista es la misma que ya suena,
#   sigue sin cortes (volver a entrar no la reinicia); si es otra, funde; si no hay ninguna, se calla con un fundido.
# - El combate tiene su propia música (combate.gd): al empezar, la exploración se calla con un fundido y recuerda por
#   dónde iba; al volver (gane, huya o pierda), sigue desde ahí.
# - Al pausar la app (Android), todo se pausa; al volver, sigue.
# - Solo pistas con permiso (docs/audio/inventario_sonidos.md): hoy, ambientes CC0. Las canciones de Suno no están en
#   el juego. Sin pista para un contexto: silencio controlado.

const FUNDIDO_SALIDA := 1.2
const FUNDIDO_ENTRADA := 2.0
const SILENCIO_DB := -60.0
const AMB := "res://audio/ambiente/"

# contexto → pista y volumen de cada capa ("" = silencio)
const CONTEXTOS := {
	"silencio": {"musica": "", "ambiente": ""},
	"carga": {"musica": "", "ambiente": ""},
	"combate": {"musica": "", "ambiente": ""},      # su música la lleva combate.gd
	"mapa": {"musica": "", "ambiente": AMB + "viento.wav", "db": -14.0},
	"pradera": {"musica": "", "ambiente": AMB + "pradera.wav", "db": -6.0},
	"ciudad": {"musica": "", "ambiente": AMB + "pradera.wav", "db": -10.0},
	"bosque": {"musica": "", "ambiente": AMB + "bosque.wav", "db": -6.0},
	"desierto": {"musica": "", "ambiente": AMB + "desierto.wav", "db": -8.0},
	"viento": {"musica": "", "ambiente": AMB + "viento.wav", "db": -10.0},
	"mazmorra": {"musica": "", "ambiente": AMB + "mazmorra.wav", "db": -6.0},
	# V12, el Mar de Cristal (sonido_v12_desierto.md §2): el viento en calma y la tormenta de arena (clima.gd los alterna)
	"mar_cristal": {"musica": "", "ambiente": "res://audio/desierto/viento.ogg", "db": -13.0},
	"tormenta_arena": {"musica": "", "ambiente": "res://audio/desierto/tormenta.ogg", "db": -9.0},
	# V12 (15/11): Sunken City 3D, el puerto en la laguna: el viento suave de la costa (no hay olas ni gaviotas en audio/:
	# pendiente). El agua, la madera y el mercado los pone la escena (Sonido.fuente_3d / fuente_linea).
	"puerto": {"musica": "", "ambiente": AMB + "viento.wav", "db": -15.0},
	# V12 (11/11): «REBELUM — When the World Forgets», la canción del usuario (Suno Pro, incluida con su permiso) para la pantalla de inicio
	# nueva, y RESERVADA para el desenlace del juego (docs/v12/MUSICA_TITULO.md). Está en Git desde el 11/11 (el usuario
	# tiene Suno Pro y la autorizó; maestras en D:\REBELUM_musica\maestros). «privada»: si el archivo faltara en una
	# copia, silencio. «bucle»: la canción entera se repite (acaba con su golpe y vuelve su
	# introducción suave); «desde_cero»: al entrar en la pantalla de inicio empieza por el principio.
	"titulo": {"musica": "res://audio/musica/titulo/when_the_world_forgets.ogg", "ambiente": "", "db_musica": -4.0,
		"bucle": true, "desde_cero": true, "privada": true},
	# V12 (11/11): «Pastoral Pulse», la música de Pastos Verdes que eligió el usuario (Suno Pro, privada como la del
	# título), ELEGIBLE en Ajustes (MUSICA_PASTOS; por defecto, el ambiente de siempre). La introducción suena una vez y
	# se repite el cuerpo: «bucle_desde» 11,17 s hasta el final del archivo (2:44,28), con un fundido cruzado de 0,4 s
	# ya hecho en el archivo (docs/v12/MUSICA_PASTOS.md). El ambiente de la pradera sigue, algo más bajo.
	"pradera_musica": {"musica": "res://audio/musica/pastos/pastoral_pulse.ogg", "ambiente": AMB + "pradera.wav",
		"db": -9.0, "db_musica": -9.0, "bucle": true, "bucle_desde": 11.17, "privada": true},
}
const MUSICA_PASTOS := ["musica", "pastos"]       # [sección, clave] de user://ajustes.cfg: «nueva» o «ambiente»


# ¿Suena la música nueva en Pastos Verdes? Solo si se eligió en Ajustes y el archivo está (es privado).
static func musica_pastos_elegida() -> bool:
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return false
	return str(c.get_value(MUSICA_PASTOS[0], MUSICA_PASTOS[1], "ambiente")) == "nueva" \
		and ResourceLoader.exists(CONTEXTOS["pradera_musica"]["musica"])


static func elegir_musica_pastos(nueva: bool) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value(MUSICA_PASTOS[0], MUSICA_PASTOS[1], "nueva" if nueva else "ambiente")
	return c.save("user://ajustes.cfg")
# Momentos de la canción del título (s), medidos en su forma de onda (docs/v12/MUSICA_TITULO.md): la entrada del grupo
# (bajo y batería) y la subida grande. La pantalla de inicio los usa para sus luces (portada/inicio_alternativo.gd).
const TITULO_ROCK := 7.0
const TITULO_SUBIDA := 53.0

var capas := {}                                    # "musica"/"ambiente" → {a, b, activo, ruta}
var contexto := ""
var _escena: Node = null
var _posiciones := {}                              # ruta → por dónde iba al callarse (para seguir al volver)
var arranques := 0                                 # cuántas veces ha empezado una pista (lo miran las pruebas)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nombre in ["musica", "ambiente"]:
		var bus := &"Musica" if nombre == "musica" else &"Ambiente"
		var c := {"a": _reproductor(bus), "b": _reproductor(bus), "ruta": ""}
		c["activo"] = c["a"]
		capas[nombre] = c


func _reproductor(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.volume_db = SILENCIO_DB
	add_child(p)
	return p


func _process(_d: float) -> void:
	var e := get_tree().current_scene
	if e != _escena:
		_escena = e
		if e != null:
			pedir(contexto_de(e))


# El contexto de una escena (y, en las zonas, de su lugar).
static func contexto_de(e: Node) -> String:
	var ruta: String = e.scene_file_path
	match ruta:
		"res://portada/inicio_alternativo.tscn":              # V12: la pantalla de inicio nueva, con la canción del título
			return "titulo"
		"res://carga.tscn":
			return "carga"
		"res://combate.tscn":
			return "combate"
		"res://mapa.tscn":
			return "mapa"
		"res://isla.tscn":
			return "viento"
		"res://garganta.tscn", "res://zonas3d/garganta_3d.tscn":   # la Garganta 2D y la 3D (T-095)
			return "mazmorra"
		"res://zonas3d/pastos_verdes_3d.tscn", "res://prototipos/sendero_puente.tscn":
			return "pradera_musica" if musica_pastos_elegida() else "pradera"   # V12: la música nueva, si se eligió
		"res://zonas3d/ciclopea_3d.tscn":                        # V12: las Cumbres de Ciclópea 3D, el viento de la 2D
			return "viento"
		"res://zonas3d/mar_cristal_3d.tscn":                     # V12: el Mar de Cristal (la tormenta la pide clima.gd)
			return "mar_cristal"
		"res://zonas3d/gran_bosque_3d.tscn":                     # V12, fase D: el Gran Bosque Verde 3D, el ambiente del bosque de la 2D
			return "bosque"
		"res://zonas3d/sunken_3d.tscn":                          # V12 (15/11): Sunken City 3D, en pruebas
			return "puerto"
		"res://ciudad_oakhaven.tscn", "res://zonas3d/oakhaven_3d.tscn":   # Oakhaven hecha a mano (T-089) y la 3D (T-103): el ambiente
			return "ciudad"                            # de las ciudades, como la Oakhaven generada (sus sonidos: fuente_2d)
		"res://zona.tscn":
			var l: Dictionary = Engine.get_meta("lugar", {})
			if l.get("tipo", "") == "ciudad":
				return "ciudad"
			match l.get("zona", ""):
				"llanura":
					return "pradera"
				"bosque":
					return "bosque"
				"desierto":
					return "desierto"
				_:
					return "viento"
	return "silencio"


# Pide un contexto. Lo que ya suena y sigue tocando, sigue; lo demás funde.
func pedir(nombre: String) -> void:
	if not CONTEXTOS.has(nombre):
		nombre = "silencio"
	var d: Dictionary = CONTEXTOS[nombre]
	if d.get("desde_cero", false) and contexto != nombre:   # la canción del título: al entrar, desde el principio
		_posiciones.erase(d.get("musica", ""))
	contexto = nombre
	_poner("musica", d.get("musica", ""), d.get("db_musica", -6.0))
	_poner("ambiente", d.get("ambiente", ""), d.get("db", -6.0))


func _poner(capa: String, ruta: String, db: float) -> void:
	var c: Dictionary = capas[capa]
	var activo: AudioStreamPlayer = c["activo"]
	if ruta == c["ruta"]:                         # la misma pista: sigue (solo ajusta el volumen si cambia)
		if ruta != "" and activo.playing:
			_fundir(activo, db, FUNDIDO_ENTRADA, false)
		elif ruta != "":
			_empezar(activo, ruta, db)
		return
	if c["ruta"] != "" and activo.playing:        # la vieja se calla y recuerda por dónde iba
		_posiciones[c["ruta"]] = activo.get_playback_position()
		_fundir(activo, SILENCIO_DB, FUNDIDO_SALIDA, true)
	c["ruta"] = ruta
	if ruta == "":
		return
	var otro: AudioStreamPlayer = c["b"] if activo == c["a"] else c["a"]
	c["activo"] = otro
	_empezar(otro, ruta, db)

# Por dónde va la canción de la capa «musica» (s), o -1 si no suena nada. La pantalla de inicio sincroniza con ella
# sus luces (TITULO_ROCK, TITULO_SUBIDA).
func posicion_musica() -> float:
	if capas.is_empty():
		return -1.0
	var p: AudioStreamPlayer = capas["musica"]["activo"]
	return p.get_playback_position() if p.playing else -1.0

func _empezar(p: AudioStreamPlayer, ruta: String, db: float) -> void:
	var s: AudioStream = Recursos.obtener(ruta) if has_node("/root/Recursos") else load(ruta)
	if s == null:                                  # sin la pista: silencio controlado
		push_warning("Musica: falta %s" % ruta)
		return
	if p.has_meta("tween"):
		var t: Tween = p.get_meta("tween")
		if t != null and t.is_valid():
			t.kill()
	if CONTEXTOS.get(contexto, {}).get("bucle", false) and "loop" in s:
		s.set("loop", true)                        # la del título, entera; la de Pastos, desde «bucle_desde»
		if "loop_offset" in s:
			s.set("loop_offset", float(CONTEXTOS[contexto].get("bucle_desde", 0.0)))
	p.stream = s
	p.volume_db = SILENCIO_DB
	var desde: float = _posiciones.get(ruta, 0.0)
	if desde >= s.get_length() - 0.5:
		desde = 0.0
	p.play(desde)
	arranques += 1
	_fundir(p, db, FUNDIDO_ENTRADA, false)


func _fundir(p: AudioStreamPlayer, db: float, segundos: float, parar: bool) -> void:
	if p.has_meta("tween"):
		var viejo: Tween = p.get_meta("tween")
		if viejo != null and viejo.is_valid():
			viejo.kill()
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(p, "volume_db", db, segundos).set_trans(Tween.TRANS_SINE)
	if parar:
		t.tween_callback(p.stop)
	p.set_meta("tween", t)


# Android: al pasar la app a segundo plano se pausa todo; al volver, sigue.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT and OS.has_feature("mobile"):
		_pausar(true)
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN and OS.has_feature("mobile"):
		_pausar(false)


func _pausar(si: bool) -> void:
	for c in capas.values():
		for k in ["a", "b"]:
			c[k].stream_paused = si
