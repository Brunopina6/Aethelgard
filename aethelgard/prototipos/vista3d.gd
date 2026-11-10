extends Node3D
# PROTOTIPO AISLADO (Fase 1B): cámara de exploración 3D elevada e inclinada, como la imagen de referencia.
# No lo usa ninguna escena del juego ni entra en el APK (exclude_filter «prototipos/*»).
# Se abre en el editor (prototipos/vista3d.tscn, F6) o con:
#   Godot --path aethelgard res://prototipos/vista3d.tscn
#
# Controles:
#   Tocar / clic / arrastrar: Kael camina hacia ese punto.   Flechas o WASD: caminar (PC).
#   Rueda o pellizco: acercar / alejar.   Q / E: más o menos inclinación.
#   T: compara perspectiva (propuesta) con ortográfica.   R: vuelve a los valores de partida.
#
# El escenario es un «blockout»: formas simples para medir encuadre, escala y oclusión, no el arte final.

# --- cámara (valores de partida para comparar en el móvil) ---
@export var inclinacion := 45.0        # grados hacia abajo
@export var distancia := 20.0          # metros de la cámara a Kael
@export var campo_vision := 38.0       # FOV vertical en perspectiva
@export var suavizado := 6.0           # cuanto más alto, más pegada sigue a Kael
@export var adelanto := 1.5            # mira un poco por delante de hacia donde camina
const DIST_MIN := 9.0
const DIST_MAX := 34.0
const INCL_MIN := 30.0
const INCL_MAX := 65.0
const GIRO := 0.0                      # la cámara nunca gira: el mundo siempre se lee igual
const VELOCIDAD := 4.2                 # m/s andando
const CORRER_DESDE := 3.0              # si el destino está más lejos, corre
# Con el mando, el stick poco inclinado anda más despacio, como en el mapa y en las zonas 2D (mapa.gd, zona.gd): la
# inclinación que pasa de la zona muerta va del 30 % (1,3 m/s, el ritmo natural del clip de andar) al 100 % (4,2 m/s,
# como siempre). Teclado y toques no cambian: van siempre al 100 % (T-084, tanda 2).
const STICK_MIN := 0.3

var cam: Camera3D
var kael: Node3D
var foco := Vector3.ZERO
var destino = null                     # Vector3 o null
var direccion_teclas := Vector2.ZERO
var info: Label
var tapados: Array = []                # MeshInstance3D que ahora están medio transparentes
var dedos := {}
var dist_pellizco := 0.0
var movimiento := ""


func _ready() -> void:
	_crear_ambiente()
	_crear_escenario()
	kael = load("res://kael_3d.gd").new()
	kael.ruta_modelo = "res://kael.fbx"
	add_child(kael)
	if kael.has_method("activar_esperas"):
		kael.activar_esperas()                     # quieto un rato, hace una de sus esperas (esperas_3d.gd)
	cam = Camera3D.new()
	cam.fov = campo_vision
	cam.far = 400.0
	add_child(cam)
	cam.current = true
	foco = kael.global_position
	_colocar_camara(1.0)
	var capa := CanvasLayer.new()
	add_child(capa)
	info = Label.new()
	info.position = Vector2(16, 12)
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	info.add_theme_constant_override("outline_size", 6)
	capa.add_child(info)
	_crear_panel_rnd(capa)
	seguro = kael.global_position
	_aplicar_perfil()
	_preparar_regulador()
	_preparar_sombreados.call_deferred()            # cuando la escena hija ya ha puesto todo lo suyo
	if Engine.has_meta("banco_proto"):
		_seguir_banco.call_deferred()


# Perfil de calidad (prototipos/calidad_proto.gd): resolución del 3D (la interfaz va siempre a
# resolución completa y nítida), MSAA y tope de FPS. El resto lo aplica cada escena al construirse.
var perfil_fps := 30


func _aplicar_perfil() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	var pf: Dictionary = cal.datos()
	var vp := get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = pf["escala_3d"]
	vp.msaa_3d = Viewport.MSAA_2X if pf["msaa"] == 2 else Viewport.MSAA_DISABLED
	perfil_fps = pf["fps"]


func _cambiar_perfil() -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	Engine.set_meta("calidad_proto", cal.siguiente())
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- calidad adaptable (encargo del 09/11)
# Calibración al entrar por primera vez con un perfil del sistema y ajuste dinámico mientras se juega
# (prototipos/regulador_calidad.gd decide; calidad_auto.gd guarda en user://ajustes.cfg). Se le pasa el tiempo REAL
# de cada fotograma (_medir), salvo en pausa o en modo ahorro (menú o diálogo esperando: Godot no redibuja y el
# tiempo entre fotogramas no dice nada de la GPU). Sin ventana (pruebas), con un banco o con CAL no hace nada.
const Regulador := preload("res://prototipos/regulador_calidad.gd")
var regulador: Regulador = null
var _perfil_vivo: Dictionary = {}          # valores con los que está la escena ahora (para los recortes en vivo)
var _saltar_muestra := true


func _preparar_regulador() -> void:
	if Engine.has_meta("banco_proto") or Engine.has_meta("calidad_proto"):
		return
	if DisplayServer.get_name() == "headless" and not Engine.get_meta("calidad_regulador_forzado", false):
		return
	var cal = load("res://prototipos/calidad_proto.gd")
	var auto = load("res://prototipos/calidad_auto.gd")
	var nombre: String = cal.actual()
	var e: Dictionary = auto.estado()
	var del_sistema: bool = not cal.fijado_a_mano()
	_perfil_vivo = cal.datos()
	# Se defienden 30 FPS; 60 solo cuando los puso el sistema (alto, a medir o medidos), nunca si los pidió el jugador.
	var objetivo := 60 if del_sistema and e["fps"] == 0 and perfil_fps == 60 else 30
	regulador = Regulador.new(nombre, perfil_fps, objetivo, del_sistema, del_sistema and not e["calibrado"],
		auto.nivel_de(nombre, e), auto.escalones_utiles(nombre).size())


func _dar_muestra(ms: float) -> void:
	var quieto := OS.low_processor_usage_mode or get_tree().paused
	var vale := not quieto and not _saltar_muestra
	_saltar_muestra = quieto                       # el primer fotograma tras el modo ahorro tampoco cuenta
	if vale:
		_atender_regulador(regulador.muestra(ms))


func _atender_regulador(acc: Dictionary) -> void:
	if acc.is_empty():
		return
	var auto = load("res://prototipos/calidad_auto.gd")
	var m: Dictionary = acc.get("medida", {})
	var medida := "p95 %.1f ms, mediana %.1f ms, %d fotogramas, presupuesto %.1f ms" % [m.get("p95", 0.0),
		m.get("mediana", 0.0), m.get("n", 0), regulador.presupuesto_ms()]
	var donde := scene_file_path.get_file()
	match String(acc["accion"]):
		"calibrado":
			auto.guardar({"calibrado": true, "fps_auto": acc["fps"]})
			auto.registrar("calibrado en %s: %s a %d FPS%s (%s)" % [donde, acc["perfil"], acc["fps"],
				", el más bajo, sin llegar del todo" if acc.get("justo", false) else "", medida])
		"fps":
			perfil_fps = int(acc["fps"])
			auto.guardar({"fps_auto": perfil_fps})
			auto.registrar("en %s, %s no aguanta 60 FPS: se queda en 30 (%s)" % [donde, regulador.perfil, medida])
		"perfil":
			auto.guardar({"perfil_auto": acc["perfil"], "perfil": acc["perfil"], "calibrado": false})
			auto.registrar("en %s, %s no llega: %s desde la próxima carga (%s)" % [donde, regulador.perfil,
				acc["perfil"], medida])
		"nivel":
			auto.guardar({"nivel": acc["nivel"], "nivel_de": regulador.perfil})
			_aplicar_recortes_en_vivo()
			auto.registrar("en %s, %s escalón %d%s (%s)" % [donde, "sube al" if acc.get("subir", false) else "baja al",
				acc["nivel"], ": " + auto.nombre_escalon(regulador.perfil, acc["nivel"]) if acc["nivel"] > 0 else "", medida])
		"aviso":
			auto.guardar({"aviso": regulador.perfil})
			auto.registrar("en %s, el perfil %s elegido a mano no llega a %d FPS (%s)" % [donde, regulador.perfil,
				regulador.objetivo, medida])
		"no_llega":
			auto.guardar({"no_llega": true})
			auto.registrar("en %s, este aparato no llega a 30 FPS ni en el perfil bajo con todos los recortes (%s; %s)" % [
				donde, medida, auto.resumen_aparato()])


# Lo que se puede cambiar sin recargar y sin que se note de golpe: la resolución del 3D, la distancia y los tramos de
# las sombras que ya hay (encenderlas o apagarlas sí se notaría: eso, en la próxima carga) y la hierba de
# sendero_puente.gd (sus trozos se reconocen por la distancia de dibujo del perfil: menos matas y más cerca). El resto
# de cambios del escalón (flores, espuma) llegan con la próxima carga, que ya lee los recortes (calidad_proto.datos).
func _aplicar_recortes_en_vivo() -> void:
	var nuevo: Dictionary = load("res://prototipos/calidad_proto.gd").datos()
	var vp := get_viewport()
	if absf(vp.scaling_3d_scale - float(nuevo["escala_3d"])) > 0.001:
		vp.scaling_3d_scale = nuevo["escala_3d"]
	var ds0 := float(_perfil_vivo.get("dist_sombras", 0.0))
	var ds1 := float(nuevo.get("dist_sombras", ds0))
	for luz in find_children("*", "DirectionalLight3D", true, false):
		var l := luz as DirectionalLight3D
		if not l.shadow_enabled:
			continue
		if ds0 > 0.0 and ds1 != ds0:
			l.directional_shadow_max_distance *= ds1 / ds0
		var tramos := int(nuevo.get("sombra_tramos", 4))
		if tramos == 1:
			l.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		elif tramos == 2 and l.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
			l.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		elif tramos >= 2 and int(_perfil_vivo.get("sombra_tramos", 4)) == 1:    # al subir de escalón, como era
			l.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if tramos == 2 \
				else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	var dh0 := float(_perfil_vivo.get("dist_hierba", 0.0))
	var dh1 := float(nuevo.get("dist_hierba", dh0))
	var h0 := int(_perfil_vivo.get("hierba", 0))
	var h1 := int(nuevo.get("hierba", h0))
	if dh0 > 0.0 and (dh1 != dh0 or h1 != h0):
		for n in find_children("*", "MultiMeshInstance3D", true, false):
			var mmi := n as MultiMeshInstance3D
			if mmi.multimesh == null or absf(mmi.visibility_range_end - dh0) > 0.01:
				continue
			mmi.visibility_range_end = dh1
			# la escena se construyó con «hierba» del momento de la carga; la proporción, respecto a esa
			var con := int(_perfil_vivo.get("hierba_construida", h0))
			mmi.multimesh.visible_instance_count = -1 if h1 >= con else ceili(mmi.multimesh.instance_count * float(h1) / con)
	nuevo["hierba_construida"] = int(_perfil_vivo.get("hierba_construida", h0))
	_perfil_vivo = nuevo


# ---------------------------------------------------------------- mundo de prueba

func _crear_ambiente() -> void:
	var env := Environment.new()
	var cielo := Sky.new()
	var mat_cielo := ProceduralSkyMaterial.new()
	mat_cielo.sky_top_color = Color(0.32, 0.55, 0.9)
	mat_cielo.sky_horizon_color = Color(0.78, 0.86, 0.95)
	mat_cielo.ground_horizon_color = Color(0.78, 0.86, 0.95)
	mat_cielo.ground_bottom_color = Color(0.55, 0.65, 0.8)
	cielo.sky_material = mat_cielo
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR   # relleno azul suave (biblia de arte)
	env.ambient_light_color = Color(0.62, 0.7, 0.9)
	env.ambient_light_energy = 0.3
	env.fog_enabled = true                 # bruma lejana: da profundidad a lo que está lejos
	env.fog_light_color = Color(0.75, 0.84, 0.95)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()    # biblia de arte: luz dorada desde arriba a la izquierda
	sol.rotation_degrees = Vector3(-48, -35, 0)
	sol.light_color = Color(1.0, 0.92, 0.78)
	sol.light_energy = 0.95
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 60.0
	add_child(sol)


func _mat(c: Color, rugosidad := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	return m


func _caja(pos: Vector3, tam: Vector3, color: Color, ocluye := true) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	add_child(cuerpo)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = _mat(color)
	cuerpo.add_child(mi)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = tam
	col.shape = bs
	cuerpo.add_child(col)
	if ocluye:
		mi.add_to_group("ocluye")


func _arbol(pos: Vector3, alto := 5.0) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	add_child(cuerpo)
	var tronco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.25
	cm.bottom_radius = 0.4
	cm.height = alto * 0.5
	tronco.mesh = cm
	tronco.position.y = alto * 0.25
	tronco.material_override = _mat(Color(0.42, 0.3, 0.2))
	cuerpo.add_child(tronco)
	var copa := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = alto * 0.38
	sm.height = alto * 0.6
	copa.mesh = sm
	copa.position.y = alto * 0.72
	copa.material_override = _mat(Color(0.33, 0.6, 0.25))
	cuerpo.add_child(copa)
	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = alto * 0.38
	col.shape = cs
	col.position.y = alto * 0.72
	cuerpo.add_child(col)
	for mi in [tronco, copa]:
		mi.add_to_group("ocluye")


func _crear_escenario() -> void:
	# suelo de hierba y camino de losas en diagonal (como la referencia)
	_caja(Vector3(0, -0.5, 0), Vector3(80, 1, 80), Color(0.42, 0.62, 0.3), false)
	for i in 14:
		var p := Vector3(-14 + i * 2.2, 0.02, 10 - i * 1.6)
		_caja(p, Vector3(2.6, 0.06, 2.2), Color(0.7, 0.66, 0.58), false)
	# acantilado a la derecha con río y cascada abajo
	_caja(Vector3(18, -3, 0), Vector3(14, 6, 60), Color(0.5, 0.48, 0.46))
	var agua := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 60)
	agua.mesh = pm
	agua.position = Vector3(30, -5.5, 0)
	if ResourceLoader.exists("res://shaders/water.gdshader"):
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/water.gdshader")
		agua.material_override = sm
	else:
		agua.material_override = _mat(Color(0.2, 0.55, 0.75), 0.1)
	add_child(agua)
	# ruinas (arcos) y un puesto, para probar que tapan a Kael
	for x in [-6.0, -2.0]:
		_caja(Vector3(x, 2.5, 3.0), Vector3(1.2, 5, 1.2), Color(0.62, 0.6, 0.55))
	_caja(Vector3(-4, 5.3, 3.0), Vector3(5.2, 0.8, 1.2), Color(0.62, 0.6, 0.55))
	_caja(Vector3(-9, 1.2, -4), Vector3(3, 2.4, 2), Color(0.6, 0.35, 0.3))
	# terraza alta con escalones (cambio de altura)
	for i in 8:                              # 8 escalones de 0,4 m hasta la terraza (3,2 m)
		var alto := 0.4 * (i + 1)
		_caja(Vector3(-2, alto * 0.5, -6.5 - i * 0.7), Vector3(4, alto, 0.7), Color(0.6, 0.58, 0.54), false)
	_caja(Vector3(-2, 1.6, -15.6), Vector3(14, 3.2, 8), Color(0.55, 0.53, 0.5), false)
	# árboles
	for p in [Vector3(-12, 0, 6), Vector3(-15, 0, -2), Vector3(4, 0, 6), Vector3(8, 0, -6), Vector3(-7, 0, 9), Vector3(2, 0, -12)]:
		_arbol(p, randf_range(4.5, 6.5))
	# lejanía: la isla flotante (render ya existente de la Arboleda Mítica) entre la bruma
	if ResourceLoader.exists("res://isla/isla_color_0_0.png"):
		var isla := Sprite3D.new()
		isla.texture = load("res://isla/isla_color_0_0.png")
		isla.pixel_size = 0.03
		isla.position = Vector3(-30, 40, -120)
		isla.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		isla.shaded = false
		isla.modulate = Color(0.85, 0.9, 1.0, 0.9)
		add_child(isla)


# ---------------------------------------------------------------- cámara

func _colocar_camara(peso: float) -> void:
	var meta := kael.global_position + _hacia() * adelanto
	foco = foco.lerp(meta, peso)
	var ang := deg_to_rad(inclinacion)
	var atras := Vector3(sin(deg_to_rad(GIRO)), 0, cos(deg_to_rad(GIRO)))
	var ojo := foco + Vector3(0, 0.9, 0)
	cam.global_position = ojo + atras * cos(ang) * distancia + Vector3.UP * sin(ang) * distancia
	cam.look_at(ojo, Vector3.UP)
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		cam.size = 2.0 * distancia * tan(deg_to_rad(campo_vision) * 0.5)   # mismo encuadre a la altura de Kael
	else:
		cam.fov = campo_vision


func _hacia() -> Vector3:
	if movimiento == "":
		return Vector3.ZERO
	var d: Vector3 = -kael.get("pivote").global_transform.basis.z if kael.get("pivote") != null else Vector3.ZERO
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.ZERO


# Lo que se pone entre la cámara y Kael se vuelve medio transparente (y vuelve al apartarse).
func _oclusion() -> void:
	var espacio := get_world_3d().direct_space_state
	var ahora: Array = []
	var desde := cam.global_position
	var hasta := kael.global_position + Vector3(0, 1.0, 0)
	var excluir: Array[RID] = []
	for i in 6:
		var q := PhysicsRayQueryParameters3D.create(desde, hasta)
		q.exclude = excluir
		var r := espacio.intersect_ray(q)
		if r.is_empty():
			break
		excluir.append(r["rid"])
		for mi in r["collider"].find_children("*", "MeshInstance3D", true, false):
			if mi.is_in_group("ocluye"):
				ahora.append(mi)
	# (en GL Compatibility «transparency» del nodo no basta: se cambia el material, que es propio de cada pieza)
	for mi in ahora:
		if not tapados.has(mi):
			_transparente(mi, true)
	for mi in tapados:
		if is_instance_valid(mi) and not ahora.has(mi):
			_transparente(mi, false)
	tapados = ahora


func _transparente(mi: MeshInstance3D, si: bool) -> void:
	var t := _material_transparente(mi)
	if t == null:
		return
	mi.material_override = t if si else mi.get_meta("mat_opaco")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


# Lo que tapa a Kael se dibuja con una copia medio transparente de su material, hecha una vez y guardada mientras dure
# la escena. Antes se cambiaba la transparencia del propio material, y Godot tenía que preparar su sombreado de nuevo (y
# lo soltaba al volver a opaco si nadie más lo usaba). Con las dos versiones vivas, cambiar es solo cambiar de material
# (medido en el PC: pruebas/medir_primeras_veces.gd y sonda_oclusion_repetida.gd, 2026-11-08).
var _trans_de := {}                    # material opaco -> su copia medio transparente


func _material_transparente(mi: MeshInstance3D) -> StandardMaterial3D:
	if not mi.has_meta("mat_opaco"):
		if not mi.material_override is StandardMaterial3D:
			return null
		mi.set_meta("mat_opaco", mi.material_override)   # el suyo, sin tocar (p. ej. alfa recortado en las tarjetas)
	var m: StandardMaterial3D = mi.get_meta("mat_opaco")
	if not _trans_de.has(m):
		var t := m.duplicate() as StandardMaterial3D
		t.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		t.albedo_color.a = 0.3
		_trans_de[m] = t
	return _trans_de[m]


# Al entrar, con la pantalla aún en negro (Recursos.cambiar_escena), se dibuja dos fotogramas, en miniatura delante de
# la cámara, una copia de cada cosa distinta de la escena (cada malla con sus materiales, la vegetación, las partículas)
# y las copias transparentes de lo que puede tapar a Kael. Godot compila (o lee de su caché) el sombreado de cada
# material la primera vez que lo dibuja, y al salir de la escena lo suelta: sin esto, cada cosa que aparecía en la vista
# por primera vez al andar daba un tirón (en el PC, hasta 42 ms la primera vez tras instalar y hasta unos 19 ms después;
# pruebas/medir_primeras_veces.gd, 2026-11-08). A cambio, la entrada en negro tarda algo más (unos 0,1-0,2 s en el PC).
func _preparar_sombreados() -> void:
	if not is_inside_tree() or cam == null:
		return
	var copias: Array = []
	var hechas := {}
	for n in get_tree().get_nodes_in_group("ocluye"):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or not is_ancestor_of(mi):
			continue
		var t := _material_transparente(mi)
		if t != null and not hechas.has(t):
			hechas[t] = true
			var c := MeshInstance3D.new()
			c.mesh = mi.mesh
			c.material_override = t
			copias.append(c)
	for g in find_children("*", "GeometryInstance3D", true, false):
		var clave := _clave_dibujo(g)
		if clave != "" and not hechas.has(clave):
			hechas[clave] = true
			copias.append(_copia_dibujo(g))
	if copias.is_empty():
		return
	var vitrina := Node3D.new()
	cam.add_child(vitrina)
	vitrina.position = Vector3(0, 0, -1.0)
	for i in copias.size():
		var c: GeometryInstance3D = copias[i]
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var aabb: AABB = c.get_aabb() if not c is CPUParticles3D else AABB(Vector3.ZERO, Vector3.ONE)
		var s := 0.01 / maxf(aabb.get_longest_axis_size(), 0.01)          # un centímetro
		c.scale = Vector3.ONE * s
		c.position = Vector3(0.012 * (i % 12) - 0.07, 0.012 * (i / 12) - 0.05, 0) - aabb.get_center() * s
		vitrina.add_child(c)
	for i in 2:                                       # dos fotogramas dibujándolas, y fuera
		await get_tree().process_frame
		if not is_instance_valid(vitrina):
			return
	vitrina.queue_free()


# Qué hace falta para dibujar algo como en la escena (los mismos materiales y el mismo tipo de dibujo); "" si no se
# copia. Los personajes con esqueleto no: ya se ven al entrar.
func _clave_dibujo(g: GeometryInstance3D) -> String:
	if not is_ancestor_of(g):
		return ""
	var mats: Array = [g.material_override, g.material_overlay]
	var tipo := ""
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.skin != null or mi.get_parent() is Skeleton3D:
			return ""
		for i in mi.mesh.get_surface_count():
			mats.append(mi.get_active_material(i))
		tipo = "malla"
	elif g is MultiMeshInstance3D:
		var mm := (g as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null:
			return ""
		for i in mm.mesh.get_surface_count():
			mats.append(mm.mesh.surface_get_material(i))
		tipo = "multi %d %s %s" % [mm.transform_format, mm.use_colors, mm.use_custom_data]
	elif g is CPUParticles3D:
		var cp := g as CPUParticles3D
		if cp.mesh == null:
			return ""
		for i in cp.mesh.get_surface_count():
			mats.append(cp.mesh.surface_get_material(i))
		tipo = "particulas"
	else:
		return ""
	var ids: Array = mats.map(func(m): return str(m.get_instance_id()) if m != null else "-")
	return tipo + " " + ",".join(ids)


func _copia_dibujo(g: GeometryInstance3D) -> GeometryInstance3D:
	var c: GeometryInstance3D
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		c = MeshInstance3D.new()
		c.mesh = mi.mesh
		for i in mi.mesh.get_surface_count():
			c.set_surface_override_material(i, mi.get_surface_override_material(i))
	elif g is MultiMeshInstance3D:
		c = MultiMeshInstance3D.new()
		c.multimesh = (g as MultiMeshInstance3D).multimesh         # la misma: todas sus copias, en un centímetro
	else:
		c = g.duplicate(0) as GeometryInstance3D                   # partículas
	c.material_override = g.material_override
	c.material_overlay = g.material_overlay
	return c


# ---------------------------------------------------------------- moverse

func _process(delta: float) -> void:
	direccion_teclas = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): direccion_teclas.x = -1
	if Input.is_key_pressed(KEY_D): direccion_teclas.x = 1
	if Input.is_key_pressed(KEY_W): direccion_teclas.y = -1
	if Input.is_key_pressed(KEY_S): direccion_teclas.y = 1
	var paso := Vector3.ZERO
	var corre := false
	var fuerza := 1.0
	if direccion_teclas.length() > 0.1:
		destino = null
		paso = Vector3(direccion_teclas.x, 0, direccion_teclas.y).normalized()
		fuerza = clampf(direccion_teclas.length(), STICK_MIN, 1.0)
	elif destino != null:
		var falta: Vector3 = destino - kael.global_position
		falta.y = 0.0
		if falta.length() < 0.15:
			destino = null
		else:
			corre = falta.length() > CORRER_DESDE
			paso = falta.normalized()
	var andado := 0.0
	if paso != Vector3.ZERO:
		# el avance del fotograma se hace en tramos cortos: igual a 20 que a 60 FPS
		var total := VELOCIDAD * (1.8 if corre else 1.0) * fuerza * delta
		var tramos := maxi(1, ceili(total / TRAMO_MAX))
		var avanzo := false
		for t in tramos:
			var siguiente: Vector3 = kael.global_position + paso * (total / tramos)
			var y := _altura_suelo(siguiente, kael.global_position.y)
			if is_nan(y):                                   # pared, pendiente, agua o borde: no pasa
				break
			kael.global_position = Vector3(siguiente.x, y, siguiente.z)
			andado += total / tramos
			avanzo = true
		if not avanzo:
			destino = null
			paso = Vector3.ZERO
	_vigilar_atasco(delta)
	if paso != Vector3.ZERO:
		kael.mirar(paso, 0.12)
		var nuevo := "correr" if corre else "andar"
		# El clip y su ritmo salen de la velocidad real (maga_3d.gd, marcha): a 4,2 m/s corre sin que los pies patinen
		# (antes andaba con un clip de 1,2 m/s). Sin marcha() (otro modelo), como antes: andar o correr según el modo.
		if kael.has_method("marcha"):
			if kael.marcha(andado / maxf(delta, 0.0001)) == "" and kael.marcha_actual() != "":
				kael.parar_marcha()
		elif movimiento != nuevo:
			kael.call(nuevo)
		movimiento = nuevo
	elif movimiento != "":
		movimiento = ""
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()                         # sin un paso de más al pararse (maga_3d.gd)
		else:
			kael.reposo()
	var zoom := Input.get_axis("camara_acercar", "camara_alejar") if InputMap.has_action("camara_acercar") else 0.0
	if zoom != 0.0:                                     # + / - o el stick derecho (la rueda y el pellizco, como siempre)
		distancia = clampf(distancia + zoom * 12.0 * delta, DIST_MIN, DIST_MAX)
	_colocar_camara(1.0 - exp(-suavizado * delta))
	_oclusion()
	if _banco.is_empty() and Engine.max_fps != perfil_fps:
		Engine.max_fps = perfil_fps                     # el del perfil (Recursos pone 30 al cambiar de escena)
	_medir(delta)
	if not _banco.is_empty():
		return                                          # el banco escribe su estado en «info»
	info.text ="Prototipo de cámara · %s · inclinación %d° · distancia %.0f m · %d FPS\nToca para andar · rueda/pellizco: zoom · Q/E: inclinación · T: perspectiva/orto · R: reiniciar" % [
		"perspectiva" if cam.projection == Camera3D.PROJECTION_PERSPECTIVE else "ortográfica",
		inclinacion, distancia, Engine.get_frames_per_second()]


# ---------------------------------------------------------------- recorrido seguro (Skill aet-fisica-recorrido)
# Reglas iguales para subir y para bajar (así no hay trampas de un solo sentido):
#   - escalón máximo SUBE_MAX hacia arriba y hacia abajo;
#   - pendiente máxima PENDIENTE_MAX (con la normal del suelo);
#   - nada a la altura de las rodillas delante (pared, columna, tronco);
#   - las zonas prohibidas de cada escena (_prohibido: agua, barrancos, bordes) no se pisan.
# Además: el destino tocado se acerca al último punto andable, y si Kael acaba en un sitio prohibido
# vuelve al último punto seguro. El paso de cada fotograma se divide en tramos de TRAMO_MAX.
const SUBE_MAX := 0.5
const PENDIENTE_MAX := 40.0                 # grados
const TRAMO_MAX := 0.15                     # metros
var seguro := Vector3.ZERO                  # último sitio andable donde estuvo Kael
var _t_seguro := 0.0
var _atasco_t := 0.0
var _atasco_dist := INF


# Las escenas dicen qué zonas no se pisan (agua, barranco, fuera del mapa). Aquí, ninguna.
func _prohibido(_p: Vector3) -> bool:
	return false


# Altura de lo que se pisa en p viniendo desde y_actual, o NAN si no se puede pasar.
func _altura_suelo(p: Vector3, y_actual: float) -> float:
	if _prohibido(p):
		return NAN
	var espacio := get_world_3d().direct_space_state
	var desde := Vector3(kael.global_position.x, y_actual + SUBE_MAX + 0.1, kael.global_position.z)
	var hacia := Vector3(p.x, y_actual + SUBE_MAX + 0.1, p.z)
	if hacia.distance_to(desde) > 0.001:
		hacia += (hacia - desde).normalized() * 0.3
		if not espacio.intersect_ray(PhysicsRayQueryParameters3D.create(desde, hacia)).is_empty():
			return NAN
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, y_actual + SUBE_MAX + 0.05, p.z), Vector3(p.x, y_actual - 8.0, p.z))
	var r := espacio.intersect_ray(q)
	if r.is_empty():
		return NAN
	var y: float = r["position"].y
	if absf(y - y_actual) > SUBE_MAX:                    # escalón demasiado alto o caída
		return NAN
	var n: Vector3 = r["normal"]
	if n.y < cos(deg_to_rad(PENDIENTE_MAX)) and absf(y - y_actual) > 0.02:
		return NAN                                       # pendiente demasiado empinada (en los dos sentidos)
	return y


# Si se toca un sitio prohibido (el río, el barranco), Kael va al último punto andable hacia él.
func _ajustar_destino(p):
	if p == null or kael == null:
		return null
	var desde := kael.global_position
	var hacia: Vector3 = p
	var plano := Vector2(hacia.x - desde.x, hacia.z - desde.z)
	var pasos := int(plano.length() / 0.25)
	var ultimo = null
	for k in pasos + 1:
		var t := float(k) / maxf(pasos, 1)
		var q := desde.lerp(hacia, t)
		if _prohibido(q):
			break
		ultimo = q
	return ultimo


# Último punto seguro y atascos: si en 1 s no se acerca al destino, se para; si está en zona prohibida,
# vuelve al último punto seguro.
func _vigilar_atasco(delta: float) -> void:
	if _prohibido(kael.global_position):
		kael.global_position = seguro
		destino = null
		return
	_t_seguro += delta
	if _t_seguro > 0.25:
		_t_seguro = 0.0
		seguro = kael.global_position
	if destino == null:
		_atasco_t = 0.0
		_atasco_dist = INF
		return
	var falta := Vector2(destino.x - kael.global_position.x, destino.z - kael.global_position.z).length()
	_atasco_t += delta
	if _atasco_t >= 1.0:
		if falta > _atasco_dist - 0.1:
			destino = null                               # no avanza: se queda donde está (sitio seguro)
		_atasco_t = 0.0
		_atasco_dist = falta


# ---------------------------------------------------------------- panel de rendimiento (Skill aet-rendimiento-android)
# Tecla F3 o botón «RND»: muestra FPS, ms por fotograma con el reloj real (mediana y percentil 95 de los
# últimos ~10 s; el delta de Godot está suavizado y esconde los tirones), ms de CPU y de GPU del dibujo
# (los que mide el motor; si el dispositivo no da la GPU sale «—»), llamadas de dibujo, triángulos y
# memoria de vídeo. Mientras está abierto guarda una línea cada 0,5 s en user://rendimiento_<escena>.csv,
# pero escribe en el almacenamiento solo cada 10 s (escribir cada medio segundo podía causar tirones).
# Botón «CAL»: cambia de perfil (bajo → medio → alto). Botón «PRUEBA»: banco de pruebas automático.
var panel_rnd: Label
var _ms: Array = []
var _u_ant := 0
var _t_rnd := 0.0
var _t_total := 0.0
var _csv: FileAccess
var _csv_pendiente: PackedStringArray = []
var _t_csv := 0.0
var csv_cada_medio_segundo := false          # solo para comparar en el banco (la forma antigua)
var _midiendo := false


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	var cal = load("res://prototipos/calidad_proto.gd")
	var bc := Button.new()
	bc.text = "CAL: " + cal.actual()
	bc.position = Vector2(1060, 12)
	bc.custom_minimum_size = Vector2(110, 56)
	bc.focus_mode = Control.FOCUS_NONE
	bc.pressed.connect(_cambiar_perfil)
	capa.add_child(bc)
	var bp := Button.new()
	bp.text = "PRUEBA"
	bp.position = Vector2(1160, 76)
	bp.custom_minimum_size = Vector2(108, 56)
	bp.focus_mode = Control.FOCUS_NONE
	bp.pressed.connect(_empezar_banco)
	capa.add_child(bp)
	var bd := Button.new()
	bd.text = "DIAG"
	bd.position = Vector2(1160, 140)
	bd.custom_minimum_size = Vector2(108, 56)
	bd.focus_mode = Control.FOCUS_NONE
	bd.pressed.connect(func(): _empezar_banco(BANCO_DIAG))
	capa.add_child(bd)
	var bt := Button.new()
	bt.text = "TOPE"
	bt.position = Vector2(1160, 204)
	bt.custom_minimum_size = Vector2(108, 56)
	bt.focus_mode = Control.FOCUS_NONE
	bt.pressed.connect(func(): _empezar_banco(BANCO_TOPE))
	capa.add_child(bt)
	var ba := Button.new()
	ba.text = "ARB"
	ba.position = Vector2(1160, 268)
	ba.custom_minimum_size = Vector2(108, 56)
	ba.focus_mode = Control.FOCUS_NONE
	ba.pressed.connect(func(): _empezar_banco(BANCO_ARBOLES))
	capa.add_child(ba)
	panel_rnd = Label.new()
	panel_rnd.position = Vector2(16, 84)
	panel_rnd.add_theme_font_size_override("font_size", 22)
	panel_rnd.add_theme_color_override("font_color", Color(1.0, 1.0, 0.75))
	panel_rnd.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	panel_rnd.add_theme_constant_override("outline_size", 6)
	panel_rnd.visible = false
	capa.add_child(panel_rnd)
	var b := Button.new()
	b.text = "RND"
	b.position = Vector2(1180, 12)
	b.custom_minimum_size = Vector2(88, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(_alternar_panel)
	capa.add_child(b)


func _alternar_panel() -> void:
	panel_rnd.visible = not panel_rnd.visible
	_medir_render(panel_rnd.visible)
	if panel_rnd.visible and _csv == null:
		var nombre := String(scene_file_path.get_file().get_basename()) if scene_file_path != "" else "escena"
		_csv = FileAccess.open("user://rendimiento_%s.csv" % nombre, FileAccess.WRITE)
		if _csv != null:
			_csv.store_line("tiempo,perfil,fps,ms_mediana,ms_p95,cpu_dibujo_ms,gpu_ms,dibujos,primitivas,memoria_video_mb")


func _medir_render(si: bool) -> void:
	_midiendo = si
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), si)


# Valores de este momento: [fps, mediana, p95, cpu_dibujo, gpu, dibujos, primitivas, memoria]
func _valores() -> Array:
	var orden := _ms.duplicate()
	orden.sort()
	var mediana: float = orden[orden.size() / 2] if orden.size() > 0 else 0.0
	var p95: float = orden[mini(orden.size() - 1, int(orden.size() * 0.95))] if orden.size() > 0 else 0.0
	var rid := get_viewport().get_viewport_rid()
	var cpu := RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu()
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(rid)
	if gpu < 0.0 or gpu > 1000.0:
		gpu = 0.0                                       # algunos drivers (Mali del Redmi) devuelven basura: «—»
	return [Performance.get_monitor(Performance.TIME_FPS), mediana, p95, cpu, gpu,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0]


func _medir(delta: float) -> void:
	_t_total += delta
	var ahora := Time.get_ticks_usec()                  # reloj real: el delta de Godot está suavizado
	if _u_ant > 0:
		_ms.append((ahora - _u_ant) / 1000.0)
	_u_ant = ahora
	if _ms.size() > 600:
		_ms.pop_front()
	if regulador != null and _ms.size() > 0:
		_dar_muestra(_ms[_ms.size() - 1])
	_banco_paso(delta)
	_t_rnd += delta
	if _t_rnd < 0.5 or panel_rnd == null or not panel_rnd.visible:
		return
	_t_rnd = 0.0
	var v := _valores()
	var cal = load("res://prototipos/calidad_proto.gd")
	panel_rnd.text = "%s · %d FPS · %.1f ms (p95 %.1f)\nCPU dibujo %.1f ms · GPU %s\n%d dibujos · %dk triángulos · %d MB vídeo" % [
		cal.actual(), v[0], v[1], v[2], v[3], ("%.1f ms" % v[4]) if v[4] > 0.0 else "—", v[5], int(v[6] / 1000), int(v[7])]
	if _csv != null:
		_csv_pendiente.append("%.1f,%s,%d,%.2f,%.2f,%.2f,%.2f,%d,%d,%.1f" % [_t_total, cal.actual(), v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7]])
		_t_csv += 0.5
		if csv_cada_medio_segundo or _t_csv >= 10.0:  # se escribe de golpe cada 10 s
			_escribir_csv()


func _escribir_csv() -> void:
	if _csv == null:
		return
	for l in _csv_pendiente:
		_csv.store_line(l)
	_csv.flush()
	_csv_pendiente.clear()
	_t_csv = 0.0


func _exit_tree() -> void:
	_escribir_csv()


# ---------------------------------------------------------------- banco de pruebas (botón «PRUEBA»)
# Recorre solo todos los casos: perfil bajo, medio y alto, cámara a 20 m y a 34 m, y un caso con el CSV
# escribiendo cada medio segundo (la forma antigua). En cada caso Kael camina en bucle por el camino y el
# puente; se esperan 3 s y se miden 8 s sin tope de FPS (en el móvil manda la sincronía de la pantalla).
# Al final se ve la tabla en pantalla y se guarda en user://banco_<escena>.csv. Se cambia de perfil
# recargando la escena, así que el estado va en Engine (meta «banco_proto»).
# Caso: [perfil, distancia, CSV antiguo, cambios sobre el perfil (A/B), nombre en la tabla]
const BANCO_CASOS := [["bajo", 20.0, false], ["bajo", 34.0, false], ["medio", 20.0, false], ["medio", 34.0, false],
	["alto", 20.0, false], ["alto", 34.0, false], ["bajo", 20.0, true]]
# Botón «TOPE»: los tres perfiles con su tope real de FPS (como se jugará), para medir los tirones
# Botón «ARB»: coste de los árboles candidatos llenando el bosque del mapa (solo durante la medición)
const BANCO_ARBOLES := [["medio", 20.0, false, {"arboles_tipo": "arce"}, "arce anterior", true],
	["medio", 20.0, false, {"arbol_matas": 1.0, "arbol_sombra_simple": false}, "mezcla completa", true],
	["medio", 20.0, false, {"arbol_matas": 1.0, "arbol_sombra_simple": true}, "solo sombra simple", true],
	["medio", 20.0, false, {"arbol_matas": 0.65, "arbol_sombra_simple": false}, "solo menos matas", true],
	["medio", 20.0, false, {}, "medio ajustado", true],
	["medio", 34.0, false, {}, "medio ajustado", true],
	["bajo", 20.0, false, {}, "bajo ajustado", true]]
const BANCO_TOPE := [["bajo", 20.0, false, {}, "bajo", true], ["medio", 20.0, false, {}, "medio", true],
	["medio", 34.0, false, {}, "medio", true], ["alto", 20.0, false, {}, "alto", true]]
# Botón «DIAG»: qué frena al perfil medio (quitando una cosa cada vez, Skill aet-rendimiento-android)
const BANCO_DIAG := [["medio", 20.0, false, {}, "medio"],
	["medio", 20.0, false, {"relieve": false}, "medio-relieve"],
	["medio", 20.0, false, {"sombras": false}, "medio-sombras"],
	["medio", 20.0, false, {"escala_3d": 0.75}, "medio-res75"],
	["medio", 20.0, false, {"hierba": 2400, "flores": 280, "dist_hierba": 30.0}, "medio-hierba"],
	["medio", 20.0, false, {"luces_faroles": false}, "medio-faroles"],
	["alto", 20.0, false, {}, "alto"],
	["alto", 20.0, false, {"sombra_res": 2048}, "alto-sombra2k"]]
const BANCO_RUTA := [Vector3(-3, 0, 5), Vector3(5.3, 0, -2), Vector3(12.7, 0, -2), Vector3(5.3, 0, -2)]
const BANCO_ESPERA := 3.0
const BANCO_MIDE := 8.0
var _banco := {}                    # caso en curso
var _bt := 0.0
var _bu0 := 0                       # reloj real al empezar a medir (µs)
var _bms: Array = []
var _bsum := [0.0, 0.0, 0.0, 0.0, 0.0]   # cpu, gpu, dibujos, primitivas, memoria
var _bn := 0
var _bpunto := 0
var tabla_banco: Label


func _empezar_banco(casos: Array = BANCO_CASOS) -> void:
	Engine.set_meta("banco_proto", {"i": 0, "resultados": [], "casos": casos,
		"perfil_previo": load("res://prototipos/calidad_proto.gd").actual()})
	_cargar_caso_banco()


func _cargar_caso_banco() -> void:
	var b: Dictionary = Engine.get_meta("banco_proto")
	var casos: Array = b["casos"]
	if Engine.has_meta("calidad_extra"):
		Engine.remove_meta("calidad_extra")
	if b["i"] < casos.size():
		Engine.set_meta("calidad_proto", casos[b["i"]][0])
		if casos[b["i"]].size() > 3 and not casos[b["i"]][3].is_empty():
			Engine.set_meta("calidad_extra", casos[b["i"]][3])
	else:
		Engine.set_meta("calidad_proto", b["perfil_previo"])   # al acabar, la tabla se ve con el perfil de antes
	get_tree().reload_current_scene()


# Se llama al cargar la escena con un banco en marcha.
func _seguir_banco() -> void:
	var b: Dictionary = Engine.get_meta("banco_proto")
	var casos: Array = b["casos"]
	if b["i"] >= casos.size():
		_mostrar_tabla_banco(b)
		return
	var caso: Array = casos[b["i"]]
	distancia = caso[1]
	_banco = {"caso": caso}
	_bt = 0.0
	_bms.clear()
	_bsum = [0.0, 0.0, 0.0, 0.0, 0.0]
	_bn = 0
	_medir_render(true)
	if caso[2]:                                     # caso «CSV antiguo»: panel abierto escribiendo cada 0,5 s
		csv_cada_medio_segundo = true
		if not panel_rnd.visible:
			_alternar_panel()
	info.text = "Banco de pruebas %d/%d: %s, %d m%s" % [b["i"] + 1, casos.size(), caso[4] if caso.size() > 4 else caso[0], caso[1], " (CSV cada 0,5 s)" if caso[2] else ""]


func _banco_paso(delta: float) -> void:
	if _banco.is_empty():
		return
	var con_tope: bool = _banco["caso"].size() > 5 and _banco["caso"][5]
	Engine.max_fps = perfil_fps if con_tope else 0   # sin tope: la capacidad; con tope: como se jugará
	if destino == null:
		destino = BANCO_RUTA[_bpunto % BANCO_RUTA.size()]
		_bpunto += 1
	# La ventana se mide con el reloj REAL: Godot recorta el delta a 8 pasos de física (~133 ms), así que con
	# fotogramas más lentos el delta avanzaba menos que el tiempo y el FPS se quedaba clavado en ~7,5.
	_bt += delta
	if _bt < BANCO_ESPERA:
		return
	if _bu0 == 0:
		_bu0 = Time.get_ticks_usec()
	_bms.append(_ms[_ms.size() - 1] if _ms.size() > 0 else delta * 1000.0)
	var v := _valores()
	_bsum[0] += v[3]
	_bsum[1] += v[4]
	_bsum[2] += v[5]
	_bsum[3] += v[6]
	_bsum[4] = v[7]
	_bn += 1
	var real := (Time.get_ticks_usec() - _bu0) / 1000000.0
	if real < BANCO_MIDE:
		return
	_bu0 = 0
	_bms.sort()
	var med: float = _bms[_bms.size() / 2]
	var b: Dictionary = Engine.get_meta("banco_proto")
	var caso: Array = _banco["caso"]
	# picos: fotogramas que tardan más de 1,5 veces lo previsto. Sin tope, lo previsto es la mediana del propio caso
	# (mide tirones, no si se llega a 30 FPS: un caso lento pero regular da 0 %); con tope, lo que pide su FPS
	var previsto: float = 1000.0 / perfil_fps if con_tope else med
	var tirones := 0
	for m in _bms:
		if m > previsto * 1.5:
			tirones += 1
	var nombre: String = caso[4] if caso.size() > 4 else caso[0]
	if con_tope:
		nombre += " tope%d" % perfil_fps
	b["resultados"].append([nombre, caso[1], caso[2], _bms.size() / real, med, _bms[int(_bms.size() * 0.95)],
		_bsum[0] / _bn, _bsum[1] / _bn, _bsum[2] / _bn, _bsum[3] / _bn, _bsum[4], 100.0 * tirones / maxf(1.0, _bms.size())])
	b["i"] += 1
	Engine.set_meta("banco_proto", b)
	_banco = {}
	_escribir_csv()
	_cargar_caso_banco()


func _mostrar_tabla_banco(b: Dictionary) -> void:
	Engine.remove_meta("banco_proto")
	Engine.set_meta("calidad_proto", b["perfil_previo"])
	var lineas := ["perfil          dist  CSV   FPS   mediana  p95    CPU    GPU    dibujos  triáng.  memoria  picos"]
	var csv := ["perfil,distancia_m,csv_0_5s,fps,ms_mediana,ms_p95,cpu_dibujo_ms,gpu_ms,dibujos,primitivas,memoria_video_mb,picos_pct"]
	for r in b["resultados"]:
		lineas.append("%-14s  %2dm  %-4s %5.1f  %5.1f ms %5.1f ms %4.1f ms %s  %4d     %4dk    %d MB   %4.1f %%" % [
			r[0], r[1], "sí" if r[2] else "no", r[3], r[4], r[5], r[6], ("%4.1f ms" % r[7]) if r[7] > 0.0 else "  —   ", int(r[8]), int(r[9] / 1000), int(r[10]), r[11]])
		csv.append("%s,%d,%s,%.1f,%.2f,%.2f,%.2f,%.2f,%d,%d,%.1f,%.2f" % [r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11]])
	var f := FileAccess.open("user://banco_%s.csv" % scene_file_path.get_file().get_basename(), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(csv))
	for l in lineas:
		print(l)
	tabla_banco = Label.new()
	tabla_banco.text = "\n".join(lineas) + "\n\n(toca para cerrar)"
	tabla_banco.position = Vector2(40, 150)
	tabla_banco.add_theme_font_size_override("font_size", 20)
	tabla_banco.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	tabla_banco.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	tabla_banco.add_theme_constant_override("outline_size", 8)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.size = Vector2(1200, 60 + 30 * b["resultados"].size())
	fondo.position = Vector2(30, 140)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			fondo.queue_free()
			tabla_banco.queue_free())
	info.get_parent().add_child(fondo)
	info.get_parent().add_child(tabla_banco)
	info.text = "Banco de pruebas terminado"


func _punto_suelo(pantalla: Vector2):
	var desde := cam.project_ray_origin(pantalla)
	var q := PhysicsRayQueryParameters3D.create(desde, desde + cam.project_ray_normal(pantalla) * 500.0)
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	return r["position"] if not r.is_empty() else null


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			dedos[ev.index] = ev.position
		else:
			dedos.erase(ev.index)
		dist_pellizco = 0.0
		if ev.pressed and dedos.size() == 1:
			destino = _ajustar_destino(_punto_suelo(ev.position))
	elif ev is InputEventScreenDrag:
		dedos[ev.index] = ev.position
		if dedos.size() == 2:                  # pellizco: zoom
			var v: Array = dedos.values()
			var d: float = v[0].distance_to(v[1])
			if dist_pellizco > 0.0:
				distancia = clampf(distancia * dist_pellizco / d, DIST_MIN, DIST_MAX)
			dist_pellizco = d
		elif dedos.size() == 1:
			destino = _ajustar_destino(_punto_suelo(ev.position))
	elif ev is InputEventMouseButton and ev.pressed:
		match ev.button_index:
			MOUSE_BUTTON_LEFT:
				destino = _ajustar_destino(_punto_suelo(ev.position))
			MOUSE_BUTTON_WHEEL_UP:
				distancia = clampf(distancia - 1.0, DIST_MIN, DIST_MAX)
			MOUSE_BUTTON_WHEEL_DOWN:
				distancia = clampf(distancia + 1.0, DIST_MIN, DIST_MAX)
	elif ev is InputEventMouseMotion and ev.button_mask & MOUSE_BUTTON_MASK_LEFT:
		destino = _ajustar_destino(_punto_suelo(ev.position))
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_Q:
				inclinacion = clampf(inclinacion + 5.0, INCL_MIN, INCL_MAX)
			KEY_E:
				inclinacion = clampf(inclinacion - 5.0, INCL_MIN, INCL_MAX)
			KEY_T:
				cam.projection = Camera3D.PROJECTION_ORTHOGONAL if cam.projection == Camera3D.PROJECTION_PERSPECTIVE else Camera3D.PROJECTION_PERSPECTIVE
			KEY_F3:
				_alternar_panel()
			KEY_R:
				inclinacion = 45.0
				distancia = 20.0
				cam.projection = Camera3D.PROJECTION_PERSPECTIVE
