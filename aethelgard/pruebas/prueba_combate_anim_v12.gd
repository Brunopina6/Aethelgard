extends SceneTree
# Animación de combate V12 (combate_anim_v12.gd, 12/11/2026): el mismo combate de verdad (combate.tscn, héroes v2,
# «-- grupo=3 auto semilla=7») dos veces en el mismo proceso: primero con el interruptor APAGADO y luego ENCENDIDO.
# Comprueba:
#   1. Interruptor: apagado, ningún héroe usa la animación v12 (activo() = false) y no se cargan los clips c12_*;
#      encendido, los tres héroes v2 la usan y tienen sus clips (los del JSON, con su duración).
#   2. Pies que no patinan: mientras el cuerpo avanza en pantalla, lo que se corre EN HORIZONTAL el pie apoyado (px de la
#      escena, por acción; y su
#      velocidad; aparte, lo que se mueve en vertical: la profundidad del escenario 2D, que los pies del clip no hacen) de
#      cada héroe. Apagado, el cuerpo se desliza con el clip de correr a su ritmo (cientos de px); con
#      la v12, FALLO si pasa de LIMITE_PIE y no se queda en menos de la mitad que apagado.
#   3. Impactos sincronizados: en el fotograma en que baja la vida del enemigo (el daño y el Sonido.golpe van en la misma
#      llamada), el clip del atacante y su instante. Kael «ataque» ≈ 0,64 s, Lya «ataque» ≈ 0,47 s, Garon «juicio» ≈ 1,10 s,
#      iguales apagado y encendido (± 2 fotogramas).
#   4. El combate sigue: cada héroe actúa, nadie se queda «animando» y el tiempo vuelve a 1. ATB al ritmo de siempre
#      (13/11): con una acción v12 en curso, pasado lo que duraba la de siempre, el ATB no avanza («sin_pausa_atb»: no se mira).
# Con «fotos=<carpeta>» (y ventana) guarda un PNG cada 2 fotogramas de las acciones de los héroes de cada pasada
# (apagado_NNNN.png, encendido_NNNN.png) para montar el vídeo comparado.
# Con «esgrima=Juicio» / «magia=Fuego» (argumentos del combate) mide esas acciones en lugar del ataque.

const FOTOGRAMAS := 900              # por pasada (30 s con --fixed-fps 30)
const LIMITE_PIE := 70.0             # px por acción: lo que se corre el pie apoyado mientras el cuerpo avanza (encendido)
const TOL_IMPACTO := 2.0 / 30.0
const ESPERADO := {"Kael": ["ataque", 0.64], "Lya": ["ataque", 0.47], "Garon": ["juicio", 1.10]}

var AnimV12 = load("res://combate_anim_v12.gd")
var c: Node
var fase := 0                        # 0: apagado, 1: encendido
var frames := 0
var fallos := 0
var fotos := ""
var n_foto := 0
var vida_antes := {}
var pies := {}                       # nombre -> {"ant": Vector2, "ant_rig": Vector2, "lado": int, "vels": []}
var impactos := [{}, {}]             # por fase: nombre -> [clip, instante]
var actuaron := [{}, {}]
var medianas := [{}, {}]
var detalles_hechos := false
var atb_ant := 0.0
var accion_ant := false
var atb_mueve := 0                   # fotogramas con acción v12 en curso en que el ATB avanzó
var frames_quieto := 0
var detalles_fin := false
var acciones := [{}, {}]            # acciones (veces que empieza a «animar») de cada uno


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	Engine.set_meta("heroes_v2", true)
	_empezar(0)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _empezar(f: int) -> void:
	fase = f
	frames = 0
	pies.clear()
	vida_antes.clear()
	Engine.set_meta("combate_anim_v12", f == 1)
	Engine.set_meta("camaras_combate", true)
	seed(7)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _process(_d: float) -> bool:
	if c == null:
		return false
	frames += 1
	if frames == 3:
		_comprobar_interruptor()
	if frames > 3:
		_medir()
	if fotos != "" and frames % 2 == 0 and c.heroes.any(func(h): return h.get("animando", false)):
		var img := root.get_viewport().get_texture().get_image()
		img.save_png(fotos.path_join("%s_%04d.png" % ["apagado" if fase == 0 else "encendido", n_foto]))
		n_foto += 1
	if detalles_hechos:
		if detalles_fin:
			_final()
			return true
		return false
	var todos: bool = actuaron[fase].size() >= c.heroes.size() and not c.heroes.any(func(h): return h.get("animando", false))
	if (todos and frames > 60) or frames >= FOTOGRAMAS or c.estado == "fin":
		_cerrar_fase()
		if fase == 0:
			c.queue_free()
			c = null
			n_foto = 0
			_empezar.call_deferred(1)
			return false
		if fase == 1 and c.estado != "fin" and not detalles_hechos:
			detalles_hechos = true
			_detalles.call_deferred()
			return false
		_final()
		return true
	return false


func _comprobar_interruptor() -> void:
	for h in c.heroes:
		var p = h.get("p3d", null)
		if p == null:
			_fallo("%s sin modelo 3D" % h["nombre"])
			continue
		var si: bool = AnimV12.activo(h)
		if fase == 0:
			if si:
				_fallo("apagado y %s usa la animación v12" % h["nombre"])
			if p.anim.has_animation("c12_arranque"):
				_fallo("apagado y %s tiene los clips c12_*" % h["nombre"])
		else:
			if not si:
				_fallo("encendido y %s no usa la animación v12 (¿héroe v2? %s)" % [h["nombre"], str(p.get("es_v2"))])
				continue
			var json := "res://personajes/heroes_v2/%s/%s_v2_combate_v12.json" % [h["nombre"].to_lower(), h["nombre"].to_lower()]
			var datos = JSON.parse_string(FileAccess.get_file_as_string(json))
			for n in datos["clips"]:
				if not p.anim.has_animation(n):
					_fallo("%s no tiene %s" % [h["nombre"], n])
				elif absf(p.anim.get_animation(n).length - float(datos["clips"][n]["duracion"])) > 0.04:
					_fallo("%s: %s dura %.2f (JSON %.2f)" % [h["nombre"], n, p.anim.get_animation(n).length, datos["clips"][n]["duracion"]])
			print("  %s: %d clips c12 (%s)" % [h["nombre"], datos["clips"].size(), ", ".join(datos["clips"].keys())])


func _pie_en_escena(h: Dictionary, p, lado: int) -> Array:
	var sk: Skeleton3D = p.skel
	var n := "Left" if lado == 0 else "Right"
	var a := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_" + n + "Foot")).origin
	var b := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_" + n + "ToeBase")).origin
	var m := (a + b) * 0.5
	var cam: Camera3D = h["cam3d"]
	var spr: Sprite2D = h["partes"]["sprite"]
	return [c.escena.to_local(spr.to_global(cam.unproject_position(m))), m.y]


func _medir() -> void:
	if detalles_hechos:                              # (lo de _detalles no es una acción del combate)
		return
	# 13/11: el ATB al ritmo de siempre: durante una acción v12, pasado lo que duraba la de siempre, quieto (y apagado, nunca)
	var suma_atb := 0.0
	for f in c.heroes + c.enemigos:
		suma_atb += float(f["atb"])
	var en_accion: bool = int(c.get_meta("c12_accion", 0)) > 0 and float(c.get_meta("c12_atb_resto", 0.0)) <= 0.0
	if fase == 0 and c.has_meta("c12_accion"):
		_fallo("apagado y el combate cuenta acciones v12")
	if en_accion and accion_ant and suma_atb > atb_ant + 0.001:
		atb_mueve += 1
	if en_accion:
		frames_quieto += 1
	atb_ant = suma_atb
	accion_ant = en_accion
	var dt := 1.0 / 30.0
	for h in c.heroes:
		var p = h.get("p3d", null)
		if p == null or p.skel == null:
			continue
		var nombre: String = h["nombre"]
		if not h.get("animando", false) and pies.get(nombre, {}).get("animaba", false):
			print("  DURACION %s %s: %d fotogramas animando (desde f%d)" % ["apagado" if fase == 0 else "encendido", nombre, frames - int(pies[nombre].get("desde", 0)), int(pies[nombre].get("desde", 0))])
		if h.get("animando", false):
			if not actuaron[fase].has(nombre) or not pies.get(nombre, {}).get("animaba", false):
				pies[nombre] = pies.get(nombre, {"vels": [], "suelo": p.get_meta("c12_tobillo", _tobillo(p))})
				pies[nombre]["desde"] = frames
				acciones[fase][nombre] = int(acciones[fase].get(nombre, 0)) + 1
			actuaron[fase][nombre] = true
		var rig: Vector2 = h["rig"].position
		var r: Dictionary = pies.get(nombre, {"vels": [], "suelo": p.get_meta("c12_tobillo", _tobillo(p))})
		var p0: Array = _pie_en_escena(h, p, 0)
		var p1: Array = _pie_en_escena(h, p, 1)
		var lado := 0 if p0[1] <= p1[1] else 1
		var bajo: float = minf(p0[1], p1[1])
		var actual: Vector2 = p0[0] if lado == 0 else p1[0]
		if "depurar=" + nombre in OS.get_cmdline_user_args() and h.get("animando", false):
			print("    DEP %s f%d anim=%s t=%.2f ss=%.2f rig=%s bajo=%.3f lado=%d pie=%s" % [nombre, frames, p.anim.assigned_animation, p.anim.current_animation_position, p.anim.speed_scale, str(rig.round()), bajo, lado, str(actual.round())])
		if r.has("ant") and h.get("animando", false) and r["lado"] == lado and bajo < r["suelo"] + 0.03 and r["bajo"] < r["suelo"] + 0.03 \
				and (rig - r["ant_rig"]).length() > 0.5 and not h.has("suelo_salto"):
			r["vels"].append(absf((actual - r["ant"]).x) / dt)
			r["vy"] = float(r.get("vy", 0.0)) + absf((actual - r["ant"]).y)
			if "depurar=" + nombre in OS.get_cmdline_user_args():
				print("    CUENTA %s f%d %s %.2f %.0f px/s" % [nombre, frames, p.anim.assigned_animation, p.anim.current_animation_position, r["vels"][-1]])
		r["ant"] = actual
		r["ant_rig"] = rig
		r["lado"] = lado
		r["bajo"] = bajo
		r["animaba"] = h.get("animando", false)
		pies[nombre] = r
	# impactos: el fotograma en que baja la vida de un enemigo, con el clip del héroe que actúa
	for e in c.enemigos:
		var antes: int = vida_antes.get(e["nombre"], int(e["hp"]))
		if int(e["hp"]) < antes and c.actor != null and c.actor.get("hero", false):
			var a = c.actor
			var p = a.get("p3d", null)
			if p != null and not impactos[fase].has(a["nombre"]):
				impactos[fase][a["nombre"]] = [String(p.anim.assigned_animation), p.anim.current_animation_position]
				print("  impacto de %s: %s a %.3f s" % [a["nombre"], p.anim.assigned_animation, p.anim.current_animation_position])
		vida_antes[e["nombre"]] = int(e["hp"])


func _cerrar_fase() -> void:
	var etiqueta := "APAGADO" if fase == 0 else "ENCENDIDO"
	print("PASADA %s: %d fotogramas, actúan %s" % [etiqueta, frames, str(actuaron[fase].keys())])
	for nombre in pies:
		var v: Array = pies[nombre]["vels"]
		v.sort()
		var med: float = v[v.size() / 2] if not v.is_empty() else 0.0
		var p90: float = v[int(v.size() * 0.9)] if not v.is_empty() else 0.0
		medianas[fase][nombre] = med
		var total := 0.0
		for x in v:
			total += x / 30.0
		var n_acc: int = maxi(1, int(acciones[fase].get(nombre, 1)))
		medianas[fase][nombre] = total / n_acc
		print("  PIES %s %s: el pie apoyado se corre %.0f px por acción en horizontal mientras el cuerpo avanza (%d acciones, %d fotogramas; mediana %.0f px/s, p90 %.0f px/s) y %.0f px en vertical (profundidad)" % [etiqueta, nombre, total / n_acc, n_acc, v.size(), med, p90, float(pies[nombre].get("vy", 0.0)) / n_acc])
	if fase == 1:
		for h in c.heroes:
			if h.get("animando", false):
				_fallo("%s se queda «animando»" % h["nombre"])
	if Engine.time_scale != 1.0:
		_fallo("el tiempo no vuelve a 1 (%.2f)" % Engine.time_scale)


func _final() -> void:
	print("  ATB: %d fotogramas de acción v12 más allá de lo que duraba la de siempre; en %d avanzó" % [frames_quieto, atb_mueve])
	if atb_mueve > 0:
		_fallo("el ATB avanza durante una acción v12 (%d fotogramas)" % atb_mueve)
	if frames_quieto == 0 and not "sin_pausa_atb" in OS.get_cmdline_user_args():
		_fallo("no se vio ninguna acción v12 más larga que la de siempre con el ATB quieto")
	for nombre in ["Kael", "Lya", "Garon"]:
		if not actuaron[1].has(nombre):
			_fallo("encendido: %s no actúa" % nombre)
		var antes: float = medianas[0].get(nombre, 0.0)
		if medianas[1].has(nombre) and medianas[1][nombre] > LIMITE_PIE and medianas[1][nombre] > antes * 0.5:
			_fallo("encendido: el pie de %s patina (%.0f px por acción; apagado %.0f; se pide ≤ %.0f o menos de la mitad)" % [nombre, medianas[1][nombre], antes, LIMITE_PIE])
		for f in 2:
			if impactos[f].has(nombre) and ESPERADO.has(nombre) and not "magia=" in str(OS.get_cmdline_user_args()):
				var i: Array = impactos[f][nombre]
				var e: Array = ESPERADO[nombre]
				if i[0] == e[0] and absf(float(i[1]) - e[1]) > TOL_IMPACTO + 0.02:
					_fallo("%s: impacto a %.3f s de «%s» (se espera %.2f)" % ["apagado" if f == 0 else "encendido", i[1], i[0], e[1]])
		if impactos[0].has(nombre) and impactos[1].has(nombre):
			var a: Array = impactos[0][nombre]
			var b: Array = impactos[1][nombre]
			print("  IMPACTO %s: apagado %s %.3f · encendido %s %.3f" % [nombre, a[0], a[1], b[0], b[1]])
			if a[0] == b[0] and absf(float(a[1]) - float(b[1])) > TOL_IMPACTO:
				_fallo("%s: el impacto se mueve (%.3f → %.3f s de %s)" % [nombre, a[1], b[1], a[0]])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# Altura del tobillo en reposo (como combate_anim_v12.gd), para saber cuándo un pie está en el suelo.
func _tobillo(p) -> float:
	var sk: Skeleton3D = p.skel
	var y := INF
	for n in ["mixamorig_LeftFoot", "mixamorig_RightFoot"]:
		var i := sk.find_bone(n)
		if i >= 0:
			y = minf(y, p.to_local(sk.global_transform * sk.get_bone_global_rest(i).origin).y)
	return y


# 5. Reacciones, defensa, cámara y victoria (encendido), con el combate parado («fin»: no corre el ATB ni actúan los
#    enemigos) para que nada se cruce: golpe fuerte → c12_recibir_fuerte y vuelta a la guardia; con la defensa puesta →
#    c12_bloqueo y luego c12_defensa, y fin_defensa → guardia; golpe ligero → recibir_golpe; la cámara acerca la escena y
#    vuelve a su sitio (y _a_pantalla la sigue); Embuir de Garon → c12_embuir; la victoria, cada uno a su tiempo.
func _detalles() -> void:
	c.estado = "fin"
	c.cola.clear()
	for f in c.heroes + c.enemigos:
		f["atb"] = 0.0
		f["vel"] = 0.0                               # (el ATB ya no se llena: nadie más actúa)
	var quietos := 0                                 # (por si quedaba una orden en marcha: 1 s seguido sin nadie animando)
	for i in 600:
		quietos = 0 if (c.heroes + c.enemigos).any(func(f): return f.get("animando", false)) else quietos + 1
		if quietos >= 30:
			break
		await process_frame
	var kael: Dictionary = c._heroe_de_grupo("Kael")
	var lya: Dictionary = c._heroe_de_grupo("Lya")
	var garon: Dictionary = c._heroe_de_grupo("Garon")
	await create_timer(0.6).timeout
	AnimV12.reaccion(c, kael, 60, true, 1.0)
	await create_timer(0.1).timeout
	_espera_clip(kael, "c12_recibir_fuerte", "golpe fuerte de Kael")
	await create_timer(1.0).timeout
	_espera_clip(kael, "guardia", "Kael vuelve a la guardia tras el golpe fuerte")
	lya["defendiendo"] = true
	AnimV12.defender(c, lya)
	await create_timer(0.3).timeout
	_espera_clip(lya, "c12_defensa", "Lya en defensa")
	AnimV12.reaccion(c, lya, 5, false, 1.0)
	await create_timer(0.1).timeout
	_espera_clip(lya, "c12_bloqueo", "Lya bloquea con la defensa puesta")
	await create_timer(0.7).timeout
	_espera_clip(lya, "c12_defensa", "Lya sigue en defensa tras bloquear")
	# la defensa sigue restando lo de siempre con la animación v12 (golpe físico de verdad de un enemigo a Lya en guardia)
	var ene: Dictionary = c.enemigos.filter(func(e): return e["hp"] > 0)[0] if c.enemigos.any(func(e): return e["hp"] > 0) else {}
	if not ene.is_empty():
		var pv0: int = lya["hp"]
		lya["hp"] = lya["hp_max"]
		pv0 = lya["hp"]
		await c._animar_golpe(ene, lya, 20, "")
		var quitado: int = pv0 - int(lya["hp"])
		var tope: int = int(int(20 * 1.6) * 0.5) + 1      # (aunque saliera crítico)
		if quitado < 1 or quitado > tope:
			_fallo("en guardia, un golpe de 20 le quita %d a Lya (se espera de 1 a %d)" % [quitado, tope])
		else:
			print("  ok: en guardia, un golpe de 20 le quita %d a Lya (la mitad, como siempre)" % quitado)
		await create_timer(0.6).timeout
	lya["defendiendo"] = false
	AnimV12.fin_defensa(c, lya)
	await create_timer(0.4).timeout
	_espera_clip(lya, "guardia", "Lya deja la defensa")
	AnimV12.reaccion(c, garon, 3, false, 1.0)
	await create_timer(0.1).timeout
	_espera_clip(garon, "recibir_golpe", "golpe ligero de Garon")
	await create_timer(0.8).timeout
	AnimV12.embuir(c, garon)
	await create_timer(0.2).timeout
	_espera_clip(garon, "c12_embuir", "Embuir de Garon")
	await create_timer(1.3).timeout
	# cámara
	var esc0: float = c.escena.scale.x
	var p0: Vector2 = c._a_pantalla(c._centro(kael))
	AnimV12.camara(c, c._centro(kael), 1.08, 0.2, 0.3, 0.2)
	await create_timer(0.3).timeout
	if not c.escena.scale.x > esc0 * 1.03:
		_fallo("la cámara no acerca la escena (%.3f → %.3f)" % [esc0, c.escena.scale.x])
	var real: Vector2 = c.escena.get_global_transform() * c._centro(kael)
	if real.distance_to(c._a_pantalla(c._centro(kael))) > 1.0:
		_fallo("_a_pantalla no sigue a la cámara (%s frente a %s)" % [str(real), str(c._a_pantalla(c._centro(kael)))])
	await create_timer(0.6).timeout
	if absf(c.escena.scale.x - esc0) > 0.0001 or c._a_pantalla(c._centro(kael)).distance_to(p0) > 0.5:
		_fallo("la cámara no vuelve a su sitio (escala %.4f, antes %.4f)" % [c.escena.scale.x, esc0])
	Engine.set_meta("camaras_combate", false)
	AnimV12.camara(c, c._centro(kael), 1.08, 0.2, 0.3, 0.2)
	await create_timer(0.3).timeout
	if absf(c.escena.scale.x - esc0) > 0.0001:
		_fallo("con las cámaras apagadas la escena se mueve")
	Engine.set_meta("camaras_combate", true)
	# técnica de Lya: la magia de nivel II con la magia poderosa (sin daño: el impacto aquí no hace nada)
	var obj: Dictionary = c.enemigos.filter(func(e): return e["hp"] > 0)[0] if c.enemigos.any(func(e): return e["hp"] > 0) else c.enemigos[0]
	c.nivel_sel = 2
	var impactos_lya := [0]
	AnimV12.magia(c, lya, obj, "Fuego", func(): impactos_lya[0] += 1)
	await create_timer(1.2).timeout
	_espera_clip(lya, "magia_poderosa", "magia poderosa de Lya (nivel II)")
	await create_timer(3.0).timeout
	if impactos_lya[0] != 1:
		_fallo("la magia poderosa de Lya llama %d veces al impacto (se espera 1)" % impactos_lya[0])
	c.nivel_sel = 1
	# victoria escalonada
	for h in [kael, lya, garon]:
		AnimV12.victoria(c, h)
	await create_timer(0.1).timeout
	_espera_clip(kael, "victoria", "victoria de Kael (al momento)")
	if String(garon["p3d"].anim.assigned_animation) == "victoria":
		_fallo("Garon celebra a la vez que Kael (debía esperar)")
	await create_timer(0.6).timeout
	_espera_clip(garon, "victoria", "victoria de Garon (después)")
	print("  DETALLES: reacciones, defensa, Embuir, cámara y victoria revisados")
	detalles_fin = true


func _espera_clip(h: Dictionary, clip: String, que: String) -> void:
	var a := String(h["p3d"].anim.assigned_animation)
	if a != clip:
		_fallo("%s: se espera «%s» y está «%s»" % [que, clip, a])
	else:
		print("  ok: %s (%s)" % [que, clip])
