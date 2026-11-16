extends Node3D
# CIUDAD DE OAKHAVEN (V12, 16/11, M0; EXPERIMENTAL): UN SECTOR MONTADO. Es el script común de todas las sub-escenas
# zonas3d/ciudad/sectores/<id>/sector.tscn (que solo dicen su «id»): construye el BLOCKOUT desde su trazado (suelos con
# sus rampas como prismas, bloques como cajas, un cuerpo de choque por caja y por suelo, rótulos) y aclara lo ocultable
# que tape a Kael. Lo monta y lo desmonta el cargador (cargador.gd) según la distancia a Kael.
# Cuando un sector tenga su modelo horneado (fase de acabado), su sector.tscn lo llevará como hijo «Modelo» y aquí solo se
# pondrán los choques; hasta entonces, todo en bloques.
#
# Optimización del 16/11 (docs/v12/ciudad_sectores/MEDIDAS_PC.md §6):
#   - TODO el blockout del sector, ocultables incluidos, es UNA malla («Blockout», blockout_opaco.gdshader) con el índice
#     de cada pieza ocultable en UV2.x; lo aclarado se quita de ella y se dibuja en «Aclarados» (blockout_claro.gdshader,
#     alfa 0,28, oculta si no hay nada aclarado). Antes, una malla por ocultable: 1 llamada (2 con algo aclarado) por
#     sector en vez de 10-31. Mismo aspecto y mismo aclarado (mismas reglas, por pieza): aclarado(id) lo dice por pieza.
#   - Las mallas y la lista de choques se calculan con preparar_datos(), que el cargador llama EN UN HILO a la vez que
#     pide la escena (datos); en el fotograma del montaje solo se crean los nodos, y los choques de un sector que no es
#     el de Kael se reparten (CHOQUES_POR_FOTOGRAMA; el de Kael, todos ya: inmediato, terminar_choques).
#   - En el bajo (solo_cerca), rotulos_cerca(): el nombre del sector solo en el sector de Kael y los «(en obras)» solo a
#     menos de ROTULO_PUERTA de Kael; cada rótulo se crea la primera vez que hace falta.

const Blockout := preload("res://zonas3d/ciudad/blockout.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const P := preload("res://zonas3d/ciudad/plano.gd")
const SH_OPACO := preload("res://zonas3d/ciudad/blockout_opaco.gdshader")
const SH_CLARO := preload("res://zonas3d/ciudad/blockout_claro.gdshader")
const MAX_OCULTABLES := 64                 # (el tamaño del uniforme «aclarado» de los dos sombreados; hoy, como mucho 30)

@export var id := ""

var trazado = null
var datos = null                           # lo de preparar_datos(id) hecho en un hilo (cargador.gd); si no, se hace aquí
var solo_cerca := false                    # (cargador.gd, perfil bajo) rótulos solo cerca de Kael: rotulos_cerca()
var inmediato := true                      # (cargador.gd) false: los choques se crean repartidos, CHOQUES_POR_FOTOGRAMA cada vez
var choques := 0                           # cuerpos de choque (suelos + bloques sólidos) ya creados, para las pruebas
const CHOQUES_POR_FOTOGRAMA := 30
var _pendientes: Array = []                # los choques de preparar_datos; se crean de _hechos en adelante
var _hechos := 0
var ocultables: Array = []                 # [[id del bloque, [AABB]]]: se aclaran si tapan a Kael (índice i → UV2.x = i + 1)
var aclarados := 0
var _indice := {}                          # id del bloque ocultable → su índice en «ocultables»
var _estado := PackedFloat32Array()        # por ocultable (MAX_OCULTABLES): 1 aclarado, 0 opaco (el uniforme «aclarado»)
var _mat_opaco: ShaderMaterial
var _mat_claro: ShaderMaterial
var _claros: MeshInstance3D


func _ready() -> void:
	if trazado == null:
		construir()


# LO PESADO, sin nodos (se puede llamar desde un hilo: solo lee el trazado, que es constante): las dos mallas en arrays
# (la opaca con todo y la de los ocultables) y la lista de choques y de ocultables.
static func preparar_datos(id_sector: String) -> Dictionary:
	var t = P.trazado(id_sector)
	if t == null:
		return {}
	var st := Blockout.nueva()
	st.set_uv2(Vector2.ZERO)
	var sc := Blockout.nueva()
	var color: Color = Blockout.COLOR_SUELO.get(id_sector, Blockout.COLOR_FONDO)
	var ocult: Array = []
	var choq: Array = []                   # ["Suelo", puntos] o ["Choque_<id>", AABB]
	for s in t.SUELOS:
		Blockout.suelo(st, s, color)
		choq.append(["Suelo", PackedVector3Array(Blockout.esquinas_suelo(s, Blockout.SOLAPE_SUELO))])
	for b in t.BLOQUES:
		if Comun.ocultable(b, t.OCULTABLES) and ocult.size() < MAX_OCULTABLES:
			ocult.append([String(b[0]), Comun.cajas_bloque(b)])
			var marca := Vector2(float(ocult.size()), 0.0)
			st.set_uv2(marca)
			Blockout.bloque(st, b)
			st.set_uv2(Vector2.ZERO)
			sc.set_uv2(marca)
			Blockout.bloque(sc, b)
		else:
			if Comun.ocultable(b, t.OCULTABLES):
				push_warning("Ciudad: el sector «%s» tiene más de %d ocultables; «%s» no se aclara" % [id_sector, MAX_OCULTABLES, b[0]])
			Blockout.bloque(st, b)
		if b[6]:
			choq.append(["Choque_" + String(b[0]), Comun.cajas_bloque(b)[0]])
	return {"opaco": st.commit_to_arrays(), "claro": sc.commit_to_arrays() if not ocult.is_empty() else [],
		"ocultables": ocult, "choques": choq}


# (Para WorkerThreadPool: deja el resultado en caja[0].)
static func preparar_en(caja: Array, id_sector: String) -> void:
	caja[0] = preparar_datos(id_sector)


func construir() -> void:
	trazado = P.trazado(id)
	if trazado == null:
		push_warning("Ciudad: el sector «%s» no tiene trazado" % id)
		return
	name = "Sector_" + id
	var d: Dictionary = datos if datos is Dictionary and not (datos as Dictionary).is_empty() else preparar_datos(id)
	datos = null
	ocultables = d["ocultables"]
	_indice.clear()
	for i in ocultables.size():
		_indice[ocultables[i][0]] = i
	_estado.resize(MAX_OCULTABLES)
	_estado.fill(0.0)
	_pendientes = d["choques"]
	_hechos = 0
	_crear_choques(_pendientes.size() if inmediato else CHOQUES_POR_FOTOGRAMA)
	set_process(_hechos < _pendientes.size())
	_mat_opaco = ShaderMaterial.new()
	_mat_opaco.shader = SH_OPACO
	add_child(_malla("Blockout", d["opaco"], _mat_opaco))
	if not ocultables.is_empty():
		_mat_claro = ShaderMaterial.new()
		_mat_claro.shader = SH_CLARO
		_claros = _malla("Aclarados", d["claro"], _mat_claro)
		_claros.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_claros.visible = false
		add_child(_claros)
	_rotulos()


func _malla(nombre: String, arrays: Array, mat: Material) -> MeshInstance3D:
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = m
	mi.material_override = mat
	return mi


# Los choques, repartidos: en el montaje de un sector que no es el de Kael, CHOQUES_POR_FOTOGRAMA por fotograma (el sector
# se monta a 25 m: le sobran fotogramas); en el de Kael (inmediato) o si pasa a serlo (terminar_choques), todos a la vez.
func _crear_choques(n: int) -> void:
	var hasta := mini(_pendientes.size(), _hechos + n)
	while _hechos < hasta:
		var c: Array = _pendientes[_hechos]
		_hechos += 1
		if c[1] is AABB:
			_choque_caja(c[0], c[1])
		else:
			_choque_suelo(c[1])


func _process(_delta: float) -> void:
	_crear_choques(CHOQUES_POR_FOTOGRAMA)
	if _hechos >= _pendientes.size():
		set_process(false)


func terminar_choques() -> void:
	if _hechos < _pendientes.size():
		_crear_choques(_pendientes.size())
		set_process(false)


func choques_completos() -> bool:
	return _hechos >= _pendientes.size()


func _choque_suelo(puntos: PackedVector3Array) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Suelo"
	var col := CollisionShape3D.new()
	var forma := ConvexPolygonShape3D.new()
	forma.points = puntos
	col.shape = forma
	cuerpo.add_child(col)
	add_child(cuerpo)
	choques += 1


func _choque_caja(nombre: String, c: AABB) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = c.get_center()
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = c.size
	col.shape = forma
	cuerpo.add_child(col)
	add_child(cuerpo)
	choques += 1


# El nombre del sector sobre su ancla «rotulo» (si no, «referencia») y «<edificio> (en obras)» delante de cada puerta
# prevista. En el bajo (solo_cerca) solo se apuntan y cada uno se crea la primera vez que hace falta (rotulos_cerca): un
# Label3D cuesta al crearlo (su texto se compone al entrar en el árbol) y la mayoría no llegan a verse.
var _rotulo_sector                         # Label3D (o null si aún no se ha creado)
var _def_sector: Array = []                # [nombre, texto, tamaño, posición]
var _rotulos_puerta: Array = []            # [Label3D o null, [nombre, texto, tamaño, posición]]


func _rotulos() -> void:
	var donde := "rotulo" if trazado.ANCLAS.has("rotulo") else "referencia"
	var ref := Comun.ancla(trazado.ANCLAS, trazado.SUELOS, donde)
	_def_sector = ["Rotulo_sector", "%s (maqueta)" % P.SECTORES[id]["nombre"], 52, ref + Vector3(0.0, 6.5, 0.0)]
	_rotulos_puerta.clear()
	for pid in trazado.PUERTAS:
		var d: Dictionary = trazado.PUERTAS[pid]
		var umbral := Comun.ancla(trazado.ANCLAS, trazado.SUELOS, d["ancla"])
		var fuera: Vector3 = d["fuera"]
		var hacia := Vector3(fuera.x - umbral.x, 0.0, fuera.z - umbral.z).normalized()
		_rotulos_puerta.append([null, ["Rotulo_" + String(pid), "%s (en obras)" % d.get("nombre", pid), 40,
			umbral + hacia * 0.9 + Vector3(0.0, 3.0, 0.0)]])
	if solo_cerca:
		return
	_rotulo_sector = _rotulo(_def_sector)
	for x in _rotulos_puerta:
		x[0] = _rotulo(x[1])


const ROTULO_CERCA := 10.0
const ROTULO_PUERTA := 10.0                # (bajo) un «(en obras)» se ve con Kael a menos de esto (en planta)…
const ROTULO_FUNDIDO := 2.0                # … y se funde en los últimos metros (sin aparecer de golpe)
const OPACIDAD := 1.0
const OPACIDAD_CONTORNO := 0.85


# def: [nombre, texto, tamaño, posición]. Cerca de la cámara (Kael unos 14 m al norte del ancla del sector, o en el
# lavadero bajo él) salía enorme y cortado, o por delante del grupo (recorrido, 16/11): no se dibuja a menos de
# ROTULO_CERCA (el título de la pantalla ya dice el sector).
func _rotulo(def: Array) -> Label3D:
	var l := Label3D.new()
	l.name = def[0]
	l.text = def[1]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = def[2]
	l.outline_size = 10
	l.modulate = Color(1.0, 0.94, 0.78, OPACIDAD)
	l.outline_modulate = Color(0.30, 0.14, 0.08, OPACIDAD_CONTORNO)
	l.pixel_size = 0.01
	l.position = def[3]
	l.visibility_range_begin = ROTULO_CERCA
	l.visibility_range_begin_margin = 2.0
	l.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(l)
	return l


# (Bajo) cada fotograma, desde el cargador: el nombre del sector, solo en el sector de Kael; cada «(en obras)», solo con
# Kael a menos de ROTULO_PUERTA (con fundido). En medio y alto (solo_cerca falso) no se llama: se ven todos, como antes.
func rotulos_cerca(kael: Vector3, es_actual: bool) -> void:
	if es_actual and _rotulo_sector == null and not _def_sector.is_empty():
		_rotulo_sector = _rotulo(_def_sector)
	if _rotulo_sector != null and _rotulo_sector.visible != es_actual:
		_rotulo_sector.visible = es_actual
	for x in _rotulos_puerta:
		var q: Vector3 = x[1][3]
		var dist := Vector2(q.x - kael.x, q.z - kael.z).length()
		var a := clampf((ROTULO_PUERTA - dist) / ROTULO_FUNDIDO, 0.0, 1.0)
		var ve := a > 0.0
		if ve and x[0] == null:
			x[0] = _rotulo(x[1])
		var l = x[0]
		if l == null:
			continue
		if l.visible != ve:
			l.visible = ve
		if ve and absf(l.modulate.a - a * OPACIDAD) > 0.01:
			l.modulate.a = a * OPACIDAD
			l.outline_modulate.a = a * OPACIDAD_CONTORNO


# Aclara lo ocultable que corta algún segmento desde (la cámara) → cada uno de «puntos» (la cabeza, la cintura, los pies
# y los lados de Kael y la cintura, la cabeza y los pies del grupo cercano: ciudad.gd, _oclusion) o que está a menos de
# CERCA_CAMARA de la cámara (con Kael junto a la muralla sur, la cámara queda encima de la puerta y sus torres llenaban
# los lados del cuadro), y devuelve a opaco lo demás. Lo aclarado sigue aclarado SOSTEN segundos (de juego, «ahora»)
# después de dejar de tapar: andando, el rayo entraba y salía del borde de una caja y la pieza parpadeaba (recorrido,
# 16/11). Devuelve cuántas quedan aclaradas. Aclarar una pieza: su índice a 1 en el uniforme «aclarado» de los dos
# materiales (sale de «Blockout» y entra en «Aclarados»; antes, la copia transparente del material en su propia malla).
# (Recorrido, 16/11: con solo la cabeza, una hoja de puerta, una lona o un arco tapaban a Kael de los hombros abajo, y
# al grupo entero, sin aclararse.)
const CERCA_CAMARA := 6.0
const SOSTEN := 1.0
var _tapo_en := PackedFloat64Array()       # por ocultable: el último momento en que tapó


func aclarar(desde: Vector3, puntos, ahora := 0.0) -> int:
	if puntos is Vector3:
		puntos = [puntos]
	aclarados = 0
	if _tapo_en.size() != ocultables.size():
		_tapo_en.resize(ocultables.size())
		_tapo_en.fill(-INF)
	var zona := AABB(desde, Vector3.ZERO)          # lo que abarcan todos los segmentos (descarta deprisa)
	for p in puntos:
		zona = zona.expand(p)
	zona = zona.grow(0.01)
	var cambia := false
	for i in ocultables.size():
		var o: Array = ocultables[i]
		var tapa := false
		for c in o[1]:
			var caja := c as AABB
			var cerca := Vector3(clampf(desde.x, caja.position.x, caja.end.x), clampf(desde.y, caja.position.y, caja.end.y),
				clampf(desde.z, caja.position.z, caja.end.z))
			if cerca.distance_to(desde) < CERCA_CAMARA:
				tapa = true
				break
			if not caja.intersects(zona):
				continue
			for p in puntos:
				if caja.intersects_segment(desde, p):
					tapa = true
					break
			if tapa:
				break
		if tapa:
			_tapo_en[i] = ahora
		elif ahora - _tapo_en[i] < SOSTEN:
			tapa = true
		var valor := 1.0 if tapa else 0.0
		if _estado[i] != valor:
			_estado[i] = valor
			cambia = true
		if tapa:
			aclarados += 1
	if cambia:
		_mat_opaco.set_shader_parameter("aclarado", _estado)
		_mat_claro.set_shader_parameter("aclarado", _estado)
	if _claros != null and _claros.visible != (aclarados > 0):
		_claros.visible = aclarados > 0
	return aclarados


# ¿Está aclarada ahora la pieza ocultable «bloque» (id del bloque)? (Lo que no es ocultable, nunca.)
func aclarado(bloque: String) -> bool:
	var i: int = _indice.get(bloque, -1)
	return i >= 0 and _estado[i] > 0.5


# Sin el sostén (Kael colocado de golpe en otro sitio: lo de antes no ha de seguir aclarado).
func olvidar_aclarados() -> void:
	_tapo_en.fill(-INF)
