extends SceneTree
# Prueba de las cargas (V12, 12/11; recursos.gd cambiar_escena, precargar y la precarga del arranque; carga.gd;
# zonas3d/mar_cristal/gusano.gd). Sin ventana, con «-- 3d mardecristal sin_prologo», todo en la carpeta aislada:
#   1. Precarga del arranque: lo apagado (héroes v2, Naira, NPC del desierto, enemigos v12) y los prototipos sin enganchar
#      no se precargan; al encender su interruptor, sí. De Bramavidrio, solo la versión en uso y el modelo y la piel de su
#      perfil (en los tres perfiles).
#   2. Cambiar de escena: mientras dura, el aviso de carga dice qué se prepara, sin cifras (ningún «%»), y la ventana no
#      recibe entrada (un toque y una tecla enviados entonces no llegan a nadie); al acabar, el aviso se va y la entrada
#      vuelve. Una segunda llamada mientras dura no cambia nada (una sola escena nueva).
#   3. Mar de Cristal por Recursos: Bramavidrio queda preparado bajo el negro (sus piezas existen, escondidas, en calma, sin
#      estudios sobrantes); abierto a mano (sin negro), no se prepara nada.
#   4. El aviso pide en segundo plano el combate (Recursos.precargar, sin bloquear).
#   5. Al ir al combate la música de la exploración se funde ya (contexto «combate»).
#   6. Región → combate → ganar → región, 4 veces (Bramavidrio y combates al azar): siempre vuelve a la región, sin errores,
#      y la memoria no crece de una vuelta a otra (objetos, nodos, huérfanos y memoria estática, de la 2.ª a la 4.ª vuelta).

const REGION := "res://zonas3d/mar_cristal_3d.tscn"
const COMBATE := "res://combate.tscn"

var fallos: Array = []
var R
var P
var entradas := 0                     # eventos que llegan a la sonda de entrada
var sonda: Node


class Sonda extends Node:
	var al_recibir: Callable
	func _input(_e: InputEvent) -> void:
		al_recibir.call()


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _ok(c: bool, t: String) -> void:
	if not c:
		_fallo(t)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	R = root.get_node("Recursos")
	P = load("res://progreso.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("incienso", 100000)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("calidad_proto", "medio")
	sonda = Sonda.new()
	sonda.al_recibir = func(): entradas += 1
	root.add_child(sonda)
	_precarga()
	await _region_a_mano()
	await _transicion_a_region()
	await _vueltas()
	await _cerrar_limpio()
	print("FALLOS: %d" % fallos.size())
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	quit(1 if not fallos.is_empty() else 0)


# ---------------------------------------------------------------- 1. precarga del arranque
func _lista(perfil: String, metas := {}) -> PackedStringArray:
	var antes: String = Engine.get_meta("calidad_proto", "")
	Engine.set_meta("calidad_proto", perfil)
	for k in metas:
		Engine.set_meta(k, metas[k])
	var r = load("res://recursos.gd").new()
	var l: PackedStringArray = r.listar()
	r.free()
	for k in metas:
		Engine.remove_meta(k)
	Engine.set_meta("calidad_proto", antes)
	return l


func _precarga() -> void:
	var V = load("res://enemigos/bramavidrio/bramavidrio_version.gd")
	var carpeta: String = V.modelo().get_base_dir() + "/"
	for perfil in ["alto", "medio", "bajo"]:
		var l := _lista(perfil)
		for c in ["res://personajes/heroes_v2/", "res://personajes/naira/", "res://personajes/desierto/",
				"res://enemigos/guardian_piedra/", "res://enemigos/gorthor/", "res://enemigos/cencerrante/",
				"res://enemigos/vidracran/", "res://enemigos/tolvanera/"]:
			_ok(not Array(l).any(func(x): return x.begins_with(c)), "1: [%s] se precarga %s, que está apagado" % [perfil, c])
		var brama := Array(l).filter(func(x): return x.begins_with("res://enemigos/bramavidrio/") and x.get_extension() in ["glb", "webp"])
		var sufijo: String = {"alto": "", "medio": "_medio", "bajo": "_bajo"}[perfil]
		_ok(brama.filter(func(x): return not x.get_basename().contains("_normal")).size() == 2 and brama.size() <= 3, "1: [%s] de Bramavidrio se precargan %s (debería ser su modelo y su piel)" % [perfil, brama])
		for x in brama:
			_ok(x.get_base_dir() + "/" == carpeta and x.get_basename().ends_with(sufijo)
				and (sufijo != "" or not (x.get_basename().ends_with("_medio") or x.get_basename().ends_with("_bajo"))),
				"1: [%s] se precarga %s (otra versión u otro perfil)" % [perfil, x])
		_ok(Array(l).has("res://combate.tscn") and Array(l).has("res://kael.fbx"), "1: [%s] falta lo común en la precarga" % perfil)
	var con := _lista("medio", {"heroes_v2": true, "enemigos_v12": true, "naira_v12": true})
	_ok(Array(con).any(func(x): return x.begins_with("res://personajes/heroes_v2/")), "1: con heroes_v2 encendido no se precargan")
	_ok(Array(con).any(func(x): return x.begins_with("res://enemigos/gorthor/")), "1: con enemigos_v12 encendido no se precargan")
	_ok(Array(con).any(func(x): return x.begins_with("res://personajes/naira/")), "1: con naira_v12 encendido no se precarga")
	print("· 1. precarga: %d archivos en medio (lo apagado, fuera)" % _lista("medio").size())


# ---------------------------------------------------------------- 3b. sin negro, no se prepara nada
func _region_a_mano() -> void:
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	await _hasta(func(): return _escena() == REGION and current_scene.get("gusano") != null, 60.0)
	await _esperar(5)
	var v = current_scene
	_ok(v.gusano._raiz == null, "3: abierta a mano (sin negro), Bramavidrio se prepara igual")
	print("· 3b. región abierta a mano: nada preparado")


# ---------------------------------------------------------------- 2, 3, 5. la transición
func _transicion_a_region() -> void:
	var cambios := [0]
	var al_cambiar := func(n: Node):
		if n.get_parent() == root and n.scene_file_path == REGION:
			cambios[0] += 1
	root.child_entered_tree.connect(al_cambiar)
	Engine.set_meta("pos_3d_ok", false)
	R.cambiar_escena(REGION)
	R.cambiar_escena(REGION)                               # una segunda petición mientras dura: no hace nada
	_ok(R.cambiando and R.aviso_carga.visible and R.texto_carga != "", "2: al cambiar de escena no sale el aviso de carga")
	_ok(not R.lbl_carga.text.contains("%") and not R.lbl_carga.text.is_valid_float(), "2: el aviso de carga lleva una cifra: «%s»" % R.lbl_carga.text)
	_ok(root.gui_disable_input, "2: mientras se cambia de escena, la ventana sigue recibiendo entrada")
	var n0 := entradas
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.position = Vector2(640, 360)
	root.push_input(toque)
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_ENTER
	tecla.pressed = true
	root.push_input(tecla)
	_ok(entradas == n0, "2: un toque o una tecla durante el cambio llegan a la escena (%d)" % (entradas - n0))
	await _hasta(func(): return not R.cambiando, 60.0)
	_ok(_escena() == REGION, "2: no llega a la región (%s)" % _escena())
	_ok(cambios[0] == 1, "2: la región se monta %d veces con dos peticiones seguidas" % cambios[0])
	_ok(not R.aviso_carga.visible and not R.negro.visible and not root.gui_disable_input, "2: al acabar quedan el aviso, el negro o la entrada bloqueada")
	var n1 := entradas
	root.push_input(tecla)
	_ok(entradas == n1 + 1, "2: al acabar la entrada no vuelve")
	root.child_entered_tree.disconnect(al_cambiar)
	# 3. Bramavidrio preparado bajo el negro y escondido
	var v = current_scene
	_ok(v.gusano._raiz != null, "3: al entrar por Recursos, Bramavidrio no se prepara")
	if v.gusano._raiz != null:
		_ok(not v.gusano._lomo.visible and not v.gusano._polvo.emitting and v.gusano.estado == "calma",
			"3: tras prepararlo quedan a la vista el surco o el polvo (estado %s)" % v.gusano.estado)
		if v.gusano._gusano3d != null:
			_ok(not v.gusano._gusano3d.visible, "3: tras prepararlo, el modelo de Bramavidrio queda a la vista")
	_ok(v.find_children("*", "SubViewport", false, false).size() == 0, "3: queda un estudio de combate en la región")
	print("· 2-3. transición con aviso y sin entrada; Bramavidrio preparado y escondido")
	# 4. el aviso pide el combate en segundo plano
	v.clima.sistemicas = false
	v._colocar_kael(Vector3(80.0, 0.0, 40.0))
	v._ultima = v.kael.global_position
	var t0 := Time.get_ticks_msec()
	v.gusano._empezar_aviso(v.kael.global_position)
	_ok(Time.get_ticks_msec() - t0 < 1000, "4: el aviso tarda %d ms (bloquea)" % (Time.get_ticks_msec() - t0))
	_ok(R.esta(COMBATE) or R._en_hilo.has(COMBATE), "4: con el aviso no se pide el combate")
	v.gusano._irse("")
	v.gusano._cambiar("calma")
	print("· 4. el aviso pide el combate sin bloquear")


# ---------------------------------------------------------------- 5, 6. combates y vueltas
func _vueltas() -> void:
	var memorias: Array = []
	for i in 4:
		var v = current_scene
		var M = root.get_node_or_null("Musica")
		if i == 0:                                          # Bramavidrio, su combate fijo (como al emerger)
			v.encuentro("mc_bramavidrio", 13, "jefe", "¡Bramavidrio te cierra el paso! No hay huida.")
		else:
			v.encuentro()
		await _hasta(func(): return R.cambiando, 10.0)
		if M != null:
			_ok(M.contexto == "combate", "5: al ir al combate, la música de la exploración sigue (%s)" % M.contexto)
		_ok(await _hasta(func(): return _escena() == COMBATE and not R.cambiando, 60.0), "6: [%d] el combate no llega" % i)
		await _esperar(20)
		var c = current_scene
		for e in c.enemigos:
			e["hp"] = 0
		c._comprobar_fin()
		_ok(await _hasta(func(): return _escena() == REGION and not R.cambiando, 90.0), "6: [%d] no vuelve a la región (%s)" % [i, _escena()])
		await _esperar(30)
		var m := {"objetos": Performance.get_monitor(Performance.OBJECT_COUNT),
			"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"huerfanos": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
			"estatica": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0}
		memorias.append(m)
		print("· 6. vuelta %d: %d objetos, %d nodos, %d huérfanos, %.1f MB" % [i + 1, m["objetos"], m["nodos"], m["huerfanos"], m["estatica"]])
	if memorias.size() == 4:
		var a: Dictionary = memorias[1]
		var b: Dictionary = memorias[3]
		_ok(b["objetos"] - a["objetos"] < 150, "6: los objetos crecen de la 2.ª a la 4.ª vuelta (%d → %d)" % [a["objetos"], b["objetos"]])
		_ok(b["nodos"] - a["nodos"] < 30, "6: los nodos crecen (%d → %d)" % [a["nodos"], b["nodos"]])
		_ok(b["huerfanos"] <= a["huerfanos"], "6: quedan nodos huérfanos (%d → %d)" % [a["huerfanos"], b["huerfanos"]])
		_ok(b["estatica"] - a["estatica"] < 8.0, "6: la memoria estática crece %.1f MB" % (b["estatica"] - a["estatica"]))


# Al acabar: fuera la región y silencio (Musica), y se esperan los fundidos. Aun así, al cerrar Godot avisa de unas 12-14
# instancias y 6-7 recursos retenidos: son las reproducciones de los OGG del ambiente del desierto (fogata, oasis y viento;
# visto con --verbose el 12/11). No crecen con las vueltas (la memoria de la parte 6 es estable) y no son de la carga.
func _cerrar_limpio() -> void:
	var M = root.get_node_or_null("Musica")
	if M != null:
		M.pedir("silencio")
	if current_scene != null:
		current_scene.queue_free()
	await _esperar(75)
	if sonda != null:
		sonda.free()
