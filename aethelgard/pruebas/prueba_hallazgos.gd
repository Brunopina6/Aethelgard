extends SceneTree
# Hallazgos (hallazgos.gd; zona.gd; ciudad_oakhaven.gd): los tomos y el equipo de T-092 que se encuentran en el mundo.
# Sin ventana, con «-- sin_prologo» (zonas 2D: la Garganta, la 2D). Partida propia (user://prueba_hallazgos.save).
#   1. Los datos: ids «hall_» sin repetir; el lugar y el sitio existen (detalle de ese lugar, pieza de Oakhaven, cofre en
#      un rincón conocido); da una sola cosa, que existe y está disponible, y su lugar es el de su «donde»; todo el
#      equipo de T-092 y los tres tomos tienen sitio (aquí, en una tienda, en un combate fijo o explicado en FUERA);
#      textos cortos, sin Érebo, sin lo pendiente de D-073 ni Final Fantasy X.
#   2. Encontrar: una sola vez; el tomo enseña su nivel III y el equipo va a «equipables»; si ya lo tenías, se apunta igual.
#   3. Partida antigua sin «cofres_abiertos»: se puede encontrar, y lo encontrado se guarda y se lee.
#   4. En el juego, como un jugador (al lado, el botón y pulsar), cada uno en su sitio: el Bosque (armadura y cofre del
#      campamento), la Garganta 2D (pilar), Ciclópea (estatua, cofre de las ruinas y cofre adonde mira), Calid
#      (máquina), el Valle de los Ecos (dos cofres) y Oakhaven (el pie del Árbol y el barril); los cofres, en suelo libre.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const H := preload("res://hallazgos.gd")
const ARCHIVO := "user://prueba_hallazgos.save"
const PROHIBIDO := ["erebo", "ladron de corazones", "corazones", "recuerdo", "memoria", "olvido", "rocio", "cripta",
	"trampilla", "conclave", "crio", "hermano", "diecisiete", "alcantarilla", "tidus", "yuna", "spira", "sinh"]
const NOMBRE_EN_DONDE := {0: "Oakhaven", 1: "Gran Bosque Verde", 2: "Garganta", 3: "Ciclópea", 6: "Valle de los Ecos"}
const TOMO_EN := {"tomo_alba": 4, "tomo_escarcha": 3, "tomo_lumbre": 6}     # combate_ampliaciones.md

var P
var R
var Extra
var Artes
var fallos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _plano(t: String) -> String:
	var r := t.to_lower()
	for p in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		r = r.replace(p[0], p[1])
	return r


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)


func _probar() -> void:
	P = load("res://progreso.gd")
	R = root.get_node("Recursos")
	Extra = load("res://equipo_extra.gd")
	Artes = load("res://artes.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_limpiar()
	_datos()
	_encontrar()
	_partida_antigua()
	_limpiar()
	await _en_el_juego()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _que_da(h: Dictionary) -> String:
	return h.get("arma", h.get("accesorio", h.get("tomo", "")))


# 1. Los datos.
func _datos() -> void:
	var ids := {}
	var dan := {}
	for h in H.HALLAZGOS:
		var id: String = h["id"]
		if ids.has(id) or not id.begins_with("hall_"):
			_fallo("1: id repetido o sin «hall_»: %s" % id)
		ids[id] = true
		var cosas := 0
		for k in ["arma", "accesorio", "tomo"]:
			cosas += 1 if h.has(k) else 0
		if cosas != 1:
			_fallo("1: %s da %d cosas" % [id, cosas])
		var cosa := _que_da(h)
		dan[cosa] = true
		if not H.disponible(h):
			_fallo("1: %s da %s, que no existe o no está disponible" % [id, cosa])
		var lugar: int = h["lugar"]
		var al: String = h["al"]
		if al.begins_with("detalle:"):
			if not P.DETALLES.get(lugar, []).any(func(d): return d["id"] == al.trim_prefix("detalle:")):
				_fallo("1: %s: el lugar %d no tiene el detalle %s" % [id, lugar, al])
		elif al.begins_with("pieza:"):
			if lugar != 0 or load("res://ciudades/oakhaven.gd").pieza(al.trim_prefix("pieza:")).is_empty():
				_fallo("1: %s: la pieza %s no existe en Oakhaven" % [id, al])
		elif al == "cofre":
			if not h.get("cerca", "") in ["ruinas", "campamento", "claro", "mirada", "agua"]:
				_fallo("1: %s: rincón desconocido «%s»" % [id, h.get("cerca", "")])
		elif al != "altar":
			_fallo("1: %s: «al» desconocido «%s»" % [id, al])
		if h.has("tomo"):
			if TOMO_EN.get(h["tomo"], -1) != lugar:
				_fallo("1: %s pone el %s en el lugar %d y el diseño dice el %d" % [id, h["tomo"], lugar, TOMO_EN.get(h["tomo"], -1)])
		else:
			var donde: String = Extra.objeto(cosa).get("donde", "")
			if not NOMBRE_EN_DONDE.get(lugar, "?") in donde:
				_fallo("1: %s pone %s en el lugar %d y su «donde» dice «%s»" % [id, cosa, lugar, donde])
		var p := _plano(h["texto"])
		if h["texto"].length() > 90:
			_fallo("1: %s: texto de %d letras" % [id, h["texto"].length()])
		for x in PROHIBIDO:
			if RegEx.create_from_string("\\b%s" % x).search(p) != null:
				_fallo("1: %s dice «%s»" % [id, x])
	var todos: Array = Extra.ARMAS.keys() + Extra.ACCESORIOS.keys() + Artes.TOMOS.keys()
	for cosa in todos:
		if not dan.has(cosa) and not H.FUERA.has(cosa):
			_fallo("1: %s no tiene sitio en el mundo ni explicación en FUERA" % cosa)
	for cosa in H.FUERA:
		if dan.has(cosa):
			_fallo("1: %s está en FUERA y también se encuentra" % cosa)
	print("HALLAZGOS %d · FUERA %d · todo: %d" % [H.HALLAZGOS.size(), H.FUERA.size(), todos.size()])


# 2. Encontrar.
func _encontrar() -> void:
	_limpiar()
	load("res://grupo.gd").empezar_solo()
	var antes: int = Artes.nivel("Kael", "Alba")
	var t: Array = H.encontrar("hall_tomo_alba")
	print("TOMO: ", t)
	if t.size() != 2 or not "Tomo del Alba" in t[1] or Artes.nivel("Kael", "Alba") < 3:
		_fallo("2: el Tomo del Alba no enseña el III a Kael (%s; nivel %d → %d)" % [t, antes, Artes.nivel("Kael", "Alba")])
	if not H.encontrado("hall_tomo_alba") or not H.encontrar("hall_tomo_alba").is_empty():
		_fallo("2: el tomo se encuentra dos veces")
	var e: Array = H.encontrar("hall_hoja_sin_nombre")
	if not "hoja_sin_nombre" in load("res://inventario.gd").datos()["equipables"] or e.size() != 2:
		_fallo("2: la Hoja sin Nombre no va a «equipables» (%s)" % [e])
	Extra.conseguir("pluma_arpia")
	var y: Array = H.encontrar("hall_pluma_arpia")
	if y.is_empty() or not "ya lo tenías" in y[-1] or not H.encontrado("hall_pluma_arpia"):
		_fallo("2: si ya lo tenías no se dice o no se apunta (%s)" % [y])


# 3. Partida antigua.
func _partida_antigua() -> void:
	_limpiar()
	P.restaurar({"grupo_activo": ["Kael"], "escena_guardada": "res://mapa.tscn", "inventario": load("res://inventario.gd").datos()})
	if Engine.has_meta("cofres_abiertos") and Engine.get_meta("cofres_abiertos").size() > 0:
		_fallo("3: una partida sin «cofres_abiertos» trae algo")
	for h in H.HALLAZGOS:
		if H.encontrado(h["id"]):
			_fallo("3: %s sale encontrado en una partida antigua" % h["id"])
	H.encontrar("hall_gemelas_muralla")
	if not P.guardar("res://mapa.tscn"):
		_fallo("3: no se guarda")
		return
	_limpiar()
	P.cargar()
	if not H.encontrado("hall_gemelas_muralla") or not "gemelas_muralla" in load("res://inventario.gd").datos()["equipables"]:
		_fallo("3: lo encontrado no se lee al cargar")


# 4. En el juego.
func _abrir(escena: String, indice: int) -> Variant:
	var l: Dictionary = load("res://mapa.gd").LUGARES[indice]
	Engine.set_meta("lugar", {"indice": indice, "nombre": l["nombre"], "tipo": l["tipo"], "zona": l.get("zona", "llanura"),
		"texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	var vieja: int = current_scene.get_instance_id() if current_scene != null else 0
	change_scene_to_file(escena)
	if not await _hasta(func(): return current_scene != null and current_scene.get_instance_id() != vieja \
			and current_scene.scene_file_path == escena and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("4: no se abre %s (lugar %d)" % [escena, indice])
		return null
	await _esperar(8)
	return current_scene


# Se pone junto a «pos» (píxeles), mira el botón y pulsa. Devuelve el texto del botón que había.
func _usar(z, pos: Vector2) -> String:
	z.jugador.position = pos + Vector2(30, 24)
	await _esperar(3)
	z._comprobar_cerca()
	var boton: String = z.boton_examinar.text if z.boton_examinar.visible else ""
	z._accion()
	await _esperar(4)
	return boton


func _tiene(cosa: String) -> bool:
	if Artes.TOMOS.has(cosa):
		return Artes.nivel("Kael" if Artes.TOMOS[cosa][0] != "Lumbre" else "Lya", Artes.TOMOS[cosa][0]) >= 3
	return cosa in load("res://inventario.gd").datos()["equipables"]


func _comprobar(z, id: String, como: String) -> void:
	var h := H.hallazgo(id)
	if not H.encontrado(id) or not _tiene(_que_da(h)):
		_fallo("4: %s no se encuentra %s (aviso «%s»)" % [id, como, z.aviso.text])
	else:
		print("HALLADO %s %s" % [id, como])


func _en_el_juego() -> void:
	var G = load("res://grupo.gd")
	for lugar in [1, 2, 3, 4, 6, 0]:
		_limpiar()
		G.empezar_solo()
		G.unir("Lya")
		var escena := "res://ciudad_oakhaven.tscn" if lugar == 0 else ("res://garganta.tscn" if lugar == 2 else "res://zona.tscn")
		var z = await _abrir(escena, lugar)
		if z == null:
			continue
		for h in H.de_lugar(lugar):
			var id: String = h["id"]
			match h["al"]:
				"cofre":
					var c = null
					for e in z.cofres:
						if e[1] == id:
							c = e
					if c == null:
						_fallo("4: %s no tiene su cofre en el lugar %d" % [id, lugar])
						continue
					if not z._suelo_libre(c[0].position / z.T):
						_fallo("4: el cofre de %s no está en suelo libre (%s)" % [id, c[0].position / z.T])
					if h.get("cerca", "") == "agua" and z._orilla().x >= 0:
						var mojado := false
						for dy in range(-2, 3):
							for dx in range(-2, 3):
								mojado = mojado or z._en_agua(c[0].position + Vector2(dx, dy) * z.T)
						if not mojado:
							_fallo("4: el cofre de %s no está junto al agua (%s)" % [id, c[0].position / z.T])
						else:
							print("ORILLA %s en %s" % [id, c[0].position / z.T])
					var b := await _usar(z, c[0].position)
					if b != "Abrir cofre":
						_fallo("4: junto al cofre de %s el botón dice «%s»" % [id, b])
					_comprobar(z, id, "en su cofre (%s)" % h.get("cerca", ""))
				"altar":
					await _usar(z, z.altar.position)
					_comprobar(z, id, "al pie del altar")
				_:
					if h["al"].begins_with("detalle:"):
						var det = null
						for d in z.detalles:
							if d[1]["id"] == h["al"].trim_prefix("detalle:"):
								det = d
						if det == null:
							_fallo("4: el lugar %d no pone el detalle de %s" % [lugar, id])
							continue
						await _usar(z, det[0].position)
						_comprobar(z, id, "al examinar %s" % det[1]["nombre"])
					elif h["al"].begins_with("pieza:"):
						for e in z.piezas:
							if e[1]["id"] == h["al"].trim_prefix("pieza:"):
								await _usar(z, e[2])
						_comprobar(z, id, "al examinar %s" % h["al"])
		# lo encontrado no se repite: el mismo sitio otra vez no da nada nuevo
		var antes: int = load("res://inventario.gd").datos()["equipables"].size()
		for h in H.de_lugar(lugar):
			if h["al"] == "altar":
				await _usar(z, z.altar.position)
		if load("res://inventario.gd").datos()["equipables"].size() != antes:
			_fallo("4: en el lugar %d, el mismo sitio da algo dos veces" % lugar)
		await _esperar(10)
