extends SceneTree
# V12 (14/11): el orbe EXPERIMENTAL de Érebo (erebo_orbe_v12.gd), apagado por defecto, en un combate de verdad con
# datos aislados y «erebo=exito» (en la lista se pasa también con «erebo_nueva» para la otra invocación, y con
# «erebo=fallo» en prueba_erebo_orbe_v12_fallo / _nueva_fallo):
#   apagado     → en «orbe_fuera» no se crea nada y el resultado es el de siempre
#   encendido   → nace EN ese evento (el agarre), sobre el orbe, con su presupuesto de partículas; lanza la onda,
#                 se borra solo y el resultado es EXACTAMENTE el del apagado (ver «comparación exacta»)
#   saltar      → saltando la invocación con el efecto vivo no queda nada en el árbol
#   repetir     → tres invocaciones seguidas: nunca hay más de uno a la vez y al final ninguno
#   salir       → borrando el combate (cambio de escena) con el efecto vivo no queda nada
# Comparación exacta (15/11): el mismo combate con el azar fijo (combate._ready hace randomize(), así que la semilla se
# pone DESPUÉS de root.add_child(c) y se vuelve a tirar el ATB inicial de los enemigos; y otra semilla justo antes de
# _invocar_sobre) se juega apagado, encendido y otra vez apagado (control: si los dos apagados no salen iguales, la
# comparación no vale y se declara). Se comparan, exactos: PV del objetivo antes y después, daño, cuántas veces cambian
# sus PV, PV y PM de todos, Armonía, ATB de todos, estado, fotogramas hasta volver y el registro. Casos:
#   «erebo=exito»: un enemigo normal (GRUPOS[9], Grimfang: muerte, PV a 0, un cambio) y un JEFE (GRUPOS[18], Guardián de
#                  piedra, sin fases: siempre arranca el orbe y quita maxi(1, round(PV × 0,2)), sin dado; un cambio)
#   «erebo=fallo»: un enemigo normal (la secuencia de fallo no saca el orbe: ni daño ni efecto)
# La tirada randi() siguiente a la invocación también se compara EXACTA (16/11: el orbe usa azar propio; antes solo
# era un aviso porque sus partículas gastaban azar global).
# Semillas: «semilla_orbe=N» y «semilla_inv=N» para reproducir otra.
# No toca la partida real: archivo de partida de prueba y user:// aislado del ejecutor.

const ARCHIVO := "user://prueba_erebo_orbe_v12.save"
const EXACTAS := ["pv0", "pv1", "dano", "cambios_objetivo", "cambios_otros", "pv_todos", "pm_heroes", "pm_antes",
	"armonia", "atb_todos", "estado", "fotogramas", "registro"]

var P
var G
var EO
var c = null
var fallos: Array = []
var hechos: Array = []
var avisos: Array = []
var _max_vivos := 0
var semilla_combate := 4242
var semilla_inv := 777
var forzado := ""


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	EO = load("res://erebo_orbe_v12.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla_orbe="):
			semilla_combate = int(a.get_slice("=", 1))
		elif a.begins_with("semilla_inv="):
			semilla_inv = int(a.get_slice("=", 1))
		elif a.begins_with("erebo="):
			forzado = a.substr(6)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _vivos() -> int:
	var n := 0
	for x in root.find_children("*", "Node3D", true, false):
		if x.get_script() == EO and not x.is_queued_for_deletion():
			n += 1
	return n


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		_max_vivos = maxi(_max_vivos, _vivos())
		if c != null and is_instance_valid(c) and c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0


func _probar() -> void:
	await _esperar(10)
	_ok(EO.permitido(), "la opción solo existe en Auditoría o editor y esta prueba corre en el editor")
	_ok(forzado == "exito" or forzado == "fallo", "falta «erebo=exito» o «erebo=fallo» en la línea de órdenes (%s)" % forzado)
	var nueva: bool = load("res://invocacion_erebo_nueva.gd").elegida()
	print("SEMILLAS combate=%d invocación=%d · erebo=%s · invocación %s" % [semilla_combate, semilla_inv, forzado,
		"nueva" if nueva else "de siempre"])
	if forzado == "fallo":
		await _comparar("normal con fallo", 9)
	else:
		await _comparar("normal con éxito", 9)
		await _comparar("jefe", 18)
		EO.elegir(true)
		await _invocar("saltar", "saltar", 9)
		_max_vivos = 0
		for i in 3:
			await _invocar("repetir %d" % (i + 1), "", 9)
		_ok(_max_vivos <= 1, "repetir: llegó a haber %d efectos a la vez" % _max_vivos)
		await _invocar("salir", "salir", 9)
	EO.elegir(false)
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for a in avisos:
		print("AVISO: ", a)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- comparación exacta apagado / encendido

func _comparar(caso: String, grupo: int) -> void:
	EO.elegir(false)
	var a: Dictionary = await _invocar(caso + " · apagado", "", grupo)
	EO.elegir(true)
	var b: Dictionary = await _invocar(caso + " · encendido", "", grupo)
	EO.elegir(false)
	var a2: Dictionary = await _invocar(caso + " · apagado (control)", "", grupo)
	if a.is_empty() or b.is_empty() or a2.is_empty():
		_ok(false, "%s: alguna de las tres invocaciones no llegó a hacerse" % caso)
		return
	for r in [["apagado", a], ["encendido", b], ["control", a2]]:
		print("TRAZA %s · %s: %s" % [caso, r[0], JSON.stringify(r[1])])
	# control: sin el orbe, dos veces lo mismo (si no, el azar o el tiempo no están controlados y comparar no vale)
	var control_ok := true
	for k in EXACTAS:
		if a[k] != a2[k]:
			control_ok = false
			_ok(false, "%s: el apagado no se repite igual en «%s» (%s / %s): el azar o el tiempo no están controlados" % [
				caso, k, var_to_str(a[k]), var_to_str(a2[k])])
	for k in EXACTAS:
		_ok(a[k] == b[k], "%s: «%s» cambia con el orbe (apagado %s / encendido %s)" % [caso, k, var_to_str(a[k]), var_to_str(b[k])])
	# lo que debe salir, en los dos lados
	var es_jefe: bool = grupo == 18
	for r in [a, b]:
		_ok(is_equal_approx(float(r["armonia"]), 0.0), "%s: la Armonía no queda a 0 (%s)" % [caso, r["armonia"]])
		_ok(r["pm_heroes"] == r["pm_antes"], "%s: cambian los PM de los héroes (%s → %s)" % [caso, r["pm_antes"], r["pm_heroes"]])
		_ok(int(r["cambios_otros"]) == 0, "%s: cambian los PV de otros %d veces" % [caso, r["cambios_otros"]])
		if es_jefe:
			var esperado: int = maxi(1, int(round(int(r["pv0"]) * 0.2)))
			_ok(int(r["dano"]) == esperado and int(r["cambios_objetivo"]) == 1 and int(r["pv1"]) > 0,
				"%s: el jefe pierde %d en %d veces (esperado %d = 20 %% de %d, una vez, sin morir)" % [caso, r["dano"],
				r["cambios_objetivo"], esperado, r["pv0"]])
		elif forzado == "exito":
			_ok(int(r["pv1"]) == 0 and int(r["dano"]) == int(r["pv0"]) and int(r["cambios_objetivo"]) == 1,
				"%s: con éxito no muere de una vez (PV %d → %d, %d cambios)" % [caso, r["pv0"], r["pv1"], r["cambios_objetivo"]])
		else:
			_ok(int(r["dano"]) == 0 and int(r["cambios_objetivo"]) == 0,
				"%s: con fallo pierde PV (%d → %d, %d cambios)" % [caso, r["pv0"], r["pv1"], r["cambios_objetivo"]])
	_ok(a["randi"] == b["randi"] and a["randi"] == a2["randi"],
		"%s: la tirada randi() siguiente cambia con el orbe (apagado %d, encendido %d, control %d)" % [caso,
		a["randi"], b["randi"], a2["randi"]])
	if a["randi"] != b["randi"] or a["randi"] != a2["randi"]:
		avisos.append("%s: la tirada randi() siguiente difiere (apagado %d, encendido %d, control %d): %s" % [caso,
			a["randi"], b["randi"], a2["randi"], "el orbe gasta azar global" if a["randi"] == a2["randi"] else
			"ni siquiera los dos apagados coinciden"])
	hechos.append("%s: apagado = encendido%s (PV %d → %d, daño %d, %d cambio(s), %d fotogramas, estado «%s»)" % [caso,
		"" if control_ok else " (CONTROL MAL)", a["pv0"], a["pv1"], a["dano"], a["cambios_objetivo"], a["fotogramas"],
		a["estado"]])


# ---------------------------------------------------------------- un combate y una invocación

func _combate(grupo: int) -> Dictionary:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)                                 # (aquí su _ready hace randomize())
	seed(semilla_combate)                             # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                     # el ATB inicial, como en combate.gd, ya con la semilla
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		await _esperar(1)
	return c.enemigos[0]


func _foto() -> Dictionary:
	var pv := {}
	var atb := {}
	var pm := {}
	for f in c.heroes + c.enemigos:
		pv[f["nombre"]] = int(f["hp"])
		atb[f["nombre"]] = float(f["atb"])
	for h in c.heroes:
		pm[h["nombre"]] = int(h.get("mp", 0))
	return {"pv": pv, "atb": atb, "pm": pm}


# modo: "" (hasta el final), "saltar" o "salir" (con el efecto vivo). Devuelve lo comparable (vacío en «salir»).
func _invocar(caso: String, modo: String, grupo: int) -> Dictionary:
	var grim: Dictionary = await _combate(grupo)
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % caso)
		c.queue_free()
		await _esperar(5)
		return {}
	c.armonia = 1.0
	for f in c.heroes + c.enemigos:                   # ATB lento y desde cero: al volver dice algo (no llega al tope)
		f["vel"] = 2.0
		f["atb"] = 0.0
	var pv0: int = grim["hp"]
	var antes := _foto()
	var visto := {"orbe_fuera": false, "efecto": null, "frame_ok": false}
	var encendido: bool = EO.activo()
	seed(semilla_inv)                                 # el azar de la invocación (y de lo que pase mientras), fijo
	c._invocar_sobre(grim)
	var conectado := false
	var previo: Dictionary = antes["pv"].duplicate()
	var cambios_obj := 0
	var cambios_otros := 0
	var fotogramas := 0
	var onda := false
	var r := {}
	for i in 3000:
		if not conectado and c.inv_erebo != null and c.inv_erebo.erebo != null:
			conectado = true
			var er = c.inv_erebo.erebo
			er.evento.connect(func(n: String):
				if n == "orbe_fuera":
					visto["orbe_fuera"] = true
					visto["efecto"] = er._orbe_v12                       # creado en ESTE evento (la conexión de Érebo va antes)
					var ef = er._orbe_v12
					visto["nacio"] = ef != null and is_instance_valid(ef)   # (luego se borra solo: aquí se apunta)
					if ef != null and is_instance_valid(ef):
						visto["frame_ok"] = ef.global_position.distance_to(er.orbe.global_position) < 0.02
						visto["particulas"] = ef.numero_particulas()
						visto["esperadas"] = 96 if er.calidad == "alta" else 48)
		if modo != "" and visto["orbe_fuera"]:
			break
		var efv = visto["efecto"]
		if efv != null and is_instance_valid(efv) and efv.onda_lanzada():
			onda = true
		await process_frame                           # (sin _esperar: el ATB de los enemigos no se toca aquí)
		fotogramas += 1
		_max_vivos = maxi(_max_vivos, _vivos())
		for f in c.heroes + c.enemigos:
			if int(f["hp"]) != int(previo[f["nombre"]]):
				previo[f["nombre"]] = int(f["hp"])
				if is_same(f, grim):
					cambios_obj += 1
				else:
					cambios_otros += 1
		if c.estado != "accion":                      # de vuelta al combate: la foto, en este mismo fotograma
			var d := _foto()
			r = {"pv0": pv0, "pv1": int(grim["hp"]), "dano": pv0 - int(grim["hp"]), "cambios_objetivo": cambios_obj,
				"cambios_otros": cambios_otros, "pv_todos": d["pv"], "pm_heroes": d["pm"], "pm_antes": antes["pm"],
				"armonia": float(c.armonia), "atb_todos": d["atb"], "estado": str(c.estado), "fotogramas": fotogramas,
				"registro": str(c.registro.text), "randi": randi()}
			break
	var esperado_orbe: bool = forzado == "exito" or grupo == 18
	if modo == "" and esperado_orbe or modo != "":
		_ok(visto["orbe_fuera"], "%s: la invocación no llega a sacar el orbe" % caso)
	elif not esperado_orbe:
		_ok(not visto["orbe_fuera"], "%s: con fallo la invocación saca el orbe" % caso)
	if encendido and visto["orbe_fuera"]:
		_ok(visto.get("nacio", false), "%s: con la opción activa no nace el efecto en «orbe_fuera»" % caso)
		_ok(visto["frame_ok"], "%s: el efecto no está sobre el orbe al nacer" % caso)
		_ok(visto.get("particulas", -1) == visto.get("esperadas", -2), "%s: partículas %s (esperadas %s)" % [caso, visto.get("particulas"), visto.get("esperadas")])
		if modo == "":
			_ok(onda, "%s: la onda no se lanza" % caso)
	else:
		_ok(not visto.get("nacio", false), "%s: sin orbe o con la opción apagada se crea el efecto" % caso)
	if modo == "saltar":
		await _esperar(3)
		c.inv_erebo.saltar()
		await _esperar(4)
		_ok(_vivos() == 0, "%s: tras saltar quedan %d efectos" % [caso, _vivos()])
		var vuelve := false
		for i in 1500:
			if c.estado != "accion":
				vuelve = true
				break
			await _esperar(1)
		_ok(vuelve, "%s: el combate no vuelve a su curso (estado %s)" % [caso, c.estado])
		_ok(grim["hp"] <= 0, "%s: el resultado (éxito forzado) no se aplica al saltar" % caso)
	elif modo == "salir":
		await _esperar(3)
		c.queue_free()
		c = null
		await _esperar(4)
		_ok(_vivos() == 0, "%s: tras borrar el combate quedan %d efectos" % [caso, _vivos()])
		Engine.time_scale = 1.0
		hechos.append(caso)
		return {}
	else:
		_ok(not r.is_empty(), "%s: el combate no vuelve a su curso (estado %s)" % [caso, c.estado])
	await _esperar(5)
	_ok(_vivos() == 0, "%s: al terminar quedan %d efectos" % [caso, _vivos()])
	_ok(is_equal_approx(Engine.time_scale, 1.0), "%s: el tiempo no vuelve a 1" % caso)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)
	hechos.append(caso)
	return r
