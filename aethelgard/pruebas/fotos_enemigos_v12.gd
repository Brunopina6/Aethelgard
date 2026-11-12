extends SceneTree
# V12, fase C: el Guardián de piedra, el Gólem de ámbar y Gorthor en el COMBATE DE VERDAD (combate.tscn), CON VENTANA.
# «antes»: combate.gd tal cual (el dibujo 2D y el goblin teñido). «después»: el mismo guion con los cambios de
# pruebas/herramientas/parche_enemigos_v12.gd aplicados EN MEMORIA (el archivo no se toca). Para cada combate fijo
# (grupo 4: Guardián y Grimfang; 6: el nido, Gólem y Grimfang; 5: Gorthor) congela el ATB y lleva al enemigo por sus
# momentos con las funciones del combate (_animar_golpe, la carga, _quitar_pv…), saca capturas y mide:
#   - dónde caen sus pies frente a los del dibujo de antes (para «pos_grupo»);
#   - a qué distancia queda la punta de su arma (o su puño, o su boca) del héroe en el instante del impacto
#     (para «distancia» de ANIM);
#   - que el impacto llega una vez y en su fotograma, y que los ganchos (carga, aturdido, fase 2, Devorar, rendirse,
#     perdón) ponen su clip.
# Argumentos: salida=<carpeta>, solo=guardian|golem|gorthor, auto (el perdón de Gorthor se decide solo).
# Termina con «FALLOS: n» (lo que no se cumple), pero es una prueba de capturas: se mira a mano.

const PARCHE := preload("res://pruebas/herramientas/parche_enemigos_v12.gd")
const CASOS := {
	"guardian": {"grupo": 4, "fijo": "", "clave": "guardian", "punta": ["arma", Vector3(0, 1.45, 0)]},
	"golem": {"grupo": 6, "fijo": "garganta_nido", "clave": "golem_ambar", "punta": ["mano.R", Vector3(0, 0.3, 0)]},
	"gorthor": {"grupo": 5, "fijo": "garganta_gorthor", "clave": "gorthor", "punta": ["arma", Vector3(0, 0.8, 0.44)]},
}

var salida := "user://fotos_enemigos_v12"
var solo := ""
var c: Node
var n := 0
var fallos := 0
var guion_parcheado: GDScript


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		if a.begins_with("solo="):
			solo = a.substr(5)
	DirAccess.make_dir_recursive_absolute(salida)
	seed(7)
	var r: Dictionary = PARCHE.aplicar(FileAccess.get_file_as_string("res://combate.gd"))
	print("parche: ok=%s faltan=%s repetidos=%s" % [r["ok"], r["faltan"], r["repetidos"]])
	if not r["ok"]:
		print("FALLO: el parche ya no encaja en combate.gd")
		print("FALLOS: 1")
		quit(1)
		return
	guion_parcheado = GDScript.new()
	guion_parcheado.source_code = r["texto"]
	var err := guion_parcheado.reload()
	if err != OK:
		print("FALLO: el guion parcheado no compila (%d)" % err)
		print("FALLOS: 1")
		quit(1)
		return
	_todo.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if cond:
		print("  ok   ", texto)
	else:
		fallos += 1
		print("  FALLO ", texto)


func _esperar(k: int) -> void:
	for i in k:
		await process_frame


func _segundos(s: float) -> void:
	await _esperar(int(round(s * 30.0)))


func _foto(carpeta: String, nombre: String) -> void:
	await _esperar(1)
	var ruta := salida.path_join(carpeta)
	DirAccess.make_dir_recursive_absolute(ruta)
	root.get_texture().get_image().save_png(ruta.path_join("%02d_%s.png" % [n, nombre]))
	n += 1
	print("foto: ", carpeta, "/", nombre)


func _empezar(caso: Dictionary, parche: bool) -> void:
	if c != null:
		c.queue_free()
		await _esperar(3)
	for k in ["grupo_combate", "combate_fijo", "tipo_combate"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("grupo_combate", caso["grupo"])
	if caso["fijo"] != "":
		Engine.set_meta("combate_fijo", caso["fijo"])
	Engine.set_meta("desde_mapa", false)
	c = load("res://combate.tscn").instantiate()
	if parche:
		c.set_script(guion_parcheado)
	root.add_child(c)
	await _esperar(5)
	for f in c.heroes + c.enemigos:                 # el ATB quieto: los momentos los pone la prueba
		f["vel"] = 0.0
		f["atb"] = 0.0
	await _segundos(3.0)                            # la entrada y el título del jefe


func _enemigo(clave: String) -> Dictionary:
	for e in c.enemigos:
		if str(e.get("clave", "")) == clave:
			return e
	return {}


func _heroe() -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == "Garon" and h["hp"] > 0:
			return h
	return c.heroes[0]


func _pantalla(e: Dictionary, punto: Vector3) -> Vector2:
	var cam: Camera3D = e["cam3d"]
	var spr: Sprite2D = e["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(cam.unproject_position(punto)))


func _todo() -> void:
	for nombre in ["guardian", "golem", "gorthor"]:
		if solo != "" and solo != nombre:
			continue
		var caso: Dictionary = CASOS[nombre]
		print("== ", nombre)
		# antes: el dibujo de siempre
		await _empezar(caso, false)
		var e0 := _enemigo(caso["clave"])
		var pies0: Vector2 = c._suelo_de(e0)
		print("  antes: modelo %s, pos %s, pies %s, centro %s" % [e0["modelo"], e0["pos"], pies0, c._centro(e0)])
		await _foto(nombre, "antes_inicio")
		# después
		await _empezar(caso, true)
		var e := _enemigo(caso["clave"])
		var p = c._p3d(e)
		_ok(p != null and p.has_method("cargar"), "después: su modelo nuevo (%s)" % e.get("modelo"))
		if p == null:
			continue
		var pies: Vector2 = c._suelo_de(e)
		var sitio_nuevo: Vector2 = c.MODELOS[e["modelo"]].get("pos_grupo", Vector2.ZERO)
		var dif := pies0 - pies
		print("  después: pos %s, pies %s; para los pies de antes, pos_grupo = %s" % [e["pos"], pies,
			sitio_nuevo + Vector2(dif.x / c.ENEMIGOS_X.x, dif.y)])
		_ok(dif.length() < 25.0, "  los pies donde los del dibujo de antes (%.0f px)" % dif.length())
		await _foto(nombre, "despues_inicio")
		await _foto(nombre, "despues_reposo")
		# ataque normal: el impacto una vez y a qué distancia queda la punta del héroe
		await _ataque(nombre, e, p, caso, "ataque")
		# la carga (gancho 4/5) y el golpe fuerte desde la carga
		e["cargando"] = true
		c._marcar_aviso(e, true)
		p.cargar()
		await _segundos(1.4)
		_ok(p.clip_actual() == "carga_espera", "  cargar(): en la carga")
		await _foto(nombre, "carga")
		e["cargando"] = false
		c._marcar_aviso(e, false)
		e["descarga"] = true
		await _ataque(nombre, e, p, caso, "golpe_fuerte")
		e["descarga"] = false
		# herido
		p.herida()
		await _segundos(0.12)
		await _foto(nombre, "herido")
		await _segundos(1.0)
		if nombre == "golem":
			e["cargando"] = true
			p.cargar()
			await _segundos(0.6)
			c._interrumpir(e, "¡Interrumpido!", "prueba")
			await _segundos(0.4)
			_ok(p.clip_actual() == "aturdido", "  interrumpido: se tambalea (gancho 6)")
			await _foto(nombre, "aturdido")
			p.reposo()
			await _segundos(0.5)
		if nombre == "gorthor":
			c._quitar_pv(e, e["hp"] - int(e["hp_max"] * 0.45))
			await _segundos(0.5)
			_ok(p.clip_actual() == "fase2", "  fase 2: ruge (gancho 8)")
			await _segundos(0.6)
			await _foto(nombre, "furia")
			await _segundos(1.6)
			e["devora"] = true
			await _ataque(nombre, e, p, caso, "devorar")
			e["devora"] = false
			c._quitar_pv(e, e["hp"])                   # último aliento: de rodillas (gancho 9) y, con «auto», perdón
			await _segundos(1.0)
			_ok(p.esta_rendido(), "  último aliento: de rodillas")
			await _foto(nombre, "rendido")
			await _segundos(0.6)
			_ok(p.clip_actual() == "arrastrarse", "  perdonado: se arrastra (gancho 10)")
			await _foto(nombre, "perdon")
			await _segundos(1.4)
			await _foto(nombre, "perdon_fin")
		else:
			c._quitar_pv(e, e["hp"])
			c._restablecer_color(e)
			await _segundos(0.7)
			await _foto(nombre, "derrota")
			await _segundos(0.6)
			await _foto(nombre, "derrota_fin")
	if c != null:
		c.queue_free()
	await _esperar(2)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# Lanza un golpe del enemigo con la función del combate (_animar_golpe → _anim_ataque_3d) a un héroe con vida de
# sobra y captura la preparación y el impacto; mide la punta del arma en pantalla frente al centro del héroe.
func _ataque(nombre: String, e: Dictionary, p, caso: Dictionary, clip: String) -> void:
	var h := _heroe()
	h["hp"] = h["hp_max"]
	var impactos := [0]
	var con := func(_a): impactos[0] += 1
	p.impacto.connect(con)
	var metodo := "devorar" if clip == "devorar" else ("golpe_fuerte" if clip == "golpe_fuerte" else "atacar_hacha")
	var t_imp: float = p.tiempo_impacto(metodo)
	c._animar_golpe(e, h, 1, "")
	await _segundos(0.55 + t_imp * 0.5)                # corre 0,55 s; a media preparación
	await _foto(nombre, clip + "_prepara")
	var resto := t_imp - t_imp * 0.5 - 1.0 / 30.0
	await _segundos(maxf(resto, 0.0))
	var punta: Vector2
	if clip == "devorar":
		punta = _pantalla(e, p.boca())
	else:
		punta = _pantalla(e, p.hueso_mundo(caso["punta"][0], caso["punta"][1]))
	var centro_h: Vector2 = c._centro(h)
	await _foto(nombre, clip + "_impacto")
	print("  %s: punta en %s, centro del héroe %s: hueco %.0f px (positivo: no llega)" % [clip, punta.round(),
		centro_h.round(), centro_h.x - punta.x])
	await _segundos(2.4)
	p.impacto.disconnect(con)
	_ok(impactos[0] == 1, "  %s: un impacto (%d)" % [clip, impactos[0]])
	_ok(p.clip_actual() == "reposo", "  %s: vuelve al reposo" % clip)
