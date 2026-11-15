extends "res://prototipos/vista3d.gd"
# BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11): LA REGIÓN. EN PRUEBAS y APAGADO: solo se entra desde el banco de pruebas
# de Auditoría («Barrio de Oakhaven (en pruebas)», banco_pruebas.gd, EXPLORAR["barrio"]). Ninguna escena del juego lo
# enlaza; Oakhaven 3D no cambia. Fuera del banco, _ready vuelve a la pantalla de carga y no sigue.
# Plan: docs/v12/BARRIO_OAKHAVEN_PLAN.md; lo hecho y el contrato real: docs/v12/BARRIO_OAKHAVEN.md.
#
# FASE 0 (lo que hay): un BLOCKOUT de cajas sacado del trazado (zonas3d/barrio/trazado.gd: suelos con sus cotas, rampas y
# escalones; fachadas con su altura aproximada; puertas marcadas; un StaticBody3D por caja), Kael andando por el bucle
# entero (caravanas → calle comercial → plaza → talleres → casas → atajo → caravanas) con la cámara por ZONAS sin girar
# (la de la muestra de la calle), la API de región del contrato y el reparto de _accion. Los interiores (agente B), los
# vecinos y sus rutinas (agente C) y la misión (agente C) son stubs que no hacen nada: las puertas dicen «en obras».
#
# CONTRATO (lo que reciben B y C de esta región; plan §11):
#   var kael, cam, perfil, interior ("" = fuera)          signal interior_cambiado(id)
#   avisar(texto, efecto := "", seg := 2.8)               guardar()            ocupado() -> bool
#   sonda(p) -> Vector2 (sol, cielo)                      iniciar_dialogo(ruta) -> bool
#   ancla(id) -> Vector3 ("int_*" → interiores; si no, trazado)
# Reparto de _accion: «entrar_<id>» y «salir_<id>» → aquí + interiores (fundido); un id de vivo.piezas() →
# vivo.hablar(id); cualquier otro → Barrio.accion(pid).

const T := preload("res://zonas3d/barrio/trazado.gd")
const Interiores := preload("res://zonas3d/barrio/interiores.gd")
const Vivo := preload("res://zonas3d/barrio/barrio_vivo.gd")
const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const Progreso := preload("res://progreso.gd")
const BP_RUTA := "res://banco_pruebas.gd"

const INDICE := 102                        # pos_3d_lugar del barrio (0-10 mapa, 99 banco, 100 mapamundi, 101 cueva)
const META_ACTIVO := "barrio_v12"          # metas de SESIÓN (banco_pruebas.gd, METAS_SESION)
const META_INTERIOR := "barrio_interior"   # {id, pos}: solo para volver a aparecer dentro tras la recarga de CAL
const META_RELOJ := "barrio_reloj"         # (del agente C: el reloj de las rutinas)
const TEXTO_OBRAS := "Aún no se puede entrar (en obras)."
const SONDA_PROVISIONAL := Vector2(1.0, 0.7)   # (fase 0: sin luz horneada; el agente A pondrá las sondas por sector)
const RADIO_SALIR := 1.3
const DIST_PREPARAR := 8.0                 # a menos de esto de una puerta, interiores.preparar(id)
const FUNDIDO := [0.35, 0.15, 0.35]        # a negro, espera, vuelta (plan §3)

signal interior_cambiado(id: String)

var brillo_sin_sombras := 1.1               # vista3d.gd: el bajo sin sombras
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var interior := ""
var interiores = null                      # zonas3d/barrio/interiores.gd (Node3D)
var vivo = null                            # zonas3d/barrio/barrio_vivo.gd (Node3D)
var exterior: Node3D
var sectores := {}                         # sector → su Node3D (para la visibilidad por sector del agente A)
var sol: DirectionalLight3D
var ambiente: Environment
var grupo: Node3D
var capa_ui: CanvasLayer
var boton_accion: Button
var boton_recargar: Button
var aviso: Label
var fundido: ColorRect
var titulo: Label
var cerca := ""
var cambiando := false                     # durante el fundido de una puerta
var dialogo_actual := ""
var ultimo_aviso := ""
var choques := 0                           # cuerpos de choque del blockout (para las pruebas)
var fuera_del_banco := false
var _bloqueo := 0.0
var _ids_vivo := {}
var _preparados := {}
var _t_puertas := 0.0
var _avisos_cola: Array = []
var _tween_aviso: Tween


# ¿Estamos en el banco de pruebas de Auditoría?
static func en_banco_pruebas() -> bool:
	return load(BP_RUTA).en_banco()


# La guardia del prólogo (plan §1), común a toda puerta o pasaje.
static func puede_pasar() -> bool:
	return Barrio.puede_pasar()


func _ready() -> void:
	if not en_banco_pruebas():
		fuera_del_banco = true                    # (una partida vieja, F6…): a la carga, sin construir nada
		set_process(false)
		set_process_unhandled_input(false)
		_volver_a_la_carga.call_deferred()
		return
	Engine.set_meta(META_ACTIVO, true)            # la región se activa a sí misma (el banco no pone metas por caso)
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	super()
	info.visible = false
	_crear_interfaz()
	interiores = Interiores.new()
	interiores.name = "Interiores"
	add_child(interiores)
	interiores.construir(self)
	vivo = Vivo.new()
	vivo.name = "BarrioVivo"
	add_child(vivo)
	vivo.montar(self)
	Barrio.registrar_dialogic()
	_colocar_kael(_sitio_de_entrada())
	_crear_grupo()
	_volver_dentro_tras_cal()
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
		dg.signal_event.connect(_al_senal)
	if has_node("/root/Sonido"):
		Sonido.oyente_3d(kael, cam)
		Sonido.pasos_3d(kael, suelo_de_pasos)


func _volver_a_la_carga() -> void:
	while is_inside_tree() and has_node("/root/Recursos") and Recursos.cambiando:
		await get_tree().process_frame             # (si llegó por Recursos.cambiar_escena, que acabe su fundido)
	if is_inside_tree() and has_node("/root/Recursos"):
		Recursos.cambiar_escena(load(BP_RUTA).CARGA)


func _exit_tree() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		if dg.timeline_ended.is_connected(_al_terminar_dialogo):
			dg.timeline_ended.disconnect(_al_terminar_dialogo)
		if dg.signal_event.is_connected(_al_senal):
			dg.signal_event.disconnect(_al_senal)
	super()


# Cachés estáticas de la región (fase 0: ninguna; el agente A pondrá aquí las de materiales y luz por sector). Las suelta
# banco_pruebas.salir().
static func soltar_caches() -> void:
	pass


# ================================================================= mundo: la tarde dorada (provisional, en tiempo real)

func _crear_ambiente() -> void:
	ambiente = Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.86, 0.80, 0.70)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.62, 0.68, 0.80)
	ambiente.ambient_light_energy = 0.55
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color(0.86, 0.76, 0.62)
	ambiente.fog_density = 0.0025
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.tonemap_exposure = 0.95
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = ambiente
	add_child(we)
	sol = DirectionalLight3D.new()                 # sol bajo del oeste-suroeste (el de la muestra de la calle)
	sol.name = "Sol"
	var h := Vector3(-0.73, 0.45, 0.51).normalized()
	sol.look_at_from_position(Vector3.ZERO, -h, Vector3.UP)
	sol.light_color = Color(1.0, 0.84, 0.64)
	sol.light_energy = 1.05
	sol.shadow_enabled = bool(perfil.get("sombras", false))
	sol.directional_shadow_max_distance = float(perfil.get("dist_sombras", 40.0))
	add_child(sol)


# ================================================================= el blockout (fase 0), sacado del trazado

const COLOR_SUELO := {"caravanas": Color(0.62, 0.55, 0.42), "comercial": Color(0.66, 0.62, 0.56),
	"plaza": Color(0.72, 0.68, 0.60), "talleres": Color(0.60, 0.54, 0.46), "residencial": Color(0.64, 0.60, 0.52),
	"atajo": Color(0.56, 0.54, 0.50)}
const COLOR_TIPO := {"casa": Color(0.86, 0.80, 0.68), "muro": Color(0.62, 0.60, 0.56), "bajo": Color(0.55, 0.45, 0.32),
	"puerta": Color(0.86, 0.52, 0.18), "decor": Color(0.70, 0.62, 0.42), "terreno": Color(0.45, 0.52, 0.32)}
const COLOR_TEJADO := Color(0.58, 0.30, 0.24)
const COLOR_FONDO := Color(0.50, 0.50, 0.40)
const GRUESO_SUELO := 2.0
const ROTULOS := {"horno": "Horno", "taller": "Taller", "vivienda": "Vivienda"}

var _caja_v: PackedVector3Array
var _caja_n: PackedVector3Array
var _mallas := {}                          # sector → SurfaceTool


func _crear_escenario() -> void:
	exterior = Node3D.new()
	exterior.name = "Exterior"
	add_child(exterior)
	var cubo := BoxMesh.new()
	var a := cubo.get_mesh_arrays()
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	if idx.is_empty():                             # (sin índices: los vértices ya van de tres en tres)
		_caja_v = vs
		_caja_n = ns
	for i in idx:
		_caja_v.append(vs[i])
		_caja_n.append(ns[i])
	for s in T.ORDEN:
		var n := Node3D.new()
		n.name = "Sector_" + s
		exterior.add_child(n)
		sectores[s] = n
	# el fondo: tierra baja bajo todo (lo que no se pisa)
	_caja_blockout("caravanas", Transform3D(Basis.IDENTITY, Vector3(-20.0, -0.53, -13.0)), Vector3(80.0, 1.0, 70.0), COLOR_FONDO,
		true, "Fondo")
	for s in T.SUELOS:
		_suelo(s)
	for b in T.BLOQUES:
		_bloque(b)
	for s in _mallas:
		var st: SurfaceTool = _mallas[s]
		var mi := MeshInstance3D.new()
		mi.name = "Blockout"
		mi.mesh = st.commit()
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		mi.material_override = m
		(sectores[s] as Node3D).add_child(mi)
	_rotulos()


# Una losa de suelo por SUELO: llana o inclinada (rampa o escalones), con la cara de arriba exactamente en altura().
func _suelo(s: Array) -> void:
	var r: Rect2 = s[1]
	var eje: String = s[2]
	var a: Vector3
	var b: Vector3
	var lado: Vector3
	if eje == "z":
		a = Vector3(r.get_center().x, s[3], r.position.y)
		b = Vector3(r.get_center().x, s[4], r.end.y)
		lado = Vector3(r.size.x, 0, 0)
	else:
		a = Vector3(r.position.x, s[3], r.get_center().y)
		b = Vector3(r.end.x, s[4], r.get_center().y)
		lado = Vector3(0, 0, r.size.y)
	var largo := a.distance_to(b)
	var dir := (b - a) / largo
	var bx: Vector3
	var by: Vector3
	var bz: Vector3
	var tam: Vector3
	if eje == "z":
		bz = dir
		bx = Vector3.RIGHT
		by = bz.cross(bx)
		tam = Vector3(lado.x, GRUESO_SUELO, largo)
	else:
		bx = dir
		bz = Vector3.BACK
		by = bz.cross(bx)
		tam = Vector3(largo, GRUESO_SUELO, lado.z)
	var base := Basis(bx, by, bz)
	var centro := (a + b) * 0.5 - by * (GRUESO_SUELO * 0.5)
	_caja_blockout(s[0], Transform3D(base, centro), tam, COLOR_SUELO.get(s[0], COLOR_FONDO), true, "Suelo")


func _bloque(b: Array) -> void:
	var r: Rect2 = b[2]
	var base: float = b[3]
	var alto: float = b[4]
	var tipo: String = b[5]
	var abajo := base - 0.5 if tipo != "puerta" else base
	var tam := Vector3(r.size.x, base + alto - abajo, r.size.y)
	var c := Vector3(r.get_center().x, abajo + tam.y * 0.5, r.get_center().y)
	_caja_blockout(b[1], Transform3D(Basis.IDENTITY, c), tam, COLOR_TIPO.get(tipo, COLOR_FONDO), b[6], "Choque_" + String(b[0]))
	if tipo == "casa":                             # el tejado: una losa con vuelo, de otro color (sin choque)
		var t := Vector3(r.size.x + 0.6, 0.45, r.size.y + 0.6)
		_caja_blockout(b[1], Transform3D(Basis.IDENTITY, Vector3(c.x, base + alto + 0.2, c.z)), t, COLOR_TEJADO, false, "")


# Una caja en la malla de su sector (con su color en los vértices) y, si es sólida, su cuerpo de choque.
func _caja_blockout(sector: String, xf: Transform3D, tam: Vector3, color: Color, solida: bool, nombre: String) -> void:
	if not _mallas.has(sector):
		var nueva := SurfaceTool.new()
		nueva.begin(Mesh.PRIMITIVE_TRIANGLES)
		_mallas[sector] = nueva
	var st: SurfaceTool = _mallas[sector]
	var esc := Transform3D(Basis(xf.basis.x * tam.x, xf.basis.y * tam.y, xf.basis.z * tam.z), xf.origin)
	for i in _caja_v.size():
		st.set_color(color)
		st.set_normal((xf.basis * _caja_n[i]).normalized())
		st.add_vertex(esc * _caja_v[i])
	if not solida:
		return
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre if nombre != "" else "Choque"
	cuerpo.transform = xf
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	col.shape = forma
	cuerpo.add_child(col)
	(sectores[sector] as Node3D).add_child(cuerpo)
	choques += 1


func _rotulos() -> void:
	for id in T.PUERTAS:
		var l := Label3D.new()
		l.name = "Rotulo_" + id
		l.text = "%s (en obras)" % ROTULOS.get(id, id)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.font_size = 40
		l.outline_size = 10
		l.modulate = Color(1.0, 0.94, 0.78)
		l.outline_modulate = Color(0.30, 0.14, 0.08, 0.85)
		l.pixel_size = 0.01
		var umbral := T.ancla(T.PUERTAS[id]["ancla"])
		var fuera: Vector3 = T.PUERTAS[id]["fuera"]
		var hacia := Vector3(fuera.x - umbral.x, 0.0, fuera.z - umbral.z).normalized()
		l.position = umbral + hacia * 0.9 + Vector3(0, 3.0, 0)       # (delante de la fachada: no la corta)
		var s := T.sector_de(umbral.x, umbral.z)
		(sectores.get(s, exterior) as Node3D).add_child(l)


# ================================================================= Kael, cámara y grupo

func _sitio_de_entrada() -> Vector3:
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	if vuelve:
		var p: Vector3 = Engine.get_meta("pos_3d")
		if Interiores.interior_de(p) == "" and T.andable(p.x, p.z):   # nunca dentro de un ORIGEN ni en lo prohibido
			return Vector3(p.x, T.altura(p.x, p.z), p.z)
	return T.ancla("inicio")


func _colocar_kael(p: Vector3) -> void:
	p.y = interiores.altura(p) if interior != "" and interiores != null else T.altura(p.x, p.z)
	kael.global_position = p
	seguro = p
	foco = T.foco_camara(p)
	destino = null
	_colocar_camara(1.0)


func _mirar_kael(angulo: float) -> void:
	if kael != null and kael.has_method("mirar"):
		kael.mirar(Vector3(-sin(angulo), 0.0, -cos(angulo)), 0.01)


func _colocar_camara(peso: float) -> void:
	if cam == null or kael == null:
		return
	var k := kael.global_position
	if interior != "" and interiores != null:
		var c: Array = interiores.camara(interior, k)
		if c.size() >= 3:
			cam.global_position = c[0]
			cam.global_rotation_degrees = c[1]
			cam.fov = c[2]
			return
	foco = foco.lerp(T.foco_camara(k), peso)
	T.poner_camara(cam, foco)


# Por dónde se anda: fuera, el trazado (y sin pisar a los vecinos); dentro, lo que diga el interior.
func _prohibido(p: Vector3) -> bool:
	if interior != "":
		return interiores == null or not interiores.andable(p)
	if not T.andable(p.x, p.z):
		return true
	return vivo != null and vivo.ocupa(p)


func suelo_de_pasos(p: Vector3) -> String:
	if interior != "":
		return "madera"
	return "grava" if T.sector_de(p.x, p.z) in ["caravanas", "talleres"] else "piedra"


# Tocar el suelo: lo que queda más de 1 m por encima de lo que se pisa (tejados, el arco) no cuenta.
func _punto_suelo(pantalla: Vector2):
	var desde := cam.project_ray_origin(pantalla)
	var hasta := desde + cam.project_ray_normal(pantalla) * 500.0
	var excluir: Array[RID] = []
	for i in 8:
		var q := PhysicsRayQueryParameters3D.create(desde, hasta)
		q.exclude = excluir
		var r := get_world_3d().direct_space_state.intersect_ray(q)
		if r.is_empty():
			return null
		var p: Vector3 = r["position"]
		if interior != "" or p.y < T.altura(p.x, p.z) + 1.0:
			return p
		excluir.append(r["rid"])
	return null


func _crear_grupo() -> void:
	if not perfil.get("grupo", true):
		return
	var G = load("res://grupo.gd")
	var activos: Array = G.activos()
	var nombres: Array = []
	for n in G.EN_EL_GRUPO:
		if n != "Kael" and n in activos:
			nombres.append(n)
	grupo = load("res://zonas3d/grupo_3d.gd").new()
	grupo.name = "Grupo"
	add_child(grupo)
	grupo.pasos_superficie = suelo_de_pasos
	grupo.preparar(self, kael, nombres)
	grupo.colocar(Vector3.BACK)


func _parar_kael() -> void:
	destino = null
	if movimiento != "":
		movimiento = ""
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()
		else:
			kael.reposo()


func ocupado() -> bool:
	if cambiando:
		return true
	var dg = get_node_or_null("/root/Dialogic")
	return dg != null and dg.current_timeline != null


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


# CAL recarga la escena entera: la posición va en la partida (la puerta de fuera si está dentro) y, solo para la sesión,
# el interior en el que estaba, para volver a aparecer dentro.
func _cambiar_perfil() -> void:
	guardar_posicion()
	if interior != "" and kael != null:
		Engine.set_meta(META_INTERIOR, {"id": interior, "pos": kael.global_position})
	super()


func _volver_dentro_tras_cal() -> void:
	if not Engine.has_meta(META_INTERIOR):
		return
	var d = Engine.get_meta(META_INTERIOR)
	Engine.remove_meta(META_INTERIOR)
	if not d is Dictionary or not Interiores.ORIGEN.has(str(d.get("id", ""))):
		return
	_pasar_dentro(str(d["id"]))
	var p = d.get("pos", null)
	if p is Vector3 and interiores.andable(p):
		_colocar_kael(p)


# ================================================================= API de región (contrato)

func avisar(texto: String, efecto := "", seg := 2.8) -> void:
	ultimo_aviso = texto
	if efecto != "" and has_node("/root/Sonido"):
		Sonido.efecto(efecto)
	if aviso == null:
		return
	aviso.text = texto
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(seg)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


# Guarda la partida (solo en el banco: va a su archivo, user://banco_pruebas.save).
func guardar() -> void:
	if not en_banco_pruebas():
		return
	guardar_posicion()
	Progreso.guardar(scene_file_path)


# La posición para la partida: dentro de un interior, SIEMPRE la puerta de fuera (nunca un ORIGEN lejano).
func guardar_posicion() -> void:
	if kael == null:
		return
	var p: Vector3 = kael.global_position
	if interior != "" and T.PUERTAS.has(interior):
		p = T.PUERTAS[interior]["fuera"]
	Engine.set_meta("pos_3d", p)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func sonda(p: Vector3) -> Vector2:
	if interior != "" and interiores != null:
		return interiores.sonda(p)
	return SONDA_PROVISIONAL


func ancla(id: String) -> Vector3:
	if id.begins_with("int_"):
		return interiores.ancla(id) if interiores != null else Vector3.ZERO
	return T.ancla(id)


# Empieza un diálogo de Dialogic. Sus señales «bar:…» van a Barrio.aplicar; al acabar se guarda y se reanudan las
# rutinas. false si no se pudo (no hay Dialogic, no existe la ruta o ya hay otro).
func iniciar_dialogo(ruta: String) -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	if dg == null or ruta == "" or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		return false
	_parar_kael()
	boton_accion.visible = false
	dialogo_actual = ruta
	dg.start(ruta)
	return true


func _al_senal(arg) -> void:
	var s := str(arg)
	if not s.begins_with("bar:"):
		return
	var t := Barrio.aplicar(s)
	if t != "":
		_avisos_cola.append(t)


func _al_terminar_dialogo() -> void:
	if dialogo_actual == "":
		return                                     # (un diálogo que no empezó el barrio)
	dialogo_actual = ""
	_bloqueo = 0.4
	guardar()
	if vivo != null:
		vivo.reanudar_todos()


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	if kael == null or fuera_del_banco:
		return
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if ocupado():
		_parar_kael()
		boton_accion.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		return
	if not _avisos_cola.is_empty() and (_tween_aviso == null or not _tween_aviso.is_running()):
		avisar(str(_avisos_cola.pop_front()), "", 3.2)
	super(delta)
	_comprobar_cerca()
	_t_puertas -= delta
	if _t_puertas <= 0.0:
		_t_puertas = 0.25
		_preparar_cercanos()


func _preparar_cercanos() -> void:
	if interior != "" or interiores == null:
		return
	for id in T.PUERTAS:
		if not _preparados.has(id) and Interiores.ORIGEN.has(id) \
				and _dist_plana(kael.global_position, T.PUERTAS[id]["fuera"]) < DIST_PREPARAR:
			_preparados[id] = true
			interiores.preparar(id)


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ================================================================= lo que se usa

# [id, posición, radio, texto del botón] de lo que hay en la zona de Kael (fuera o en su interior).
func piezas_al_alcance() -> Array:
	var r: Array = []
	if interior == "":
		for id in T.PUERTAS:
			var d: Dictionary = T.PUERTAS[id]
			r.append(["entrar_" + id, d["fuera"], d["radio"], d["texto"]])
	elif interiores != null:
		r.append(["salir_" + interior, interiores.salida(interior), RADIO_SALIR, "Salir"])
	_ids_vivo.clear()
	if vivo != null:
		for pz in vivo.piezas():
			_ids_vivo[str(pz[0])] = true
			r.append(pz)
	for pid in Barrio.PIEZAS:
		var d: Dictionary = Barrio.PIEZAS[pid]
		var a := str(d.get("ancla", ""))
		var de_dentro := a.begins_with("int_")
		if (interior == "" and de_dentro) or (interior != "" and not a.begins_with("int_%s_" % interior)):
			continue
		r.append([pid, ancla(a), float(d.get("radio", 1.4)), str(d.get("boton", "Examinar"))])
	return r


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	var p := kael.global_position
	for pz in piezas_al_alcance():
		var q: Vector3 = pz[1]
		var d := _dist_plana(p, q)
		if d < float(pz[2]) and d < mejor and absf(p.y - q.y) < 1.6:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[3]
	boton_accion.visible = cerca != "" and _bloqueo <= 0.0


func _unhandled_input(ev: InputEvent) -> void:
	if fuera_del_banco or kael == null or ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	super(ev)


func _accion() -> void:
	if _bloqueo > 0.0 or ocupado() or cerca == "":
		return
	_bloqueo = 0.5
	var id := cerca
	if id.begins_with("entrar_"):
		_entrar(id.trim_prefix("entrar_"))
	elif id.begins_with("salir_"):
		_salir_interior()
	elif _ids_vivo.has(id):
		vivo.hablar(id)
	else:
		_accion_barrio(id)


func _accion_barrio(pid: String) -> void:
	var r: Dictionary = Barrio.accion(pid)
	if r.is_empty():
		return
	if str(r.get("dialogo", "")) != "" and iniciar_dialogo(str(r["dialogo"])):
		pass
	elif str(r.get("texto", "")) != "":
		avisar(str(r["texto"]), str(r.get("efecto", "")))
	if r.get("guardar", false):
		guardar()


# ================================================================= puertas e interiores (con el agente B)

func _entrar(id: String) -> void:
	if not puede_pasar():
		avisar(Barrio.TEXTO_PROLOGO, "", 2.8)
		return
	var a := Barrio.puerta(id)
	if a != "":
		avisar(a, "", 2.8)
		return
	if not Interiores.ORIGEN.has(id):
		avisar(TEXTO_OBRAS, "", 2.4)
		return
	interiores.preparar(id)
	await _fundir(_pasar_dentro.bind(id))
	if is_inside_tree():
		guardar_posicion()


func _pasar_dentro(id: String) -> void:
	interior = id
	interiores.mostrar(id)
	exterior.visible = false
	_colocar_kael(interiores.entrada(id))
	_mirar_kael(interiores.mira_entrada(id))
	if grupo != null:
		grupo.colocar(Vector3.BACK)
	if vivo != null:
		vivo.al_interior(id)
	interior_cambiado.emit(id)


func _salir_interior() -> void:
	if interior == "":
		return
	await _fundir(_pasar_fuera)
	if is_inside_tree():
		guardar_posicion()


func _pasar_fuera() -> void:
	var id := interior
	interior = ""
	interiores.mostrar("")
	exterior.visible = true
	var d: Dictionary = T.PUERTAS.get(id, {"fuera": T.INICIO, "mira": 0.0})
	_colocar_kael(d["fuera"])
	_mirar_kael(float(d["mira"]))
	if grupo != null:
		grupo.colocar(Vector3.BACK)
	if vivo != null:
		vivo.al_interior("")
	interior_cambiado.emit("")


# El fundido de las puertas (plan §3: 0,35 s a negro, 0,15 s, 0,35 s de vuelta), sin cambio de escena.
func _fundir(cambio: Callable) -> void:
	if cambiando:
		return
	cambiando = true
	_parar_kael()
	boton_accion.visible = false
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, FUNDIDO[0])
	await t.finished
	cambio.call()
	await get_tree().create_timer(FUNDIDO[1]).timeout
	if not is_inside_tree():
		return
	t = create_tween()
	t.tween_property(fundido, "color:a", 0.0, FUNDIDO[2])
	await t.finished
	cambiando = false


# ================================================================= interfaz

func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	titulo = Label.new()
	titulo.text = "Barrio de Oakhaven (en pruebas) · bloques provisionales · perfil %s" % nombre_perfil
	titulo.position = Vector2(250, 40)
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.84))
	titulo.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.06, 0.85))
	titulo.add_theme_constant_override("outline_size", 6)
	capa_ui.add_child(titulo)
	boton_accion = Button.new()
	boton_accion.position = Vector2(960, 600)
	boton_accion.custom_minimum_size = Vector2(290, 84)
	boton_accion.add_theme_font_size_override("font_size", 28)
	boton_accion.focus_mode = Control.FOCUS_NONE
	boton_accion.visible = false
	boton_accion.pressed.connect(_accion)
	capa_ui.add_child(boton_accion)
	boton_recargar = Button.new()                  # plan §7: la prueba de guardar y cargar de verdad (solo en el banco)
	boton_recargar.text = "Guardar y recargar"
	boton_recargar.position = Vector2(16, 152)
	boton_recargar.custom_minimum_size = Vector2(210, 48)
	boton_recargar.add_theme_font_size_override("font_size", 19)
	boton_recargar.focus_mode = Control.FOCUS_NONE
	boton_recargar.pressed.connect(guardar_y_recargar)
	capa_ui.add_child(boton_recargar)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 120)
	aviso.position = Vector2(140, 470)
	aviso.add_theme_font_size_override("font_size", 28)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	aviso.add_theme_color_override("font_outline_color", Color(0.16, 0.10, 0.08, 0.9))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


# «Guardar y recargar» (plan §7): guarda, lee el archivo del banco, lo restaura y vuelve a ESTA escena directamente
# (restaurar devolvería el mapa para zonas3d/ si la exploración 3D está apagada).
func guardar_y_recargar() -> void:
	if ocupado() or not en_banco_pruebas() or not has_node("/root/Recursos") or Recursos.cambiando:
		return
	guardar()
	var d = Progreso.leer(Progreso.archivo())
	if d is Dictionary:
		Progreso.restaurar(d)
	Recursos.cambiar_escena(scene_file_path)
