extends "res://combate.gd"
# SOLO PARA PRUEBAS: combate.gd con los enganches de M1 y M2 de docs/diseno/combate_enganches.md (§2.1: A2 a A7),
# sin tocar combate.gd. Sirve para comprobar, antes de enganchar de verdad, que ese código funciona en un combate
# (prueba_artes_combate) y que sin usar las artes el combate da lo mismo que hoy (prueba_combate_huella con
# «con_enganches»). Se crea con Node2D.new() + set_script(), porque combate.tscn es solo un Node2D con combate.gd.
# Las funciones copiadas (_siguiente_turno, _menu_magia y el principio de _carga_magia) son las de 2386761 con su
# enganche: si combate.gd cambia, pueden quedarse atrás. Al enganchar en combate.gd, este archivo se borra.
# Falta A8 (el aviso «aprende» al subir de nivel), que solo cambia un texto al final del combate.

const Artes := preload("res://artes.gd")
const Extra := preload("res://equipo_extra.gd")


# A2: el Aliento y la regeneración del equipo, al empezar el turno de un héroe.
func _siguiente_turno() -> void:
	if estado != "esperando" or cola.is_empty():
		return
	var f = cola.pop_front()
	if f["hp"] <= 0:
		return
	if f["hero"]:
		actor = f
		if f.get("defendiendo", false):          # la defensa dura hasta su siguiente turno
			f["defendiendo"] = false
			f["rig"].modulate = Color(1, 1, 1)
		_tic_estados_heroe(f)
		_mostrar_menu()
	else:
		estado = "enemigo"
		_turno_enemigo(f)


# A3
func _hechizos(f: Dictionary) -> Array:
	return super(f) + Artes.hechizos(f["nombre"])


# A4
func _menu_magia(nivel := 0) -> void:
	estado = "magia"
	var por_nivel := [[], [], []]
	var familias: Array = []
	var sabe := {}
	for h in _hechizos(actor):
		if Artes.es_arte(h[0]):
			if not h[0] in familias:
				familias.append(h[0])
			sabe[h[0]] = h[1]
		else:
			por_nivel[h[1] - 1].append(h)
	if nivel == 0:
		nivel = magia_nivel_menu.get(actor["nombre"], 1)
	var p: Dictionary = Artes.pestanas_magia(por_nivel.map(func(x): return not x.is_empty()), familias, nivel)
	nivel = p["valor"]
	magia_nivel_menu[actor["nombre"]] = nivel
	var pestanas: Array = []
	for t in p["pestanas"]:
		var tab: Dictionary = t.duplicate()
		tab["accion"] = _menu_magia.bind(t["valor"])
		pestanas.append(tab)
	var items: Array = []
	if nivel >= 4:
		var fam: String = familias[nivel - 4]
		for it in Artes.filas_familia(fam, sabe[fam], actor, heroes, enemigos, cola, MODO_PRUEBAS, ATB_MAX):
			it["accion"] = _elegir_hechizo.bind(fam, it["nivel"])
			items.append(it)
	else:
		for h in por_nivel[nivel - 1]:
			var d: Dictionary = h[2]
			items.append({"texto": d["nombre"], "accion": _elegir_hechizo.bind(h[0], h[1]), "icono": h[0],
				"derecha": "PM ∞" if MODO_PRUEBAS else "%d PM" % d["coste"], "apagado": not _puede_pagar(d["coste"]),
				"desc": _desc_magia(h[0], d)})
	menu.submenu(items, pestanas, p["activa"])


# A5
func _elegir_hechizo(magia: String, nivel: int, sola := false) -> void:
	if Artes.es_arte(magia):
		_elegir_arte(magia, nivel, sola)
		return
	super(magia, nivel, sola)


# A6
func _elegir_arte(fam: String, nv: int, sola := false) -> void:
	var d: Dictionary = Artes.datos(fam, nv)
	var objs: Array = Artes.objetivos(fam, nv, actor, heroes, enemigos, cola, ATB_MAX)
	if objs.is_empty() or not _puede_pagar(d["coste"]):
		return
	if d["todos"]:
		_lanzar_arte(fam, nv, objs)
	elif sola:
		_lanzar_arte(fam, nv, [objs[0]])
	else:
		_pedir_objetivo(objs, func(f): _lanzar_arte(fam, nv, [f]), _menu_magia.bind(0),
			"TOCA UN ENEMIGO" if d["a"] == "enemigos" else "TOCA A UN ALIADO")


func _lanzar_arte(fam: String, nv: int, objs: Array) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	var d: Dictionary = Artes.datos(fam, nv)
	_gastar_pm(quien, d["coste"])
	_actualizar()
	registro.text = "%s lanza %s" % [quien["nombre"], d["nombre"]]
	quien["animando"] = true
	var circulo := _carga_magia(quien, fam, 1.0 + 0.3 * (nv - 1))
	var p = _p3d(quien)
	if p != null:
		await p.lanzar_magia()
	else:
		await get_tree().create_timer(0.5).timeout
	var extra := int(quien.get("efectos", {}).get("apoyo_turnos", 0.0))
	var hechos: Array = Artes.aplicar(fam, nv, objs, cola, ATB_MAX, extra)
	_sonar(Artes.sonido(fam, nv))
	var col: Color = Artes.COLOR[fam]
	if fam == "Alba" and nv == 2:
		_fogonazo(Color(0.55, 0.35, 0.8), 0.25, 1.2)
	for x in hechos:
		var f: Dictionary = x["f"]
		_onda(_suelo_de(f), Color(col, 0.9), 20.0, 160.0, 0.7, 8.0)
		_particulas(_centro(f) + Vector2(0, 60), Color(col, 1.0), Color(col, 0.0), 26, 1.0, Vector2(40, 120), 60.0,
			Vector2(0, -1), 30.0, Vector2(0, -60), 0.07)
		if x.has("atb"):
			_numero_flotante(f, "Retraso" if x["atb"] < 0.0 else "¡Antes!", col, 32)
		elif x.has("pv"):
			_revivir_visual(f)
			_numero_flotante(f, "+%d" % x["pv"], C_CURA)
		elif x.has("aliento"):
			_numero_flotante(f, "Aliento", col, 30)
		elif x.has("barrera"):
			_numero_flotante(f, "❄ %d" % x["barrera"], col, 30)
		elif x.has("brasa"):
			_numero_flotante(f, "Brasa", col, 30)
	_actualizar()
	_quitar_carga(circulo)
	await get_tree().create_timer(0.9).timeout
	if p != null:
		p.fin_magia()
	await get_tree().create_timer(0.3).timeout
	quien["animando"] = false
	_terminar_turno()


func _revivir_visual(f: Dictionary) -> void:
	var p = _p3d(f)
	if p != null and p.has_method("revivir"):
		p.revivir()
	elif f.has("cuerpo"):
		f["cuerpo"].rotation_degrees = 0.0
		f["rig"].position = f["rig_base"]
	_restablecer_color(f)


func _tic_estados_heroe(f: Dictionary) -> void:
	var con_aliento := int(f.get("aliento", 0)) > 0
	var cura: int = Artes.curar_al_empezar_turno(f, Extra.regen(f.get("efectos", {})))
	if cura > 0:
		_numero_flotante(f, "+%d" % cura, C_CURA)
		if con_aliento:
			_sonar(Artes.SONIDO_ESTADO["aliento"])
		_actualizar()


func _sonar(nombre: String) -> void:
	if Sonido.EFECTOS.has(nombre):
		Sonido.efecto(nombre)


# A7: el círculo de carga de siempre, con el color de la familia nueva (las de siempre, sin cambios).
func _carga_magia(o: Dictionary, magia: String, tam := 1.0) -> Node2D:
	if MAGIAS.has(magia):
		return super(o, magia, tam)
	var color: Color = Artes.COLOR[magia]
	var raiz := Node2D.new()
	raiz.position = _suelo_de(o)
	raiz.scale = Vector2(1.0, 0.32) * tam
	raiz.material = mat_aditivo
	raiz.modulate.a = 0.0
	escena.add_child(raiz)
	var giro := Node2D.new()
	giro.use_parent_material = true
	raiz.add_child(giro)
	giro.draw.connect(func(): _dibujar_circulo(giro, color))
	create_tween().bind_node(giro).set_loops().tween_property(giro, "rotation", TAU, 4.0).from(0.0)
	var t := create_tween()
	t.tween_property(raiz, "modulate:a", 1.0, 0.3)
	var gl := _brillo(color)
	gl.scale = Vector2(1.6, 1.6)
	gl.modulate.a = 0.5
	raiz.add_child(gl)
	var chispas := _particulas(raiz.position, Color(color, 0.9), Color(color, 0.0), 30, 1.0, Vector2(40, 110),
		90.0, Vector2(0, -1), 10.0, Vector2(0, -60), 0.06, true)
	raiz.set_meta("chispas", chispas)
	return raiz
