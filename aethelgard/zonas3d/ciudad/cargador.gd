extends Node3D
# CIUDAD DE OAKHAVEN (V12, 16/11, M0; EXPERIMENTAL): EL CARGADOR POR PROXIMIDAD. Cada sector es una sub-escena
# (zonas3d/ciudad/sectores/<id>/sector.tscn, con sector.gd). Según la distancia en planta de Kael a la CAJA de cada sector
# (plano.gd, SECTORES):
#   - a menos de RADIO_PRECARGA (40 m) se pide su escena en un hilo (ResourceLoader.load_threaded_request);
#   - a menos de RADIO_MONTAJE (25 m) se MONTA (se instancia y se añade); el sector donde está Kael, siempre (si su carga no
#     ha terminado, se espera a ella: es lo único que bloquea);
#   - se DESMONTA al pasar de RADIO_DESCARGA (60 m): histéresis de 35 m con el montaje; y su escena se suelta;
#   - como mucho MAXIMO[perfil] montados a la vez (bajo 3: el actual y los vecinos más cercanos; medio 5; alto, los 8). Si
#     sobran, se queda el actual y los más cercanos; uno montado tiene MARGEN_CAMBIO metros de ventaja, para que dos
#     sectores a la misma distancia no se turnen a cada paso.
# Lo que no está montado se ve como MAQUETA LEJANA: una malla barata por sector (sus suelos y sus bloques altos, sin
# choques), creada al empezar desde los trazados, que se oculta mientras su sector está montado. Así se ve siempre la
# ciudad entera (el Árbol Milenario desde cualquier sitio).
# NUNCA carga interiores: solo pide las rutas de sector.tscn (las pruebas lo comprueban en «pedidos»); las puertas son
# previstas y la escena dice «Aún no se puede entrar (en obras).».
# Presupuestos del plan (§5, A MEDIR; ninguna cifra de Android sin el Redmi): bajo ≤ 65 llamadas y ≤ 160 mil primitivas.
# Optimización del 16/11 (docs/v12/ciudad_sectores/MEDIDAS_PC.md §6): a la vez que se pide la escena en hilo, sus mallas
# y su lista de choques se preparan en otro hilo (WorkerThreadPool, sector.gd preparar_datos); el sector cuenta como
# «cargado» cuando están las dos cosas; en el fotograma del montaje solo se crean los nodos (y, salvo en el
# sector de Kael y en los que están a menos de RADIO_INMEDIATO de él, los choques se reparten en unos fotogramas:
# sector.gd, inmediato). En el bajo, los rótulos de los
# sectores montados solo cerca de Kael (sector.gd, rotulos_cerca). (Tarea de prioridad alta: dura 2-4 ms en el PC; con
# prioridad baja, con el PC ocupado, la prueba B la vio sin terminar en 60 fotogramas.)

const P := preload("res://zonas3d/ciudad/plano.gd")
const Blockout := preload("res://zonas3d/ciudad/blockout.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const Sector := preload("res://zonas3d/ciudad/sector.gd")
const PREPARAR_EN_HILO := true             # (para medir) false: las mallas se hacen en el fotograma del montaje, como antes
const ROTULOS_CERCA := ["bajo"]            # perfiles con los rótulos solo cerca de Kael

const RADIO_PRECARGA := 40.0
const RADIO_MONTAJE := 25.0
const RADIO_DESCARGA := 60.0
const MARGEN_CAMBIO := 5.0
# (16/11, revisión) un sector montado a menos de esto de Kael recibe TODOS sus choques en el montaje (y, si se acerca,
# en cuanto lo está), no repartidos: en un cruce del bajo, o con Kael colocado junto a un borde, el vecino entraba con
# Kael a menos de 1 m y sus paredes de la linde pasaban 1-4 fotogramas sin cuerpo (se podían cruzar y un toque las
# atravesaba). Los que se montan de lejos (lo normal, a RADIO_MONTAJE) siguen repartidos.
const RADIO_INMEDIATO := 6.0
const MAXIMO := {"bajo": 3, "medio": 5, "alto": 8}
const ALTO_LEJANA := 1.5                   # en la maqueta lejana, solo los bloques de al menos este alto (y los suelos)
const RUTA := "res://zonas3d/ciudad/sectores/%s/sector.tscn"

signal sector_montado(id: String)
signal sector_desmontado(id: String)

var perfil := "alto"
var estado := {}                           # id → "lejos" | "cargando" | "cargado" | "error"
var escenas := {}                          # id → PackedScene (cargada y aún cerca)
var montados := {}                         # id → Node3D (el sector montado)
var lejanas := {}                          # id → MeshInstance3D (maqueta lejana)
var distancias := {}                       # id → m (la última actualización)
var actual := ""                           # el sector de Kael
var pedidos: Array = []                    # todas las rutas pedidas en hilo o cargadas (para las pruebas)
var montajes := 0                          # (para las pruebas) cuántas veces se ha montado y desmontado algo
var desmontajes := 0
var esperas := 0                           # cuántas veces hubo que esperar a una carga (el sector de Kael sin terminar)
var datos := {}                            # id → lo preparado en hilo (sector.gd, preparar_datos), con su escena
var _tareas := {}                          # id → [tarea de WorkerThreadPool, caja con el resultado]


static func ruta_escena(id: String) -> String:
	return RUTA % id


func preparar(nombre_perfil: String, con_lejana := true) -> void:
	perfil = nombre_perfil if MAXIMO.has(nombre_perfil) else "bajo"
	for id in P.ORDEN:
		estado[id] = "lejos"
		distancias[id] = INF
	if con_lejana:
		_crear_lejanas()


func maximo() -> int:
	return int(MAXIMO.get(perfil, 3))


# ---------------------------------------------------------------------------------------------------- maqueta lejana

func _crear_lejanas() -> void:
	var raiz := Node3D.new()
	raiz.name = "Lejana"
	add_child(raiz)
	for id in P.ORDEN:
		var t = P.trazado(id)
		var st := Blockout.nueva()
		var color: Color = Blockout.COLOR_SUELO.get(id, Blockout.COLOR_FONDO)
		for s in t.SUELOS:
			Blockout.suelo(st, s, color.darkened(0.08))
		for b in t.BLOQUES:
			if float(b[4]) >= ALTO_LEJANA and String(b[5]) != "puerta":
				Blockout.bloque(st, b)
		var mi := Blockout.malla(st, "Lejana_" + id)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi)
		lejanas[id] = mi


# ---------------------------------------------------------------------------------------------------- cada paso

# Con Kael en p: pide, monta y desmonta. «forzar»: el sector de Kael se monta ya (al entrar o al colocar a Kael).
func actualizar(p: Vector3, _forzar := false) -> void:
	var k := Vector2(p.x, p.z)
	actual = P.sector_de(p.x, p.z)
	for id in P.ORDEN:
		distancias[id] = P.distancia_a_sector(id, k)
	for id in P.ORDEN:                                  # precarga en hilo
		if estado[id] == "lejos" and float(distancias[id]) < RADIO_PRECARGA:
			_pedir(id)
	_sondear()
	var quedan := _deseados()
	for id in montados.keys():
		if not id in quedan:
			_desmontar(id)
	for id in quedan:
		if montados.has(id):
			continue
		if estado[id] == "cargado" or id == actual:     # (el actual, aunque haya que esperar a su carga)
			_montar(id)
	for id in P.ORDEN:                                  # lo lejos y desmontado suelta su escena
		if not montados.has(id) and float(distancias[id]) > RADIO_DESCARGA and estado[id] == "cargado":
			escenas.erase(id)
			datos.erase(id)
			estado[id] = "lejos"
	for id in lejanas:
		(lejanas[id] as Node3D).visible = not montados.has(id)
	for id in montados:                                 # (el sector de Kael y los que tiene pegados: todos sus choques ya)
		if id == actual or float(distancias[id]) < RADIO_INMEDIATO:
			(montados[id] as Node).terminar_choques()
	if perfil in ROTULOS_CERCA:
		for id in montados:
			(montados[id] as Node).rotulos_cerca(p, id == actual)
	else:                                               # (18/11) medio y alto: los «(en obras)» cercanos, encima (sector.gd)
		for id in montados:
			(montados[id] as Node).rotulos_delante(p)


# Los que deben estar montados: el actual y, por cercanía (con ventaja para los ya montados), los ya montados a menos de
# RADIO_DESCARGA y los que están a menos de RADIO_MONTAJE con su carga ya terminada (uno que aún carga no echa a otro: si
# no, en el bajo se desmontaba un vecino para dejar un hueco que nadie ocupaba); como mucho maximo().
func _deseados() -> Array:
	var cand: Array = []
	for id in P.ORDEN:
		var d: float = distancias[id]
		if id == actual or (montados.has(id) and d <= RADIO_DESCARGA) or (d < RADIO_MONTAJE and estado[id] == "cargado"):
			cand.append(id)
	cand.sort_custom(func(a, b): return _clave(a) < _clave(b))
	return cand.slice(0, maximo())


func _clave(id: String) -> float:
	if id == actual:
		return -INF
	return float(distancias[id]) - (MARGEN_CAMBIO if montados.has(id) else 0.0)


func _pedir(id: String) -> void:
	var ruta := ruta_escena(id)
	if ResourceLoader.load_threaded_request(ruta, "PackedScene") == OK:
		estado[id] = "cargando"
		pedidos.append(ruta)
		# (16/11) a la vez, sus mallas y sus choques en otro hilo: solo necesitan el trazado, no la escena
		if PREPARAR_EN_HILO and not datos.has(id) and not _tareas.has(id):
			var caja := [null]
			_tareas[id] = [WorkerThreadPool.add_task(Sector.preparar_en.bind(caja, id), true, "ciudad: " + id), caja]
	else:
		estado[id] = "error"
		push_warning("Ciudad: no se pudo pedir %s" % ruta)


# «cargando» dura hasta tener la escena (carga en hilo) Y sus datos (preparados en otro hilo, a la vez).
func _sondear() -> void:
	for id in P.ORDEN:
		if estado[id] != "cargando":
			continue
		if not escenas.has(id):
			var e := ResourceLoader.load_threaded_get_status(ruta_escena(id))
			if e == ResourceLoader.THREAD_LOAD_LOADED:
				_recoger(id)
			elif e == ResourceLoader.THREAD_LOAD_FAILED or e == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_fallo(id)
			continue
		_recoger(id)


# Recoge la escena (si aún no ha terminado, espera) y sus datos si ya están; con «esperar», espera también a ellos.
func _recoger(id: String, esperar := false) -> void:
	if not escenas.has(id):
		var r = ResourceLoader.load_threaded_get(ruta_escena(id))
		if not r is PackedScene:
			_fallo(id)
			return
		escenas[id] = r
	if _tareas.has(id) and (esperar or WorkerThreadPool.is_task_completed(_tareas[id][0])):
		_terminar_datos(id)
	if not _tareas.has(id):
		estado[id] = "cargado"


func _terminar_datos(id: String) -> void:
	var t: Array = _tareas[id]
	_tareas.erase(id)
	WorkerThreadPool.wait_for_task_completion(t[0])
	if t[1][0] is Dictionary and not (t[1][0] as Dictionary).is_empty():
		datos[id] = t[1][0]


func _fallo(id: String) -> void:
	estado[id] = "error"
	if _tareas.has(id):                              # (toda tarea se espera: WorkerThreadPool)
		_terminar_datos(id)


func _montar(id: String) -> void:
	if estado[id] == "lejos":
		_pedir(id)
	if estado[id] == "cargando":
		esperas += 1
		_recoger(id, true)
	if not escenas.has(id):
		return
	var s: Node3D = (escenas[id] as PackedScene).instantiate()
	s.datos = datos.get(id)
	s.solo_cerca = perfil in ROTULOS_CERCA
	s.inmediato = id == actual or float(distancias.get(id, INF)) < RADIO_INMEDIATO   # (los demás: repartidos, sector.gd)
	add_child(s)
	montados[id] = s
	montajes += 1
	if lejanas.has(id):
		(lejanas[id] as Node3D).visible = false
	sector_montado.emit(id)


func _desmontar(id: String) -> void:
	var s: Node3D = montados[id]
	montados.erase(id)
	remove_child(s)
	s.queue_free()
	desmontajes += 1
	if lejanas.has(id):
		(lejanas[id] as Node3D).visible = true
	sector_desmontado.emit(id)


# Todo fuera (al salir de la escena o en las pruebas). Las cargas en curso se recogen para no dejarlas colgadas.
func desmontar_todo() -> void:
	for id in montados.keys():
		_desmontar(id)
	for id in P.ORDEN:
		if estado.get(id, "") == "cargando":
			_recoger(id, true)
	escenas.clear()
	datos.clear()
	for id in P.ORDEN:
		estado[id] = "lejos"


func _exit_tree() -> void:
	for id in P.ORDEN:                              # (una carga en hilo sin recoger quedaría en el cargador de Godot; una
		if estado.get(id, "") == "cargando":        # tarea sin esperar, en WorkerThreadPool)
			_recoger(id, true)


# Los sectores montados (ids), en el orden del plano.
func ids_montados() -> Array:
	return P.ORDEN.filter(func(id): return montados.has(id))


# Aclara en los sectores montados lo ocultable que corta los rayos de la cámara a «puntos» (Kael y el grupo: sector.gd).
func aclarar(desde: Vector3, puntos, ahora := 0.0) -> int:
	var n := 0
	for id in montados:
		n += (montados[id] as Node).aclarar(desde, puntos, ahora)
	return n


func olvidar_aclarados() -> void:
	for id in montados:
		(montados[id] as Node).olvidar_aclarados()
