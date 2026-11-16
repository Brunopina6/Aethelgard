extends Node3D
# CIUDAD DE OAKHAVEN (V12, 16/11, M0; EXPERIMENTAL): UN SECTOR MONTADO. Es el script común de todas las sub-escenas
# zonas3d/ciudad/sectores/<id>/sector.tscn (que solo dicen su «id»): construye el BLOCKOUT desde su trazado (suelos con
# sus rampas como prismas, bloques como cajas, un cuerpo de choque por caja y por suelo, rótulos) y aclara lo ocultable
# que tape a Kael. Lo monta y lo desmonta el cargador (cargador.gd) según la distancia a Kael.
# Cuando un sector tenga su modelo horneado (fase de acabado), su sector.tscn lo llevará como hijo «Modelo» y aquí solo se
# pondrán los choques; hasta entonces, todo en bloques.

const Blockout := preload("res://zonas3d/ciudad/blockout.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const P := preload("res://zonas3d/ciudad/plano.gd")

@export var id := ""

var trazado = null
var choques := 0                           # cuerpos de choque (suelos + bloques sólidos), para las pruebas
var ocultables: Array = []                 # [[MeshInstance3D, [AABB]]]: se aclaran si tapan a Kael
var aclarados := 0


func _ready() -> void:
	if trazado == null:
		construir()


func construir() -> void:
	trazado = P.trazado(id)
	if trazado == null:
		push_warning("Ciudad: el sector «%s» no tiene trazado" % id)
		return
	name = "Sector_" + id
	var st := Blockout.nueva()
	var color: Color = Blockout.COLOR_SUELO.get(id, Blockout.COLOR_FONDO)
	for s in trazado.SUELOS:
		Blockout.suelo(st, s, color)
		_choque_suelo(s)
	for b in trazado.BLOQUES:
		if Comun.ocultable(b, trazado.OCULTABLES):
			var so := Blockout.nueva()
			Blockout.bloque(so, b)
			var mi := Blockout.malla(so, "Ocultable_" + String(b[0]))
			add_child(mi)
			ocultables.append([mi, Comun.cajas_bloque(b)])
		else:
			Blockout.bloque(st, b)
		if b[6]:
			_choque_caja(String(b[0]), Comun.cajas_bloque(b)[0])
	add_child(Blockout.malla(st, "Blockout"))
	_rotulos()


func _choque_suelo(s: Array) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Suelo"
	var col := CollisionShape3D.new()
	var forma := ConvexPolygonShape3D.new()
	forma.points = PackedVector3Array(Blockout.esquinas_suelo(s, Blockout.SOLAPE_SUELO))
	col.shape = forma
	cuerpo.add_child(col)
	add_child(cuerpo)
	choques += 1


func _choque_caja(nombre: String, c: AABB) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Choque_" + nombre
	cuerpo.position = c.get_center()
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = c.size
	col.shape = forma
	cuerpo.add_child(col)
	add_child(cuerpo)
	choques += 1


# El nombre del sector sobre su ancla «rotulo» (si no, «referencia») y «<edificio> (en obras)» delante de cada puerta
# prevista.
func _rotulos() -> void:
	var donde := "rotulo" if trazado.ANCLAS.has("rotulo") else "referencia"
	var ref := Comun.ancla(trazado.ANCLAS, trazado.SUELOS, donde)
	var l := _rotulo("Rotulo_sector", "%s (maqueta)" % P.SECTORES[id]["nombre"], 52)
	l.position = ref + Vector3(0.0, 6.5, 0.0)
	# cerca de la cámara (Kael unos 14 m al norte de su ancla, o en el lavadero bajo él) salía enorme y cortado, o por
	# delante del grupo (recorrido, 16/11): no se dibuja a menos de ROTULO_CERCA (el título de la pantalla ya dice el sector)
	l.visibility_range_begin = ROTULO_CERCA
	l.visibility_range_begin_margin = 2.0
	l.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for pid in trazado.PUERTAS:
		var d: Dictionary = trazado.PUERTAS[pid]
		var umbral := Comun.ancla(trazado.ANCLAS, trazado.SUELOS, d["ancla"])
		var fuera: Vector3 = d["fuera"]
		var hacia := Vector3(fuera.x - umbral.x, 0.0, fuera.z - umbral.z).normalized()
		var lp := _rotulo("Rotulo_" + String(pid), "%s (en obras)" % d.get("nombre", pid), 40)
		lp.position = umbral + hacia * 0.9 + Vector3(0.0, 3.0, 0.0)
		lp.visibility_range_begin = ROTULO_CERCA
		lp.visibility_range_begin_margin = 2.0
		lp.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


const ROTULO_CERCA := 10.0


func _rotulo(nombre: String, texto: String, tam: int) -> Label3D:
	var l := Label3D.new()
	l.name = nombre
	l.text = texto
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = tam
	l.outline_size = 10
	l.modulate = Color(1.0, 0.94, 0.78)
	l.outline_modulate = Color(0.30, 0.14, 0.08, 0.85)
	l.pixel_size = 0.01
	add_child(l)
	return l


# Aclara (copia medio transparente del material) lo ocultable que corta algún segmento desde (la cámara) → cada uno de
# «puntos» (la cabeza, la cintura, los pies y los lados de Kael y la cintura, la cabeza y los pies del grupo cercano:
# ciudad.gd, _oclusion) o que está a menos de CERCA_CAMARA de la cámara (con Kael junto a la muralla sur, la cámara
# queda encima de la puerta y sus torres llenaban los lados del cuadro), y devuelve a opaco lo demás. Lo aclarado sigue
# aclarado SOSTEN segundos (de juego, «ahora») después de dejar de tapar: andando, el rayo entraba y salía del borde de
# una caja y la pieza parpadeaba (recorrido, 16/11). Devuelve cuántas quedan aclaradas.
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
		var mi: MeshInstance3D = o[0]
		mi.material_override = Blockout.material(tapa)
		if tapa:
			aclarados += 1
	return aclarados


# Sin el sostén (Kael colocado de golpe en otro sitio: lo de antes no ha de seguir aclarado).
func olvidar_aclarados() -> void:
	_tapo_en.fill(-INF)
