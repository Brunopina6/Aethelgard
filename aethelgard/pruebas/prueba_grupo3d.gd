extends SceneTree
# Prueba del grupo en la región 3D de Pastos Verdes (zonas3d/grupo_3d.gd), con la exploración 3D activa («-- 3d»):
#   1. al entrar, Lya y Garon están junto a Kael, en suelo andable y fuera de las zonas prohibidas;
#   2. Kael recorre el camino, cruza el puente y da media vuelta sobre el puente: ninguno de los dos pisa una zona
#      prohibida, se queda atrás (Lya respecto a Kael y Garon respecto a Lya), flota o se hunde, ni atraviesa a otro;
#   3. al pararse Kael, los dos se paran cerca de él, sin pisarse;
#   4. si Kael aparece en otro sitio (vuelta de un combate), los dos aparecen detrás de él;
#   5. con «grupo»: false en el perfil de calidad (banco GRUPO), no sale nadie.
# No escribe archivos (progreso.gd no guarda durante las pruebas). Termina con quit(1) y «FALLO» si algo no se cumple.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const RUTA := [Vector3(-9, 0, 9), Vector3(-3, 0, 5), Vector3(5.3, 0, -2), Vector3(12.7, 0, -2), Vector3(5.3, 0, -2),
	Vector3(-3, 0, 5)]
const OTRO_SITIO := Vector3(16, 0, -6)
const MAX_DETRAS := 4.0          # metros como mucho de cada uno al de delante mientras andan
const MAX_JUNTOS := 10           # fotogramas como mucho con dos del grupo a menos de 0,4 m
const ESPERA_TRAMO := 600        # fotogramas para cada tramo de la ruta

var frames := 0
var fase := 0
var f_fase := 0
var v                            # la región
var tramo := 0
var max_lya := 0.0
var max_garon := 0.0
var pisa := 0                    # fotogramas en que alguien del grupo pisa una zona prohibida
var flota := 0                   # fotogramas con alguien a más de 0,3 m del suelo, por encima o por debajo
var juntos := 0                  # fotogramas con dos del grupo a menos de 0,4 m (se atraviesan)
var medidos := 0
var fallos: Array = []


func _initialize() -> void:
	var m3 = load("res://modo3d.gd")
	if not m3.activo():
		_fallo("la exploración 3D no está activa (falta «-- 3d»)")
		return
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true})   # sin las escenas de la misión (prueba_ruta_alpha)
	if Engine.has_meta("calidad_extra"):
		Engine.remove_meta("calidad_extra")
	change_scene_to_file(REGION)
	_fase(1)


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	quit(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _grupo() -> Array:
	return v.grupo.nodos() if v.grupo != null else []


# Distancia del nodo al suelo que tiene debajo (o INF si no hay suelo).
func _al_suelo(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.6, 0), p - Vector3(0, 3.0, 0))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	return INF if r.is_empty() else absf(r["position"].y - p.y)


func _comprobar_sitios(cuando: String) -> void:
	var k: Vector3 = v.kael.global_position
	var g := _grupo()
	for i in g.size():
		var p: Vector3 = g[i].global_position
		var delante: Vector3 = k if i == 0 else g[i - 1].global_position
		var d := _plana(p, delante)
		if d > 2.6:
			fallos.append("%s: %s está a %.2f m del de delante" % [cuando, g[i].name, d])
		if v._prohibido(p):
			fallos.append("%s: %s está en una zona prohibida (%s)" % [cuando, g[i].name, p.snapped(Vector3.ONE * 0.1)])
		if _al_suelo(p) > 0.3:
			fallos.append("%s: %s no está sobre el suelo (%s)" % [cuando, g[i].name, p.snapped(Vector3.ONE * 0.1)])
	print("%s: Kael %s · %s" % [cuando, k.snapped(Vector3.ONE * 0.1), ", ".join(g.map(func(n): return "%s %s" % [n.name, n.global_position.snapped(Vector3.ONE * 0.1)]))])


func _medir() -> void:
	var k: Vector3 = v.kael.global_position
	var g := _grupo()
	var todos: Array = [k] + g.map(func(n): return n.global_position)
	medidos += 1
	for i in g.size():
		var p: Vector3 = g[i].global_position
		var d := _plana(p, todos[i])
		if i == 0:
			max_lya = maxf(max_lya, d)
		else:
			max_garon = maxf(max_garon, d)
		if v._prohibido(p):
			pisa += 1
		if _al_suelo(p) > 0.3:
			flota += 1
	for a in todos.size():
		for b in range(a + 1, todos.size()):
			if _plana(todos[a], todos[b]) < 0.4:
				juntos += 1


func _process(_d: float) -> bool:
	frames += 1
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 10:
				v = current_scene
				var g := _grupo()
				var nombres: Array = g.map(func(n): return String(n.name))
				if nombres != ["Lya", "Garon"]:
					_fallo("el grupo no son Lya y Garon: %s" % str(nombres))
					return false
				for n in g:
					if n.get("anim") == null or n.get("skel") == null:
						_fallo("%s no tiene modelo, animaciones o esqueleto" % n.name)
						return false
				_comprobar_sitios("al entrar")
				tramo = 0
				v.destino = RUTA[0]
				_fase(2)
		2:
			v.pasos = 0                                    # siempre dentro de los pasos seguros: sin encuentros
			_medir()
			var meta: Vector3 = RUTA[tramo]
			if v.destino == null or frames - f_fase > ESPERA_TRAMO:
				var lejos := _plana(v.kael.global_position, meta)
				if lejos > 0.8:
					fallos.append("Kael no llegó a %s (se quedó a %.1f m)" % [meta, lejos])
				tramo += 1
				if tramo >= RUTA.size():
					_fase(3)
				else:
					v.destino = RUTA[tramo]
					f_fase = frames
		3:
			if frames - f_fase >= 90:                      # 3 s quieto
				_comprobar_sitios("con Kael parado")
				for m in v.grupo.miembros:
					if m["estado"] != "":
						fallos.append("con Kael parado, %s sigue andando (%s)" % [m["nombre"], m["estado"]])
				var g := _grupo()
				var todos: Array = [v.kael.global_position] + g.map(func(n): return n.global_position)
				for a in todos.size():
					for b in range(a + 1, todos.size()):
						if _plana(todos[a], todos[b]) < 0.6:
							fallos.append("con Kael parado, dos del grupo están a %.2f m" % _plana(todos[a], todos[b]))
				var y: float = v.altura(OTRO_SITIO.x, OTRO_SITIO.z)
				v._colocar_kael(Vector3(OTRO_SITIO.x, y, OTRO_SITIO.z))   # como al volver de un combate
				_fase(4)
		4:
			if frames - f_fase >= 5:
				_comprobar_sitios("tras aparecer Kael en otro sitio")
				Engine.set_meta("calidad_extra", {"grupo": false})
				change_scene_to_file(REGION)
				v = null
				_fase(5)
		5:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 10:
				Engine.remove_meta("calidad_extra")
				if current_scene.grupo != null:
					fallos.append("con «grupo»: false en el perfil, el grupo sigue saliendo")
				return _terminar()
	if frames > 6000:
		_fallo("la prueba no terminó (fase %d)" % fase)
	return false


func _terminar() -> bool:
	print("recorrido: %d fotogramas · Lya-Kael hasta %.2f m · Garon-Lya hasta %.2f m · pisan zona prohibida %d · fuera del suelo %d · juntos %d" % [
		medidos, max_lya, max_garon, pisa, flota, juntos])
	if max_lya > MAX_DETRAS:
		fallos.append("Lya se quedó a %.2f m de Kael (máximo %.1f)" % [max_lya, MAX_DETRAS])
	if max_garon > MAX_DETRAS:
		fallos.append("Garon se quedó a %.2f m de Lya (máximo %.1f)" % [max_garon, MAX_DETRAS])
	if pisa > 0:
		fallos.append("el grupo pisó una zona prohibida en %d fotogramas" % pisa)
	if flota > 0:
		fallos.append("el grupo estuvo fuera del suelo en %d fotogramas" % flota)
	if juntos > MAX_JUNTOS:
		fallos.append("dos del grupo se atravesaron en %d fotogramas (máximo %d)" % [juntos, MAX_JUNTOS])
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	return true
