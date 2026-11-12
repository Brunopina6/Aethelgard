extends SceneTree
# V12 (12/11/2026, animaciones): fotos de Humbaba en Godot con el «estudio» del combate (combate.gd estudio_3d: la misma
# cámara ortográfica a 12°, la luz dorada y el relleno azul) y su encuadre de MODELOS["humbaba"]. Una hoja por clip con
# el principio, cada evento de humbaba_clips.json y el final; y la secuencia de las fases (material de la fase 1, 2 y 3
# y la armadura rota). Necesita ventana (no --headless).
#   godot --path aethelgard --script res://pruebas/fotos_humbaba.gd -- salida=<carpeta> [perfil=alto|medio|bajo]
#         [clips=idle,roar,atk_puno] [fondo=1]

const Humbaba := preload("res://enemigos/humbaba/humbaba_3d.gd")
var salida := ""
var perfil := "alto"
var solo: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("clips="):
			solo = Array(a.substr(6).split(","))
	if salida == "":
		salida = OS.get_user_data_dir() + "/fotos_humbaba"
	DirAccess.make_dir_recursive_absolute(salida)
	if "bosque=1" in OS.get_cmdline_user_args():
		_bosque_fotos.call_deferred()
	elif "combate=1" in OS.get_cmdline_user_args():
		_combate_fotos.call_deferred()
	else:
		_hacer.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hacer() -> void:
	var C = load("res://combate.gd")
	var m: Dictionary = C.MODELOS["humbaba"]
	var raiz := Node2D.new()
	root.add_child(raiz)
	var est: Dictionary = C.estudio_3d(raiz, m, 1.0, Color(0.85, 0.95, 0.8))
	var vp: SubViewport = est["vp"]
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var h = C.modelo_3d(m)
	h.calidad = perfil
	vp.add_child(h)
	await _esperar(4)
	var datos: Dictionary = h.datos
	print("HUMBABA perfil=%s huesos=%d clips=%d" % [h.calidad_usada, h.skel.get_bone_count(), h.anim.get_animation_list().size()])
	var clips: Array = datos.get("clips", {}).keys()
	for clip in clips:
		if not solo.is_empty() and not (clip in solo):
			continue
		var info: Dictionary = datos["clips"][clip]
		var ts: Array = [0.0]
		for ev in info.get("eventos", {}):
			ts.append(float(info["eventos"][ev]))
		var dur := float(info["duracion"])
		ts.append_array([dur * 0.25, dur * 0.5, dur * 0.75, dur])
		ts.sort()
		var unicos: Array = []
		for t in ts:
			if unicos.is_empty() or absf(t - unicos[-1]) > 0.05:
				unicos.append(t)
		var imgs: Array = []
		for t in unicos.slice(0, 8):
			h.anim.play(clip, 0.0)
			h.anim.seek(minf(t, dur - 0.001), true)
			h.anim.pause()
			await _esperar(3)
			var im: Image = vp.get_texture().get_image()
			imgs.append(im)
		_hoja(imgs, salida.path_join("godot_%s_%s.png" % [perfil, clip]), 4)
	# las tres fases (idle) y la armadura rota
	var imgs2: Array = []
	for f in [1, 2, 3]:
		h._cambio_ahora(f)
		h.anim.play("idle_angry" if f > 1 else "idle", 0.0)
		h.anim.seek(1.0, true)
		h.anim.pause()
		await _esperar(4)
		imgs2.append(vp.get_texture().get_image())
	_hoja(imgs2, salida.path_join("godot_%s_fases.png" % perfil), 3)
	print("FOTOS ", salida)
	quit(0)


func _hoja(imgs: Array, ruta: String, cols: int) -> void:
	if imgs.is_empty():
		return
	var w: int = imgs[0].get_width()
	var hh: int = imgs[0].get_height()
	var k := 0.5
	var cw := int(w * k)
	var ch := int(hh * k)
	var filas := int(ceil(imgs.size() / float(cols)))
	var hoja := Image.create(cw * mini(cols, imgs.size()), ch * filas, false, Image.FORMAT_RGBA8)
	hoja.fill(Color(0.32, 0.36, 0.3))
	for i in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(cw, ch)
		hoja.blend_rect(im, Rect2i(0, 0, cw, ch), Vector2i((i % cols) * cw, (i / cols) * ch))
	hoja.save_png(ruta)
	print("HOJA ", ruta)


# ================================================================= «combate=1»: capturas de un combate de verdad (grupo 17)
# Cada ataque forzado en su fase (como prueba_humbaba_combate.gd) y una foto de la pantalla entera en cada evento del
# clip (aviso, impacto…), más el reposo, las fases y el vulnerable: para el encuadre, los efectos y la legibilidad.

var cola_fotos: Array = []


func _combate_fotos() -> void:
	var H = load("res://combate_humbaba.gd")
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 12
		G.datos()[n]["pv"] = -1
	Engine.set_meta("zona", "bosque")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("grupo_combate", H.GRUPO)
	seed(7)
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(150)
	var hb: Dictionary = {}
	for e in c.enemigos:
		if H.es(e):
			hb = e
	var p = c._p3d(hb)
	await _foto_pantalla("00_reposo")
	var hecho := -1                                      # los héroes le golpean (cada uno su ataque de siempre)
	for fr in 900:
		await process_frame
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != hecho:
			hecho = c.turnos_heroe
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(hb)
		if fr % 45 == 20 and c.actor is Dictionary and c.actor.get("animando", false):
			await _foto_pantalla("01_heroe_%03d" % fr)
		if c.turnos_heroe >= 4:
			break
	p.evento.connect(func(clip, nombre): cola_fotos.append("%s_%s" % [clip, nombre]))
	for par in [["puno", 1], ["raices", 1], ["guadana", 1], ["aliento", 2], ["ojo", 2], ["llamada", 2], ["abrazo", 3], ["requiem", 3]]:
		c.estado = "accion"
		for f in c.heroes + c.enemigos:
			f["atb"] = 0.0
		c.cola.clear()
		for h in c.heroes:
			h["hp"] = h["hp_max"]
		hb["hb_fase"] = par[1]
		if not hb.has("hb_paso"):
			hb["hb_paso"] = {1: 0, 2: 0, 3: 0}
		hb["hb_paso"][par[1]] = H.CICLOS[par[1]].find(par[0])
		hb["hp"] = int(hb["hp_max"] * [1.0, 0.6, 0.3][par[1] - 1])
		if p.fase != par[1]:
			p._cambio_ahora(par[1])
		var fin := [false]
		var corre := func():
			await H.turno(c, hb, c.heroes.filter(func(h): return h["hp"] > 0), 1.0)
			if par[0] == "requiem":
				await H.turno(c, hb, c.heroes.filter(func(h): return h["hp"] > 0), 1.0)
			fin[0] = true
		corre.call()
		while not fin[0]:
			await process_frame
			while not cola_fotos.is_empty():
				await _foto_pantalla(cola_fotos.pop_front())
		await _esperar(20)
		await _foto_pantalla("%s_despues" % par[0])
	print("FOTOS ", salida)
	quit(0)


func _foto_pantalla(nombre: String) -> void:
	await process_frame
	var im: Image = root.get_viewport().get_texture().get_image()
	im.save_png(salida.path_join("combate_%s.png" % nombre))


# ================================================================= «bosque=1»: el santuario del Gran Bosque con el interruptor
func _bosque_fotos() -> void:
	Engine.set_meta("humbaba_v12", true)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_humbaba.save")
	change_scene_to_file("res://zonas3d/gran_bosque_3d.tscn")
	await _esperar(90)
	var z = current_scene
	var hb = z.get("humbaba")
	print("BOSQUE humbaba=", hb != null)
	if hb == null:
		quit(1)
		return
	await _foto_pantalla("bosque_entrada")
	var destino: Vector3 = hb.global_position + Vector3(0, 0, 1) * 12.0
	z._colocar_kael(destino)
	await _esperar(60)
	await _foto_pantalla("bosque_santuario")
	z._comprobar_cerca()
	print("BOSQUE cerca=", z.cerca, " boton=", z.boton_accion.text)
	z._colocar_kael(hb.global_position + Vector3(0, 0, 1) * 5.5)
	await _esperar(30)
	z._comprobar_cerca()
	print("BOSQUE cerca=", z.cerca, " boton=", z.boton_accion.text)
	await _foto_pantalla("bosque_cerca")
	if z.cerca == "humbaba":
		z._accion()
		await _esperar(25)
		await _foto_pantalla("bosque_despierta")
	await _esperar(90)
	print("BOSQUE escena=", current_scene.scene_file_path if current_scene else "")
	Engine.remove_meta("humbaba_v12")
	quit(0)
