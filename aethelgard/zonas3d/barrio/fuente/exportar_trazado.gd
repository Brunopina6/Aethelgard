extends SceneTree
# BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11, agente A): escribe zonas3d/barrio/modelos/barrio.json DESDE el trazado
# (zonas3d/barrio/trazado.gd, la única fuente). Lo leen el generador de Blender (fuente/crear_barrio.py: suelos, cotas,
# bloques, anclas, zonas de cámara para el recorte y las sondas) y la prueba del lado sur. Así las cámaras y las cotas
# no se duplican a mano (el aviso de MUESTRA_CALLE_OAKHAVEN.md §9).
# Uso: godot --headless --path aethelgard --script res://zonas3d/barrio/fuente/exportar_trazado.gd
#      (con APPDATA y LOCALAPPDATA aislados, como todo lo que se lanza de Godot).

const T := preload("res://zonas3d/barrio/trazado.gd")
const SALIDA := "res://zonas3d/barrio/modelos/barrio.json"


static func rect(r: Rect2) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]


static func v3(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func datos() -> Dictionary:
	var d := {"version": 1, "orden": T.ORDEN, "tramos_eo": T.TRAMOS_EO, "inicio": v3(T.INICIO)}
	var sec := {}
	for s in T.SECTORES:
		sec[s] = rect(T.SECTORES[s])
	d["sectores"] = sec
	var cot := {}
	for s in T.COTAS:
		cot[s] = [T.COTAS[s].x, T.COTAS[s].y]
	d["cotas"] = cot
	d["suelos"] = T.SUELOS.map(func(s): return [s[0], rect(s[1]), s[2], s[3], s[4]])
	d["bloques"] = T.BLOQUES.map(func(b): return [b[0], b[1], rect(b[2]), b[3], b[4], b[5], b[6]])
	var an := {}
	for a in T.ANCLAS:
		an[a] = v3(T.ancla(a))
	d["anclas"] = an
	var pa := {}
	for p in T.PASOS:
		pa[p] = rect(T.PASOS[p])
	d["pasos"] = pa
	var pu := {}
	for id in T.PUERTAS:
		var q: Dictionary = T.PUERTAS[id]
		pu[id] = {"fuera": v3(q["fuera"]), "mira": q["mira"], "ancla": q["ancla"], "paso": q["paso"]}
	d["puertas"] = pu
	d["grafo"] = T.GRAFO
	d["bucle"] = T.BUCLE
	var zonas: Array = []
	for z in T.CAMARA_ZONAS:
		var o := {"sector": z["sector"], "rect": rect(z["rect"]), "modo": z["modo"]}
		for k in ["x", "z"]:
			if z.has(k):
				o[k] = [z[k].x, z[k].y]
		for k in ["z_riel", "eje", "atraso"]:
			if z.has(k):
				o[k] = z[k]
		zonas.append(o)
	d["camara_zonas"] = zonas
	d["camara"] = {"offset": v3(T.OFFSET_CAMARA), "inclinacion": T.INCLINACION, "campo": T.CAMPO, "margen": T.MARGEN_CAMARA}
	return d


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA.get_base_dir()))
	var f := FileAccess.open(SALIDA, FileAccess.WRITE)
	f.store_string(JSON.stringify(datos(), "  ", false))
	f.close()
	print("barrio.json escrito: %s" % ProjectSettings.globalize_path(SALIDA))
	quit(0)
