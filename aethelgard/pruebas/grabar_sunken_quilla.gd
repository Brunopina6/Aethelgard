extends SceneTree
# GRABACIÓN (V12, 16/11; no es una prueba): Kael recorre la Quilla horneada de Sunken City (EXPERIMENTAL) de la popa a la
# rampa con la cuadrilla trabajando, se para a hablar con el calafate y sigue. Con el Movie Maker de Godot:
#   godot --path aethelgard --write-movie <x.avi> --fixed-fps 30 --resolution 1280x720 \
#         --script res://pruebas/grabar_sunken_quilla.gd -- 3d sunken3d sin_prologo [perfil=bajo|medio|alto]
# Partida propia (Engine «archivo_partida_prueba»), que se borra al acabar.

const REGION := "res://zonas3d/sunken_3d.tscn"
const ARCHIVO := "user://grabar_sunken_quilla.save"
const RECORRIDO := [Vector2(40.0, 50.5), Vector2(40.0, 45.0), Vector2(41.3, 41.2), "hablar:calafate", Vector2(40.6, 38.4),
	Vector2(39.2, 36.0), Vector2(38.6, 33.0), "hablar:carpintera", Vector2(40.6, 31.6), Vector2(41.3, 30.6),
	"hablar:marineros", Vector2(40.0, 29.4)]
var v
var T


func _initialize() -> void:
	var perfil := "bajo"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("sunken_quilla_v12", true)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	var P = load("res://progreso.gd")
	P.cargar()
	for h in ["pv_02", "pv_03", "pv_05"]:
		P.poner_hito(h)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("partida_lista", true)
	_grabar.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _grabar() -> void:
	change_scene_to_file(REGION)
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.get("kael") != null:
			break
	v = current_scene
	T = load("res://zonas3d/sunken/trazado.gd")
	v._colocar_kael(T.en_mundo(RECORRIDO[0]))
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)
	await _frames(45)
	for paso in RECORRIDO.slice(1):
		if paso is String:
			var id: String = String(paso).trim_prefix("hablar:")
			v._comprobar_cerca()
			v.cerca = id
			v._bloqueo = 0.0
			v._accion()
			await _frames(110)
			continue
		v.destino = v._ajustar_destino(T.en_mundo(paso))
		for i in 240:
			await process_frame
			if v.destino == null:
				break
		await _frames(8)
	await _frames(60)
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	quit()
