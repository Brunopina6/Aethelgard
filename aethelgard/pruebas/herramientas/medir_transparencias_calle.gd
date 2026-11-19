extends SceneTree
# MEDIDA (19/11, TRANSPARENCIAS_19_11, PC-9): la rareza de la muestra de la calle (MUESTRA_CALLE_OAKHAVEN.md §7: «una
# capa transparente oscura no oscurecía nada en bajo y medio»), en la escena REAL. Carga la muestra con cada perfil
# (y, si se pide, con la escala 3D cambiada por calidad_extra o con el ambiente tocado), pone la cámara de la muestra
# sobre Kael, hace una captura SIN capas y otra CON una fila de cuadros negros al 50 % de cada tipo (mezcla estándar,
# con luz, multiplicar, sombreado propio con ALPHA, trama, mezcla sin niebla, y un negro OPACO con y sin niebla, que
# dice de qué color sale «el negro» por sí solo) a 4 cm, 1,5 cm y 5 mm del adoquín y otra fila flotando a 1,5 m, y
# mide el color en el centro de cada cuadro antes y después. No es una prueba: guarda capturas y medidas.json.
#   Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/medir_transparencias_calle.gd
#     -- 3d sin_prologo salida=<carpeta> casos=bajo,medio,alto,bajo@1.0,alto@0.75,bajo#sinniebla+lineal
#   «perfil@escala»: el perfil con escala_3d cambiada. «perfil#mod+mod...»: el ambiente tocado; mod = glow, singlow
#   (resplandor forzado), sinniebla (fog_enabled = false), lineal (mapeo de tonos lineal), sinajustes
#   (adjustment_enabled = false). «filas=antigua»: la colocación del primer informe (la fila de 5 mm caía FUERA de la
#   pantalla y sobre el camino de tierra; se deja para enseñarlo).
# (revisión) Un punto que cae fuera de la ventana o detrás de la cámara sale como «fuera» (antes se recortaba al borde
# en silencio y daba números normales), y uno cuyo color «sin» cambia entre dos capturas seguidas (hierba que se mueve
# con el viento, Kael que respira) sale como «inestable»: sus relaciones no valen.

const MUESTRA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const CAPA := Color(0.0, 0.0, 0.0, 0.5)
# [altura, nombre, z respecto a Kael] y los x de las columnas. Las filas del suelo van DETRÁS de Kael (z < 0), que es
# donde la cámara de la muestra ve adoquín; delante (z > 0,7) empieza el camino de tierra con hierba.
const FILAS := [[0.04, "suelo", -0.7], [0.015, "suelo15mm", -1.4], [0.005, "suelo5mm", -2.1], [1.5, "aire", 3.0]]
const COLUMNAS := [-6.0, -5.0, -4.0, -3.0, -2.0, 2.0, 3.0, 4.0, 5.0]
const LADO := 0.5
const FILAS_ANTIGUAS := [[0.04, "suelo", 1.2], [0.015, "suelo15mm", 2.4], [0.005, "suelo5mm", 3.4], [1.5, "aire", 1.2]]

var salida := "D:/REBELUM_diagnostico/transparencias_19_11/calle"
var casos: Array = ["bajo", "medio", "alto"]
var antigua := false
var ic := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var capas: Array = []            # [nombre, nodo, posición del centro]
var antes := {}
var resultado := {}
var img_sin: Image
var img_sin2: Image


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("casos="):
			casos = Array(a.substr(6).split(","))
		elif a == "filas=antigua":
			antigua = true
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("archivo_partida_prueba", "user://medir_transparencias_calle.save")
	_cargar()


func _caso() -> Dictionary:
	var c: String = casos[ic]
	var r := {"perfil": c, "extra": {}, "mods": []}
	if "#" in c:
		r.mods = Array(c.get_slice("#", 1).split("+"))
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
	if antigua:
		return r
	var msn := m.duplicate()
	msn.disable_fog = true
	r.append(["mezcla_sn", msn])
	var s2 := Shader.new()
	s2.code = "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;\nvoid fragment(){ ALBEDO = vec3(0.0); ALPHA = 0.5; }\n"
	var sm2 := ShaderMaterial.new()
	sm2.shader = s2
	r.append(["sh_mix_sn", sm2])
	var ng := StandardMaterial3D.new()               # negro OPACO: el color que da «el negro» de la capa por sí solo
	ng.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ng.albedo_color = Color.BLACK
	r.append(["negro", ng])
	var ngs := ng.duplicate()
	ngs.disable_fog = true
	r.append(["negro_sn", ngs])
	return r


func _poner_capas() -> void:
	var k: Vector3 = v.kael.global_position
	var mats := _materiales()
	var filas: Array = FILAS_ANTIGUAS if antigua else FILAS
	for fila in filas:
		for i in mats.size():
			var x: float = (-3.0 + 1.5 * i) if antigua else float(COLUMNAS[i])
			var p: Vector3 = k + Vector3(x, fila[0], fila[2])
			var mi := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(0.8, 0.8) if antigua else Vector2(LADO, LADO)
			if fila[1] == "aire":
				pm.orientation = PlaneMesh.FACE_Z
			mi.mesh = pm
			mi.material_override = mats[i][1]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			v.add_child(mi)
			mi.global_position = p
			mi.visible = false
			capas.append([mats[i][0] + "_" + fila[1], mi, p])


# El píxel de la imagen donde cae un punto del mundo, o (-1, -1) si cae fuera de la ventana o detrás de la cámara.
func _pixel(img: Image, p: Vector3) -> Vector2i:
	if v.cam.is_position_behind(p):
		return Vector2i(-1, -1)
	var px := Vector2i(v.cam.unproject_position(p) * Vector2(img.get_size()) / root.get_viewport().get_visible_rect().size)
	if px.x < 0 or px.y < 0 or px.x >= img.get_width() or px.y >= img.get_height():
		return Vector2i(-1, -1)
	return px


func _suma(c: Color) -> float:
	return c.r + c.g + c.b


# Cobertura: de una rejilla de 9×9 puntos dentro del cuadro (±40 % del lado), qué parte sale al menos un 5 % más
# oscura, contando solo los puntos dentro de la ventana y estables (mismo color en las dos capturas «sin»).
func _cobertura(con: Image, q: Array) -> Dictionary:
	var n := 0
	var osc := 0
	var fuera := 0
	var inest := 0
	var m: float = (0.8 if antigua else LADO) * 0.4
	var aire: bool = String(q[0]).ends_with("_aire")
	for i in 9:
		for j in 9:
			var a_ := -m + m * 0.25 * i
			var b_ := -m + m * 0.25 * j
			var d := Vector3(a_, b_ if aire else 0.0, 0.0 if aire else b_)
			var px := _pixel(img_sin, q[2] + d)
			if px.x < 0:
				fuera += 1
				continue
			var a := img_sin.get_pixelv(px)
			if absf(_suma(a) - _suma(img_sin2.get_pixelv(px))) > 0.03:
				inest += 1
				continue
			n += 1
			if _suma(con.get_pixelv(px)) < _suma(a) * 0.95:
				osc += 1
	return {"cobertura": snappedf(float(osc) / float(n), 0.001) if n > 0 else -1.0, "fuera": fuera, "inestables": inest}


func _medir(img: Image) -> Dictionary:
	var med := {}
	for q in capas:
		var px := _pixel(img, q[2])
		if px.x < 0:
			med[q[0]] = null
			continue
		var col := img.get_pixelv(px)
		med[q[0]] = [snappedf(col.r, 0.001), snappedf(col.g, 0.001), snappedf(col.b, 0.001), snappedf(col.a, 0.001), px.x, px.y]
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
				if v.ambiente != null:
					for mod in c.mods:
						match mod:
							"glow", "singlow":
								v.ambiente.glow_enabled = mod == "glow"
								v.ambiente.glow_intensity = 0.35
								v.ambiente.glow_bloom = 0.02
								v.ambiente.glow_hdr_threshold = 1.1
							"sinniebla":
								v.ambiente.fog_enabled = false
							"lineal":
								v.ambiente.tonemap_mode = Environment.TONE_MAPPER_LINEAR
							"sinajustes":
								v.ambiente.adjustment_enabled = false
							_:
								push_error("medir_transparencias_calle: modificador desconocido «%s»" % mod)
				_poner_capas()
			elif frames - f_fase == 20:
				img_sin2 = root.get_viewport().get_texture().get_image()
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
					"niebla": v.ambiente.fog_enabled if v.ambiente != null else null,
					"ajustes": v.ambiente.adjustment_enabled if v.ambiente != null else null,
					"mapa_tonos": v.ambiente.tonemap_mode if v.ambiente != null else null}
				var r := {"info": info}
				var fueras := 0
				for q in capas:
					var a = antes[q[0]]
					var d = despues[q[0]]
					if a == null or d == null:
						r[q[0]] = "fuera"
						fueras += 1
						continue
					var cob := _cobertura(img, q)
					var pa := Vector2i(a[4], a[5])
					var estable: bool = absf(_suma(img_sin.get_pixelv(pa)) - _suma(img_sin2.get_pixelv(pa))) <= 0.03
					r[q[0]] = {"sin": a.slice(0, 4), "con": d.slice(0, 4), "px": [a[4], a[5]], "estable": estable,
						"ratio": snappedf((d[0] + d[1] + d[2]) / maxf(a[0] + a[1] + a[2], 0.001), 0.001)}
					r[q[0]].merge(cob)
				resultado[casos[ic]] = r
				print("CASO %s %s" % [casos[ic], JSON.stringify(r)])
				if fueras > 0:
					print("AVISO %s: %d cuadros caen FUERA de la pantalla (sin medida)" % [casos[ic], fueras])
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
