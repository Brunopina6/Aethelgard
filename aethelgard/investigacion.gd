extends RefCounted
# Investigaciones de los talleres (fase 2, 10/11): base técnica compartida por los talleres de Lya (alquimia), Kael
# (forja) y Garon (armaduras). Aún sin pantalla ni efectos en el juego: lo jugable llega en la fase 3, con el diseño
# aprobado (docs/fase2_optimizacion/FASE3_TALLERES.md).
#   Datos: res://datos/investigaciones/*.tres (datos/tipos/investigacion.gd), leídos con datos/catalogo.gd.
#   Avance: en la partida, clave «investigaciones» (progreso.gd CLAVES) = {id: {"progreso": n, "completada": bool}}.
#     Una partida antigua no la tiene y empieza vacía; un id que ya no existe se conserva tal cual (no se borra nada).
#   Estados: «bloqueada» (faltan requisitos), «disponible», «en_curso» y «completada».
# Empezar NO gasta materiales: «tener» es el requisito. Cuánto cuesta investigar se decide en la fase 3.
# V12, fase E: «estudiar hechizos / conocimientos antiguos» es una categoría más, no un sistema aparte. Una
# investigación (taller «arcano») desbloquea magia con «magia:<escuela>:<nivel>» en su mismo campo «desbloquea»
# (magia_negra.gd). Se guarda igual que las demás (clave «investigaciones»): una partida antigua no sabe nada nuevo.

const Catalogo := preload("res://datos/catalogo.gd")


static func _partida() -> Dictionary:
	if not Engine.has_meta("investigaciones") or not Engine.get_meta("investigaciones") is Dictionary:
		Engine.set_meta("investigaciones", {})
	return Engine.get_meta("investigaciones")


static func _datos(id: String) -> Resource:
	return Catalogo.uno("investigaciones", id)


# Motivos por los que aún no se puede empezar (vacío = se puede). Frases para el jugador.
static func faltan(id: String) -> Array:
	var v := _datos(id)
	if v == null:
		return ["No existe esa investigación."]
	var r: Array = []
	for q in v.requisitos:
		match str(q.get("tipo", "")):
			"material":
				var tiene: int = load("res://inventario.gd").cantidad(str(q["id"]))
				if tiene < int(q["cantidad"]):
					r.append("Hace falta tener %s (%d de %d). No se gasta." % [q["id"], tiene, int(q["cantidad"])])
			"hito":
				if not load("res://progreso.gd").hito(str(q["id"])):
					r.append(str(q.get("pista", "Aún no es el momento.")))
			"investigacion":
				if estado(str(q["id"])) != "completada":
					var otra := _datos(str(q["id"]))
					r.append("Antes hay que investigar %s." % (otra.nombre if otra != null else q["id"]))
			"nivel":
				var g: Dictionary = load("res://grupo.gd").datos()
				var nivel: int = int(g.get(q["heroe"], {}).get("nivel", 0))
				if nivel < int(q["nivel"]):
					r.append("%s necesita el nivel %d." % [q["heroe"], int(q["nivel"])])
			_:
				r.append("Requisito desconocido.")
	return r


# 14/11: ¿sale en la pantalla del taller? (su «si»; empezada o completada, siempre). Solo es lo que se ENSEÑA: no cambia
# lo que se puede hacer.
static func visible(id: String) -> bool:
	var v := _datos(id)
	if v == null:
		return false
	if _partida().has(id) or str(v.get("si")) == "" or v.get("si") == null:
		return true
	return load("res://encargos.gd").cumple(str(v.si))


static func estado(id: String) -> String:
	if _datos(id) == null:
		return ""
	var p: Dictionary = _partida().get(id, {})
	if p.get("completada", false):
		return "completada"
	if p.has("progreso"):
		return "en_curso"
	return "disponible" if faltan(id).is_empty() else "bloqueada"


# Empieza una investigación. Devuelve "" si empezó o el primer motivo por el que no.
static func empezar(id: String) -> String:
	var e := estado(id)
	if e == "":
		return "No existe esa investigación."
	if e == "en_curso" or e == "completada":
		return "Ya está %s." % ("en curso" if e == "en_curso" else "completada")
	var f := faltan(id)
	if not f.is_empty():
		return f[0]
	_partida()[id] = {"progreso": 0, "completada": false}
	return ""


# Suma avances a una investigación en curso; al llegar a sus «pasos», queda completada. Devuelve si se completó ahora.
static func avanzar(id: String, n := 1) -> bool:
	var v := _datos(id)
	if v == null or estado(id) != "en_curso" or n <= 0:
		return false
	var p: Dictionary = _partida()[id]
	p["progreso"] = mini(int(p["progreso"]) + n, v.pasos)
	if int(p["progreso"]) >= v.pasos:
		p["completada"] = true
		return true
	return false


static func completadas() -> Array:
	var r: Array = []
	for id in _partida():
		if _partida()[id].get("completada", false):
			r.append(id)
	return r


# Recetas de un taller que ya se pueden usar: las que no piden investigación y las de investigaciones completadas.
# Los borradores no salen salvo que se pidan (pruebas).
static func recetas_de(taller: String, con_borradores := false) -> Array:
	var r: Array = []
	var todas: Dictionary = Catalogo.todos("recetas")
	for id in todas:
		var x: Resource = todas[id]
		if x.taller != taller or (x.borrador and not con_borradores):
			continue
		if x.investigacion == "" or estado(x.investigacion) == "completada":
			r.append(id)
	return r


# Al ganar un combate (combate.gd, _fin_combate): cada investigación en curso avanza un paso. Devuelve las que se
# completan ahora (para avisar). Sin investigaciones en curso no hace nada.
static func avanzar_en_curso(n := 1) -> Array:
	var r: Array = []
	for id in _partida().keys():
		if estado(id) == "en_curso" and avanzar(id, n):
			r.append(id)
	return r


# V12, fase E: ¿hay alguna investigación completada que desbloquee este hechizo («magia:<escuela>:<nivel>»)?
static func magia_desbloqueada(escuela: String, nivel: int) -> bool:
	var clave := "magia:%s:%d" % [escuela, nivel]
	for id in completadas():
		var v := _datos(id)
		if v != null and clave in v.desbloquea:
			return true
	return false


# Lo que desbloquea de magia una investigación (sus «magia:…»), para los talleres y las pruebas.
static func magias_de(id: String) -> Array:
	var v := _datos(id)
	if v == null:
		return []
	return Array(v.desbloquea).filter(func(x): return str(x).begins_with("magia:"))


# Recetas que desbloquea (sin las de magia): lo que el taller enseña como «Desbloquea: …».
static func recetas_que_desbloquea(id: String) -> Array:
	var v := _datos(id)
	if v == null:
		return []
	return Array(v.desbloquea).filter(func(x): return not str(x).begins_with("magia:"))
