extends SceneTree
# V12 (13/11), Cumbres de Ciclópea 3D, segunda pasada (todo dentro de «ciclopea3d», apagado):
#   1. La estatua: la pieza de Blender (zonas3d/ciclopea/modelos/estatua.glb) dentro del presupuesto, mirando al norte
#      (al pico), con su choque; sin ella (Engine «ciclopea_estatua_primitivas»), la de primitivas de respaldo.
#   2. La ventisca va y viene (calma → sube → ventisca → amaina → calma), cierra la bruma y apaga el sol, la nevada se
#      vuelve horizontal y salen las ráfagas; sin transparencias grandes (las ráfagas, opacas); al abrigo de un refugio
#      encendido apenas se nota.
#   3. Los refugios de montaña: tres, junto al camino, alcanzables y sin pisar nada; encender cada uno (Poción, hito,
#      fuego), los tres (120 monedas, una vez); descansar cura y guarda; el atajo de bajada con el de abajo y el de arriba
#      encendidos; al cargar la partida siguen encendidos; nada en Orbes.
# Uso: --headless --path aethelgard --script res://pruebas/prueba_ciclopea3d_v2.gd --fixed-fps 30 -- 3d ciclopea3d sin_prologo

const REGION := "res://zonas3d/ciclopea_3d.tscn"
var T = load("res://zonas3d/ciclopea/trazado.gd")
var D = load("res://zonas3d/ciclopea/disposicion_2d.gd")
var R = load("res://zonas3d/ciclopea/refugios.gd")
var P = load("res://progreso.gd")
var I = load("res://inventario.gd")
var v
var fallos := 0


func _initialize() -> void:
	_correr()


func _mal(t: String) -> void:
	fallos += 1
	print("FALLO: " + t)


func _ok(t: String) -> void:
	print("OK " + t)


func _frames(n: int) -> void:
	for i in n:
		if v != null and is_instance_valid(v) and "pasos" in v:
			v.pasos = 0
		await process_frame


func _cargar() -> void:
	change_scene_to_file(REGION)
	await _frames(25)
	v = current_scene


func _correr() -> void:
	await _frames(2)
	for k in ["cofres_abiertos", "lore_visto", "hitos", "pos_3d"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	# ---------------------------------------------------------------- 1. la estatua
	await _cargar()
	var est: Node3D = v.escenario.estatua
	var pieza: Node3D = est.get_node_or_null("Pieza")
	if pieza == null:
		_mal("la estatua no es la pieza de Blender")
	else:
		var tris := 0
		for mi in pieza.find_children("*", "MeshInstance3D", true, false):
			var a := (mi as MeshInstance3D).mesh.surface_get_arrays(0)
			tris += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		var adelante: Vector3 = est.global_transform.basis.z           # el modelo mira a +z local
		if tris > 4000 or tris < 1000:
			_mal("la estatua tiene %d triángulos (presupuesto 4000)" % tris)
		elif adelante.z > -0.9:
			_mal("la estatua no mira al norte (al pico): %s" % adelante)
		elif not v._prohibido(est.global_position):
			_mal("se puede atravesar la estatua")
		else:
			_ok("estatua de Blender: %d triángulos, mira al norte, choca" % tris)
	Engine.set_meta("ciclopea_estatua_primitivas", true)
	await _cargar()
	if v.escenario.estatua.get_node_or_null("Pieza") != null or v.escenario.estatua.get_child_count() == 0:
		_mal("sin la pieza no queda la estatua de primitivas")
	else:
		_ok("respaldo: la estatua de primitivas (%d mallas)" % v.escenario.estatua.get_child_count())
	Engine.remove_meta("ciclopea_estatua_primitivas")

	# ---------------------------------------------------------------- 2. la ventisca
	await _cargar()
	var vt = v.ventisca
	var niebla0: float = vt.env.fog_density
	var sol0: float = vt.sol.light_energy
	vt.forzar("ventisca")
	await _frames(60)
	if vt.intensidad < 0.6 or vt.env.fog_density < niebla0 * 2.0 or vt.sol.light_energy > sol0 * 0.8 or not vt.rafagas.emitting:
		_mal("en la ventisca no se cierra la bruma o no salen las ráfagas (i %.2f, bruma %.4f, sol %.2f)" % [vt.intensidad, vt.env.fog_density, vt.sol.light_energy])
	else:
		_ok("ventisca: bruma %.4f → %.4f, sol %.2f → %.2f, ráfagas" % [niebla0, vt.env.fog_density, sol0, vt.sol.light_energy])
	var m: StandardMaterial3D = vt.rafagas.mesh.material
	if m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		_mal("las ráfagas son transparentes")
	vt.forzar("baja", 1.0)
	await _frames(30 * 4)
	if vt.estado != "calma" or vt.intensidad > 0.15 or vt.rafagas.emitting:
		_mal("la ventisca no amaina (%s, %.2f)" % [vt.estado, vt.intensidad])
	else:
		_ok("amaina y vuelve la calma (%s)" % vt.estado)
	# que va y viene sola: con tiempos cortos, una vuelta entera
	vt.forzar("calma", 0.5)
	var vistos := {}
	for i in 30 * 60:
		vistos[vt.estado] = true
		if vt.estado == "sube" and vt.dura > 1.0:
			vt.dura = 1.0
		if vt.estado == "ventisca" and vt.dura > 1.0:
			vt.dura = 1.0
		if vt.estado == "baja" and vt.dura > 1.0:
			vt.dura = 1.0
		if vistos.size() == 4 and vt.estado == "calma":
			break
		await _frames(1)
	if vistos.size() < 4:
		_mal("la ventisca no da la vuelta sola: %s" % [vistos.keys()])
	else:
		_ok("va y viene: %s" % [vistos.keys()])

	# ---------------------------------------------------------------- 3. los refugios
	var rf = v.refugios
	var sitios: Array = R.sitios()
	if sitios.size() != 3:
		_mal("no hay tres refugios")
	for i in sitios.size():
		var c: Vector2 = sitios[i][0]
		var pu: Vector3 = rf.puerta(i)
		if v._prohibido(pu) or T.dist_caminos(c) < 2.5 or T.dist_caminos(c) > 6.0:
			_mal("el refugio %d no se alcanza o está mal puesto (puerta %s, a %.1f del camino)" % [i, pu, T.dist_caminos(c)])
	_ok("tres refugios junto al camino: %s" % [sitios.map(func(s): return s[0])])
	var oro0: int = I.oro()
	var poc0: int = _pociones()
	for i in [0, 2]:
		v._colocar_kael(rf.puerta(i))
		await _frames(3)
		v._comprobar_cerca()
		if v.cerca != "refugio:%d" % i or v.boton_accion.text != "Encender el refugio":
			_mal("en la puerta del refugio %d no sale «Encender el refugio» (%s, %s)" % [i, v.cerca, v.boton_accion.text])
			continue
		v._bloqueo = 0.0
		v._accion()
		await _frames(3)
	if not (P.hito("cc_refugio_1") and P.hito("cc_refugio_3")) or not rf.fuegos[0].visible or _pociones() != poc0 + 2:
		_mal("encender no apunta el hito, el fuego o la Poción")
	elif not rf.atajo_abierto():
		_mal("con el de abajo y el de arriba encendidos no se abre el atajo")
	else:
		_ok("encender: hito, fuego y Poción; atajo abierto")
	# el atajo: del de arriba al de abajo
	var arriba: Array = rf.piezas().filter(func(p): return p[0] == "atajo:bajar")
	v._colocar_kael(arriba[0][1])
	await _frames(3)
	v._comprobar_cerca()
	if v.cerca != "atajo:bajar":
		_mal("junto al refugio de arriba no sale «Bajar por el atajo» (%s)" % v.cerca)
	else:
		v._bloqueo = 0.0
		v._accion()
		await _frames(40)
		var abajo: Vector3 = T.en_mundo(sitios[0][0])
		var d := Vector2(v.kael.global_position.x - abajo.x, v.kael.global_position.z - abajo.z).length()
		if d > 5.0 or v._prohibido(v.kael.global_position):
			_mal("el atajo no lleva al refugio de abajo (a %.1f m)" % d)
		else:
			_ok("el atajo baja al refugio de abajo (a %.1f m)" % d)
	# el tercero: los tres encendidos, el premio una vez
	v._colocar_kael(rf.puerta(1))
	await _frames(3)
	v._comprobar_cerca()
	v._bloqueo = 0.0
	v._accion()
	await _frames(3)
	if not rf.todos() or not P.hito("cc_refugios") or I.oro() != oro0 + R.PREMIO_TODOS:
		_mal("los tres encendidos no dan el premio (oro %d → %d)" % [oro0, I.oro()])
	else:
		_ok("los tres refugios: +%d monedas, una vez" % R.PREMIO_TODOS)
	# descansar: cura y no vuelve a dar premio
	var G = load("res://grupo.gd")
	var n: String = "Kael"
	var e: Dictionary = G.datos()[n]
	G.guardar_vida(n, 1, int(e["pm"]))
	v._bloqueo = 0.0
	v._comprobar_cerca()
	if v.boton_accion.text != "Descansar junto al fuego":
		_mal("un refugio encendido no ofrece «Descansar junto al fuego» (%s)" % v.boton_accion.text)
	v._accion()
	await _frames(3)
	if int(G.datos()[n]["pv"]) < int(G.estadisticas(n)["pv_max"]) or I.oro() != oro0 + R.PREMIO_TODOS:
		_mal("descansar no cura o da más premio")
	else:
		_ok("descansar junto al fuego cura (sin más premio)")
	# al abrigo, la ventisca apenas se nota
	vt = v.ventisca
	vt.forzar("ventisca")
	v._colocar_kael(rf.puerta(1))
	await _frames(60)
	var abrigada: float = vt.intensidad
	v._colocar_kael(T.en_mundo(Vector2(40.0, 30.0)))
	await _frames(60)
	if abrigada > 0.4 or vt.intensidad < 0.6:
		_mal("el abrigo del refugio no se nota (%.2f junto al fuego, %.2f fuera)" % [abrigada, vt.intensidad])
	else:
		_ok("al abrigo de un refugio: %.2f; a la intemperie: %.2f" % [abrigada, vt.intensidad])
	# guardar y cargar: siguen encendidos
	v.guardar_posicion()
	await _cargar()
	if not v.refugios.todos() or not v.refugios.fuegos[2].visible:
		_mal("al cargar, los refugios se apagan")
	else:
		_ok("al cargar, los tres siguen encendidos")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _pociones() -> int:
	return I.cantidad("Poción")
