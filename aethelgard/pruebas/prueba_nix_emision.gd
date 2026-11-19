extends SceneTree
# V12 (19/11, C-6): la EMISIÓN DE LOS ORNAMENTOS de Nix (piloto FBX) en un COMBATE DE VERDAD (combate.tscn, Kael, Lya y
# Nix; interruptores «nix_v12» y «nix_fbx» encendidos solo en esta prueba). Lee en cada fotograma el uniforme
# «ornamentos» del material de la ropa (lo que de verdad dibuja) y comprueba:
#   1. Ascuas de Nácar (rango I): sube a la BÁSICA y vuelve a 0 al acabar;
#   2. Colapso del Firmamento (rango VI, se prepara): FUERTE mientras canaliza, SUPREMA al soltarlo, 0 al acabar;
#   3. INTERRUPCIÓN: con el Colapso en preparación, un golpe que rompe el conjuro (combate.gd _quitar_pv → _conjuro_roto)
#      la deja a 0 en el acto, y sigue a 0 hasta su turno siguiente;
#   4. MUERTE: con las Ascuas subiendo, Nix cae (_quitar_pv + _restablecer_color, como el juego) → 0 en el acto, y no
#      vuelve a subir aunque el hechizo termine de resolverse;
#   5. PAUSA (SceneTree.paused) con el Colapso en preparación → 0 en el acto y quieta mientras dura;
#   6. FIN DEL COMBATE con el Colapso saliendo (suprema): todos los enemigos caen (_comprobar_fin → victoria) → 0;
#   7. SALIDA de la escena con la emisión encendida → el material queda a 0;
#   8. sin el interruptor nix_fbx, la Nix de siempre no tiene material de ornamentos (nada cambia).
# No toca la partida de verdad (datos aislados con ejecutar_pruebas.ps1).

const MAX_FOTOGRAMAS := 9000
const NF := preload("res://personajes/nix/fbx/nix_fbx.gd")

var P
var G
var MN
var c = null
var p = null                     # modelo 3D de Nix
var mat: ShaderMaterial = null   # material de su ropa
var frames := 0
var f_inicio := 0
var paso := 0
var fase := ""
var maximos := {}
var fallos: Array = []
var hechos: Array = []
var datos := {}
var escenario := ""
var pendientes := ["fbx", "sin"]


func _ok(cond: bool, texto: String) -> void:
	print(("OK    " if cond else "FALLO ") + "%s: %s" % [escenario, texto])
	if not cond:
		fallos.append("%s: %s" % [escenario, texto])


func _limpiar() -> void:
	for k in P.CLAVES + ["nix_v12", "nix_fbx", "naira_v12", "partida_lista", "grupo_combate", "combate_fijo",
			"tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	MN = load("res://magia_negra.gd")


func _orn() -> float:
	return float(mat.get_shader_parameter("ornamentos")) if mat != null else -1.0


func _cerca(v: float, nivel: int) -> bool:
	return absf(v - NF.NIVELES[nivel]) < 0.02


func _empezar(e: String) -> void:
	escenario = e
	paso = 0
	fase = ""
	maximos.clear()
	datos.clear()
	_limpiar()
	G.datos()
	Engine.set_meta("nix_v12", true)
	if e == "fbx":
		Engine.set_meta("nix_fbx", true)
	G.unir("Nix")
	G.formar(["Kael", "Lya", "Nix"])
	for n in G.datos():
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(19)
	c.MODO_PRUEBAS = false
	for en in c.enemigos:
		en["atb"] = 0.0
		en["vel"] = 0.0                            # los enemigos no actúan: los golpes los da la prueba
		en["hp_max"] = 900
		en["hp"] = 900
	f_inicio = frames
	var nix := _nix()
	p = c._p3d(nix) if not nix.is_empty() else null
	mat = p.get("_mat_ropa") if p != null else null
	if e == "sin":
		_ok(p != null and not p._fbx and mat == null, "sin nix_fbx: la Nix de siempre, sin material de ornamentos")
		var con := 0
		for m in p.find_children("*", "MeshInstance3D", true, false):
			for s in m.get_surface_override_material_count():
				var sm := m.get_surface_override_material(s) as ShaderMaterial
				if sm != null and sm.shader != null and sm.shader.resource_path == NF.SHADER_ROPA:
					con += 1
		_ok(con == 0, "sin nix_fbx: ningún material con la emisión de los ornamentos (%d)" % con)
		p.concentrar()
		_ok(p.has_method("apagar_emision") and p.has_method("nivel_emision"), "nix_3d.gd tiene apagar_emision y nivel_emision")
		if p.has_method("apagar_emision"):
			p.apagar_emision()
			_ok(p.nivel_emision() == 0.0, "sin nix_fbx: concentrarse y apagar no hacen nada")
		hechos.append("sin nix_fbx: la Nix de siempre, sin ornamentos")
		datos["apagar"] = frames
		return
	_ok(p != null and p._fbx and mat != null and mat.shader.resource_path == NF.SHADER_ROPA,
		"con nix_fbx: la ropa con nix_fbx_ropa.gdshader")
	_ok(_orn() == 0.0, "al empezar el combate, apagada (%.2f)" % _orn())


func _nix() -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == "Nix":
			return h
	return {}


func _lanzar(fam: String) -> void:
	c._menu_magia(c.PESTANA_NEGRA)
	c._menu_escuela(fam)
	c._elegir_negra(fam, 1)
	if c.estado == "objetivo":
		c._confirmar_objetivo(c.enemigos.filter(func(x): return x["hp"] > 0)[0])


func _preparar_colapso(quien: Dictionary) -> void:
	quien["nx_sellos"] = 3
	quien["nx_cd"] = {}
	quien["nx_cd_turno"] = {}
	quien["mp"] = quien["mp_max"]
	_lanzar("nix_colapso")


func _anotar() -> void:
	if fase == "" or mat == null:
		return
	maximos[fase] = maxf(float(maximos.get(fase, 0.0)), _orn())


func _process(_d: float) -> bool:
	frames += 1
	if frames < 10:
		return false
	# (una instancia liberada es «== null»: la salida se mira antes)
	if datos.has("liberado"):
		if frames - int(datos["liberado"]) >= 3:
			_salir()
		return false
	if c == null:
		if pendientes.is_empty():
			_terminar()
			return true
		_empezar(pendientes.pop_front())
		return false
	if datos.has("apagar"):
		if frames - int(datos["apagar"]) > 40:
			c.queue_free()                         # la escena del combate sale (con la emisión encendida en «fbx»)
			datos["liberado"] = frames
		return false
	var nix := _nix()
	_vigilar(nix)                                  # (antes de anotar: el cambio de fase, en el mismo fotograma)
	_anotar()
	if datos.has("apagar"):
		return false
	if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		var quien: Dictionary = c.actor
		if quien["nombre"] != "Nix":
			c._defender()
		else:
			_turno_nix(quien)
	if frames - f_inicio > MAX_FOTOGRAMAS and not datos.has("apagar"):
		_ok(false, "no llegó al final (paso %d, fase %s, estado %s)" % [paso, fase, c.estado])
		datos["apagar"] = frames
	return false


# Lo que pasa entre turnos: el Colapso se prepara y sale solo; aquí se rompe, se pausa y se acaba el combate.
func _vigilar(nix: Dictionary) -> void:
	match paso:
		2:
			if fase == "canal" and not nix.has("conjuro"):
				fase = "suelta"                    # el Colapso sale (su barra se llenó)
		3:
			if fase == "romper" and nix.has("conjuro") and _orn() >= NF.NIVELES[NF.FUERTE] - 0.02:
				_ok(_cerca(_orn(), NF.FUERTE), "Colapso en preparación: fuerte (%.2f)" % _orn())
				nix["hp"] = nix["hp_max"]
				var golpe := ceili(nix["hp_max"] * MN.UMBRAL_ROTURA)
				c._quitar_pv(nix, golpe)         # el golpe que rompe el conjuro (el mismo camino que el de un enemigo)
				_ok(not nix.has("conjuro"), "el golpe rompe el conjuro")
				_ok(_orn() == 0.0, "INTERRUPCIÓN (conjuro roto): a 0 en el acto (%.2f)" % _orn())
				fase = "rota"
				datos["rota"] = frames
			elif fase == "rota" and frames - int(datos["rota"]) == 60:
				_ok(_orn() == 0.0, "tras el conjuro roto sigue a 0 (%.2f)" % _orn())
		4:
			if fase == "morir" and _orn() > 0.2:
				c._quitar_pv(nix, nix["hp"])
				c._restablecer_color(nix)        # como el juego tras un golpe: a 0 PV, morir()
				_ok(p._muerta, "Nix cae (morir())")
				_ok(_orn() == 0.0, "MUERTE con las Ascuas subiendo: a 0 en el acto (%.2f)" % _orn())
				fase = "muerta"
				datos["muerta"] = frames
			elif fase == "muerta" and frames - int(datos["muerta"]) == 75:
				_ok(_orn() == 0.0 and float(maximos.get("muerta", 0.0)) == 0.0,
					"muerta no vuelve a subir aunque el hechizo acabe de resolverse (máx. %.2f)" % float(maximos.get("muerta", 0.0)))
				nix["hp"] = nix["hp_max"]          # la prueba la levanta para seguir
				p.revivir()
				c._actualizar()
				fase = ""
		5:
			if fase == "pausa" and nix.has("conjuro") and _orn() >= NF.NIVELES[NF.FUERTE] - 0.02:
				paused = true
				_ok(_orn() == 0.0, "PAUSA con el Colapso en preparación: a 0 en el acto (%.2f)" % _orn())
				fase = "en_pausa"
				datos["pausa"] = frames
			elif fase == "en_pausa":
				if frames - int(datos["pausa"]) >= 20:
					_ok(float(maximos.get("en_pausa", 0.0)) == 0.0, "y quieta mientras dura la pausa (máx. %.2f)" % float(maximos.get("en_pausa", 0.0)))
					paused = false
					fase = "tras_pausa"
			elif fase == "tras_pausa" and not nix.has("conjuro"):
				fase = "final"                     # el Colapso sale: suprema otra vez
			elif fase == "final" and _orn() > 1.0:
				for e in c.enemigos:
					e["hp"] = 0
				c._comprobar_fin()
				_ok(c.estado == "fin", "todos los enemigos caen: fin del combate")
				_ok(_orn() == 0.0, "FIN DEL COMBATE (victoria) con el Colapso saliendo: a 0 en el acto")
				fase = "fin"
				datos["fin"] = frames
			elif fase == "fin" and frames - int(datos["fin"]) == 60:
				_ok(float(maximos.get("fin", 0.0)) == 0.0, "tras la victoria sigue a 0 (máx. %.2f)" % float(maximos.get("fin", 0.0)))
				# SALIDA de la escena con la emisión encendida (el gesto de las Ascuas, sin pasar por el menú)
				p.lanzar_negra("nix_ascuas")
				datos["salida"] = frames
				fase = "salida"
			elif fase == "salida" and frames - int(datos["salida"]) == 20:
				_ok(_orn() > 0.2, "antes de salir, encendida (%.2f)" % _orn())
				hechos.append("Ascuas básica, Colapso fuerte y suprema, conjuro roto, muerte, pausa y victoria: a 0")
				datos["apagar"] = frames


func _turno_nix(quien: Dictionary) -> void:
	quien["mp"] = maxi(quien["mp"], 60)
	match paso:
		0:
			fase = "ascuas"
			_lanzar("nix_ascuas")
			paso = 1
		1:
			_ok(_cerca(float(maximos.get("ascuas", 0.0)), NF.BASICA), "Ascuas: llega a la básica (máx. %.2f)" % float(maximos.get("ascuas", 0.0)))
			_ok(_orn() == 0.0, "Ascuas: a 0 al acabar (%.2f)" % _orn())
			fase = "canal"
			_preparar_colapso(quien)
			_ok(quien.has("conjuro"), "el Colapso se prepara")
			paso = 2
		2:
			if quien.has("conjuro"):
				c._defender()
				return
			_ok(_cerca(float(maximos.get("canal", 0.0)), NF.FUERTE), "Colapso canalizando: fuerte (máx. %.2f)" % float(maximos.get("canal", 0.0)))
			_ok(_cerca(float(maximos.get("suelta", 0.0)), NF.SUPREMA), "Colapso al soltarlo: suprema (máx. %.2f)" % float(maximos.get("suelta", 0.0)))
			_ok(_orn() == 0.0, "Colapso: a 0 al acabar (%.2f)" % _orn())
			fase = "romper"
			_preparar_colapso(quien)
			paso = 3
		3:
			if fase != "rota":
				c._defender()
				return
			_ok(_orn() == 0.0 and float(maximos.get("rota", 0.0)) == 0.0, "conjuro roto: a 0 hasta su turno (máx. %.2f)" % float(maximos.get("rota", 0.0)))
			fase = "morir"
			_lanzar("nix_ascuas")
			paso = 4
		4:
			if fase != "":
				c._defender()
				return
			_ok(not p._muerta, "Nix vuelve a estar en pie")
			fase = "pausa"
			_preparar_colapso(quien)
			paso = 5
		_:
			c._defender()


func _salir() -> void:
	if escenario == "fbx":
		_ok(_orn() == 0.0, "SALIDA de la escena: el material queda a 0 (%.2f)" % _orn())
	c = null
	p = null
	mat = null
	paused = false
	datos.clear()
	_limpiar()


func _terminar() -> void:
	_limpiar()
	for h in hechos:
		print("OK ", h)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
