extends SceneTree
# Las armas especiales (C2) se ven distintas (material_arma.gd: «tinte», «color_brillo» y un filo de luz, sin luces ni
# partículas) y la Hoja sin Nombre sube el ataque también en el menú Grupo (grupo.gd). En un combate de verdad, con
# cada arma puesta: el arma del modelo 3D lleva el tinte y el brillo de su ficha; sin arma especial, el material de
# siempre (blanco, sin aura). Con «fotos=<carpeta>» y ventana, una captura de cada una. Datos aislados.

const ARCHIVO := "user://prueba_armas_especiales.save"
const CASOS := [["Kael", "hoja_sin_nombre", "sable"], ["Kael", "guardiana_ambar", "sable"], ["Lya", "baculo_peregrino", "vara"],
	["Lya", "rama_milenaria", "vara"], ["Garon", "fauces_gorthor", "espada"], ["Garon", "gemelas_muralla", "espada"]]

var P
var G
var I
var X
var c = null
var fotos := ""
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	X = load("res://equipo_extra.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "inventario", "lore_visto"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


# El material de la primera malla del arma del héroe (el nodo «sable», «vara» o «espada» de su modelo 3D).
func _material(heroe: String, nodo: String) -> ShaderMaterial:
	for h in c.heroes:
		if h["nombre"] == heroe:
			var p = c._p3d(h)
			var n = p.get(nodo) if p != null and nodo in p else null
			if n == null:
				return null
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				if mi.material_override is ShaderMaterial:
					return mi.material_override
	return null


func _probar() -> void:
	await _esperar(10)
	for caso in [["", "", ""]] + CASOS:
		_limpiar()
		G.datos()
		I.datos()
		Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
		for n in ["Kael", "Lya", "Garon"]:
			G.datos()[n]["nivel"] = 10
		if caso[1] != "":
			X.conseguir(caso[1])
			_ok(I.equipar(caso[0], "arma", caso[1]), "%s: no se puede poner" % caso[1])
			_ok(not I.arma_de(caso[0]).is_empty() and I.arma_de(caso[0]).get("modelo", "") != "", "%s: arma_de no la da" % caso[1])
		Engine.set_meta("zona", "ceniza")
		Engine.set_meta("fondo_combate", "llanura")
		Engine.set_meta("tipo_combate", "normal")
		Engine.set_meta("grupo_combate", 9)
		c = load("res://combate.tscn").instantiate()
		root.add_child(c)
		await _esperar(20)
		if caso[1] == "":
			for d in [["Kael", "sable"], ["Lya", "vara"], ["Garon", "espada"]]:
				var m0 := _material(d[0], d[1])
				_ok(m0 != null and m0.get_shader_parameter("aura") == null or (m0 != null and float(m0.get_shader_parameter("aura")) == 0.0),
					"sin arma especial, %s lleva aura" % d[0])
			hechos.append("las de siempre, sin tinte")
		else:
			var arma: Dictionary = X.ARMAS[caso[1]]
			var m := _material(caso[0], caso[2])
			_ok(m != null, "%s: no encuentro el material del arma de %s" % [caso[1], caso[0]])
			if m != null:
				var t = m.get_shader_parameter("tinte")
				var b = m.get_shader_parameter("color_brillo")
				_ok(t is Color and (t as Color).is_equal_approx(arma["tinte"]), "%s: el tinte es %s" % [caso[1], t])
				_ok(b is Color and (b as Color).is_equal_approx(arma["color_brillo"]), "%s: el color del brillo es %s" % [caso[1], b])
				_ok(float(m.get_shader_parameter("aura")) > 0.0, "%s: sin filo de luz" % caso[1])
			hechos.append(caso[1])
			if fotos != "":
				await _esperar(4)
				var img := root.get_viewport().get_texture().get_image()
				if img != null and not img.is_empty():
					img.save_png(fotos.path_join("%s_%s.png" % [caso[0].to_lower(), caso[1]]))
		c.queue_free()
		c = null
		await _esperar(5)
	# la Hoja sin Nombre en el menú Grupo: estadisticas() ya suma su ataque
	_limpiar()
	G.datos()
	I.datos()
	var base: int = G.estadisticas("Kael")["ataque"]
	X.conseguir("hoja_sin_nombre")
	I.equipar("Kael", "arma", "hoja_sin_nombre")
	var con_hoja: int = G.estadisticas("Kael")["ataque"]
	Engine.set_meta("lore_visto", {"a": true, "b": true, "c": true, "d": true})
	_ok(G.estadisticas("Kael")["ataque"] == con_hoja + 4, "Hoja sin Nombre: el menú no suma 1 por recuerdo (%d y %d)" % [G.estadisticas("Kael")["ataque"], con_hoja])
	_ok(base > 0, "sin ataque base")
	hechos.append("Hoja sin Nombre en grupo.gd")
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	if Engine.has_meta("fondo_combate"):
		Engine.remove_meta("fondo_combate")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
