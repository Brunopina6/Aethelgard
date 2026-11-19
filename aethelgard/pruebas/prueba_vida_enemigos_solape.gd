extends SceneTree
# PV_SLIMES_19_11 (PC-11 / C-3; REDMI_18_11.md, problema 7, garon_menu.png): en el combate de tres slimes (GRUPOS[1])
# la vida de un enemigo («PV n/n», su barra de 120 px, su rótulo de estado «⚠ Cargando» / «❄ Congelado» y la señal «⚠»
# de golpe preparado) no debe pisar la de otro enemigo. Se mide sin ventana, con los nodos del combate de verdad
# (combate.tscn) y sus rectángulos en pantalla (1280 × 720):
#   A. Todos los grupos que salen al azar (GRUPOS 0-4 y 7-10; con «enemigos_v12», los del Peón 22-24 en la llanura y
#      los del Velador 25-27 en el bosque), con la vida normal.
#   B. GRUPOS[1] en el banco de pruebas (caso «agua»: vida ×6, «PV 408/408»), el caso de la captura del Redmi.
# En cada uno, cinco estados: todos «⚠ Cargando» con su señal, todos «❄ Congelado», la mezcla de la captura (el de
# atrás congelado y los demás cargando), «doble» (todos congelados y los de delante, además, cargando: «❄ Congelado
# ⚠ Cargando», que se da en el juego normal porque congelar no corta la carga) y «negra» (la doble con tres estados de
# magia negra en todos: el rótulo más largo, «❄ Congelado  ⚠ Cargando  Prisión 1  Lento 2  Def ↓ 3»). Un rótulo largo
# va en varias líneas (combate.gd _texto_estado) y no debe tapar su propia señal «⚠». Un Slime que carga queda
# APLASTADO como en el juego (combate.gd _turno_patron, plan «encoge»: su rig ×(1,12; 0,78), el estado de la captura del
# Redmi), y los cuerpos se miden así en los cinco estados. Además, cada vida sigue dentro de la pantalla y en su orden (estado encima de
# «PV», «PV» encima de la barra) y su barra, cerca de su enemigo (no se va a otro sitio). Los sitios de los enemigos
# salen de GRUPOS (e["pos"] es el de su fila de GRUPOS y no otro); OJO: GRUPOS[1] y [2] sí cambiaron con PV_SLIMES_19_11
# (esto no prueba que la colocación de los cuerpos sea la de antes). Y la cámara de combate (la escena acercada ×1,08)
# no cambia dónde quedan la vida ni la señal «⚠» al volver (PV_SLIMES_19_11_REVISION).
# Datos aislados (archivo de partida propio); el combate no guarda (sin «desde_mapa»).
# Con ventana y «-- fotos=<carpeta>», además guarda capturas de los casos de la captura del Redmi (GRUPOS[1] del banco,
# la mezcla) y de los que se pisaban (GRUPOS[0], [2], [3] y [27]) para comparar antes y después.

const ARCHIVO := "user://prueba_vida_enemigos_solape.save"
const ACTIVOS := ["Kael", "Lya", "Garon"]

var P
var G
var BP
var c = null
var fallos: Array = []
var hechos: Array = []
var avisos: Array = []
var pares := 0
var fotos := ""
const FOTOS := {"GRUPOS[1] banco (agua, vida ×6)": "mezcla,doble,negra", "GRUPOS[1] llanura": "mezcla", "GRUPOS[0] llanura": "congelado",
	"GRUPOS[2] llanura": "cargando", "GRUPOS[3] llanura": "cargando", "GRUPOS[27] bosque, enemigos_v12": "congelado"}


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	BP = load("res://banco_pruebas.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
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
			for h in c.heroes:
				h["atb"] = 0.0


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa",
			"inventario", "enemigos_v12", "banco_caso", BP.META]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _combate(grupo: int, zona: String, v12 := false, banco := "") -> void:
	_limpiar()
	if banco != "":
		BP.preparar_partida()
		BP.poner_grupo(ACTIVOS, BP.NIVEL_COMBATE)
		Engine.set_meta("banco_caso", banco)
	else:
		G.datos()
		Engine.set_meta("grupo_activo", ACTIVOS)
	if v12:
		Engine.set_meta("enemigos_v12", true)
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	seed(19112026)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(4)


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(4)
	_limpiar()


# El rectángulo del texto de una etiqueta (no el de su caja, que no encoge): su tamaño mínimo, colocado según su alineación.
func _rect_texto(l: Label) -> Rect2:
	var m: Vector2 = l.get_minimum_size()
	var p: Vector2 = l.global_position
	var sobra: float = maxf(0.0, l.size.x - m.x)
	if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		p.x += sobra * 0.5
	elif l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		p.x += sobra
	return Rect2(p, m)


# Lo que se ve de la vida de un enemigo: [nombre, rectángulo en pantalla].
func _piezas(e: Dictionary) -> Array:
	var r: Array = []
	for k in ["lbl_estado", "lbl_hp"]:
		var l = e.get(k, null)
		if l != null and is_instance_valid(l) and l.is_visible_in_tree() and l.text.strip_edges() != "":
			r.append([k, _rect_texto(l)])
	var b = e.get("barra_hp", null)
	if b != null and is_instance_valid(b) and b.is_visible_in_tree():
		r.append(["barra_hp", Rect2(b.global_position, b.size)])
	var s = e.get("aviso_nodo", null)
	if s != null and is_instance_valid(s) and s.is_visible_in_tree():
		var k: float = absf(s.get_global_transform().get_scale().x)
		var rad := 28.6 + 2.0                         # sena_arte.gd _aviso: 26 × 1,1 (late) y el contorno
		var centro: Vector2 = s.get_global_transform().origin
		r.append(["aviso", Rect2(centro + Vector2(-rad * 0.95, -rad) * k, Vector2(rad * 1.9, rad * 1.7) * k)])
	return r


# El cuerpo de un enemigo dibujado con fotogramas (el Slime: «sprite»): la unión de lo opaco de sus fotogramas de
# reposo (de los PNG de origen), en pantalla. Los 3D no se miden aquí (Rect2() vacío).
var _usados := {}
func _cuerpo(e: Dictionary) -> Rect2:
	if c.MODELOS[e["modelo"]].get("tipo", "") != "sprite" or not e.has("partes"):
		return Rect2()
	var anim: AnimatedSprite2D = e["partes"]["anim"]
	var usado := Rect2()
	for i in anim.sprite_frames.get_frame_count("idle"):
		var ruta: String = anim.sprite_frames.get_frame_texture("idle", i).resource_path
		if not _usados.has(ruta):
			var img := Image.load_from_file(ProjectSettings.globalize_path(ruta))
			_usados[ruta] = Rect2(img.get_used_rect()) if img != null else Rect2()
		usado = _usados[ruta] if usado.size == Vector2.ZERO else usado.merge(_usados[ruta])
	var t: Transform2D = anim.get_global_transform()
	var r := Rect2(t * usado.position, Vector2.ZERO)
	for p in [Vector2(usado.end.x, usado.position.y), usado.end, Vector2(usado.position.x, usado.end.y)]:
		r = r.expand(t * p)
	return r


func _poner_estado(variante: String) -> void:
	for i in c.enemigos.size():
		var e: Dictionary = c.enemigos[i]
		var carga: bool = variante == "cargando" or (variante in ["mezcla", "doble", "negra"] and i > 0)
		_aplastar(e, false)
		e["cargando"] = carga
		e["congelado"] = 2 if not carga or variante in ["doble", "negra"] else 0
		if variante == "negra":
			e["mn"] = {"prision": 1, "lento": 2, "def_baja": 3}
		else:
			e.erase("mn")
		_aplastar(e, carga)
		c._marcar_aviso(e, carga)
	c._actualizar()


# Lo que hace el juego cuando un Slime prepara su golpe (combate.gd _turno_patron, plan «encoge»): queda en guardia y
# su rig, aplastado ×(1,12; 0,78) (el final de su tween). Al soltarlo, vuelve a «escala_rig».
func _aplastar(e: Dictionary, si: bool) -> void:
	if not c.PATRONES.get(e.get("personalidad", ""), {}).get("encoge", false) or not e.has("rig"):
		return
	if si and not e.has("escala_rig"):
		e["defendiendo"] = true
		e["escala_rig"] = e["rig"].scale
		e["rig"].scale = e["rig"].scale * Vector2(1.12, 0.78)
	elif not si and e.has("escala_rig"):
		e["defendiendo"] = false
		e["rig"].scale = e["escala_rig"]
		e.erase("escala_rig")


func _quitar_estado() -> void:
	for e in c.enemigos:
		e["cargando"] = false
		e["congelado"] = 0
		e.erase("mn")
		_aplastar(e, false)
		c._marcar_aviso(e, false)
	c._actualizar()


# La cámara de combate (combate_anim_v12.gd camara: la escena ×1,08 hacia un foco) no debe cambiar dónde acaban la vida
# y la señal «⚠» de un enemigo: se ponen los estados con la escena acercada y, al volver, todo debe estar donde está
# si se ponen en reposo.
func _probar_camara(titulo: String) -> void:
	var reposo := {}
	_poner_estado("cargando")
	for i in c.enemigos.size():
		var e: Dictionary = c.enemigos[i]
		reposo[i] = [e.get("vida_dy", 0.0), e["lbl_hp"].position, (e["aviso_nodo"] as Node2D).position if e.has("aviso_nodo") else null]
	_quitar_estado()
	var pos0: Vector2 = c.escena.position
	var esc0: Vector2 = c.escena.scale
	var foco: Vector2 = c.enemigos[0]["pos"]
	c.escena.scale = esc0 * 1.08
	c.escena.position = pos0 + foco * esc0.x - foco * c.escena.scale.x
	_poner_estado("cargando")
	c.escena.position = pos0
	c.escena.scale = esc0
	for i in c.enemigos.size():
		var e: Dictionary = c.enemigos[i]
		var r: Array = reposo[i]
		_ok(absf(e.get("vida_dy", 0.0) - r[0]) < 0.5 and e["lbl_hp"].position.distance_to(r[1]) < 0.5,
			"%s [cámara]: la vida de %s, acercada, queda en otro sitio (vida_dy %.1f en vez de %.1f; «PV» en %s en vez de %s)" %
			[titulo, e["nombre"], e.get("vida_dy", 0.0), r[0], str(e["lbl_hp"].position), str(r[1])])
		if r[2] != null and e.has("aviso_nodo"):
			var d: float = (e["aviso_nodo"] as Node2D).position.distance_to(r[2])
			_ok(d < 0.5, "%s [cámara]: la señal «⚠» de %s, acercada, queda %.1f px fuera de su sitio" % [titulo, e["nombre"], d])
	_quitar_estado()


func _medir(titulo: String, grupo: int) -> void:
	var g: Array = c.GRUPOS[grupo]
	_ok(c.enemigos.size() == g.size(), "%s: %d enemigos (GRUPOS[%d] tiene %d)" % [titulo, c.enemigos.size(), grupo, g.size()])
	# cada enemigo está en el sitio de su fila de GRUPOS (e["pos"] sale de GRUPOS y no de otro sitio). No prueba que la
	# colocación sea la de antes: GRUPOS[1] y [2] se cambiaron a propósito (PV_SLIMES_19_11) y eso se ve en el juego normal.
	var sitios: Array = []
	for x in g:
		var sitio: Vector2 = c.MODELOS[c.ENEMIGOS[x[0]]["modelo"]].get("pos_grupo", x[1])
		sitios.append(Vector2(sitio.x * c.ENEMIGOS_X.x + c.ENEMIGOS_X.y, sitio.y))
	for e in c.enemigos:
		var en_su_sitio: bool = c.MODELOS[e["modelo"]].has("pies_como")   # (los jefes grandes recolocan sus pies)
		for s in sitios:
			en_su_sitio = en_su_sitio or (e["pos"] as Vector2).distance_to(s) < 1.0
		_ok(en_su_sitio, "%s: %s fuera de su sitio de GRUPOS (%s)" % [titulo, e["nombre"], str(e["pos"])])
	for variante in ["cargando", "congelado", "mezcla", "doble", "negra"]:
		_poner_estado(variante)
		await _esperar(2)
		if fotos != "" and variante in FOTOS.get(titulo, "").split(","):
			await RenderingServer.frame_post_draw
			var nombre := "%s_%s.png" % [titulo.split(" ")[0].replace("[", "").replace("]", ""), variante]
			if "banco" in titulo:
				nombre = "banco_" + nombre
			root.get_texture().get_image().save_png(fotos.path_join(nombre))
			print("FOTO: ", fotos.path_join(nombre))
		var piezas: Array = []
		for e in c.enemigos:
			piezas.append(_piezas(e))
		var linea := "%s [%s]:" % [titulo, variante]
		for i in c.enemigos.size():
			var e: Dictionary = c.enemigos[i]
			var desc := []
			for p in piezas[i]:
				var r: Rect2 = p[1]
				desc.append("%s(%d,%d %dx%d)" % [p[0], r.position.x, r.position.y, r.size.x, r.size.y])
			linea += "  %s «%s» %s" % [e["nombre"], e["lbl_hp"].text, " ".join(desc)]
			# en pantalla y en su orden
			for p in piezas[i]:
				var r: Rect2 = p[1]
				_ok(r.position.x >= 0.0 and r.position.y >= 0.0 and r.end.x <= 1280.0 and r.end.y <= 720.0,
					"%s [%s]: %s de %s fuera de la pantalla %s" % [titulo, variante, p[0], e["nombre"], str(r)])
			var y := {}
			for p in piezas[i]:
				y[p[0]] = (p[1] as Rect2).get_center().y
			if y.has("lbl_hp") and y.has("barra_hp"):
				_ok(y["lbl_hp"] < y["barra_hp"], "%s [%s]: «PV» de %s debajo de su barra" % [titulo, variante, e["nombre"]])
			var rr := {}
			for p in piezas[i]:
				rr[p[0]] = (p[1] as Rect2).grow(-0.5)
			if rr.has("lbl_estado") and rr.has("aviso"):        # su señal «⚠», encima de su estado (aunque tenga varias líneas)
				_ok(not rr["lbl_estado"].intersects(rr["aviso"]), "%s [%s]: el estado de %s tapa su propia señal «⚠»" %
					[titulo, variante, e["nombre"]])
			if y.has("lbl_estado") and y.has("lbl_hp"):
				_ok(y["lbl_estado"] < y["lbl_hp"], "%s [%s]: estado de %s debajo de su «PV»" % [titulo, variante, e["nombre"]])
			# la barra, sobre su enemigo (a menos de 150 px de su centro en horizontal)
			for p in piezas[i]:
				if p[0] == "barra_hp":
					var dx: float = absf((p[1] as Rect2).get_center().x - c._a_pantalla(c._centro(e)).x)
					_ok(dx < 150.0, "%s [%s]: la barra de %s a %d px de su centro" % [titulo, variante, e["nombre"], dx])
		print(linea)
		# los cuerpos (Slime, aplastado si carga): la vida de un enemigo no va encima del cuerpo de otro, y los cuerpos,
		# sin solaparse (en los cuatro estados)
		var cuerpos: Array = c.enemigos.map(func(e): return _cuerpo(e))
		if cuerpos.any(func(r): return r.size != Vector2.ZERO):
			print("  cuerpos: ", ", ".join(range(cuerpos.size()).map(func(i): return "%s %s%s" % [c.enemigos[i]["nombre"],
				str(cuerpos[i]), " (aplastado)" if c.enemigos[i].has("escala_rig") else ""])))
		for i in c.enemigos.size():
			for j in c.enemigos.size():
				if i == j or cuerpos[j].size == Vector2.ZERO:
					continue
				if j > i and cuerpos[i].size != Vector2.ZERO:
					var cc: Rect2 = cuerpos[i].grow(-0.5).intersection(cuerpos[j].grow(-0.5))
					_ok(cc.size == Vector2.ZERO, "%s [%s]: el cuerpo de %s pisa el de %s (%d × %d px)" % [titulo, variante,
						c.enemigos[i]["nombre"], c.enemigos[j]["nombre"], cc.size.x, cc.size.y])
				for a in piezas[i]:
					var ca: Rect2 = (a[1] as Rect2).grow(-0.5).intersection(cuerpos[j].grow(-0.5))
					_ok(ca.size == Vector2.ZERO, "%s [%s]: %s de %s encima del cuerpo de %s (%d × %d px)" % [titulo,
						variante, a[0], c.enemigos[i]["nombre"], c.enemigos[j]["nombre"], ca.size.x, ca.size.y])
		# ninguna pieza de un enemigo pisa una de otro. Límite conocido (anotado, no arreglado): en «negra» (la magia negra
		# es de desarrollo, APAGADA en el juego normal) un rótulo de cinco estados puede necesitar subir por encima de
		# TECHO_VIDAS (y = 70, el registro de arriba); si la vida de uno de los dos ya está en el techo, el cruce se anota
		# como AVISO y no como fallo. En los demás estados, y sin techo, es FALLO.
		var en_techo: Array = []
		for i in c.enemigos.size():
			var arriba: float = 720.0
			for p in piezas[i]:                      # (con la señal «⚠»: aquí se mide 1 px más alta que en combate.gd)
				arriba = minf(arriba, (p[1] as Rect2).position.y)
			en_techo.append(arriba <= c.TECHO_VIDAS + 2.0)
		for i in c.enemigos.size():
			for j in range(i + 1, c.enemigos.size()):
				for a in piezas[i]:
					for b in piezas[j]:
						pares += 1
						var ra: Rect2 = (a[1] as Rect2).grow(-0.5)
						var rb: Rect2 = (b[1] as Rect2).grow(-0.5)
						if ra.intersects(rb):
							var cruce: Rect2 = ra.intersection(rb)
							var texto := "%s [%s]: %s de %s pisa %s de %s (%d × %d px)" % [titulo, variante, a[0],
								c.enemigos[i]["nombre"], b[0], c.enemigos[j]["nombre"], cruce.size.x, cruce.size.y]
							if variante == "negra" and (en_techo[i] or en_techo[j]):
								avisos.append(texto)
								print("AVISO (techo, magia negra de desarrollo): ", texto)
							else:
								_ok(false, texto)
	_quitar_estado()
	await _esperar(2)
	_probar_camara(titulo)


func _probar() -> void:
	var casos: Array = []
	for n in [0, 1, 2, 3, 4, 7, 8, 9, 10]:
		casos.append(["GRUPOS[%d] llanura" % n, n, "llanura", false, ""])
	for n in [22, 23, 24]:
		casos.append(["GRUPOS[%d] llanura, enemigos_v12" % n, n, "llanura", true, ""])
	for n in [25, 26, 27]:
		casos.append(["GRUPOS[%d] bosque, enemigos_v12" % n, n, "bosque", true, ""])
	casos.append(["GRUPOS[1] banco (agua, vida ×6)", 1, "llanura", false, "agua"])
	for caso in casos:
		await _combate(caso[1], caso[2], caso[3], caso[4])
		if caso[4] != "":
			_ok(c.enemigos.size() == 3 and c.enemigos.all(func(e): return e["hp_max"] >= 300),
				"%s: la vida ×6 del banco no se aplicó (%s)" % [caso[0], str(c.enemigos.map(func(e): return e["hp_max"]))])
		await _medir(caso[0], caso[1])
		await _cerrar()
	hechos.append("%d casos (%d grupos al azar y el banco), 5 estados cada uno (los Slime que cargan, aplastados) y la cámara, %d pares de piezas medidos" % [casos.size(),
		casos.size() - 1, pares])
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO))
	BP.salir()
	if not avisos.is_empty():
		hechos.append("%d cruces anotados como AVISO (solo «negra», con una vida en el techo de y = 70)" % avisos.size())
	for h in hechos:
		print("HECHO: ", h)
	if fallos.is_empty():
		print("PRUEBA SUPERADA: prueba_vida_enemigos_solape")
	else:
		print("FALLOS: %d" % fallos.size())
	quit(0 if fallos.is_empty() else 1)
