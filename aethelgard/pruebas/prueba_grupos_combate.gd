extends SceneTree
# Prueba del grupo activo (grupo.gd, «grupo_activo») con grupos de uno, dos y tres héroes: Kael; Kael y Lya; los tres.
# Con «-- 3d sin_prologo auto»: en el combate, cada héroe ataca solo en su turno (combate.gd). Comprueba:
#   1. cada combate tiene exactamente a los presentes: los ausentes no salen, no actúan y no se pueden atacar;
#   2. los encuentros al azar de cada tamaño se ganan solo atacando (Kael solo, sin cura): se juegan todos sus grupos;
#   3. huir y perder funcionan; al perder, los presentes vuelven con la vida llena;
#   4. ganar da experiencia solo a los presentes, la que toca (como combate.gd: la de los enemigos que no huyeron, por
#      el multiplicador de su nivel; los caídos, la mitad), y los ausentes no cambian en nada; huir y perder no dan;
#   5. guardar y cargar conserva el grupo; las partidas de antes conservan el suyo; una partida nueva de la versión
#      experimental empieza con Kael solo;
#   6. el menú del grupo solo enseña a los presentes.
# No toca la partida de verdad (usa su propio archivo).

const ARCHIVO := "user://prueba_grupos_combate.save"
const MAX_FOTOGRAMAS := 6000                      # 200 s de juego por combate como mucho: ninguno se queda atascado

var P
var G
var casos: Array = []
var caso := {}
var c
var frames := 0
var f_caso := 0
var f_fin := -1
var antes := {}                                   # copia de los datos del grupo antes del combate
var actores := {}                                 # quién ha actuado en el combate
var fallos: Array = []
var resumen: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	if not load("res://modo3d.gd").activo() or not "auto" in OS.get_cmdline_user_args():
		print("FALLO: faltan «-- 3d» o «auto»")
		quit(1)
		return
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	_comprobar_partidas()
	var c_ = load("res://combate.gd")
	for tam in [1, 2, 3]:
		var activos: Array = G.EN_EL_GRUPO.slice(0, tam)
		var grupos: Array = c_.AL_AZAR_POR_TAMANO.get(tam, [0, 3])
		for g in grupos:
			casos.append({"activos": activos, "grupo": g, "modo": "ganar"})
		casos.append({"activos": activos, "grupo": grupos[0], "modo": "huir"})
		casos.append({"activos": activos, "grupo": grupos[0], "modo": "perder"})
	# el reparto al azar de cada tamaño solo saca sus grupos
	for tam in [1, 2]:
		for i in 200:
			var g: int = c_.grupo_al_azar(tam)
			if not g in c_.AL_AZAR_POR_TAMANO[tam]:
				fallos.append("con %d héroes sale el grupo %d al azar" % [tam, g])
				break


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


# 5. Guardar y cargar con cada tamaño, partidas de antes y partida nueva.
func _comprobar_partidas() -> void:
	for tam in [1, 2, 3]:
		_limpiar()
		var activos: Array = G.EN_EL_GRUPO.slice(0, tam)
		G.datos()
		Engine.set_meta("grupo_activo", activos)
		var d: Dictionary = P.volcar("res://mapa.tscn").duplicate(true)
		_limpiar()
		P.restaurar(d)
		if G.activos() != activos:
			fallos.append("5: guardar y cargar con %d cambia el grupo a %s" % [tam, G.activos()])
	var antiguas := [[{}, ["Kael", "Lya", "Garon"]], [{"pv_02": true}, ["Kael"]],
		[{"pv_02": true, "pv_03": true}, ["Kael", "Lya"]], [{"pv_02": true, "pv_03": true, "pv_05": true}, ["Kael", "Lya", "Garon"]]]
	for a in antiguas:
		_limpiar()
		G.datos()
		var d := {"grupo": G.datos().duplicate(true), "hitos": a[0], "escena_guardada": "res://mapa.tscn"}
		_limpiar()
		P.restaurar(d)
		if G.activos() != a[1]:
			fallos.append("5: una partida de antes con hitos %s da el grupo %s y no %s" % [a[0].keys(), G.activos(), a[1]])
	_limpiar()
	_borrar()
	if P.cargar() != "" or G.activos() != ["Kael"]:
		fallos.append("5: una partida nueva de la versión experimental no empieza con Kael solo (%s)" % G.activos())
	# unirse: entra en el grupo y conserva sus datos tal cual (la nivelación automática es solo una propuesta, D-062)
	_limpiar()
	G.datos()["Kael"]["nivel"] = 4
	G.datos()["Lya"]["pv"] = 12
	var lya_antes: Dictionary = G.datos()["Lya"].duplicate(true)
	G.empezar_solo()
	G.unir("Lya")
	if G.activos() != ["Kael", "Lya"]:
		fallos.append("5: al unirse, Lya no entra en el grupo (%s)" % G.activos())
	if G.datos()["Lya"] != lya_antes:
		fallos.append("5: al unirse, los datos de Lya cambian: %s → %s" % [lya_antes, G.datos()["Lya"]])
	G.unir("Lya")
	if G.activos() != ["Kael", "Lya"]:
		fallos.append("5: unirse dos veces repite a Lya (%s)" % G.activos())
	print("OK 5: guardar y cargar con 1, 2 y 3; partidas de antes; partida nueva con Kael solo; unirse sin cambiar datos")


# 6. El menú del grupo enseña solo a los presentes.
func _comprobar_menus() -> void:
	for tam in [1, 2, 3]:
		_limpiar()
		G.datos()
		var activos: Array = G.EN_EL_GRUPO.slice(0, tam)
		Engine.set_meta("grupo_activo", activos)
		var m = load("res://menus.gd").new()
		root.add_child(m)
		var vistos: Array = []
		for b in m.find_children("*", "Button", true, false):
			if b.text in G.EN_EL_GRUPO and not b.text in vistos:
				vistos.append(b.text)
		m.free()
		if vistos != activos:
			fallos.append("6: con %s, el menú del grupo enseña %s" % [activos, vistos])
	print("OK 6: el menú del grupo enseña solo a los presentes (1, 2 y 3)")


# ¿Acabó el combate en pie? (combate.gd da a los caídos la mitad de la experiencia, en enteros: con poca, 0).
func _en_pie(n: String) -> bool:
	for h in c.heroes:
		if h["nombre"] == n:
			return h["hp"] > 0
	return false


# Experiencia acumulada de verdad: la de los niveles ya subidos más la actual (al subir, «exp» vuelve a empezar).
func _exp_total(d: Dictionary) -> int:
	var t := int(d["exp"])
	for i in range(1, int(d["nivel"])):
		t += G.exp_para(i)
	return t


# La que reparte combate.gd al ganar: la de los enemigos que no huyeron (un cobarde que huye no da nada: si el único
# enemigo era un Slime y huyó, se gana sin experiencia), por el multiplicador del nivel del héroe; los caídos, la mitad.
func _exp_esperada(n: String, nivel: int) -> int:
	var total := 0
	for e in c.enemigos:
		if not e.get("huido", false):
			total += int(e.get("exp", 0))
	var cantidad := int(round(total * P.mult_exp(Engine.get_meta("zona", "llanura"),
		Engine.get_meta("tipo_combate", "normal"), nivel)))
	return cantidad if _en_pie(n) else cantidad / 2


func _siguiente_caso() -> void:
	if casos.is_empty():
		_terminar()
		return
	caso = casos.pop_front()
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", caso["activos"])
	Engine.set_meta("grupo_combate", caso["grupo"])
	Engine.set_meta("tipo_combate", "normal")
	antes = G.datos().duplicate(true)
	actores.clear()
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	f_caso = frames
	f_fin = -1


func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:                               # en _initialize la raíz aún no está en el árbol: aquí ya sí
		_comprobar_menus()
		_siguiente_caso()
		return false
	if c == null:
		return false
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	if frames - f_caso == 5:
		if nombres != caso["activos"]:
			fallos.append("1: con %s, en el combate están %s" % [caso["activos"], nombres])
		if caso["modo"] == "huir":
			c._escapar()
		elif caso["modo"] == "perder":
			for h in c.heroes:
				h["hp"] = 0
			c._comprobar_fin()
	var actor = c.get("actor")
	if actor is Dictionary and actor.get("hero", false):
		actores[actor["nombre"]] = true
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
	if f_fin >= 0 and frames - f_fin >= 150:      # reparto de experiencia y vuelta (5 s de juego)
		_comprobar_caso(nombres)
		c.queue_free()
		c = null
		_siguiente_caso()
	elif frames - f_caso > MAX_FOTOGRAMAS:
		fallos.append("el combate de %s contra el grupo %d no terminó (¿atascado?)" % [caso["activos"], caso["grupo"]])
		c.queue_free()
		c = null
		_siguiente_caso()
	return false


func _comprobar_caso(nombres: Array) -> void:
	var gana: bool = c.enemigos.all(func(e): return e["hp"] <= 0 or e.get("huido", false))
	var segundos := (f_fin - f_caso) / 30.0
	for n in actores:
		if not n in caso["activos"]:
			fallos.append("1: %s actuó sin estar en el grupo" % n)
	for n in G.EN_EL_GRUPO:
		var ahora: Dictionary = G.datos()[n]
		if not n in caso["activos"]:
			if var_to_str(ahora) != var_to_str(antes[n]):
				fallos.append("4: %s, ausente, ha cambiado tras %s" % [n, caso["modo"]])
		else:
			var ganada := _exp_total(ahora) - _exp_total(antes[n])
			var esperada := _exp_esperada(n, int(antes[n]["nivel"])) if caso["modo"] == "ganar" else 0
			if ganada != esperada:
				fallos.append("4: %s ganó %d de experiencia al %s contra el grupo %d; tocaban %d%s" % [n, ganada,
					caso["modo"], caso["grupo"], esperada, "" if _en_pie(n) else " (caído: la mitad)"])
	match caso["modo"]:
		"ganar":
			if not gana:
				fallos.append("2: %s NO gana contra el grupo %d solo atacando (%.0f s)" % [caso["activos"], caso["grupo"], segundos])
		"huir":
			if gana or not c.registro.text.contains("huye"):
				fallos.append("3: %s no huye bien («%s»)" % [caso["activos"], c.registro.text])
		"perder":
			for n in caso["activos"]:
				var e: Dictionary = G.estadisticas(n)
				if e["pv"] != e["pv_max"]:
					fallos.append("3: tras perder, %s no vuelve con la vida llena (%d/%d)" % [n, e["pv"], e["pv_max"]])
	var huidos: int = c.enemigos.filter(func(e): return e.get("huido", false)).size()
	resumen.append("%s · grupo %d · %s: %s en %.0f s%s" % [caso["activos"], caso["grupo"], caso["modo"],
		"victoria" if gana else ("huida" if caso["modo"] == "huir" else "derrota"), segundos,
		"" if huidos == 0 else (" (huyó 1 enemigo: no da experiencia)" if huidos == 1 else
			" (huyeron %d enemigos: no dan experiencia)" % huidos)])


func _terminar() -> void:
	for l in resumen:
		print("  ", l)
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
