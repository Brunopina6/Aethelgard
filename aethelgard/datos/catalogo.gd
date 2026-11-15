extends RefCounted
# Catálogo de datos (fase 2, 10/11): lee los recursos de res://datos/<tipo>/ (un .tres por cosa) y comprueba que
# encajan entre sí. Añadir contenido = añadir un archivo, sin tocar los scripts grandes.
#   Catalogo.todos("materiales")           → {id: recurso}
#   Catalogo.uno("recetas", "pocion_menor") → el recurso o null
#   Catalogo.validar()                      → lista de errores (vacía si todo está bien); lo usa prueba_datos
# Funciona también en la APK: ResourceLoader.list_directory ve los recursos exportados.
# Tipos de hoy: materiales (en uso: botín y tienda), recetas e investigaciones (base de los talleres, aún sin jugar).

const TIPOS := ["materiales", "recetas", "investigaciones"]
# Los tres talleres previstos (fase 3) y quién lleva cada uno.
const TALLERES := {"alquimia": "Lya", "forja": "Kael", "armaduras": "Garon", "conjunto": "Kael, Lya y Garon",
	"arcano": "la maga negra (V12, fase E: estudiar hechizos; sin pantalla hasta que llegue)"}
const REQUISITOS := ["material", "hito", "investigacion", "nivel"]
const HEROES := ["Kael", "Lya", "Garon"]

static var _cache := {}
# Las pruebas pueden leer otra carpeta con datos de ejemplo (usar_raiz); el juego, siempre res://datos/.
static var raiz := "res://datos/"


static func usar_raiz(r: String) -> void:
	raiz = r
	_cache.clear()


static func carpeta(tipo: String) -> String:
	return raiz + tipo + "/"


static func todos(tipo: String) -> Dictionary:
	if _cache.has(tipo):
		return _cache[tipo]
	var r := {}
	for f in _archivos(tipo):
		var d = load(f)
		if d is Resource and str(d.get("id")) != "" and not r.has(d.get("id")):
			r[d.get("id")] = d
	_cache[tipo] = r
	return r


static func uno(tipo: String, id: String) -> Resource:
	return todos(tipo).get(id)


# Para las pruebas: vuelve a leer los archivos.
static func olvidar() -> void:
	_cache.clear()


static func _archivos(tipo: String) -> PackedStringArray:
	var r := PackedStringArray()
	var c := carpeta(tipo)
	if not DirAccess.dir_exists_absolute(c) and ResourceLoader.list_directory(c).is_empty():
		return r
	for n in ResourceLoader.list_directory(c):
		if n.get_extension() in ["tres", "res"]:
			r.append(c + n)
	return r


static func _id_valido(id: String) -> bool:
	if id == "":
		return false
	for ch in id:
		if not (ch >= "a" and ch <= "z" or ch >= "0" and ch <= "9" or ch == "_"):
			return false
	return true


# Todos los errores de los datos: ids vacíos, repetidos o mal escritos, campos que faltan y referencias a cosas que
# no existen. Cada error, una frase con el archivo.
static func validar() -> Array:
	var errores: Array = []
	var por_tipo := {}
	for tipo in TIPOS:
		var vistos := {}
		for f in _archivos(tipo):
			var d = load(f)
			if not d is Resource or d.get("id") == null:
				errores.append("%s: no es un recurso de datos" % f)
				continue
			var id := str(d.get("id"))
			if not _id_valido(id):
				errores.append("%s: id «%s» no válido (minúsculas, cifras y _)" % [f, id])
			if vistos.has(id):
				errores.append("%s: id «%s» repetido (también en %s)" % [f, id, vistos[id]])
			vistos[id] = f
		por_tipo[tipo] = vistos
	var mats := todos("materiales")
	var claves := {}
	for id in mats:
		var m: Resource = mats[id]
		if m.clave_inventario == "" or m.nombre == "":
			errores.append("material «%s»: falta clave_inventario o nombre" % id)
		if claves.has(m.clave_inventario):
			errores.append("material «%s»: clave de inventario «%s» repetida" % [id, m.clave_inventario])
		claves[m.clave_inventario] = id
		if m.venta < 0:
			errores.append("material «%s»: venta negativa" % id)
	var recetas := todos("recetas")
	var invs := todos("investigaciones")
	for id in recetas:
		var r: Resource = recetas[id]
		if not TALLERES.has(r.taller):
			errores.append("receta «%s»: taller «%s» desconocido" % [id, r.taller])
		if r.materiales.is_empty():
			errores.append("receta «%s»: no gasta ningún material" % id)
		for clave in r.materiales:
			if not claves.has(clave):
				errores.append("receta «%s»: el material «%s» no existe" % [id, clave])
			elif int(r.materiales[clave]) <= 0:
				errores.append("receta «%s»: cantidad de «%s» no positiva" % [id, clave])
		if r.resultado == "" or r.cantidad <= 0:
			errores.append("receta «%s»: sin resultado o con cantidad no positiva" % id)
		if r.investigacion != "" and not invs.has(r.investigacion):
			errores.append("receta «%s»: la investigación «%s» no existe" % [id, r.investigacion])
	for id in invs:
		var v: Resource = invs[id]
		if not TALLERES.has(v.taller):
			errores.append("investigación «%s»: taller «%s» desconocido" % [id, v.taller])
		if v.pasos <= 0:
			errores.append("investigación «%s»: pasos no positivos" % id)
		for rid in v.desbloquea:
			if str(rid).begins_with("magia:"):        # V12, fase E: un hechizo (magia_negra.gd), no una receta
				if not load("res://magia_negra.gd").desbloqueo_valido(str(rid)):
					errores.append("investigación «%s»: desbloquea la magia «%s», que no existe" % [id, rid])
				continue
			if not recetas.has(rid):
				errores.append("investigación «%s»: desbloquea la receta «%s», que no existe" % [id, rid])
		for q in v.requisitos:
			errores.append_array(_errores_requisito(id, q, claves, invs))
	for ciclo in ciclos_investigacion(invs):          # 15/11: A → B → A y ciclos más largos
		errores.append("investigaciones en ciclo de requisitos: %s" % " → ".join(ciclo + [ciclo[0]]))
	return errores


# 15/11 (auditoría externa): los ciclos de requisitos «investigacion» (A pide B, B pide A, o más largos). Cada ciclo,
# con sus ids en orden (sin repetir el primero), y cada uno una sola vez. Una que se pide a sí misma también es un
# ciclo. Búsqueda en profundidad con «en curso» / «hecho».
static func ciclos_investigacion(invs: Dictionary) -> Array:
	var marca := {}
	var ciclos: Array = []
	var vistos := {}
	var ids: Array = invs.keys()
	ids.sort()
	for id in ids:
		_visitar(str(id), invs, marca, [], ciclos, vistos)
	return ciclos


static func _visitar(id: String, invs: Dictionary, marca: Dictionary, camino: Array, ciclos: Array, vistos: Dictionary) -> void:
	if int(marca.get(id, 0)) == 2:
		return
	if int(marca.get(id, 0)) == 1:
		var ciclo: Array = camino.slice(camino.find(id))
		var clave := ciclo.duplicate()
		clave.sort()
		if not vistos.has(str(clave)):
			vistos[str(clave)] = true
			ciclos.append(ciclo)
		return
	marca[id] = 1
	camino.append(id)
	var v = invs.get(id)
	if v != null:
		for q in v.requisitos:
			if q is Dictionary and str(q.get("tipo", "")) == "investigacion" and invs.has(str(q.get("id", ""))):
				_visitar(str(q.get("id", "")), invs, marca, camino, ciclos, vistos)
	camino.pop_back()
	marca[id] = 2


# Los ids que están en algún ciclo (investigacion.gd los da por bloqueados sin recorrerlos: así no se cuelga aunque
# un dato mal escrito llegue a la APK). Se calcula una vez por catálogo cargado.
static func en_ciclo(id: String) -> bool:
	if not _cache.has("_en_ciclo"):
		var malos := {}
		for c in ciclos_investigacion(todos("investigaciones")):
			for x in c:
				malos[x] = true
		if not malos.is_empty():
			push_error("Catálogo: investigaciones en ciclo de requisitos: %s" % str(malos.keys()))
		_cache["_en_ciclo"] = malos
	return _cache["_en_ciclo"].has(id)


static func _errores_requisito(id: String, q, claves: Dictionary, invs: Dictionary) -> Array:
	if not q is Dictionary or not q.get("tipo", "") in REQUISITOS:
		return ["investigación «%s»: requisito no válido %s" % [id, q]]
	match q["tipo"]:
		"material":
			if not claves.has(str(q.get("id", ""))) or int(q.get("cantidad", 0)) <= 0:
				return ["investigación «%s»: requisito de material no válido %s" % [id, q]]
		"hito":
			if str(q.get("id", "")) == "":
				return ["investigación «%s»: requisito de hito sin id" % id]
		"investigacion":
			var otra := str(q.get("id", ""))
			if not invs.has(otra) or otra == id:
				return ["investigación «%s»: requiere «%s», que no existe o es ella misma" % [id, otra]]
		"nivel":
			if not q.get("heroe", "") in HEROES or int(q.get("nivel", 0)) <= 0:
				return ["investigación «%s»: requisito de nivel no válido %s" % [id, q]]
	return []
