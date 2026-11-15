extends SceneTree
# Invariantes del combate (10/11, auditoría: «combate seguro»). Red de seguridad para separar combate.gd en módulos sin
# cambiar nada: juega combates automáticos («-- auto»), uno por semilla, y en CADA fotograma comprueba:
#   1. Nadie está dos veces en la cola de turnos (un doble turno).
#   2. Las barras ATB están entre 0 y ATB_MAX, y los PV entre 0 y su máximo.
#   3. El estado del combate es uno de los conocidos.
#   4. El combate termina (victoria o derrota) antes del límite, y al terminar el tiempo vuelve a la velocidad normal.
# No cambia el combate ni sus reglas: solo mira.
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»), así que antes los cinco combates eran
# al azar, grupo de enemigos incluido, aunque se sembrara antes de add_child. Ahora, con cada semilla: el grupo se elige
# con ella (grupo_al_azar de combate.gd, fijado con «grupo_combate») y, DESPUÉS de root.add_child(c), se siembra otra
# vez y se vuelve a tirar el ATB inicial de los enemigos (como prueba_gorthor_v12.gd). El primer combate se empieza
# diferido: desde _initialize el add_child no ejecuta el _ready al momento. Imprime «SEMILLA» por combate y
# una «TRAZA» por turno (fotograma, quién y PV de todos).

const SEMILLAS := [1, 7, 42, 2026, 31337]
const LIMITE := 3000                                # fotogramas por combate (100 s de juego con --fixed-fps 30)
const ESTADOS := ["esperando", "menu", "objetivo", "magia", "pocion", "enemigo", "accion", "decision", "fin"]

var c: Node
var i_semilla := -1
var frames := 0
var fallos := 0
var avisados := {}
var estado_ant := ""


func _initialize() -> void:
	if not "auto" in OS.get_cmdline_user_args():
		print("FALLO: falta «-- auto» (los héroes no actuarían solos)")
		quit(1)
		return
	_siguiente.call_deferred()                      # (diferido: en _initialize la raíz aún no está en el árbol y el
	                                                # _ready del combate llegaría después de la semilla)


func _fallo(t: String) -> void:
	if avisados.has(t):                             # el mismo fallo, una vez por combate
		return
	avisados[t] = true
	fallos += 1
	print("FALLO: [semilla %d] %s" % [SEMILLAS[i_semilla], t])


func _siguiente() -> void:
	if c != null:
		c.queue_free()
	i_semilla += 1
	if i_semilla >= SEMILLAS.size():
		print("FALLOS: %d" % fallos)
		quit(1 if fallos > 0 else 0)
		return
	frames = 0
	avisados = {}
	estado_ant = ""
	Engine.time_scale = 1.0
	var s: int = SEMILLAS[i_semilla]
	seed(s)                                         # el grupo de enemigos, al azar pero con la semilla
	Engine.set_meta("grupo_combate", load("res://combate.gd").grupo_al_azar(load("res://grupo.gd").activos().size()))
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)                               # (aquí su _ready hace randomize())
	seed(s)                                         # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                   # el ATB inicial, como en combate.gd, ya con la semilla
	print("SEMILLA %d · %s" % [s, ", ".join(c.enemigos.map(func(e): return e["nombre"]))])


func _process(_d: float) -> bool:
	if c == null or not is_instance_valid(c) or c.is_queued_for_deletion():
		return false
	frames += 1
	var vistos := {}
	for f in c.cola:
		var id: String = "%s/%s" % [f["nombre"], f["hero"]]   # cada combatiente tiene un nombre único en su bando
		if vistos.has(id):
			_fallo("%s está dos veces en la cola de turnos" % f["nombre"])
		vistos[id] = true
	for f in c.heroes + c.enemigos:
		if float(f["atb"]) < 0.0 or float(f["atb"]) > c.ATB_MAX + 0.001:
			_fallo("la barra ATB de %s se sale (%.2f)" % [f["nombre"], f["atb"]])
		if int(f["hp"]) < 0 or int(f["hp"]) > int(f["hp_max"]):
			_fallo("los PV de %s se salen (%d de %d)" % [f["nombre"], f["hp"], f["hp_max"]])
	if not c.estado in ESTADOS:
		_fallo("estado desconocido «%s»" % c.estado)
	if c.estado != estado_ant and c.estado in ["menu", "enemigo"]:   # una línea por turno
		var pv := []
		for f in c.heroes + c.enemigos:
			pv.append("%s %d" % [f["nombre"], int(f["hp"])])
		var quien: String = str(c.actor["nombre"]) if c.estado == "menu" and c.actor is Dictionary else "enemigo"
		print("TRAZA %d f%05d %s · %s" % [SEMILLAS[i_semilla], frames, quien, ", ".join(pv)])
	estado_ant = c.estado
	var en_fin: bool = c.estado == "fin" and frames > 60
	var vivos_h: int = c.heroes.filter(func(h): return int(h["hp"]) > 0).size()
	var vivos_e: int = c.enemigos.filter(func(e): return int(e["hp"]) > 0).size()
	if en_fin and (vivos_h == 0 or vivos_e == 0):
		if frames > 120 and not is_equal_approx(Engine.time_scale, 1.0):
			_fallo("al terminar, el tiempo sigue a %.2f" % Engine.time_scale)
		print("semilla %d: %s en %d fotogramas" % [SEMILLAS[i_semilla], "victoria" if vivos_e == 0 else "derrota", frames])
		_siguiente()
		return false
	if frames >= LIMITE:
		_fallo("el combate no termina en %d fotogramas (estado «%s», héroes vivos %d, enemigos vivos %d)" % [LIMITE, c.estado, vivos_h, vivos_e])
		_siguiente()
	return false
