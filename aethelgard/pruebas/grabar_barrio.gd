extends SceneTree
# GRABACIÓN (16/11, agente A), no prueba: el recorrido del BARRIO EXPERIMENTAL de Oakhaven (zonas3d/barrio/, en pruebas;
# solo desde el banco de Auditoría) para el Movie Maker de Godot. Kael ANDA (2,2 m/s, marcha() del personaje) el bucle
# entero del trazado (T.BUCLE: caravanas → calle comercial → plaza → talleres → casas → atajo → caravanas) con el grupo
# detrás; la cámara es la del barrio (por zonas, sin girar). Se para un momento en el horno, la plaza, el patio de
# talleres, la vivienda y el arco del atajo.
# Uso (datos aislados: APPDATA/LOCALAPPDATA a una carpeta temporal, nunca la real):
#   godot --path aethelgard --write-movie <x.avi> --fixed-fps 30 --resolution 1280x720 \
#         --script res://pruebas/grabar_barrio.gd -- 3d sin_prologo [perfil=bajo|medio|alto]

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const T := preload("res://zonas3d/barrio/trazado.gd")
const VEL := 2.2
const PARADAS := {"n_horno": 1.2, "n_plaza": 1.2, "n_patio_n": 1.0, "n_res_c": 1.2, "n_atajo_s": 0.8}
var perfil := "bajo"
var v
var tramo := 0
var parada := 0.0
var fin := 0.0
var frames := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()                                  # la partida del banco (archivo propio en user://)
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(ESCENA)


func _process(delta: float) -> bool:
	frames += 1
	if v == null:
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			v = current_scene
			v._colocar_kael(T.ancla(T.BUCLE[0]))
			if v.grupo != null:
				v.grupo.colocar(Vector3.BACK)
			for n in v.get_children():                     # sin el panel de medidas ni los botones en el vídeo
				if n is CanvasLayer:
					for b in n.get_children():
						if b is Button or (b is Label and b != v.get("titulo") and b != v.get("aviso")):
							b.visible = false
			parada = 1.0
			tramo = 1
		return false
	v.boton_accion.visible = false
	if fin > 0.0:
		fin -= delta
		if fin <= 0.0:
			print("GRABACIÓN HECHA (%d fotogramas)" % frames)
			quit(0)
			return true
		return false
	if parada > 0.0:
		parada -= delta
		if v.kael.has_method("parar_marcha") and v.kael.marcha_actual() != "":
			v.kael.parar_marcha()
		return false
	var meta := T.ancla(T.BUCLE[tramo])
	var p: Vector3 = v.kael.global_position
	var falta := Vector3(meta.x - p.x, 0.0, meta.z - p.z)
	var paso := VEL * delta
	if falta.length() <= paso:
		p = Vector3(meta.x, p.y, meta.z)
		parada = float(PARADAS.get(T.BUCLE[tramo], 0.0))
		tramo += 1
		if tramo >= T.BUCLE.size():
			fin = 1.5
			parada = 0.0
	else:
		var dir := falta.normalized()
		p += dir * paso
		v.kael.mirar(dir, 0.15)
		if v.kael.has_method("marcha"):
			v.kael.marcha(VEL)
	p.y = T.altura(p.x, p.z)
	v.kael.global_position = p
	v.seguro = p
	return false
