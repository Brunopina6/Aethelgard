extends SceneTree
# Prueba dura del grupo (zonas3d/grupo_3d.gd) en Pastos Verdes 3D, con la exploración 3D activa («-- 3d»). Un solo
# recorrido correcto no demuestra nada, así que aquí hay muchos:
#   - tres series de destinos al azar por toda la región, con semilla fija (siempre los mismos), cada una con otra
#     distancia de cámara (9, 20 y 34 m);
#   - sitios difíciles: las dos puntas del puente, el borde del barranco, alrededor de Tilo, el cofre y los árboles;
#   - giros bruscos y media vuelta cada pocos tramos.
# En cada fotograma, para Lya y Garon:
#   - no pisan zonas prohibidas (río, barranco, fuera del mapa) y están sobre el suelo;
#   - la ruta es válida: entre un fotograma y el siguiente no atraviesan nada a la altura de las rodillas;
#   - no se quedan atrás (cada uno a 4 m como mucho del de delante, salvo justo después de reaparecer).
# Antes, comprueba que en el juego normal se cuentan los pasos (los encuentros siguen activos); para que un combate
# no corte las rutas, después se ponen a 0 solo en esta prueba.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const SEMILLAS := [7, 23, 101]
const DISTANCIAS := [9.0, 20.0, 34.0]
const DESTINOS_POR_SERIE := 9
const DIFICILES := [Vector3(5.2, 0, -2.0), Vector3(12.9, 0, -2.0), Vector3(5.0, 0, -4.2), Vector3(13.6, 0, 0.4),
	Vector3(9.0, 0, -2.0), Vector3(14.8, 0, 2.6), Vector3(-6.0, 0, 6.6), Vector3(-12.0, 0, 6.0)]
const MAX_DETRAS := 4.0
const ESPERA_TRAMO := 450

var frames := 0
var fase := 0
var f_fase := 0
var v
var destinos: Array = []
var tramo := 0
var serie := 0
var previas := {}
var recien := {}                                  # fotogramas desde que cada uno reapareció
var datos := {"medidos": 0, "pisa": 0, "flota": 0, "cruza": 0, "lejos": 0, "juntos": 0, "reapariciones": 0,
	"sin_llegar": 0, "max_lya": 0.0, "max_garon": 0.0, "metros": 0.0}
var kael_antes := Vector3.ZERO
var fallos: Array = []
var pasos_antes := 0


func _initialize() -> void:
	if not load("res://modo3d.gd").activo():
		print("FALLO: la exploración 3D no está activa (falta «-- 3d»)")
		quit(1)
		return
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # los dos ya se han unido
	Engine.set_meta("combates_ganados", {})
	change_scene_to_file(REGION)
	_fase(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# Un sitio para ir: andable, lejos de las salidas (sacarían al mapa) y del mirador (empezaría el combate).
func _valido(p: Vector3) -> bool:
	if v._prohibido(p):
		return false
	for s in v.salidas:
		if _plana(p, s["pos"]) < 4.0:
			return false
	return _plana(p, v.CENTINELA) > 6.5


# Tocar el suelo hace andar a Kael en línea recta (no busca rodeos), así que cada destino nuevo tiene que poder
# alcanzarse en línea recta desde el anterior. Si no, Kael se para enseguida y el grupo apenas se mueve.
func _preparar_serie() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLAS[serie]
	destinos.clear()
	var dificiles := DIFICILES.duplicate()
	var actual: Vector3 = v.kael.global_position
	var k := 0
	while destinos.size() < DESTINOS_POR_SERIE and k < 2000:
		k += 1
		var p: Vector3
		if destinos.size() % 3 == 2:
			p = destinos[destinos.size() - 2]            # media vuelta: al sitio de antes
		elif rng.randf() < 0.35 and not dificiles.is_empty():
			p = dificiles[rng.randi() % dificiles.size()]
		else:
			var a := rng.randf() * TAU
			p = actual + Vector3(cos(a), 0, sin(a)) * rng.randf_range(3.0, 10.0)
		p = Vector3(p.x, v.altura(p.x, p.z), p.z)
		if _valido(p) and _alcanzable(actual, p):
			destinos.append(p)
			dificiles.erase(p)
			actual = p
	v.distancia = DISTANCIAS[serie]
	tramo = 0
	print("serie %d (semilla %d, cámara a %.0f m): %d destinos" % [serie + 1, SEMILLAS[serie], v.distancia, destinos.size()])
	_ir()


# Se puede ir andando en línea recta: cada 0,25 m, suelo andable, sin escalones de más de 0,45 m y sin nada a la
# altura de las rodillas (las mismas reglas que Kael, un poco más estrictas).
func _alcanzable(a: Vector3, b: Vector3) -> bool:
	var n := int(_plana(a, b) / 0.25)
	var prev := a
	for i in range(1, n + 1):
		var q := a.lerp(b, float(i) / n)
		if v._prohibido(q):
			return false
		var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(Vector3(q.x, prev.y + 0.6, q.z), Vector3(q.x, prev.y - 2.0, q.z)))
		if r.is_empty() or absf(r["position"].y - prev.y) > 0.45 or r["normal"].y < cos(deg_to_rad(38.0)):
			return false
		q.y = r["position"].y
		if _cruza(prev, q):
			return false
		prev = q
	return true


func _ir() -> void:
	v.destino = v._ajustar_destino(destinos[tramo])
	f_fase = frames


func _process(_d: float) -> bool:
	frames += 1
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 10:
				v = current_scene
				if v.grupo == null or v.grupo.nodos().size() != 2:
					print("FALLO: no están Lya y Garon")
					quit(1)
					return true
				pasos_antes = v.pasos
				var p := Vector3(-9.0, 0, 9.0)
				v.destino = v._ajustar_destino(Vector3(p.x, v.altura(p.x, p.z), p.z))
				_fase(2)
		2:                                          # juego normal: se cuentan los pasos
			if v.destino == null or frames - f_fase > 300:
				if v.pasos <= pasos_antes:
					fallos.append("en el juego normal no se cuentan los pasos (los encuentros no funcionarían)")
				else:
					print("OK: en el juego normal se cuentan los pasos (%d → %d)" % [pasos_antes, v.pasos])
				_iniciar_medida()
				_preparar_serie()
				_fase(3)
		3:
			v.pasos = 0                             # solo aquí: que un combate no corte las rutas
			_medir()
			if v.destino == null or frames - f_fase > ESPERA_TRAMO:
				if _plana(v.kael.global_position, destinos[tramo]) > 1.5:
					datos["sin_llegar"] += 1        # Kael no puede llegar (no es cosa del grupo)
				tramo += 1
				if tramo < destinos.size():
					_ir()
				else:
					serie += 1
					if serie < SEMILLAS.size():
						_preparar_serie()
					else:
						return _terminar()
	if frames > 40000:
		print("FALLO: la prueba no terminó")
		quit(1)
		return true
	return false


func _iniciar_medida() -> void:
	kael_antes = v.kael.global_position
	for n in v.grupo.nodos():
		previas[n] = n.global_position
		recien[n] = 999


func _al_suelo(p: Vector3) -> float:
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.6, 0), p - Vector3(0, 3.0, 0)))
	return INF if r.is_empty() else absf(r["position"].y - p.y)


func _cruza(a: Vector3, b: Vector3) -> bool:
	if _plana(a, b) < 0.01:
		return false
	var h := maxf(a.y, b.y) + 0.6
	return not v.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(a.x, h, a.z), Vector3(b.x, h, b.z))).is_empty()


func _medir() -> void:
	datos["medidos"] += 1
	var paso_kael := _plana(v.kael.global_position, kael_antes)
	if paso_kael < 2.0:
		datos["metros"] += paso_kael
	kael_antes = v.kael.global_position
	var nodos: Array = v.grupo.nodos()
	var delante: Vector3 = v.kael.global_position
	var todos: Array = [delante]
	for i in nodos.size():
		var n = nodos[i]
		var p: Vector3 = n.global_position
		var antes: Vector3 = previas.get(n, p)
		if _plana(p, antes) > 2.0:                  # ha reaparecido detrás del de delante
			datos["reapariciones"] += 1
			recien[n] = 0
		elif _cruza(antes, p):
			datos["cruza"] += 1
			if datos["cruza"] <= 3:
				print("  %s atraviesa algo entre %s y %s" % [n.name, antes.snapped(Vector3.ONE * 0.1), p.snapped(Vector3.ONE * 0.1)])
		recien[n] += 1
		previas[n] = p
		if v._prohibido(p):
			datos["pisa"] += 1
		if _al_suelo(p) > 0.3:
			datos["flota"] += 1
		var d := _plana(p, delante)
		if recien[n] > 30:
			if i == 0:
				datos["max_lya"] = maxf(datos["max_lya"], d)
			else:
				datos["max_garon"] = maxf(datos["max_garon"], d)
			if d > MAX_DETRAS:
				datos["lejos"] += 1
		delante = p
		todos.append(p)
	for a in todos.size():
		for b in range(a + 1, todos.size()):
			if _plana(todos[a], todos[b]) < 0.4:
				datos["juntos"] += 1


func _terminar() -> bool:
	print("rutas: %d fotogramas y %.0f m andados por Kael · Lya-Kael hasta %.2f m · Garon-Lya hasta %.2f m · pisan %d · fuera del suelo %d · atraviesan %d · lejos %d · juntos %d · reapariciones %d · destinos sin llegar (Kael) %d" % [
		datos["medidos"], datos["metros"], datos["max_lya"], datos["max_garon"], datos["pisa"], datos["flota"], datos["cruza"],
		datos["lejos"], datos["juntos"], datos["reapariciones"], datos["sin_llegar"]])
	if datos["metros"] < 120.0 or datos["sin_llegar"] > 3:
		fallos.append("la prueba no ha recorrido bastante (%.0f m; %d destinos sin llegar)" % [datos["metros"], datos["sin_llegar"]])
	if datos["pisa"] > 0:
		fallos.append("el grupo pisó una zona prohibida en %d fotogramas" % datos["pisa"])
	if datos["flota"] > 0:
		fallos.append("el grupo estuvo fuera del suelo en %d fotogramas" % datos["flota"])
	if datos["cruza"] > 0:
		fallos.append("el grupo atravesó algo en %d fotogramas" % datos["cruza"])
	if datos["lejos"] > 0:
		fallos.append("alguien se quedó a más de %.0f m del de delante en %d fotogramas" % [MAX_DETRAS, datos["lejos"]])
	if datos["juntos"] > datos["medidos"] / 100:
		fallos.append("dos del grupo se atravesaron en %d fotogramas (más del 1 %%)" % datos["juntos"])
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	return true
