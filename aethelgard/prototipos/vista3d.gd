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
	var m := mi.material_override as StandardMaterial3D
	if m == null:
		return
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if si else BaseMaterial3D.TRANSPARENCY_DISABLED
	m.albedo_color.a = 0.3 if si else 1.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


# ---------------------------------------------------------------- moverse

func _process(delta: float) -> void:
	direccion_teclas = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): direccion_teclas.x = -1
	if Input.is_key_pressed(KEY_D): direccion_teclas.x = 1
	if Input.is_key_pressed(KEY_W): direccion_teclas.y = -1
	if Input.is_key_pressed(KEY_S): direccion_teclas.y = 1
	var paso := Vector3.ZERO
	var corre := false
	if direccion_teclas.length() > 0.1:
		destino = null
		paso = Vector3(direccion_teclas.x, 0, direccion_teclas.y).normalized()
	elif destino != null:
		var falta: Vector3 = destino - kael.global_position
		falta.y = 0.0
		if falta.length() < 0.15:
			destino = null
		else:
			corre = falta.length() > CORRER_DESDE
			paso = falta.normalized()
	if paso != Vector3.ZERO:
		# el avance del fotograma se hace en tramos cortos: igual a 20 que a 60 FPS
		var total := VELOCIDAD * (1.8 if corre else 1.0) * delta
		var tramos := maxi(1, ceili(total / TRAMO_MAX))
		var avanzo := false
		for t in tramos:
			var siguiente: Vector3 = kael.global_position + paso * (total / tramos)
			var y := _altura_suelo(siguiente, kael.global_position.y)
			if is_nan(y):                                   # pared, pendiente, agua o borde: no pasa
				break
			kael.global_position = Vector3(siguiente.x, y, siguiente.z)
			avanzo = true
		if not avanzo:
			destino = null
			paso = Vector3.ZERO
	_vigilar_atasco(delta)
	if paso != Vector3.ZERO:
		kael.mirar(paso, 0.12)
		var nuevo := "correr" if corre else "andar"
		if movimiento != nuevo:
			movimiento = nuevo
			kael.call(nuevo)
	elif movimiento != "":
		movimiento = ""
		kael.reposo()
	_colocar_camara(1.0 - exp(-suavizado * delta))
	_oclusion()
	_medir(delta)
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
# Tecla F3 o botón «RND»: muestra FPS, ms por fotograma (mediana y percentil 95 de los últimos 10 s),
# ms de proceso y de física, llamadas de dibujo, primitivas y memoria de vídeo. Mientras está abierto
# guarda una línea cada 0,5 s en user://rendimiento_<escena>.csv.
var panel_rnd: Label
var _ms: Array = []
var _t_rnd := 0.0
var _t_total := 0.0
var _csv: FileAccess


func _crear_panel_rnd(capa: CanvasLayer) -> void:
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
	if panel_rnd.visible and _csv == null:
		var nombre := String(scene_file_path.get_file().get_basename()) if scene_file_path != "" else "escena"
		_csv = FileAccess.open("user://rendimiento_%s.csv" % nombre, FileAccess.WRITE)
		if _csv != null:
			_csv.store_line("tiempo,fps,ms_fotograma,ms_proceso,ms_fisica,dibujos,primitivas,memoria_video_mb")


func _medir(delta: float) -> void:
	_t_total += delta
	_ms.append(delta * 1000.0)
	if _ms.size() > 600:
		_ms.pop_front()
	_t_rnd += delta
	if _t_rnd < 0.5 or panel_rnd == null or not panel_rnd.visible:
		return
	_t_rnd = 0.0
	var orden := _ms.duplicate()
	orden.sort()
	var mediana: float = orden[orden.size() / 2]
	var p95: float = orden[mini(orden.size() - 1, int(orden.size() * 0.95))]
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var proceso := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var fisica := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var dibujos := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitivas := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	panel_rnd.text = "%d FPS · %.1f ms (p95 %.1f)\nproceso %.1f ms · física %.1f ms\n%d dibujos · %dk triángulos · %d MB vídeo" % [
		fps, mediana, p95, proceso, fisica, dibujos, int(primitivas / 1000), int(vram)]
	if _csv != null:
		_csv.store_line("%.1f,%d,%.2f,%.2f,%.2f,%d,%d,%.1f" % [_t_total, fps, mediana, proceso, fisica, dibujos, primitivas, vram])
		_csv.flush()


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
