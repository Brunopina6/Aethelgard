extends SceneTree
# V12 (13/11): Nix, cuarta heroína y maga negra (PROTOTIPO; personajes/nix/, interruptor «nix_v12» encendido SOLO en
# esta prueba). Comprueba:
#   R. Reglas sin combate: el interruptor (sin él no existe aunque la partida traiga sus datos), sus datos (PV y defensa
#      por debajo de Kael, sin magias de siempre ni invocación), sus tres hechizos piloto (datos, conversión del daño),
#      el reparto en área (×3/n con 4 o más), la espera en turnos propios, los sellos de Eclipse (máximo 3, uno por
#      acción, los que gastan no dan) y la probabilidad del Lento (≈ 70 %).
#   A. Combate de verdad (Kael, Lya y Nix; Garon en la reserva) con el guion de la prueba en cada menú: Nix en el sitio
#      de Garon y en su puesto; su modelo (nix_3d.gd), clips, cara, LOD y bastón en el hueso; menú de magia con sus tres
#      hechizos y el culminante apagado por los sellos; Ascuas (daño, sello, gesto P01), Aguja (daño, Lento o «Falla»,
#      sello, gesto P02), Ascuas otra vez (3 sellos), Ascuas con 3 (siguen 3); Colapso: gasta 48 PM y los 3 sellos, se
#      prepara (concentrarse) y se suelta solo en su turno siguiente sobre todos (gesto P07, un sonido), no da sello y
#      deja 4 turnos de espera; defender (su clip); golpe recibido; al ganar, su victoria.
#   C. Sin interruptor: el combate de siempre, nadie la nombra y nadie sabe sus hechizos.
# No toca la partida de verdad.

const MAX_FOTOGRAMAS := 12000
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»). Los combates A y C no sembraban (el
# seed(12345) de R es para la probabilidad del Lento, sin combate, y ese sí era fijo): el daño y el Lento o «Falla» de la
# Aguja salían al azar. Ahora se siembra DESPUÉS de root.add_child(c) (como prueba_gorthor_v12.gd); el ATB de los
# enemigos ya lo pone la prueba a 0. Imprime «SEMILLA» por combate y una «TRAZA» por turno de Nix (paso y PV).
const SEMILLA := 13

var P
var G
var MN
var NX
var c = null
var frames := 0
var f_inicio := 0
var escenario := ""
var pendientes := ["R", "A", "C"]
var fallos: Array = []
var hechos: Array = []
var paso := 0
var sonidos: Array = []
var datos := {}
var clips_vistos := {}


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append("%s: %s" % [escenario, texto])


func _limpiar() -> void:
	for k in P.CLAVES + ["nix_v12", "naira_v12", "partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona",
			"desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	MN = load("res://magia_negra.gd")
	NX = load("res://personajes/nix/nix_combate.gd")
	if "auto" in OS.get_cmdline_user_args():
		print("FALLO: esta prueba lleva su guion: sin «-- auto»")
		quit(1)


# ---------------------------------------------------------------- R: reglas
func _reglas() -> void:
	escenario = "R"
	_limpiar()
	G.datos()
	_ok(not G.disponible("Nix") and not G.nix_v12(), "sin interruptor, Nix está disponible")
	_ok(G.unir("Nix") == "", "sin interruptor, Nix se une")
	_ok(MN.hechizos("Nix").is_empty(), "sin interruptor, Nix sabe magia negra")
	Engine.set_meta("nix_v12", true)
	_ok(G.disponible("Nix"), "con interruptor, Nix no está disponible")
	var h: Dictionary = G.HEROES["Nix"]
	_ok(h["magias"].is_empty() and h.get("provisional", false) and h["arma"] == "cetro", "los datos de Nix")
	var ek: Dictionary = {"pv": 40 + G.HEROES["Kael"]["atributos"]["vitalidad"] * 8, "def": G.HEROES["Kael"]["atributos"]["defensa"]}
	var pv_nix: int = 40 + h["atributos"]["vitalidad"] * 8
	_ok(pv_nix < ek["pv"] and pv_nix >= int(ek["pv"] * 0.85) and h["atributos"]["defensa"] < ek["def"],
		"PV o defensa de Nix (%d) no quedan algo por debajo de Kael (%d)" % [pv_nix, ek["pv"]])
	_ok(h["atributos"]["magia"] >= G.HEROES["Lya"]["atributos"]["magia"], "la magia de Nix no es la más alta")
	var fams: Array = MN.familias_de("Nix")
	_ok(fams == ["nix_ascuas", "nix_aguja", "nix_colapso"], "sus hechizos: %s" % [fams])
	var a: Dictionary = MN.datos("nix_ascuas", 1)
	var b: Dictionary = MN.datos("nix_aguja", 1)
	var z: Dictionary = MN.datos("nix_colapso", 1)
	_ok(a["coste"] == 5 and a["dano"] == 40 and a.get("genera_sello", false) and MN.ELEMENTO["nix_ascuas"] == "Fuego",
		"Ascuas de Nácar")
	_ok(b["coste"] == 5 and b["dano"] == 38 and b["estado"]["tipo"] == "lento" and is_equal_approx(float(b["prob"]), 0.7)
		and MN.ELEMENTO["nix_aguja"] == "Hielo", "Aguja de Invierno")
	_ok(z["coste"] == 48 and z["dano"] == 140 and z["a"] == "enemigos" and z["sellos"] == 3 and z["cd"] == 4
		and float(z["prep"]) > 0.0 and not z.get("genera_sello", false), "Colapso del Firmamento")
	# reparto en área: 1-3 blancos igual; con 4 o más, ×3/n
	_ok(MN.dano_base(z, 140, {"hp": 100}, 3) == 140 and MN.dano_base(z, 140, {"hp": 100}, 4) == 105
		and MN.dano_base(z, 140, {"hp": 100}, 6) == 70, "el reparto en área")
	_ok(MN.dano_base(MN.datos("negra_fuego", 3), 60, {"hp": 100}, 6) == 60, "el reparto toca a otra magia negra")
	# sellos: uno por acción si alcanzó a alguien, máximo 3; los que gastan no dan; sin alcanzar, nada
	var f := {"nombre": "Nix", "hp": 10}
	NX.al_confirmar(f, "nix_ascuas", a)
	_ok(not NX.tras_resolver(f, a) and NX.sellos(f) == 0, "da sello sin alcanzar a nadie")
	for i in 5:
		NX.al_confirmar(f, "nix_ascuas", a)
		NX.marcar_afecto(f, a)
		NX.marcar_afecto(f, a)                     # (dos blancos: sigue siendo un sello)
		NX.tras_resolver(f, a)
		if i == 0:
			_ok(NX.sellos(f) == 1, "dos blancos dan más de un sello")
	_ok(NX.sellos(f) == 3, "los sellos no paran en 3: %d" % NX.sellos(f))
	_ok(NX.motivo(f, "nix_colapso", z) == "", "con 3 sellos el Colapso no se puede")
	NX.al_confirmar(f, "nix_colapso", z)
	NX.marcar_afecto(f, z)
	_ok(not NX.tras_resolver(f, z) and NX.sellos(f) == 0, "el Colapso no gasta los sellos o da uno")
	_ok(NX.motivo(f, "nix_colapso", z).begins_with("Necesita"), "sin sellos el Colapso se puede")
	# espera: 4 turnos propios bloqueados, el quinto se puede
	f["nx_sellos"] = 3
	var bloqueados := 0
	for t in 5:
		NX.al_empezar_turno(f)
		if NX.motivo(f, "nix_colapso", z) != "":
			bloqueados += 1
	_ok(bloqueados == 4 and NX.motivo(f, "nix_colapso", z) == "", "la espera no son 4 turnos propios (%d)" % bloqueados)
	_ok(NX.motivo(f, "nix_ascuas", a) == "", "la espera de una bloquea a otra")
	# probabilidad del Lento (semilla fija)
	seed(12345)
	var entra := 0
	for i in 2000:
		if NX.estado_entra(b):
			entra += 1
	_ok(abs(entra / 2000.0 - 0.7) < 0.04, "el Lento entra el %.1f %%" % (entra / 20.0))
	_ok(NX.estado_entra(MN.datos("negra_hielo", 2)), "la probabilidad toca la Escarcha de siempre")
	hechos.append("R: interruptor, datos, tres hechizos, área ×3/n, sellos (1 por acción, tope 3), espera de 4 turnos, Lento ≈ %d %%" % roundi(entra / 20.0))
	_limpiar()


# ---------------------------------------------------------------- combates
func _empezar(e: String) -> void:
	escenario = e
	paso = 0
	datos.clear()
	sonidos.clear()
	clips_vistos.clear()
	_limpiar()
	G.datos()
	Engine.set_meta("nix_v12", true)               # la partida la une con el interruptor...
	G.unir("Nix")
	if e == "A":
		G.formar(["Kael", "Lya", "Nix"])
	else:
		Engine.remove_meta("nix_v12")              # ...y se juega sin él (la versión de hoy)
	for n in G.datos():
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	datos["antes"] = G.datos().duplicate(true)
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)                              # (aquí su _ready hace randomize())
	seed(SEMILLA)                                  # desde aquí, el azar del combate es fijo (el ATB enemigo se pone a 0 abajo)
	print("SEMILLA %d · %s" % [SEMILLA, e])
	c.MODO_PRUEBAS = false
	c.sonido_pedido.connect(func(n): sonidos.append(n))
	for en in c.enemigos:
		en["atb"] = 0.0
		en["vel"] = 0.2
		en["hp_max"] = 600
		en["hp"] = 600
	f_inicio = frames
	_al_empezar()


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _vivos() -> Array:
	return c.enemigos.filter(func(x): return x["hp"] > 0)


func _filas() -> Array:
	return c.menu.filas.map(func(f): return f["item"])


func _lanzar(fam: String, objetivo = null) -> void:
	c._menu_magia(c.PESTANA_NEGRA)
	c._menu_escuela(fam)
	c._elegir_negra(fam, 1)
	if objetivo != null:
		_ok(c.estado == "objetivo", "%s no pide objetivo" % fam)
		c._confirmar_objetivo(objetivo)


func _al_empezar() -> void:
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	match escenario:
		"A":
			_ok(nombres == ["Kael", "Lya", "Nix"], "en el combate: %s" % [nombres])
			var nix := _heroe("Nix")
			_ok(not nix.is_empty() and nix["pos"] == Vector2(270, 100), "Nix no está en el sitio de Garon")
			var p = c._p3d(nix) if not nix.is_empty() else null
			_ok(p != null and p.get_script().resource_path == "res://personajes/nix/nix_3d.gd" and p.anim != null,
				"Nix sin su modelo")
			if p != null and p.anim != null:
				for k in ["reposo", "guardia", "andar", "correr", "magia_lanzar", "magia_estado", "magia_culminante",
						"magia_concentrar", "recibir_golpe", "defender", "defensa", "victoria", "derribo", "derrota",
						"levantarse", "ataque", "hablar"]:
					_ok(p.anim.has_animation(k), "falta el clip %s" % k)
				var contrato: Dictionary = p._clips
				var ajenos: Array = Array(p.anim.get_animation_list()).filter(func(n): return n != "RESET" and not contrato.has(n))
				_ok(ajenos.is_empty() and contrato.size() >= 20, "clips que no son de su contrato: %s" % [ajenos])
				if p._fbx:
					# 14/11, con «-- nix_fbx»: el modelo del FBX con su vestuario (cara en la textura, LOD del
					# importador, cetro propio por socket); prueba_nix_fbx.gd comprueba el modelo en detalle
					_ok(p.ruta_modelo == "res://personajes/nix/fbx/nix_fbx.glb", "en combate no carga el GLB del FBX: %s" % p.ruta_modelo)
					_ok(p.find_child("ropa_nix", true, false) is MeshInstance3D, "Nix FBX sin su ropa")
					_ok(p.vara != null and p.vara.find_child("cetro_nix", true, false) != null, "Nix FBX sin su cetro en el socket")
				else:
					_ok(p.find_child("cara_nix", true, false) != null and p.v2 != null and p.v2.tiene_cara(), "Nix sin su cara")
					for l in ["cuerpo_nix", "cuerpo_nix_lod1", "cuerpo_nix_lod2"]:
						var mi = p.find_child(l, true, false)
						_ok(mi is MeshInstance3D, "falta %s" % l)
					var l0 = p.find_child("cuerpo_nix", true, false)
					_ok(l0 != null and l0.visibility_range_begin == 0.0 and l0.visibility_range_end > 0.0, "el LOD0 sin su distancia")
					_ok(p.skel.find_bone("arma_d") >= 0 and p.vara == null, "el bastón no va en su hueso")
				var pm: Vector3 = p.punto_magia()
				_ok(pm.y > p.global_position.y + 0.5, "el punto de la magia no está en el cristal: %s" % pm)
				datos["p"] = p
			var e: Dictionary = G.estadisticas("Nix")
			_ok(nix.get("hp_max", 0) == e["pv_max"] and nix.get("mp_max", 0) == e["pm_max"], "Nix sin sus datos")
			_ok(nix.get("hp_max", 0) < _heroe("Kael").get("hp_max", 0), "Nix con más PV que Kael")
		"C":
			_ok(nombres == ["Kael", "Lya", "Garon"], "sin interruptor, en el combate: %s" % [nombres])
			_ok(MN.hechizos("Nix").is_empty(), "sin interruptor, Nix sabe magia negra")
			_ok(c.heroes.all(func(h): return not h.has("nx_sellos")), "sellos sin Nix")
			datos["fin_guion"] = true


func _process(_d: float) -> bool:
	frames += 1
	if frames < 10:
		return false
	_foto()
	if c == null:
		if pendientes.is_empty():
			_terminar()
			return true
		var sig: String = pendientes.pop_front()
		if sig == "R":
			_reglas()
			return false
		_empezar(sig)
		return false
	if datos.has("p") and is_instance_valid(datos["p"]) and datos["p"].anim != null:
		clips_vistos[String(datos["p"].anim.current_animation)] = true
	if datos.has("apagar"):
		if frames - int(datos["apagar"]) > 200:
			_al_acabar()
			c.queue_free()
			c = null
			_limpiar()
		return false
	if datos.has("fin_guion") and not datos.has("ganado"):
		datos["ganado"] = frames
		for e in c.enemigos:
			e["hp"] = 0
		c._comprobar_fin()
	if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		var quien: Dictionary = c.actor
		if quien["nombre"] != "Nix":
			quien["mp"] = quien["mp_max"]
		if escenario == "A":
			_turno_a(quien)
		else:
			c._defender()
	if datos.has("ganado") and c.estado == "fin" and frames - int(datos["ganado"]) > 30 and not datos.has("apagar"):
		datos["apagar"] = frames
	elif frames - f_inicio > MAX_FOTOGRAMAS and not datos.has("apagar"):
		_ok(false, "no llegó al final (paso %d, estado %s)" % [paso, c.estado])
		c.set_process(false)
		datos["apagar"] = frames
	return false


# Con ventana y «-- fotos=<carpeta>»: un JPG cada 3 fotogramas del combate A (para el vídeo de evidencias).
func _foto() -> void:
	if c == null or escenario != "A" or frames % 3 != 0 or DisplayServer.get_name() == "headless":
		return
	var dir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			dir = a.substr(6)
	if dir == "":
		return
	var img := root.get_texture().get_image()
	if img != null:
		img.save_jpg("%s/f_%05d.jpg" % [dir, frames], 0.85)


func _fila(texto: String) -> Dictionary:
	for i in _filas():
		if str(i.get("texto", "")) == texto:
			return i
	return {}


func _turno_a(quien: Dictionary) -> void:
	if quien["nombre"] != "Nix":
		if quien["nombre"] == "Kael" and paso == 7 and not datos.has("herida"):
			datos["herida"] = true
			var nix := _heroe("Nix")
			var p = datos.get("p")
			c._quitar_pv(nix, 3)
			if p != null:
				p.herida()
		c._defender()
		return
	var vivos := _vivos()
	quien["mp"] = maxi(quien["mp"], 60)
	var pv := []                                   # una línea por turno de Nix (para reproducir la semilla)
	for f in c.heroes + c.enemigos:
		pv.append("%s %d" % [f["nombre"], int(f["hp"])])
	print("TRAZA f%05d Nix paso %d · %s" % [frames - f_inicio, paso, ", ".join(pv)])
	match paso:
		0:
			# 15/11 (revisión de personajes): Nix usa magia negra y NO invoca. Con la Armonía llena y Lya en pie, su
			# menú principal no tiene la orden INVOCACIÓN (ni apagada); llamar a la acción con Nix de actor no invoca.
			var armonia_antes: float = c.armonia
			c.armonia = 1.0
			c._mostrar_menu()
			var ordenes: Array = _filas().map(func(i): return str(i.get("tipo", i.get("texto", ""))))
			_ok(not ("invocacion" in ordenes) and not ("INVOCACIÓN" in ordenes),
				"el menú de Nix tiene INVOCACIÓN: %s" % [ordenes])
			_ok("MAGIA" in ordenes, "el menú de Nix no tiene MAGIA: %s" % [ordenes])
			c._invocar()
			_ok(c.estado == "menu" and c.inv_erebo == null, "_invocar con Nix de actor invoca (estado %s)" % c.estado)
			c.armonia = armonia_antes
			hechos.append("A: menú de Nix %s, sin INVOCACIÓN con la Armonía llena" % [ordenes])
			c._menu_magia()
			var escuelas: Array = _filas().filter(func(i): return i.has("escuela")).map(func(i): return i["escuela"])
			_ok(escuelas == ["nix_ascuas", "nix_aguja", "nix_colapso"], "el menú de Nix: %s" % [escuelas])
			c._menu_escuela("nix_colapso")
			var fz := _fila("Colapso del Firmamento")
			_ok(not fz.is_empty() and fz.get("apagado", false) and str(fz.get("desc", "")).begins_with("Necesita 3 sellos")
				and str(fz.get("derecha", "")).contains("◈3"), "el Colapso sin sellos: %s" % [fz])
			datos["hp0"] = vivos[0]["hp"]
			_lanzar("nix_ascuas", vivos[0])
			paso = 1
		1:
			_ok(vivos[0]["hp"] < int(datos["hp0"]), "Ascuas no hace daño")
			_ok(NX.sellos(quien) == 1, "Ascuas no da un sello (%d)" % NX.sellos(quien))
			_ok(clips_vistos.has("magia_lanzar"), "Ascuas sin su gesto (P01)")
			datos["hp1"] = vivos[0]["hp"]
			_lanzar("nix_aguja", vivos[0])
			datos["obj"] = vivos[0]
			paso = 2
		2:
			var obj: Dictionary = datos["obj"]
			_ok(obj["hp"] < int(datos["hp1"]), "Aguja no hace daño")
			_ok(NX.sellos(quien) == 2, "Aguja no da un sello (%d)" % NX.sellos(quien))
			_ok(clips_vistos.has("magia_estado"), "Aguja sin su gesto (P02)")
			datos["lento"] = MN.turnos(obj, "lento") > 0
			_lanzar("nix_ascuas", vivos[0])
			paso = 3
		3:
			_ok(NX.sellos(quien) == 3, "tercer sello (%d)" % NX.sellos(quien))
			_lanzar("nix_ascuas", vivos[0])
			paso = 4
		4:
			_ok(NX.sellos(quien) == 3, "los sellos pasan de 3 (%d)" % NX.sellos(quien))
			c._menu_magia(c.PESTANA_NEGRA)
			c._menu_escuela("nix_colapso")
			var fz := _fila("Colapso del Firmamento")
			_ok(not fz.is_empty() and not fz.get("apagado", false), "con 3 sellos el Colapso sigue apagado: %s" % [fz])
			datos["pm"] = quien["mp"]
			datos["pv"] = vivos.map(func(e): return e["hp"])
			datos["son"] = sonidos.size()
			_lanzar("nix_colapso")
			_ok(quien.has("conjuro") and quien["mp"] == int(datos["pm"]) - 48 and NX.sellos(quien) == 0,
				"el Colapso no se prepara, no gasta 48 PM o los sellos")
			var p = datos.get("p")
			# (con el FBX la concentración empieza por «canalizar» y enlaza el bucle)
			_ok(p != null and String(p.anim.current_animation) in (["magia_concentrar", "canalizar"] if p._fbx else ["magia_concentrar"]),
				"Nix no se concentra al preparar")
			paso = 5
		5:
			_ok(not quien.has("conjuro"), "el Colapso sigue preparándose")
			var bajan: Array = []
			for i in vivos.size():
				bajan.append(int(datos["pv"][i]) - vivos[i]["hp"])
			_ok(bajan.all(func(x): return x > 0), "el Colapso no daña a todos: %s" % [bajan])
			_ok(clips_vistos.has("magia_culminante"), "el Colapso sin su gesto (P07)")
			var nuevos: Array = sonidos.slice(int(datos["son"]))
			_ok(nuevos.count("negra_colapso") + nuevos.count("golpe_critico") == 1, "el Colapso suena %s" % [nuevos])
			_ok(NX.sellos(quien) == 0, "el Colapso da un sello")
			quien["nx_sellos"] = 3                          # para ver la espera aunque tenga sellos
			c._menu_magia(c.PESTANA_NEGRA)
			c._menu_escuela("nix_colapso")
			var fz := _fila("Colapso del Firmamento")
			_ok(fz.get("apagado", false) and str(fz.get("desc", "")).begins_with("Aún no"), "sin espera tras el Colapso: %s" % [fz])
			hechos.append("A: Ascuas, Aguja (%s), sellos hasta 3, Colapso preparado y suelto sobre todos, un sonido, espera" %
				("Lento" if datos.get("lento", false) else "falló el Lento"))
			c._defender()
			paso = 6
		6:
			_ok(clips_vistos.has("defender") or clips_vistos.has("defensa"), "Defender sin su clip")
			paso = 7
			c._defender()
		7:
			_ok(datos.has("herida") and clips_vistos.has("recibir_golpe"), "el golpe recibido sin su clip")
			datos["fin_guion"] = true
			c._defender()
		_:
			c._defender()


func _al_acabar() -> void:
	match escenario:
		"A":
			_ok(clips_vistos.has("victoria"), "sin su victoria")
			var ganada: int = int(G.datos()["Nix"]["exp"]) - int(datos["antes"]["Nix"]["exp"]) + \
				(int(G.datos()["Nix"]["nivel"]) - int(datos["antes"]["Nix"]["nivel"])) * 1000
			_ok(ganada > 0, "Nix no gana experiencia")
			hechos.append("A: Nix en el sitio de Garon, modelo, clips, cara, LOD, bastón en su hueso, defensa, golpe y victoria")
		"C":
			hechos.append("C: sin interruptor, el combate de siempre")


func _terminar() -> void:
	_limpiar()
	for h in hechos:
		print("OK ", h)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
