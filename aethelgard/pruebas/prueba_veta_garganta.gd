extends SceneTree
# La veta del Hierro de la Falla en la Garganta 3D (V10, encargo «El pedido de Maese Ferro»; zonas3d/garganta_3d.gd).
# Escena de verdad, «-- 3d garganta3d sin_prologo». Partida propia (user://prueba_veta_garganta.save).
#   1. Sin el encargo no hay veta.
#   2. Con la pista de Garon (hito enc_herrero_pista), la veta está; picarla da 1 Hierro de la Falla y el hito
#      enc_herrero_veta, y la veta desaparece. Con Lya y Garon en el grupo lo comentan (gg_veta).
#   3. Picarla otra vez no da más hierro. Sin Lya ni Garon: solo el aviso, sin diálogo.
#   4. (15/11, auditoría) Partida antigua que perdió el hierro (veta picada, pedido sin cerrar, cero hierro): al entrar
#      la veta vuelve y da UNO; picar otra vez no da más; al volver a entrar con el hierro no está; con el pedido ya
#      cerrado y sin hierro, tampoco. Nunca cierra el encargo.
# Termina con «FALLOS: n» y quit(1) si algo no se cumple.

const REGION := "res://zonas3d/garganta_3d.tscn"
const ARCHIVO := "user://prueba_veta_garganta.save"
const HIERRO := "Hierro de la Falla"

var frames := 0
var paso := 0
var f_paso := 0
var t_paso := 0
const ESPERA_MAX_MS := 60000            # (19/11, PC-10) tope de cada paso por RELOJ (antes, 3600 fotogramas en total)
const TOPE_TOTAL_MS := 150000           # (19/11, PC-10, KAEL_ESPERAS_19_11) y de toda la prueba, por debajo de los 180 s del ejecutor
var t_inicio := Time.get_ticks_msec()
var R
var P
var inv
var fallos: Array = []
var viejo: Node = null


func _initialize() -> void:
	R = root.get_node("Recursos")
	P = load("res://progreso.gd")
	inv = load("res://inventario.gd")
	if not load("res://modo3d.gd").activo():
		fallos.append("la exploración 3D no está activa (falta «-- 3d»)")
		_terminar()
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("partida_lista", true)
	for k in ["mazmorras", "inventario", "grupo_activo", "pos_3d", "pos_3d_ok", "pos_3d_lugar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	change_scene_to_file(REGION)
	_siguiente(1)


func _siguiente(n: int) -> void:
	paso = n
	f_paso = frames
	t_paso = Time.get_ticks_msec()


func _lista() -> bool:
	return current_scene != null and current_scene.scene_file_path == REGION and not R.cambiando and frames - f_paso >= 8


func _hierro() -> int:
	return inv.cantidad(HIERRO)


func _terminar() -> void:
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _process(_d: float) -> bool:
	frames += 1
	if paso > 0 and Time.get_ticks_msec() - t_inicio > TOPE_TOTAL_MS:
		fallos.append("la prueba no terminó en %d s de reloj (paso %d, escena=%s)" % [TOPE_TOTAL_MS / 1000, paso,
			current_scene.scene_file_path if current_scene != null else "(ninguna)"])
		_terminar()
		return false
	if paso > 0 and Time.get_ticks_msec() - t_paso > ESPERA_MAX_MS:
		fallos.append("el paso %d no terminó en %d s (escena=%s, R.cambiando=%s)" % [paso, ESPERA_MAX_MS / 1000,
			current_scene.scene_file_path if current_scene != null else "(ninguna)", R.cambiando])
		_terminar()
		return false
	var dg = root.get_node_or_null("Dialogic")
	match paso:
		1:
			if _lista():
				var r = current_scene
				if r.veta != null:
					fallos.append("1: sin el encargo ya hay veta")
				P.poner_hito("enc_herrero_pedido")
				P.poner_hito("enc_herrero_pista")
				Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
				viejo = r
				change_scene_to_file(REGION)
				_siguiente(2)
		2:
			if _lista() and current_scene != viejo:
				var r = current_scene
				if r.veta == null:
					fallos.append("2: con la pista de Garon no está la veta")
				Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])   # la región pone el grupo de la misión al entrar
				var antes := _hierro()
				r._picar_veta()
				if _hierro() != antes + 1:
					fallos.append("2: picar la veta no da 1 %s (%d → %d)" % [HIERRO, antes, _hierro()])
				if not P.hito("enc_herrero_veta"):
					fallos.append("2: no se apunta enc_herrero_veta")
				_siguiente(3)
		3:
			if frames - f_paso >= 4:
				var r = current_scene
				if r.veta != null and is_instance_valid(r.veta) and not r.veta.is_queued_for_deletion():
					fallos.append("2: la veta sigue ahí")
				if dg == null or dg.current_timeline == null or not dg.current_timeline.resource_path.ends_with("gg_veta.dtl"):
					fallos.append("2: con Lya y Garon no empieza gg_veta (%s)" % [dg.current_timeline.resource_path if dg != null and dg.current_timeline != null else "ninguno"])
				if dg != null and dg.current_timeline != null:
					dg.end_timeline()
				var antes := _hierro()
				r._picar_veta()
				if _hierro() != antes:
					fallos.append("3: picarla otra vez da más hierro")
				# sin Lya ni Garon: solo el aviso
				Engine.get_meta("hitos", {}).erase("enc_herrero_veta")
				_siguiente(4)
		4:
			if frames - f_paso >= 12:
				var r = current_scene
				Engine.set_meta("grupo_activo", ["Kael"])
				var antes := _hierro()
				r._picar_veta()
				if _hierro() != antes + 1 or not P.hito("enc_herrero_veta"):
					fallos.append("3: sin Lya ni Garon, picar no da el hierro o el hito")
				if dg != null and dg.current_timeline != null and dg.current_timeline.resource_path.ends_with("gg_veta.dtl"):
					fallos.append("3: sin Lya ni Garon empieza gg_veta")
				if dg != null and dg.current_timeline != null:
					dg.end_timeline()
				while _hierro() > 0:                   # la partida antigua: el hierro vendido antes de la reserva
					inv.gastar(HIERRO)
				viejo = r
				change_scene_to_file(REGION)
				_siguiente(5)
		5:
			if _lista() and current_scene != viejo:
				var r = current_scene
				if r.veta == null or not r._veta_pendiente():
					fallos.append("4: sin hierro y con el pedido pendiente, la veta no vuelve")
				if not r._piezas_al_alcance().any(func(x): return x[0] == "veta"):
					fallos.append("4: la veta recuperada no tiene botón")
				r._picar_veta()
				if _hierro() != 1:
					fallos.append("4: la veta recuperada no da 1 %s (%d)" % [HIERRO, _hierro()])
				r._picar_veta()
				if _hierro() != 1:
					fallos.append("4: la veta recuperada da hierro dos veces (%d)" % _hierro())
				if P.hito("enc_herrero_fin"):
					fallos.append("4: recuperar el hierro cierra el encargo")
				if not load("res://talleres.gd").reservado(HIERRO):
					fallos.append("4: el hierro recuperado se puede vender")
				viejo = r
				change_scene_to_file(REGION)
				_siguiente(6)
		6:
			if _lista() and current_scene != viejo:
				var r = current_scene
				if r.veta != null or r._piezas_al_alcance().any(func(x): return x[0] == "veta"):
					fallos.append("4: con el hierro en la mochila, la veta sigue ahí")
				P.poner_hito("enc_herrero_fin")
				inv.gastar(HIERRO)
				viejo = r
				change_scene_to_file(REGION)
				_siguiente(7)
		7:
			if _lista() and current_scene != viejo:
				var r = current_scene
				if r.veta != null or r._veta_pendiente():
					fallos.append("4: con el pedido cerrado, la veta vuelve")
				var antes := _hierro()
				r._picar_veta()
				if _hierro() != antes:
					fallos.append("4: con el pedido cerrado, picar da hierro")
				print("OK veta de la Garganta: aparece con la pista, da el hierro una vez, gg_veta con Lya y Garon; recuperación")
				_terminar()
				return true
	return false
