extends SceneTree
# Prueba de los comentarios de los héroes en Pastos Verdes 3D (09/11; textos de narrativa en dialogos/comentarios.gd):
#   1. Al abrir el cofre, sale el comentario de «cofre» poco después del premio (no antes de 1 s).
#   2. Quieto unos 14 s sin diálogo, sale el de «quieto»; moverse reinicia la espera.
#   3. Si empieza un diálogo, el comentario en pantalla se quita.
# Misión desde cero, sin prólogo («-- 3d sin_prologo»); solo habla quien está en el grupo.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const Comentarios := preload("res://dialogos/comentarios.gd")

var fallos := 0
var D
var R


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	Engine.set_meta("hitos", {})
	Engine.set_meta("cofres_abiertos", {})
	Engine.set_meta(Comentarios.META, {})
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


# (19/11, PC-10) por RELOJ, solo para montar la región: con --fixed-fps los fotogramas vuelan y una carga va en tiempo
# real. El resto espera en tiempo de JUEGO a propósito (comentarios y diálogos).
func _hasta_reloj(cond: Callable, segundos := 60.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(segundos * 1000.0):
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _caja(r) -> Node:
	if r._capa_ui == null:
		return null
	for n in r._capa_ui.get_children():
		if n.name.begins_with("comentario") and not n.is_queued_for_deletion():
			return n
	return null


func _dicho(momento: String) -> bool:
	var d := Comentarios.dichos()
	for f in Comentarios.MOMENTOS[momento]["frases"]:
		if d.has(f["texto"]):
			return true
	return false


func _probar() -> void:
	if not await _hasta_reloj(func(): return current_scene != null and current_scene.scene_file_path == REGION and not R.cambiando, 90.0):
		_fallo("no se llega a la región en 90 s (R.cambiando=%s)" % R.cambiando)
		print("FALLOS: %d" % fallos)
		quit(1)
		return
	var r = current_scene
	if await _hasta(func(): return D.current_timeline != null, 20.0):     # PV-02 al llegar
		await _esperar(10)
		D.end_timeline()
	await _hasta(func(): return D.current_timeline == null, 10.0)
	await _esperar(20)
	Engine.set_meta(Comentarios.META, {})
	# 1. el cofre
	if r.cofre == null:
		_fallo("1: la región no tiene cofre")
	else:
		r._abrir_cofre()
		await _esperar(20)                                   # 0,66 s: aún no
		if _caja(r) != null:
			_fallo("1: el comentario del cofre sale antes de tiempo")
		if not await _hasta(func(): return _caja(r) != null, 6.0):
			_fallo("1: tras abrir el cofre no sale ningún comentario")
		elif not _dicho("cofre"):
			_fallo("1: el comentario que sale no es el del cofre")
		await _hasta(func(): return _caja(r) == null, 20.0)
	# 2. quieto
	r._quieto_t = 0.0
	await _esperar(30 * 10)                                  # 10 s: aún no
	if _caja(r) != null:
		_fallo("2: el comentario de quieto sale antes de los 14 s")
	r.destino = r.kael.global_position + Vector3(1.5, 0, 0)   # se mueve: la espera vuelve a cero
	await _esperar(5)
	if r._quieto_t > 0.5:
		_fallo("2: moverse no reinicia la espera (%.1f s)" % r._quieto_t)
	r.destino = null
	await _hasta(func(): return r.movimiento == "", 5.0)
	if not await _hasta(func(): return _caja(r) != null, 20.0):
		_fallo("2: quieto 20 s no sale ningún comentario")
	elif not _dicho("quieto"):
		_fallo("2: el comentario que sale no es el de quieto")
	# 3. un diálogo quita el comentario
	if _caja(r) != null:
		D.start("pv_tilo")
		await _esperar(5)
		if _caja(r) != null:
			_fallo("3: con un diálogo abierto sigue el comentario en pantalla")
		D.end_timeline()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
