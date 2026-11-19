extends SceneTree
# MEDIDA (19/11, TRANSPARENCIAS_19_11, PC-9): la rareza de la muestra de la calle (MUESTRA_CALLE_OAKHAVEN.md §7: «una
# capa transparente oscura no oscurecía nada en bajo y medio»), en la escena REAL. Carga la muestra con cada perfil
# (y, si se pide, con la escala 3D cambiada por calidad_extra), pone la cámara de la muestra sobre Kael, hace una
# captura SIN capas y otra CON una fila de cuadros negros al 50 % (mezcla estándar, sombreado propio con ALPHA,
# multiplicar, Sprite3D) en el suelo delante de Kael y otra fila flotando a 1,5 m, y mide el color en el centro de
# cada cuadro antes y después. No es una prueba: guarda capturas y medidas.json en la carpeta de salida.
#   Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/medir_transparencias_calle.gd
#     -- 3d sin_prologo salida=<carpeta> casos=bajo,medio,alto,bajo@1.0,alto@0.75
#   («perfil@escala»: el perfil con escala_3d cambiada; «perfil#singlow», «perfil#glow»: resplandor forzado)

const MUESTRA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const CAPA := Color(0.0, 0.0, 0.0, 0.5)

var salida := "D:/REBELUM_diagnostico/transparencias_19_11/calle"
var casos: Array = ["bajo", "medio", "alto"]
var ic := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var capas: Array = []            # [nombre, nodo, posición del centro]
var antes := {}
var resultado := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("casos="):
			casos = Array(a.substr(6).split(","))
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("archivo_partida_prueba", "user://medir_transparencias_calle.save")
	_cargar()


func _caso() -> Dictionary:
	var c: String = casos[ic]
	var r := {"perfil": c, "extra": {}, "glow": ""}
	if "#" in c:
		r.glow = c.get_slice("#", 1)
		c = c.get_slice("#", 0)
		r.perfil = c
	if "@" in c:
		r.perfil = c.get_slice("@", 0)
		r.extra["escala_3d"] = float(c.get_slice("@", 1))
	return r


func _cargar() -> void:
	var c := _caso()
	Engine.set_meta("calidad_proto", c.perfil)
	Engine.set_meta("calidad_extra", c.extra)
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(MUESTRA)
	v = null
	capas.clear()
	_fase(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames


func _materiales() -> Array:
	var r := []
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = CAPA
	r.append(["mezcla", m])
	var ml := m.duplicate()
	ml.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	r.append(["mezcla_luz", ml])
	var mu := m.duplicate()
	mu.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mu.albedo_color = Color(0.5, 0.5, 0.5, 1.0)
	r.append(["multiplicar", mu])
	var s := Shader.new()
	s.code = "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never, cull_disabled;\nvoid fragment(){ ALBEDO = vec3(0.0); ALPHA = 0.5; }\n"
	var sm := ShaderMaterial.new()
	sm.shader = s
	r.append(["sh_mix", sm])
	var ph := m.duplicate()
	ph.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
	r.append(["trama", ph])
	return r


func _poner_capas() -> void:
	var k: Vector3 = v.kael.global_position
	var mats := _materiales()
	# filas: a 4 cm del suelo, a 1,5 cm y a 5 mm (como una sombra falsa pegada al suelo), y en el aire a 1,5 m
	for fila in [[0.04, "suelo", 1.2], [0.015, "suelo15mm", 2.4], [0.005, "suelo5mm", 3.4], [1.5, "aire", 1.2]]:
		for i in mats.size():
			var p: Vector3 = k + Vector3(-3.0 + 1.5 * i, fila[0], fila[2])
			var mi := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(0.8, 0.8)
			if fila[1] == "aire":
				pm.orientation = PlaneMesh.FACE_Z
			mi.mesh = pm
			mi.material_override = mats[i][1]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			v.add_child(mi)
			mi.global_position = p
			mi.visible = false
			capas.append([mats[i][0] + "_" + fila[1], mi, p])


# Cobertura: de una rejilla de 9×9 puntos dentro del cuadro (±0,3 m), qué parte sale al menos un 5 % más oscura.
func _cobertura(sin: Image, con: Image, q: Array) -> float:
	var n := 0
	var osc := 0
	var esc := Vector2(sin.get_size()) / root.get_viewport().get_visible_rect().size
	var aire: bool = String(q[0]).ends_with("_aire")
	for i in 9:
		for j in 9:
			var d := Vector3(-0.3 + 0.075 * i, -0.3 + 0.075 * j if aire else 0.0, 0.0 if aire else -0.3 + 0.075 * j)
			var px := Vector2i(v.cam.unproject_position(q[2] + d) * esc).clamp(Vector2i.ZERO, sin.get_size() - Vector2i.ONE)
			var a := sin.get_pixelv(px)
			var b := con.get_pixelv(px)
			n += 1
			if b.r + b.g + b.b < (a.r + a.g + a.b) * 0.95:
				osc += 1
	return snappedf(float(osc) / float(n), 0.001)


var img_sin: Image


func _medir(img: Image) -> Dictionary:
	var med := {}
	for q in capas:
		var px: Vector2 = v.cam.unproject_position(q[2]) * Vector2(img.get_size()) / root.get_viewport().get_visible_rect().size
		var col := img.get_pixelv(Vector2i(px).clamp(Vector2i.ZERO, img.get_size() - Vector2i.ONE))
		med[q[0]] = [snappedf(col.r, 0.001), snappedf(col.g, 0.001), snappedf(col.b, 0.001), snappedf(col.a, 0.001)]
	return med


func _process(_d: float) -> bool:
	frames += 1
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == MUESTRA and frames - f_fase >= 30:
				v = current_scene
				v._colocar_kael(v.SITIO_FOTO)
				_fase(2)
		2:
			if frames - f_fase == 1:
				v.set_process(false)
				load("res://zonas3d/muestra_calle/muestra_calle.gd").camara_muestra(v.cam, v.kael.global_position)
				var c := _caso()
				if c.glow != "" and v.ambiente != null:
					v.ambiente.glow_enabled = c.glow == "glow"
					v.ambiente.glow_intensity = 0.35
					v.ambiente.glow_bloom = 0.02
					v.ambiente.glow_hdr_threshold = 1.1
				_poner_capas()
			elif frames - f_fase == 30:
				var img := root.get_viewport().get_texture().get_image()
				img.save_png("%s/%s_sin.png" % [salida, casos[ic]])
				antes = _medir(img)
				img_sin = img
				for q in capas:
					q[1].visible = true
			elif frames - f_fase == 60:
				var img := root.get_viewport().get_texture().get_image()
				img.save_png("%s/%s_con.png" % [salida, casos[ic]])
				var despues := _medir(img)
				var vp := root.get_viewport()
				var info := {"escala": vp.scaling_3d_scale, "msaa": vp.msaa_3d,
					"glow": v.ambiente.glow_enabled if v.ambiente != null else null,
					"mapa_tonos": v.ambiente.tonemap_mode if v.ambiente != null else null}
				var r := {"info": info}
				for q in capas:
					var a: Array = antes[q[0]]
					var d: Array = despues[q[0]]
					r[q[0]] = {"sin": a, "con": d, "ratio": snappedf((d[0] + d[1] + d[2]) / maxf(a[0] + a[1] + a[2], 0.001), 0.001), "cobertura": _cobertura(img_sin, img, q)}
				resultado[casos[ic]] = r
				print("CASO %s %s" % [casos[ic], JSON.stringify(r)])
				v.set_process(true)
				ic += 1
				if ic >= casos.size():
					var f := FileAccess.open(salida.path_join("medidas.json"), FileAccess.WRITE)
					f.store_string(JSON.stringify(resultado, "  "))
					f.close()
					Engine.remove_meta("calidad_proto")
					Engine.remove_meta("calidad_extra")
					print("MEDIR_TRANSPARENCIAS_CALLE FIN %d casos" % casos.size())
					return true
				_cargar()
	return false
