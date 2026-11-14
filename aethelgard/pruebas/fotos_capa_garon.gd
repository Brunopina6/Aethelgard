extends SceneTree
# La capa de Garon en todas sus poses (encargo del 13/11/2026: «la capa de Garon está mal puesta»). Con ventana:
#   godot --path aethelgard --script res://pruebas/fotos_capa_garon.gd -- salida=<carpeta> [versiones=originales,v2,v3]
#       [capa=rigida|articulada]   (14/11: sin «capa=», la que elija el juego; la rígida es la de siempre)
#
# Un estudio fijo (suelo, luz, tres cámaras que ven el MISMO fotograma: de frente a 3/4, de lado y de espaldas desde
# arriba como en exploración) y el Garon de cada versión con sus métodos de siempre: reposo, andar, correr, Juicio,
# Giro, victoria y derrota, capturados en instantes fijos. Guarda una imagen por instante y una hoja por versión
# (columnas = instantes, filas = cámaras). Además mide, en cada instante, dónde queda la capa respecto al pecho de
# Garon: si se mete en el cuerpo (su parte de arriba por delante de la espalda) o si se gira respecto a los hombros.

const SCRIPTS := {
	"originales": "res://garon_3d.gd",
	"v2": "res://personajes/heroes_v2/garon_v2_3d.gd",
	"v3": "res://personajes/heroes_v3/garon_v3_3d.gd",
}
const TAM := Vector2i(300, 380)
const CAMARAS := [
	{"n": "frente", "pos": Vector3(-2.5, 1.35, 1.7)},     # (Garon mira hacia -X, como en combate)
	{"n": "lado", "pos": Vector3(0.0, 1.2, 3.1)},
	{"n": "espalda", "pos": Vector3(2.7, 2.3, -1.4)},
]
# [acción, fotogramas que espera antes de la foto, nombre de la foto ("" = sin foto)]
const GUION := [
	["reposo", 40, "reposo"],
	["andar", 22, "andar_a"], ["", 9, "andar_b"],
	["correr", 22, "correr_a"], ["", 6, "correr_b"],
	["girar", 8, "media_vuelta_a"], ["", 8, "media_vuelta_b"],     # (14/11) media vuelta corriendo en el sitio
	["volver", 10, "parar"], ["", 20, ""],                          # para y vuelve a mirar como antes
	["reposo", 30, ""],
	["juicio", 14, "juicio_salta"], ["", 12, "juicio_arriba"], ["", 8, "juicio_impacto"], ["", 18, "juicio_fin"],
	["reposo", 40, ""],
	["giro", 10, "giro_a"], ["", 9, "giro_b"], ["", 9, "giro_c"], ["", 9, "giro_d"], ["", 9, "giro_e"],
	["reposo", 40, ""],
	["cubrir", 25, "defensa"], ["", 15, "defensa_b"], ["fin_cubrir", 25, ""],   # (14/11) la Guardia
	["reposo", 20, ""],
	["victoria", 30, "victoria"], ["", 30, "victoria_b"],
	["morir", 25, "derrota_a"], ["", 50, "derrota"],
]

var salida := ""
var versiones: PackedStringArray = ["originales", "v2", "v3"]
var vi := -1
var paso := 0
var espera := 0
var g: Node3D
var vistas: Array = []
var fotos: Array = []                 # [nombre, [Image × 3]]
var medidas: Array = []
var estudio: Node3D
var capa_modo := ""                   # "rigida", "articulada" o "" (la del juego)
var giro_restante := 0.0
var rapidez := 0.0                    # m/s hacia donde mira (andar y correr se desplazan: la tela reacciona a la marcha)
var camaras: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("versiones="):
			versiones = a.substr(10).split(",")
		elif a.begins_with("capa="):
			capa_modo = a.substr(5)
	if capa_modo != "":
		Engine.set_meta("capa_garon", capa_modo)
	if salida == "":
		salida = OS.get_user_data_dir().path_join("capa_garon")
	DirAccess.make_dir_recursive_absolute(salida)
	_montar_estudio()
	_siguiente_version()


func _montar_estudio() -> void:
	estudio = Node3D.new()
	root.add_child(estudio)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.68, 0.74)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.environment.ambient_light_energy = 0.6
	estudio.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 35, 0)
	sol.light_energy = 1.2
	estudio.add_child(sol)
	var suelo := MeshInstance3D.new()
	suelo.mesh = PlaneMesh.new()
	suelo.mesh.size = Vector2(60, 60)   # (14/11: Garon ahora anda y corre de verdad)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.45, 0.4)
	suelo.material_override = m
	estudio.add_child(suelo)
	for c in CAMARAS:
		var vp := SubViewport.new()
		vp.size = TAM
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.msaa_3d = Viewport.MSAA_4X
		root.add_child(vp)
		var cam := Camera3D.new()
		cam.fov = 38.0
		vp.add_child(cam)
		cam.look_at_from_position(c["pos"], Vector3(0, 0.95, 0))
		vistas.append(vp)
		camaras.append(cam)


func _siguiente_version() -> void:
	if g != null:
		_hoja()
		g.queue_free()
		g = null
	vi += 1
	if vi >= versiones.size():
		var f := FileAccess.open(salida.path_join("medidas.txt"), FileAccess.WRITE)
		for l in medidas:
			f.store_line(l)
			print(l)
		f.close()
		quit(0)
		return
	var v: String = versiones[vi]
	Engine.set_meta("heroes_version", v)
	Engine.set_meta("heroes_v2", v != "originales")
	Engine.set_meta("heroes_v3", v == "v3")
	if not ResourceLoader.exists(SCRIPTS[v]):
		print("SIN %s: falta %s" % [v, SCRIPTS[v]])
		_siguiente_version()
		return
	g = Node3D.new()
	g.set_script(load(SCRIPTS[v]))
	root.add_child(g)
	rapidez = 0.0
	giro_restante = 0.0
	paso = 0
	espera = 20
	fotos = []


func _process(_d: float) -> bool:
	if g == null:
		return false
	if giro_restante != 0.0:
		var p_giro := signf(giro_restante) * minf(absf(giro_restante), PI / 15.0)
		g.rotate_y(p_giro)
		giro_restante -= p_giro
	if rapidez > 0.0:
		var sk: Skeleton3D = g.get("skel")
		var adelante: Vector3 = sk.global_transform.basis * g.get("gestos").adelante
		adelante.y = 0.0
		g.global_position += adelante.normalized() * rapidez * _d
	var centro := Vector3(g.global_position.x, 0.0, g.global_position.z)   # las cámaras le siguen
	for i in camaras.size():
		camaras[i].look_at_from_position(CAMARAS[i]["pos"] + centro, Vector3(0, 0.95, 0) + centro)
	if espera > 0:
		espera -= 1
		return false
	if paso >= GUION.size():
		_siguiente_version()
		return false
	var p: Array = GUION[paso]
	if espera == 0 and p.size() > 3:
		pass
	if not g.has_meta("_hecho_%d" % paso):
		g.set_meta("_hecho_%d" % paso, true)
		_accion(p[0])
		espera = p[1]
		return false
	if p[2] != "":
		_foto(p[2])
	paso += 1
	return false


func _accion(a: String) -> void:
	if a != "":
		rapidez = 0.0
	match a:
		"reposo":
			if g.has_method("revivir") and g.get("_muerta"):
				g.revivir()
			g.reposo()
		"andar":
			g.andar()
			rapidez = float(g.get("vel_andar"))
		"correr":
			g.correr()
			rapidez = float(g.get("vel_correr"))
		"girar":
			g.correr()
			rapidez = float(g.get("vel_correr"))
			giro_restante = PI
		"volver":
			g.reposo()
			giro_restante = -PI
		"cubrir":
			g.cubrir(g.global_transform.basis * Vector3(-1, 0, 0))
		"fin_cubrir":
			g.fin_cubrir()
		"juicio":
			g.atacar_juicio(func(): pass)
		"giro":
			g.atacar_giro(func(): pass)
		"victoria":
			g.victoria()
		"morir":
			g.morir()


func _foto(n: String) -> void:
	var imgs: Array = []
	for vp in vistas:
		imgs.append(vp.get_texture().get_image())
	fotos.append([n, imgs])
	var v: String = versiones[vi]
	for i in imgs.size():
		imgs[i].save_png(salida.path_join("%s_%s_%s.png" % [v, n, CAMARAS[i]["n"]]))
	_medir(n)


# Dónde queda la capa respecto al pecho: el borde de arriba de la capa debe quedar DETRÁS de la espalda (en el sentido
# de «adelante» del pecho de ahora) y su eje lateral, paralelo a los hombros.
func _medir(n: String) -> void:
	var capa: Node3D = g.get("capa")
	var sk: Skeleton3D = g.get("skel")
	if capa == null or sk == null:
		medidas.append("%s %s: sin capa" % [versiones[vi], n])
		return
	var gs = g.get("gestos")
	var i_bi: int = gs.idx["brazo_i"]
	var i_bd: int = gs.idx["brazo_d"]
	var i_p: int = gs.idx["pecho"]
	var i_c: int = gs.idx["cuello"]
	var tr := sk.global_transform
	var bi := tr * sk.get_bone_global_pose(i_bi).origin
	var bd := tr * sk.get_bone_global_pose(i_bd).origin
	var pecho := tr * sk.get_bone_global_pose(i_p).origin
	var cuello := tr * sk.get_bone_global_pose(i_c).origin
	var arriba := (cuello - pecho).normalized()
	var hombros := (bd - bi).normalized()
	var adelante := arriba.cross(hombros).normalized()
	var ct := capa.global_transform
	var lado_capa := ct.basis.x.normalized()
	var giro := rad_to_deg(acos(clampf(absf(lado_capa.dot(hombros)), 0.0, 1.0)))
	var hacia := (ct.origin - pecho).dot(adelante)          # < 0: la capa sale por detrás del pecho
	var atras_capa := ct.basis.z.normalized()               # +Z de la capa = su «adelante» (hacia el cuerpo)
	var al_reves := atras_capa.dot(adelante) < 0.0
	var bajo := INF                                          # el punto más bajo de la tela (el suelo está en y = 0)
	var ancho := 0.0
	for mi in capa.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = mi.mesh
		var xs: Array = []
		var puntos: Array = []
		if capa.has_method("puntos_mundo"):         # la articulada: la tela como se ve (con sus huesos)
			puntos = Array(capa.puntos_mundo())
		else:
			for v in m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				puntos.append(mi.global_transform * v)
		for w in puntos:
			bajo = minf(bajo, w.y)
			xs.append(w.dot(lado_capa))
		if not xs.is_empty():
			ancho = maxf(ancho, xs.max() - xs.min())
	medidas.append("%s %-15s giro respecto a los hombros %5.1f°  enganche %+.3f m (negativo = detrás)  %s  borde más bajo %+.3f m  ancho %.2f m (hombros %.2f m)" % [
		versiones[vi], n, giro, hacia, "AL REVÉS" if al_reves else "bien orientada", bajo, ancho, bi.distance_to(bd)])


func _hoja() -> void:
	if fotos.is_empty():
		return
	var cols := fotos.size()
	var hoja := Image.create(TAM.x * cols, TAM.y * CAMARAS.size(), false, Image.FORMAT_RGBA8)
	for c in cols:
		for r in CAMARAS.size():
			var im: Image = fotos[c][1][r]
			im.convert(Image.FORMAT_RGBA8)
			hoja.blit_rect(im, Rect2i(Vector2i.ZERO, TAM), Vector2i(c * TAM.x, r * TAM.y))
	hoja.save_png(salida.path_join("hoja_%s.png" % versiones[vi]))
	var nombres := ", ".join(fotos.map(func(x): return x[0]))
	medidas.append("HOJA %s: columnas %s; filas %s" % [versiones[vi], nombres, ", ".join(CAMARAS.map(func(x): return x["n"]))])
