extends SceneTree
# Los patrones de los enemigos de siempre (T-097, 09/11), en combates de verdad, sin ventana y con datos aislados.
# Para Grimfang (Hachazo), el Slime (se encoge y rebota) y el Gólem de ámbar (Pisotón a todos): el aviso (cartel, «⚠
# Cargando», la señal dibujada sin nodos ni partículas, su voz una vez y ningún daño ese turno), el golpe en el turno
# siguiente (a quien avisó o a todos, un impacto por héroe), la recuperación el turno después (sin daño) y, con el
# héroe en guardia, la mitad o menos. El Slime encogido está en guardia hasta su golpe. El Guardián (jefe) avisa con la
# señal y la quita al descargar. (Que Kael solo gane, lo prueba prueba_grupos_combate.) Cada combate prueba hasta 8
# semillas hasta ver el patrón entero. Ganar con guion no prueba la estrategia de un jugador.

const ARCHIVO := "user://prueba_patrones_enemigos.save"

var P
var G
var c = null
var fallos: Array = []
var hechos: Array = []
var voces: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _combate(activos: Dictionary, grupo: int, semilla: int, tipo := "normal") -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "ceniza")                # nivel 34: nadie huye solo por «zona limpia»
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("grupo_combate", grupo)
	voces.clear()
	c = load("res://combate.tscn").instantiate()
	c.voz_pedida.connect(func(q: String, ev: String): voces.append([q, ev]))
	root.add_child(c)
	seed(semilla)


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(5)


func _probar() -> void:
	await _esperar(10)
	await _patron("Grimfang", "grimfang", 9, {"Kael": 3}, false, true)
	await _patron("Slime", "slime", 7, {"Kael": 3}, false, true)
	await _patron("Gólem", "golem_ambar", 6, {"Kael": 8, "Lya": 8, "Garon": 8}, true, false)
	await _jefe()
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# Juega hasta ver aviso → golpe → recuperación de «clave» (y una defensa, si «defender»), con varias semillas.
func _patron(nombre: String, clave: String, grupo: int, activos: Dictionary, a_todos: bool, gana_solo: bool) -> void:
	var visto := {"aviso": 0, "golpe": 0, "recupera": 0, "defendido": 0}
	for intento in 8:
		_combate(activos, grupo, 20261109 + intento * 13)
		var e: Dictionary = {}
		for x in c.enemigos:
			if x["clave"] == clave:
				e = x
		_ok(not e.is_empty(), "%s: no está en el grupo %d" % [nombre, grupo])
		if not e.is_empty():                         # con más vida, para que le dé tiempo a enseñar el patrón entero
			e["hp"] = 600
			e["hp_max"] = 600
		if e.is_empty():
			await _cerrar()
			return
		var pv_antes := {}
		var turno := false
		var antes := {"cargando": false, "recupera": false}
		var cambios := {}
		var pv_turno := {}
		var defendio := false
		var f_fin := -1
		for fr in 9000:
			await _esperar(1)
			for h in c.heroes:
				if turno and h["hp"] != pv_antes.get(h["nombre"], h["hp"]):
					cambios[h["nombre"]] = cambios.get(h["nombre"], 0) + 1
				pv_antes[h["nombre"]] = h["hp"]
			var su_turno: bool = c.estado == "enemigo" and c.atacante_actual != null and is_same(c.atacante_actual, e)
			if not turno and not su_turno and c.estado != "enemigo":
				antes = {"cargando": e.get("cargando", false), "recupera": e.get("recupera", false)}
			if su_turno and not turno:
				turno = true
				cambios.clear()
				for h in c.heroes:
					pv_turno[h["nombre"]] = h["hp"]
			elif turno and not su_turno and c.estado != "enemigo":
				turno = false
				var tocados: int = cambios.keys().size()
				if antes["recupera"]:
					visto["recupera"] += 1
					_ok(tocados == 0 and c.registro.text.contains("recupera"), "%s: al recuperar golpea (%s)" % [nombre, c.registro.text])
				elif antes["cargando"]:
					visto["golpe"] += 1
					var vivos: int = c.heroes.filter(func(h): return pv_turno[h["nombre"]] > 0).size()
					_ok(tocados == (vivos if a_todos else 1) and cambios.values().all(func(n): return n <= 1),
						"%s: el golpe anunciado toca a %d (esperado %d): %s" % [nombre, tocados, vivos if a_todos else 1, cambios])
					_ok(e.get("aviso_nodo", null) == null, "%s: la señal de aviso sigue tras golpear" % nombre)
					if defendio and not a_todos:
						visto["defendido"] += 1
						var k: Dictionary = c.heroes[0]
						var sin: int = int(e["atk"] * c.PATRONES[e["personalidad"]]["mult"] * (1.5 if e.get("furia", false) else 1.0)) + 3 - int(k.get("def", 0) / 2.0)
						var dano: int = pv_turno[k["nombre"]] - k["hp"]
						_ok(dano <= int(sin * c.MULT_CRITICO * 0.5) + 1, "%s: en guardia quita %d (sin guardia, hasta %d; con crítico, ×1,6)" % [nombre, dano, sin])
				elif e.get("cargando", false):
					visto["aviso"] += 1
					var nodo = e.get("aviso_nodo", null)
					_ok(tocados == 0 and nodo != null and is_instance_valid(nodo) and nodo.get_child_count() == 0,
						"%s: el aviso hace daño o no tiene su señal" % nombre)
					_ok(e["lbl_estado"].text.contains("Cargando"), "%s: no se ve «⚠ Cargando»" % nombre)
					_ok(voces.filter(func(v): return v == [e["nombre"], "ataque"]).size() >= 1, "%s: el aviso no pide su voz" % nombre)
					if clave == "slime":
						_ok(e.get("defendiendo", false), "Slime: encogido no está en guardia")
				defendio = false
			if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
				if e.get("cargando", false) and c.actor["nombre"] == c.heroes[0]["nombre"]:
					defendio = true
					c._defender()
				else:
					var obj = c.enemigos.filter(func(x): return x["hp"] > 0)
					if obj.is_empty():
						c._defender()
					else:
						c._menu_objetivo("atacar", "")
						c._confirmar_objetivo(obj[0])
			if c.estado == "fin" and f_fin < 0:
				f_fin = fr
			if f_fin >= 0 and fr - f_fin > 60:
				break
		await _cerrar()
		if visto["aviso"] > 0 and visto["golpe"] > 0 and visto["recupera"] > 0 and (a_todos or visto["defendido"] > 0):
			break
	_ok(visto["aviso"] > 0 and visto["golpe"] > 0 and visto["recupera"] > 0, "%s: no se vio el patrón entero: %s" % [nombre, visto])
	_ok(a_todos or visto["defendido"] > 0, "%s: no se vio el golpe defendido: %s" % [nombre, visto])
	hechos.append("%s %s" % [nombre, visto])


# El Guardián de piedra (jefe) avisa su golpe devastador con la señal y la quita al descargar.
func _jefe() -> void:
	_combate({"Kael": 12, "Lya": 12, "Garon": 12}, 4, 20261109, "jefe")
	var g: Dictionary = c.enemigos.filter(func(x): return x.get("personalidad", "") == "jefe")[0]
	var con_senal := false
	var sin_senal_tras := false
	for fr in 9000:
		await _esperar(1)
		if g.get("cargando", false) and g.get("aviso_nodo", null) != null:
			con_senal = true
		if con_senal and not g.get("cargando", false) and c.estado != "enemigo":
			sin_senal_tras = g.get("aviso_nodo", null) == null
			break
		if c.estado == "menu" and c.menu.activo:
			c._defender()
		if c.estado == "fin":
			break
	_ok(con_senal and sin_senal_tras, "Guardián: su golpe devastador no lleva la señal o no la quita (%s, %s)" % [con_senal, sin_senal_tras])
	await _cerrar()
	hechos.append("Guardián (jefe): señal de aviso")
