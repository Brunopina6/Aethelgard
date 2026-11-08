extends SceneTree
# Prueba del cofre de Pastos Verdes 3D (zonas3d/pastos_verdes_3d.gd), con la exploración 3D activa («-- 3d»). El
# guardado automático de la región escribe de verdad, pero en el archivo propio de la prueba
# (user://prueba_cofre3d.save, Engine «archivo_partida_prueba»): así se comprueba la partida guardada, no solo la memoria.
#   1. Al entrar, el cofre está cerrado y con su destello; el sonido no satura y no es mudo.
#   2. Kael llega andando hasta el cofre desde el camino y sale «Abrir cofre».
#   3. Al abrirlo: un premio (monedas, pociones o éter), el aviso, el sonido y la tapa abierta. Abrirlo otra vez no
#      da nada más.
#   4. La partida guardada lleva el cofre abierto y el premio.
#   5. Tras un combate (combate.tscn de verdad) y la vuelta, sigue abierto y sin botón.
#   6. Tras salir al mapa y volver a entrar, sigue abierto.
#   7. Al cargar la partida guardada, sigue abierto y el premio no se repite.
# No toca la partida de verdad.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ARCHIVO := "user://prueba_cofre3d.save"
const DESDE := Vector3(13.3, 0, -2)              # la salida del puente (SENDERO[5])
const ESPERA_MAX_MS := 40000

var frames := 0
var paso := 0
var t_paso := 0
var f_paso := 0
var R
var P
var inv
var antes := {}                                   # inventario antes de abrir
var despues := {}                                 # inventario después de abrir
var fallos: Array = []


func _initialize() -> void:
	R = root.get_node("Recursos")
	P = load("res://progreso.gd")
	inv = load("res://inventario.gd")
	if not load("res://modo3d.gd").activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d»)")
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	Engine.set_meta("partida_lista", true)         # como si la partida se hubiera cargado al arrancar
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true})   # sin las escenas de la misión
	if Engine.get_meta("cofres_abiertos", {}).has("pastos3d_arbol_magico"):
		_fallo("el cofre ya estaba abierto antes de empezar")
		return
	change_scene_to_file(REGION)
	_siguiente()


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	_borrar()
	quit(1)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _siguiente() -> void:
	paso += 1
	t_paso = Time.get_ticks_msec()
	f_paso = frames


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _inventario() -> Dictionary:
	return {"oro": inv.oro(), "Poción": inv.cantidad("Poción"), "Éter": inv.cantidad("Éter")}


func _lista(n: int) -> bool:                       # la escena esperada, ya cargada
	return _escena() == REGION and not R.cambiando and frames - f_paso >= n


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		_fallo("el paso %d no terminó en %d s (escena=%s)" % [paso, ESPERA_MAX_MS / 1000, _escena()])
		return false
	var r = current_scene
	match paso:
		1:
			if _lista(10):
				_entrada(r)
		2:                                          # Kael anda hasta el cofre
			r.pasos = 0                             # sin encuentros mientras anda (solo en la prueba)
			if r.cerca == "cofre":
				print("OK 2: Kael llegó andando hasta el cofre (%.1f m); botón «%s»" % [_plana(r.kael.global_position,
					r.cofre.global_position), r.boton_accion.text])
				_abrir(r)
			elif frames - f_paso > 900:
				_fallo("Kael no llegó al cofre (se quedó a %.1f m)" % _plana(r.kael.global_position, r.cofre.global_position))
		3:                                          # la tapa termina de abrirse; luego, al combate
			if frames - f_paso >= 30:
				_tras_abrir(r)
		4:
			if _escena() == "res://combate.tscn" and not R.cambiando and frames - f_paso >= 5:
				r._volver_al_mapa()
				_siguiente()
		5:
			if _lista(5):
				_comprobar_abierto(r, "5 (tras el combate)")
				r._salir()
				_siguiente()
		6:
			if _escena() == "res://mapa.tscn" and not R.cambiando and frames - f_paso >= 5:
				change_scene_to_file(REGION)
				_siguiente()
		7:
			if _lista(10):
				_comprobar_abierto(r, "6 (al volver a entrar)")
				var guardada = P.leer(ARCHIVO)
				for k in P.CLAVES:
					if Engine.has_meta(k):
						Engine.remove_meta(k)
				Engine.remove_meta("partida_lista")
				var escena: String = P.cargar()
				if guardada == null or escena == "":
					_fallo("no se pudo cargar la partida guardada")
					return false
				change_scene_to_file(REGION)
				_siguiente()
		8:
			if _lista(10):
				_comprobar_abierto(r, "7 (al cargar la partida)")
				if _inventario() != despues:
					fallos.append("7: al cargar, el inventario es %s y no %s" % [_inventario(), despues])
				return _terminar()
	return false


func _entrada(r) -> void:
	if r.cofre == null or r.tapa_cofre == null:
		_fallo("no hay cofre en la región")
		return
	if r.cofre_abierto() or absf(r.tapa_cofre.rotation.x) > 0.01 or r.brillo_cofre == null:
		fallos.append("1: el cofre no empieza cerrado y con su destello")
	if r._prohibido(r.cofre.global_position) or r._dist_sendero(r.cofre.global_position) < 1.2:
		fallos.append("1: el cofre está en una zona prohibida o encima del camino")
	var w: AudioStreamWAV = r.sonido_cofre()
	var pico := 0.0
	var suma := 0.0
	for i in range(0, w.data.size(), 2):
		var s: float = absf(w.data.decode_s16(i) / 32767.0)
		pico = maxf(pico, s)
		suma += s * s
	var rms := sqrt(suma / (w.data.size() / 2.0))
	var dur := (w.data.size() / 2.0) / w.mix_rate
	print("OK 1: cofre cerrado en %s; sonido de %.2f s, pico %.2f y RMS %.3f" % [r.cofre.global_position.snapped(Vector3.ONE * 0.1), dur, pico, rms])
	if pico >= 0.99 or rms < 0.01:
		fallos.append("1: el sonido del cofre satura o es casi mudo (pico %.2f, RMS %.3f)" % [pico, rms])
	var y: float = r.altura(DESDE.x, DESDE.z)
	r._colocar_kael(Vector3(DESDE.x, y, DESDE.z))
	r.destino = r._ajustar_destino(r.cofre.global_position + (DESDE - r.cofre.global_position).normalized() * 1.0)
	_siguiente()


func _abrir(r) -> void:
	antes = _inventario()
	r._accion()
	despues = _inventario()
	var dif := {}
	for k in antes:
		if despues[k] != antes[k]:
			dif[k] = despues[k] - antes[k]
	var premio_ok: bool = dif.size() == 1 and (
		(dif.has("oro") and dif["oro"] >= 40 and dif["oro"] <= 120) or dif.get("Poción", 0) == 2 or dif.get("Éter", 0) == 1)
	if not r.cofre_abierto() or not premio_ok:
		fallos.append("3: al abrir, el cofre=%s y el premio=%s" % [r.cofre_abierto(), dif])
	if not r.aviso.text.begins_with("¡Has encontrado"):
		fallos.append("3: el aviso dice «%s»" % r.aviso.text)
	var sonando := false
	for n in r.get_children():
		if n is AudioStreamPlayer and n.playing:
			sonando = true
	if not sonando:
		fallos.append("3: no suena nada al abrir")
	r._accion()                                     # otra vez: nada más
	r._abrir_cofre()
	if _inventario() != despues:
		fallos.append("3: abrir otra vez cambia el inventario (%s)" % _inventario())
	print("OK 3: premio %s; aviso «%s»" % [dif, r.aviso.text])
	_siguiente()


func _tras_abrir(r) -> void:
	if absf(r.tapa_cofre.rotation.x - deg_to_rad(r.COFRE_ABIERTA)) > 0.05 or r.brillo_cofre != null:
		fallos.append("3: la tapa no se ha abierto o sigue el destello")
	var guardada = P.leer(ARCHIVO)
	if guardada == null or not guardada.get("cofres_abiertos", {}).has(r.ID_COFRE):
		fallos.append("4: la partida guardada no lleva el cofre abierto")
	elif guardada["inventario"]["oro"] != despues["oro"] or guardada["inventario"]["objetos"].get("Poción", 0) != despues["Poción"] \
			or guardada["inventario"]["objetos"].get("Éter", 0) != despues["Éter"]:
		fallos.append("4: la partida guardada no lleva el premio")
	else:
		print("OK 4: la partida guardada lleva el cofre abierto y el premio")
	r._encuentro()
	_siguiente()


func _comprobar_abierto(r, cuando: String) -> void:
	r._comprobar_cerca()
	var ok: bool = r.cofre_abierto() and absf(r.tapa_cofre.rotation.x - deg_to_rad(r.COFRE_ABIERTA)) < 0.01 \
		and r.brillo_cofre == null and _inventario() == despues
	r._colocar_kael(r.cofre.global_position + Vector3(1.2, 0, 0.4))
	r._comprobar_cerca()
	if r.cerca == "cofre":
		ok = false
	if ok:
		print("OK %s: el cofre sigue abierto, sin botón, y el inventario no cambia" % cuando)
	else:
		fallos.append("%s: el cofre no sigue abierto o el inventario cambió (%s)" % [cuando, _inventario()])


func _terminar() -> bool:
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	return true


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
