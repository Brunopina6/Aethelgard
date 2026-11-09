extends SceneTree
# Notas para encontrar en la Garganta y en Pastos Verdes (dialogos/notas/garganta.gd y pastos_verdes.gd; progreso.gd,
# CIUDADES; diario.gd; zonas3d/pastos_verdes_3d.gd). Sin ventana, con «-- 3d sin_prologo». Partida propia.
#   1. Los datos: de 3 a 5 en la Garganta y de 2 a 3 en Pastos Verdes; ids «nota_» sin repetir entre todos los lugares;
#      cada texto, en dos líneas del aviso de las zonas 3D (1000 px a 30 px) y sin nada de Érebo (D-033), de lo que
#      espera decisión del usuario (D-073) ni de Final Fantasy X; las de la Garganta, en una cornisa de su trazado y a
#      más de RADIO + 0,5 m de lo que ya se usa allí (ascensor, palanca, pilar, cofre, detalle de los puentes, puerta).
#   2. El Diario: una nota leída de cada lugar sale en «Notas» con su lugar (también Pastos Verdes, que no está en
#      LUGARES); las no leídas, no.
#   3. En Pastos Verdes 3D: las tres, junto al camino y lejos de Tilo, la estela, el cofre, la lavanda y el centinela;
#      al lado, «Examinar»; al pulsar, su texto, queda leída una sola vez y se apaga su destello.
#   4. Una partida antigua sin «lore_visto» carga con las notas sin leer.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const NG := preload("res://dialogos/notas/garganta.gd")
const NP := preload("res://dialogos/notas/pastos_verdes.gd")
const TG := preload("res://zonas3d/garganta/trazado.gd")
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ARCHIVO := "user://prueba_notas_exploracion.save"
const PROHIBIDO := ["erebo", "ladron de corazones", "corazones", "recuerdo", "memoria", "olvido", "rocio", "cripta",
	"trampilla", "conclave", "crio", "hermano", "diecisiete", "alcantarilla", "tidus", "yuna", "spira", "sinh"]

var P
var R
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
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_limpiar()
	await _datos()
	await _diario()
	_partida_antigua()
	await _en_pastos()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Los datos.
func _datos() -> void:
	if not (P.CIUDADES.get(2, "") == "res://dialogos/notas/garganta.gd" and P.CIUDADES.get(10, "") == "res://dialogos/notas/pastos_verdes.gd"):
		_fallo("1: progreso.gd no conoce las notas de la Garganta (2) y de Pastos Verdes (10): %s" % [P.CIUDADES])
	if NG.NOTAS.size() < 3 or NG.NOTAS.size() > 5:
		_fallo("1: %d notas en la Garganta (de 3 a 5)" % NG.NOTAS.size())
	if NP.NOTAS.size() < 2 or NP.NOTAS.size() > 3:
		_fallo("1: %d notas en Pastos Verdes (de 2 a 3)" % NP.NOTAS.size())
	var ids := {}
	for l in P.CIUDADES:
		for n in P.notas_de(l):
			if ids.has(n["id"]) or not n["id"].begins_with("nota_"):
				_fallo("1: id repetido o sin «nota_»: %s" % n["id"])
			ids[n["id"]] = true
	var aviso := Label.new()
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 100)
	aviso.add_theme_font_size_override("font_size", 30)
	root.add_child(aviso)
	for n in NG.NOTAS + NP.NOTAS:
		if n["nombre"] == "" or n["texto"] == "":
			_fallo("1: %s sin nombre o sin texto" % n["id"])
		var p := _plano(n["nombre"] + " " + n["texto"])
		for x in PROHIBIDO:
			if RegEx.create_from_string("\\b%s" % x).search(p) != null:
				_fallo("1: %s dice «%s»" % [n["id"], x])
		aviso.text = n["texto"]
		await _esperar(2)
		if aviso.get_line_count() > 2:
			_fallo("1: %s ocupa %d líneas en el aviso" % [n["id"], aviso.get_line_count()])
		print("NOTA %s | %d letras | %d línea(s) | %s" % [n["id"], n["texto"].length(), aviso.get_line_count(), n["texto"]])
	aviso.free()
	var usados := {"ascensor": TG.ASCENSOR_ARRIBA, "palanca": TG.PALANCA, "pilar": TG.PILAR_PEREGRINO,
		"cofre del nido": TG.COFRE_NIDO, "detalle de los puentes": TG.DETALLE_PUENTES, "puerta": TG.PUERTA}
	for n in NG.NOTAS:
		var q: Vector3 = n["pos"]
		if not q.y in [TG.ALTO, TG.BAJO, TG.NIDO] or q.z < TG.Z_NORTE or q.z > TG.Z_FIN_CAMINO:
			_fallo("1: %s no está en una cornisa de la Garganta (%s)" % [n["id"], q])
		for k in usados:
			var u: Vector3 = usados[k]
			if absf(u.y - q.y) < 1.0 and Vector2(u.x - q.x, u.z - q.z).length() < NG.RADIO + 0.5:
				_fallo("1: %s está pegada a %s (sus botones se pisarían)" % [n["id"], k])
		if not NG.CASILLA_2D.has(n["id"]):
			_fallo("1: %s no dice dónde iría en la Garganta 2D" % n["id"])


# 2. El Diario.
func _diario() -> void:
	_limpiar()
	P.ver_nota(NG.NOTAS[0]["id"])
	P.ver_nota(NP.NOTAS[0]["id"])
	var d = load("res://diario.gd").new()
	root.add_child(d)
	await _esperar(6)
	var textos: Array = []
	for l in d.find_children("*", "Label", true, false):
		textos.append(l.text)
	var todo := "\n".join(PackedStringArray(textos))
	for e in [[NG.NOTAS[0], "Garganta del Diablo"], [NP.NOTAS[0], "Pastos Verdes"]]:
		if not ("%s · %s" % [e[0]["nombre"], e[1]]) in todo:
			_fallo("2: el Diario no enseña «%s · %s»" % [e[0]["nombre"], e[1]])
	for n in [NG.NOTAS[1], NP.NOTAS[1]]:
		if n["nombre"] in todo:
			_fallo("2: el Diario enseña %s sin haberla leído" % n["id"])
	d.queue_free()
	await _esperar(2)


# 4. Partida antigua.
func _partida_antigua() -> void:
	_limpiar()
	P.restaurar({"grupo_activo": ["Kael"], "escena_guardada": "res://mapa.tscn"})
	for n in NG.NOTAS + NP.NOTAS:
		if P.visto(n["id"]):
			_fallo("4: en una partida sin «lore_visto», %s sale leída" % n["id"])
	if not P.ver_nota(NP.NOTAS[1]["id"]) or P.ver_nota(NP.NOTAS[1]["id"]):
		_fallo("4: en una partida antigua no se apunta una nota (o se apunta dos veces)")


# 3. En Pastos Verdes 3D (con la misión hecha, para que ninguna escena se cruce).
func _en_pastos() -> void:
	_limpiar()
	for h in ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo"]:
		P.poner_hito(h)
	Engine.set_meta("combates_ganados", {"pastos_centinela": true})
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == REGION \
			and current_scene.get("kael") != null and not R.cambiando, 120.0):
		_fallo("3: no se abre Pastos Verdes 3D")
		return
	var r = current_scene
	await _esperar(30)
	if r.notas.size() != NP.NOTAS.size():
		_fallo("3: hay %d notas en la escena y %d en los datos" % [r.notas.size(), NP.NOTAS.size()])
		return
	var otros := {"Tilo": r.tilo, "la estela": r.estela, "el cofre": r.cofre, "la lavanda": r.lavanda}
	for e in r.notas:
		for f in r.notas:
			if e != f and r._dist_plana(e[0].global_position, f[0].global_position) < r.RADIO_ACCION + 0.5:
				_fallo("3: %s y %s están pegadas" % [e[1]["id"], f[1]["id"]])
	for e in r.notas:
		var p: Vector3 = e[0].global_position
		for k in otros:
			if otros[k] != null and r._dist_plana(p, otros[k].global_position) < r.RADIO_ACCION + 0.5:
				_fallo("3: %s está pegada a %s" % [e[1]["id"], k])
		if r._dist_plana(p, r.CENTINELA) < r.RADIO_CENTINELA:
			_fallo("3: %s está en el círculo del centinela" % e[1]["id"])
		var ds: float = r._dist_sendero(p)
		if ds > 3.5:
			_fallo("3: %s está a %.1f m del camino" % [e[1]["id"], ds])
		if r._dist_plana(p, e[1]["cerca"]) > 4.0:
			_fallo("3: %s se ha ido a %.1f m de su sitio" % [e[1]["id"], r._dist_plana(p, e[1]["cerca"])])
	var e0: Array = r.notas[0]
	r._colocar_kael(e0[0].global_position + Vector3(1.0, 0, 0.6))
	await _esperar(20)
	r._comprobar_cerca()
	if r.cerca != "nota:" + e0[1]["id"] or not r.boton_accion.visible or r.boton_accion.text != "Examinar":
		_fallo("3: junto a %s no sale «Examinar» (cerca «%s», botón «%s»)" % [e0[1]["id"], r.cerca, r.boton_accion.text])
		return
	r._accion()
	await _esperar(6)
	if r.aviso.text != e0[1]["texto"]:
		_fallo("3: al examinar sale «%s»" % r.aviso.text)
	if not P.visto(e0[1]["id"]):
		_fallo("3: la nota no queda leída")
	if e0[2] != null and is_instance_valid(e0[2]):
		_fallo("3: el destello sigue tras leerla")
	if P.ver_nota(e0[1]["id"]):
		_fallo("3: la misma nota cuenta como nueva otra vez")
	print("PASTOS: ", e0[1]["id"], " → ", r.aviso.text)
