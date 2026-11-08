extends SceneTree
# Sonda (no es una prueba): ¿por qué cuesta unos 8 ms el fotograma en que un árbol empieza a tapar a Kael?
# 1) Kael anda como en medir_primeras_veces.gd hasta que algo lo tapa; apunta esas piezas y dónde estaba Kael.
# 2) Las saca del grupo «ocluye» (para que _oclusion no las toque) y las vuelve transparentes y opacas a mano cinco
#    veces con Kael en ese sitio (el árbol entre la cámara y Kael, grande en pantalla) y otras cinco con Kael lejos.
# 3) Repite en ese sitio cambiando una sola pieza cada vez.
#   Godot --path aethelgard --script res://pruebas/sonda_oclusion_repetida.gd --fixed-fps 30 -- 3d sin_prologo

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
var v
var frames := 0
var u_ant := 0
var piezas: Array = []
var sitio := Vector3.ZERO
var salida := Vector3.ZERO
var pendiente := ""
var resultados := {}
var fase := "cargar"
var f0 := 0


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Engine.set_meta("calidad_proto", "bajo")
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})
	change_scene_to_file(REGION)


func _poner(grupo: Array, si: bool, nombre: String) -> void:
	for mi in grupo:
		v._transparente(mi, si)
	pendiente = nombre


func _process(_d: float) -> bool:
	frames += 1
	var ahora := Time.get_ticks_usec()
	var ms := (ahora - u_ant) / 1000.0 if u_ant > 0 else 0.0
	u_ant = ahora
	Engine.max_fps = 0
	if pendiente != "":
		if not resultados.has(pendiente):
			resultados[pendiente] = []
		resultados[pendiente].append(snappedf(ms, 0.1))
		pendiente = ""
	if v == null and current_scene != null and current_scene.scene_file_path == REGION:
		v = current_scene
		f0 = frames
		fase = "asentarse"
	if v == null:
		return false
	v.perfil_fps = 0
	v.pasos = 0
	var f := frames - f0
	match fase:
		"asentarse":
			if f == 60:
				salida = v.kael.global_position
				v.destino = v._ajustar_destino(v.SENDERO[3])
				fase = "andar"
		"andar":
			if not v.tapados.is_empty():
				piezas = v.tapados.duplicate()
				sitio = v.kael.global_position
				for mi in piezas:
					var m = mi.get_meta("mat_opaco", mi.material_override)
					var mat_superficie = mi.mesh.surface_get_material(0)
					print("PIEZA %s  %d vértices  override=%s  material_de_la_malla=%s  sombra=%d  se_vuelve_transparente=%s" % [
						mi.get_path(), mi.mesh.surface_get_array_len(0), m.get_class() if m else "-",
						mat_superficie.get_class() if mat_superficie else "-", mi.cast_shadow, mi.has_meta("mat_opaco")])
				piezas = piezas.filter(func(mi): return mi.has_meta("mat_opaco"))
				fase = "parar"
				f0 = frames
		"parar":
			if f == 1:
				v.destino = null
				for mi in v.tapados:
					v._transparente(mi, false)
					mi.remove_from_group("ocluye")
				v.tapados = []
				v._colocar_kael(sitio)
			elif f >= 30:
				fase = "en_el_sitio"
				f0 = frames
		"en_el_sitio", "lejos", "una_a_una":
			var t := f % 20
			if fase == "una_a_una":
				var cual: Array = [piezas[0]] if f < 100 or piezas.size() < 2 else [piezas[1]]
				if t == 0:
					_poner(cual, true, "%s pieza %d a transparente" % [fase, 0 if f < 100 else 1])
				elif t == 10:
					_poner(cual, false, "%s pieza %d a opaco" % [fase, 0 if f < 100 else 1])
			else:
				if t == 0:
					_poner(piezas, true, fase + ": a transparente")
				elif t == 10:
					_poner(piezas, false, fase + ": a opaco")
			if f == 99 and fase == "en_el_sitio":
				v._colocar_kael(salida + Vector3(0, 0, 6))
				fase = "lejos_esperar"
				f0 = frames
			elif f == 99 and fase == "lejos":
				v._colocar_kael(sitio)
				fase = "volver_esperar"
				f0 = frames
			elif f == 199 and fase == "una_a_una":
				for k in resultados:
					print("%s: %s ms" % [k, resultados[k]])
				quit(0)
				return true
		"lejos_esperar":
			if f >= 30:
				fase = "lejos"
				f0 = frames
		"volver_esperar":
			if f >= 30:
				fase = "una_a_una"
				f0 = frames
	if frames > 3000:
		print("TIEMPO AGOTADO en la fase ", fase)
		quit(1)
		return true
	return false
