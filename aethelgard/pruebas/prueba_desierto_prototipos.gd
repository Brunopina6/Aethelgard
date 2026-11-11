extends SceneTree
# Prueba sin ventana de los PROTOTIPOS del desierto (V12, 12/11/2026, especialista de animaciones):
#   --headless --script res://pruebas/prueba_desierto_prototipos.gd --fixed-fps 30
# Comprueba, sin tocar la región ni el combate:
#   - Ismena y Oren (npc_desierto_3d.gd): cargan, tienen sus clips, el reposo va en bucle, un gesto vuelve al reposo,
#     hablar() no repite el mismo gesto dos frases seguidas y el interruptor está APAGADO por defecto.
#   - Vidracrán y Tolvanera: cada clip existe y dura lo que dice su _clips.json; las secuencias del contrato
#     (enterrarse → no se le puede apuntar → aviso → emerger con impacto; ráfaga, torbellino, curarse, agua, derrota)
#     emiten sus señales y el impacto llega en su instante (±2 fotogramas a 30 fps).
# Acaba con «FALLOS: n» y quit(n > 0).

var fallos := 0
var cuadros := 0


func _initialize() -> void:
	_correr.call_deferred()


func _process(_d: float) -> bool:
	cuadros += 1
	return false


func _ok(cond: bool, txt: String) -> void:
	if cond:
		print("ok    ", txt)
	else:
		print("FALLO ", txt)
		fallos += 1


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await _esperar(int(ceil(s * 30.0)) + 2)


func _json(ruta: String) -> Dictionary:
	var f := FileAccess.open(ruta, FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) if f else {}


func _correr() -> void:
	await _npcs()
	await _vidracran()
	await _tolvanera()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _npcs() -> void:
	var NPC = load("res://personajes/desierto/npc_desierto_3d.gd")
	_ok(not NPC.activado(), "el interruptor npc_desierto_v12 está apagado por defecto")
	for q in [["ismena", ["reposo", "hablar", "mapa", "horizonte", "reganar"]], ["oren", ["reposo", "hablar", "risa", "encogerse"]]]:
		var n: Node3D = NPC.crear(q[0])
		root.add_child(n)
		await _esperar(3)
		_ok(n.anim != null, "%s: modelo y AnimationPlayer" % q[0])
		if n.anim == null:
			continue
		for c in q[1]:
			_ok(n.anim.has_animation(c), "%s: clip %s" % [q[0], c])
		_ok(n.anim.get_animation("reposo").loop_mode == Animation.LOOP_LINEAR, "%s: reposo en bucle" % q[0])
		var g: String = q[1][2]
		n.gesto(g)
		await _esperar(2)
		_ok(String(n.anim.current_animation) == g, "%s: suena el gesto %s" % [q[0], g])
		await _segundos(n.anim.get_animation(g).length + 0.4)
		_ok(String(n.anim.current_animation) == "reposo", "%s: tras %s vuelve al reposo" % [q[0], g])
		n.en_dialogo(true)
		var vistos: Array = []
		for i in 6:
			n.hablar()
			await _esperar(2)
			vistos.append(String(n.anim.current_animation))
			await _segundos(n.anim.current_animation_length if String(n.anim.current_animation) != "reposo" else 0.2)
		var repetido := false
		for i in range(1, vistos.size()):
			if vistos[i] != "reposo" and vistos[i] == vistos[i - 1]:
				repetido = true
		_ok(not repetido, "%s: hablar() no repite el mismo gesto seguido %s" % [q[0], vistos])
		n.queue_free()
		await _esperar(2)


func _comprobar_clips(c: Node3D, cual: String) -> void:
	var info := _json("res://enemigos/%s/%s_clips.json" % [cual, cual])
	_ok(not info.is_empty(), "%s: %s_clips.json" % [cual, cual])
	for clip in info:
		if clip.begins_with("_"):
			continue
		var tiene: bool = c.anim.has_animation(clip)
		_ok(tiene, "%s: clip %s" % [cual, clip])
		if tiene:
			var d: float = c.anim.get_animation(clip).length
			_ok(absf(d - float(info[clip]["duracion"])) <= 1.5 / 30.0, "%s: %s dura %.3f s (ficha %.3f)" % [cual, clip, d, info[clip]["duracion"]])


func _medir_impacto(c: Node3D, ataque: String, esperado: float, cual: String) -> void:
	var t0 := cuadros
	var golpe := [-1]
	var cb := func(_a): golpe[0] = cuadros
	c.impacto.connect(cb)
	c.atacar(ataque)
	await _segundos(c.duracion(ataque) + 0.5)
	c.impacto.disconnect(cb)
	_ok(golpe[0] >= 0, "%s: %s emite impacto" % [cual, ataque])
	if golpe[0] >= 0:
		var t: float = (golpe[0] - t0) / 30.0
		_ok(absf(t - esperado) <= 2.0 / 30.0, "%s: impacto de %s a %.3f s (ficha %.3f)" % [cual, ataque, t, esperado])


func _vidracran() -> void:
	var c: Node3D = load("res://enemigos/vidracran/vidracran_3d.gd").new()
	root.add_child(c)
	await _esperar(3)
	_ok(c.anim != null and c.skel != null, "vidracran: modelo, AnimationPlayer y esqueleto")
	if c.anim == null:
		return
	await _comprobar_clips(c, "vidracran")
	_ok(c.puede_ser_objetivo(), "vidracran: fuera de la arena se le puede apuntar")
	await _medir_impacto(c, "pinzas", 14.0 / 30.0, "vidracran")
	c.enterrarse()
	await _segundos(c.duracion("enterrarse") + 0.2)
	_ok(c.enterrado and not c.puede_ser_objetivo(), "vidracran: enterrado, no se le puede apuntar")
	_ok(String(c.anim.current_animation) == "enterrado", "vidracran: espera enterrado (cola fuera)")
	var avisado := [false]
	c.aviso.connect(func(_a): avisado[0] = true)
	c.avisar()
	await _segundos(c.duracion("aviso_aguijon") + 0.2)
	_ok(avisado[0], "vidracran: el bulbo avisa (señal aviso)")
	_ok(c.enterrado and String(c.anim.current_animation) == "enterrado", "vidracran: tras el aviso sigue enterrado")
	await _medir_impacto(c, "emerger_aguijon", 15.0 / 30.0, "vidracran")
	_ok(not c.enterrado and String(c.anim.current_animation) == "reposo", "vidracran: tras emerger, fuera y en reposo")
	c.recibir_golpe()
	await _segundos(0.8)
	_ok(String(c.anim.current_animation) == "reposo", "vidracran: tras el golpe, reposo")
	var fin := [false]
	c.clip_terminado.connect(func(cl): fin[0] = fin[0] or cl == "derrota")
	c.derrota()
	await _segundos(c.duracion("derrota") + 0.3)
	_ok(fin[0], "vidracran: derrota termina")
	c.queue_free()
	await _esperar(2)


func _tolvanera() -> void:
	var c: Node3D = load("res://enemigos/tolvanera/tolvanera_3d.gd").new()
	root.add_child(c)
	await _esperar(3)
	_ok(c.anim != null and c.skel != null and c._i_escombros >= 0, "tolvanera: modelo, esqueleto y hueso de escombros")
	if c.anim == null:
		return
	await _comprobar_clips(c, "tolvanera")
	_ok(c._mats.size() == 3, "tolvanera: tres capas de polvo con su sombreado (%d)" % c._mats.size())
	var avisado := [false]
	c.aviso.connect(func(_a): avisado[0] = true)
	c.avisar()
	await _segundos(c.duracion("aviso_rafaga") + 0.1)
	_ok(avisado[0], "tolvanera: aviso de la ráfaga")
	await _medir_impacto(c, "rafaga", 13.0 / 30.0, "tolvanera")
	await _medir_impacto(c, "torbellino", 26.0 / 30.0, "tolvanera")
	var curado := [false]
	c.curado.connect(func(): curado[0] = true)
	c.curarse_viento()
	await _segundos(c.duracion("curarse_viento") + 0.4)
	_ok(curado[0] and String(c.anim.current_animation) == "reposo", "tolvanera: el viento le cura y vuelve al reposo")
	c.asentar_agua()
	await _segundos(c.duracion("agua_asienta") + 0.4)
	_ok(String(c.anim.current_animation) == "reposo", "tolvanera: el Agua lo asienta y se recompone")
	var fin := [false]
	c.clip_terminado.connect(func(cl): fin[0] = fin[0] or cl == "derrota")
	c.derrota()
	await _segundos(c.duracion("derrota") + 0.3)
	_ok(fin[0], "tolvanera: derrota termina")
	c.queue_free()
	await _esperar(2)
