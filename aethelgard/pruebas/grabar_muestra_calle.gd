extends SceneTree
# GRABACIÓN (15/11), no prueba: Kael andando por la MUESTRA GRÁFICA de una calle de Oakhaven (zonas3d/muestra_calle/),
# para el Movie Maker de Godot. Kael ANDA (1,4 m/s, el clip de andar: marcha() del personaje) por un recorrido fijo:
# del oeste a la puerta (se para), por la calle a la boca del callejón, sube los escalones (se para), baja y sigue a la
# esquina del torreón (se para). La cámara es la de la muestra (le sigue en x, sin girar).
# Uso (datos aislados: APPDATA/LOCALAPPDATA a una carpeta temporal):
#   godot --path aethelgard --write-movie <x.avi> --fixed-fps 30 --resolution 1280x720 \
#         --script res://pruebas/grabar_muestra_calle.gd -- 3d sin_prologo [perfil=bajo|medio|alto]

const ESCENA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const VEL := 1.4
# [x, z, segundos de parada al llegar]
const RUTA := [[-11.0, 1.2, 0.8], [-8.4, 0.6, 0.0], [-6.6, -1.1, 1.6], [-4.2, 0.4, 0.0], [-1.2, 0.2, 0.0],
	[0.0, -2.6, 0.0], [0.0, -4.4, 0.0], [0.0, -6.4, 1.4], [0.0, -3.4, 0.0], [1.6, -0.4, 0.0], [5.0, 0.9, 0.0],
	[8.0, 0.6, 2.2]]
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
	Engine.set_meta("archivo_partida_prueba", "user://grabar_muestra_calle.save")
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("muestra_sin_titulo", true)
	change_scene_to_file(ESCENA)


func _suelo(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, p.y + 1.2, p.z), Vector3(p.x, p.y - 2.0, p.z))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	return r["position"].y if not r.is_empty() else p.y


func _process(delta: float) -> bool:
	frames += 1
	if v == null:
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			v = current_scene
			var r0: Array = RUTA[0]
			v._colocar_kael(Vector3(r0[0], 0.0, r0[1]))
			for n in v.get_children():                     # sin el panel de medidas (CAL/RND) en el vídeo
				if n is CanvasLayer:
					for b in n.get_children():
						if b is Button or (b is Label and b != v.get("titulo")):
							b.visible = false
			parada = float(r0[2])
			tramo = 1
		return false
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
	var meta_r: Array = RUTA[tramo]
	var p: Vector3 = v.kael.global_position
	var meta := Vector3(meta_r[0], p.y, meta_r[1])
	var falta := Vector3(meta.x - p.x, 0.0, meta.z - p.z)
	var paso := VEL * delta
	if falta.length() <= paso:
		p = Vector3(meta.x, p.y, meta.z)
		parada = float(meta_r[2])
		tramo += 1
		if tramo >= RUTA.size():
			fin = maxf(parada, 0.5)
			parada = 0.0
	else:
		var dir := falta.normalized()
		p += dir * paso
		v.kael.mirar(dir, 0.15)
		if v.kael.has_method("marcha"):
			v.kael.marcha(VEL)
	p.y = _suelo(p)
	v.kael.global_position = p
	v.seguro = p
	return false
