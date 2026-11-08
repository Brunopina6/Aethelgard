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
}

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
		"res://carga.tscn":
			return "carga"
		"res://combate.tscn":
			return "combate"
		"res://mapa.tscn":
			return "mapa"
		"res://isla.tscn":
			return "viento"
		"res://garganta.tscn":
			return "mazmorra"
		"res://zonas3d/pastos_verdes_3d.tscn", "res://prototipos/sendero_puente.tscn":
			return "pradera"
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
	contexto = nombre
	var d: Dictionary = CONTEXTOS[nombre]
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


func _empezar(p: AudioStreamPlayer, ruta: String, db: float) -> void:
	var s: AudioStream = Recursos.obtener(ruta) if has_node("/root/Recursos") else load(ruta)
	if s == null:                                  # sin la pista: silencio controlado
		push_warning("Musica: falta %s" % ruta)
		return
	if p.has_meta("tween"):
		var t: Tween = p.get_meta("tween")
		if t != null and t.is_valid():
			t.kill()
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
