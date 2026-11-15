extends SceneTree
# Capturas COMPARABLES de las correcciones de la muestra de la calle (15/11, encargo del usuario tras probarla en el
# Redmi): Kael en los mismos sitios, con la cámara DE JUEGO de la muestra (la escena corre normal: la cámara le sigue),
# para comparar antes y después de cada corrección:
#   callejon_alto     arriba del callejón (donde el tejado del oeste lo tapaba)
#   callejon_rellano  el rellano del callejón, en sombra (Kael muy azul)
#   puerta            al sol, ante la puerta verde (la sombra de contacto)
#   inicio            al sol, al oeste (la sombra de contacto, otra luz)
# Por sitio: la captura entera (1600×720, como el Redmi) y un recorte 2× alrededor de Kael; imprime la sonda (sol/cielo),
# si un rayo de la cámara al pecho de Kael choca con algo y el color medio del recorte.
# Uso: --path aethelgard --resolution 1600x720 --script res://pruebas/fotos_muestra_correcciones.gd -- 3d sin_prologo
#      perfil=bajo etiqueta=antes|despues salida=<carpeta>

const MUESTRA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const SITIOS := [["callejon_alto", Vector3(0.0, 0.0, -7.1)], ["callejon_oeste", Vector3(-1.45, 0.0, -7.1)], ["callejon_oeste_bajo", Vector3(-1.45, 0.0, -5.8)], ["callejon_rellano", Vector3(0.0, 0.0, -5.6)],
	["puerta", Vector3(-6.6, 0.0, -1.2)], ["inicio", Vector3(-9.5, 0.0, 1.0)]]
var perfil := "bajo"
var etiqueta := "antes"
var salida := "D:/REBELUM_diagnostico/muestra_calle_15_11/correcciones"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("etiqueta="):
			etiqueta = a.trim_prefix("etiqueta=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		elif a == "precalentar":                     # (el interruptor de sesión del banco)
			Engine.set_meta("muestra_precalentar", true)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_muestra_correcciones.save")
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("muestra_sin_titulo", true)
	DirAccess.make_dir_recursive_absolute(salida)
	_hacer.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _hacer() -> void:
	var P = load("res://progreso.gd")
	P.cargar()
	Engine.set_meta("partida_lista", true)
	change_scene_to_file(MUESTRA)
	while current_scene == null or current_scene.scene_file_path != MUESTRA:
		await process_frame
	await _frames(60)
	var v = current_scene
	for s in SITIOS:
		v._colocar_kael(s[1])
		await _frames(90)                                      # la cámara y la luz de Kael se asientan
		var img: Image = root.get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var base := "%s/%s_%s_%s" % [salida, etiqueta, s[0], perfil]
		img.save_png(base + ".png")
		var k: Vector3 = v.kael.global_position
		var pecho := k + Vector3(0, 1.0, 0)
		var vp_tam := Vector2(img.get_size())
		var sp: Vector2 = v.cam.unproject_position(pecho) * (vp_tam / root.get_visible_rect().size)
		var lado := 180
		var r := Rect2i(int(sp.x) - lado / 2, int(sp.y) - lado / 2 - 10, lado, lado).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var rec := img.get_region(r)
		var suma := Color(0, 0, 0, 0)
		for y in rec.get_height():
			for x in rec.get_width():
				suma += rec.get_pixel(x, y)
		var n := float(rec.get_width() * rec.get_height())
		rec.resize(rec.get_width() * 2, rec.get_height() * 2, Image.INTERPOLATE_NEAREST)
		rec.save_png(base + "_kael.png")
		var q := PhysicsRayQueryParameters3D.create(v.cam.global_position, pecho)
		var choque: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
		var sv: Vector2 = v.sonda(k)
		print("FOTO %s · %s · %s: Kael %s · pantalla %s · sonda sol %.2f cielo %.2f · rayo cámara→Kael %s · color medio del recorte (%.3f, %.3f, %.3f)" % [
			etiqueta, s[0], perfil, str(k), str(sp.round()), sv.x, sv.y,
			("choca con " + _nombre_choque(choque)) if not choque.is_empty() else "libre", suma.r / n, suma.g / n, suma.b / n])
	print("FOTOS HECHAS")
	quit(0)


# (las cajas van todas en el cuerpo «Choques»: el nombre de la caja está en su forma)
func _nombre_choque(ch: Dictionary) -> String:
	var cu = ch["collider"]
	if cu is CollisionObject3D:
		var dueno = cu.shape_owner_get_owner(cu.shape_find_owner(int(ch["shape"])))
		if dueno != null:
			return str(dueno.name)
	return str(cu.name)
