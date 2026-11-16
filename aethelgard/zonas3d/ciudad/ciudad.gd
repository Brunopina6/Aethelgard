extends "res://prototipos/vista3d.gd"
# CIUDAD COMPLETA de Oakhaven (V12, 16/11, M0): LA ESCENA. EXPERIMENTAL y APAGADA: solo se entra desde el banco de pruebas
# de Auditoría («Ciudad de Oakhaven (maqueta, en pruebas)», banco_pruebas.gd, EXPLORAR["ciudad"]). Ninguna escena del juego
# la enlaza; Oakhaven 3D, la 2D y el barrio no cambian. Fuera del banco, _ready vuelve a la pantalla de carga y no sigue.
# Plan: docs/v12/CIUDAD_OAKHAVEN_PLAN.md; contrato, cargador y pruebas: docs/v12/CIUDAD_OAKHAVEN.md.
#
# MAQUETA (M0): los 8 sectores en bloques sacados de sus trazados, montados por proximidad (cargador.gd) y, lo lejano, en
# maqueta lejana. Kael y el grupo con los controles normales (tocar/clic y teclas): lo que se pisa y a qué altura lo dicen
# los trazados (plano.andable / plano.altura: escaleras y rampas andables), y no se atraviesan los bloques (choques de los
# sectores montados). Cámara inclinada sin girar, la del barrio, con zonas por sector; lo que la escena puede ocultar
# (cubiertas, copas y las casas OCULTABLES de cada trazado) se aclara si se pone entre la cámara y la cabeza de Kael.
# Puertas solo previstas: «Aún no se puede entrar (en obras).». Nunca se cargan interiores.
#
# API de región (la del barrio): kael, cam, perfil · avisar(texto, efecto, seg) · guardar() · guardar_posicion() ·
# ocupado() · ancla(id) · sonda(p) (provisional) · iniciar_dialogo(ruta) · volver_al_banco().

const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const Blockout := preload("res://zonas3d/ciudad/blockout.gd")
const Cargador := preload("res://zonas3d/ciudad/cargador.gd")
const Progreso := preload("res://progreso.gd")
const BP_RUTA := "res://banco_pruebas.gd"

const INDICE := 103                        # pos_3d_lugar de la ciudad (0-10 mapa, 99 banco, 100 mapamundi, 101 cueva, 102 barrio)
const META_ACTIVO := "ciudad_v12"          # meta de SESIÓN (banco_pruebas.gd, METAS_SESION; recursos.gd, APAGADOS)
const TEXTO_OBRAS := "Aún no se puede entrar (en obras)."
const TEXTO_SALIDA := "La Puerta del Sur sale al camino. En la maqueta no se sale: usa «Volver al banco»."
const SONDA_PROVISIONAL := Vector2(1.0, 0.7)
const RADIO_PUERTA_SUR := 1.8

var brillo_sin_sombras := 1.1               # vista3d.gd: el bajo sin sombras
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var cargador: Cargador
var exterior: Node3D
var sol: DirectionalLight3D
var ambiente: Environment
var grupo: Node3D
var capa_ui: CanvasLayer
var boton_accion: Button
var boton_recargar: Button
var aviso: Label
var titulo: Label
var cerca := ""
var ultimo_aviso := ""
var dialogo_actual := ""
var aclarados := 0                         # piezas aclaradas ahora (para las pruebas)
var fuera_del_banco := false
var _bloqueo := 0.0
var _t_titulo := 0.0
var _tween_aviso: Tween
static var _puertas: Array = []            # plano.puertas(), una vez


static func en_banco_pruebas() -> bool:
	return load(BP_RUTA).en_banco()


func _ready() -> void:
	if not en_banco_pruebas():
		fuera_del_banco = true                    # (una partida vieja, F6…): a la carga, sin construir nada
		set_process(false)
		set_process_unhandled_input(false)
		_volver_a_la_carga.call_deferred()
		return
	Engine.set_meta(META_ACTIVO, true)            # la escena se activa a sí misma (como el barrio)
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	super()
	info.visible = false
	_crear_interfaz()
	_colocar_kael(_sitio_de_entrada())
	_crear_grupo()
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
	if has_node("/root/Sonido"):
		Sonido.oyente_3d(kael, cam)
		Sonido.pasos_3d(kael, suelo_de_pasos)


func _volver_a_la_carga() -> void:
	while is_inside_tree() and has_node("/root/Recursos") and Recursos.cambiando:
		await get_tree().process_frame
	if is_inside_tree() and has_node("/root/Recursos"):
		Recursos.cambiar_escena(load(BP_RUTA).CARGA)


func _exit_tree() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null and dg.timeline_ended.is_connected(_al_terminar_dialogo):
		dg.timeline_ended.disconnect(_al_terminar_dialogo)
		if dialogo_actual != "" and dg.current_timeline != null:
			dialogo_actual = ""
			dg.end_timeline(true)
	super()
	Blockout.soltar()                              # (los materiales compartidos no llegan vivos al apagado del motor)


# ================================================================= mundo

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
	sol = DirectionalLight3D.new()                 # el sol bajo del oeste-suroeste del barrio (provisional)
	sol.name = "Sol"
	var h := Vector3(-0.73, 0.45, 0.51).normalized()
	sol.look_at_from_position(Vector3.ZERO, -h, Vector3.UP)
	sol.light_color = Color(1.0, 0.84, 0.64)
	sol.light_energy = 1.05
	sol.shadow_enabled = bool(perfil.get("sombras", false))
	sol.directional_shadow_max_distance = float(perfil.get("dist_sombras", 40.0))
	add_child(sol)


func _crear_escenario() -> void:
	exterior = Node3D.new()
	exterior.name = "Exterior"
	add_child(exterior)
	var st := Blockout.nueva()                     # el campo bajo y alrededor de la ciudad (sin choque: no se pisa)
	var r := P.CAJA_CIUDAD.grow(80.0)
	Blockout.caja(st, AABB(Vector3(r.position.x, -4.0, r.position.y), Vector3(r.size.x, 0.8, r.size.y)), Blockout.COLOR_FONDO)
	var fondo := Blockout.malla(st, "Fondo")
	fondo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	exterior.add_child(fondo)
	cargador = Cargador.new()
	cargador.name = "Cargador"
	exterior.add_child(cargador)
	cargador.preparar(nombre_perfil)


# ================================================================= Kael, cámara y grupo

func _sitio_de_entrada() -> Vector3:
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	if vuelve:
		var p: Vector3 = Engine.get_meta("pos_3d")
		if P.andable(p.x, p.z):
			return Vector3(p.x, P.altura(p.x, p.z), p.z)
	return P.ancla("inicio")


func _colocar_kael(p: Vector3) -> void:
	p.y = P.altura(p.x, p.z)
	kael.global_position = p
	seguro = p
	destino = null
	if cargador != null:
		cargador.actualizar(p, true)
	foco = P.foco_camara(p)
	_colocar_camara(1.0)


func _colocar_camara(peso: float) -> void:
	if cam == null or kael == null:
		return
	foco = foco.lerp(P.foco_camara(kael.global_position), peso)
	P.poner_camara(cam, foco)


# Lo que tapa a Kael se aclara (en vista3d, lo del grupo «ocluye»; aquí, lo ocultable de los sectores montados).
func _oclusion() -> void:
	if cam == null or kael == null or cargador == null:
		return
	aclarados = cargador.aclarar(cam.global_position, kael.global_position + Vector3(0.0, Comun.ALTO_CABEZA, 0.0))


func _prohibido(p: Vector3) -> bool:
	return not P.andable(p.x, p.z)


# Lo que se pisa y su cota salen del PLANO (no de los choques): funciona igual con el sector de al lado aún sin montar. Los
# choques montados siguen parando a Kael ante lo sólido (el rayo a la altura de las rodillas de vista3d).
func _altura_suelo(p: Vector3, y_actual: float) -> float:
	if _prohibido(p):
		return NAN
	var h := P.altura(p.x, p.z)
	if absf(h - y_actual) > SUBE_MAX:
		return NAN
	var desde := Vector3(kael.global_position.x, y_actual + SUBE_MAX + 0.1, kael.global_position.z)
	var hacia := Vector3(p.x, y_actual + SUBE_MAX + 0.1, p.z)
	if hacia.distance_to(desde) > 0.001:
		hacia += (hacia - desde).normalized() * 0.3
		if not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(desde, hacia)).is_empty():
			return NAN
	return h


# Si se toca un sitio que no se pisa, Kael va al último punto andable de la recta.
func _ajustar_destino(p):
	if p == null or kael == null:
		return null
	var desde := kael.global_position
	var hacia: Vector3 = p
	var n := int(Vector2(hacia.x - desde.x, hacia.z - desde.z).length() / 0.1)
	var ultimo = null
	for i in n + 1:
		var q := desde.lerp(hacia, float(i) / maxf(n, 1))
		if _prohibido(q):
			break
		ultimo = Vector3(q.x, P.altura(q.x, q.z), q.z)
	return ultimo


# Tocar el suelo: lo que queda más de 1 m por encima de lo que se pisa (tejados, cubiertas) no cuenta. (Recorrido, 16/11)
# Lo alto de un bloque bajo que no se pisa (un pretil de 0,9 m, un banco) tampoco, si detrás se ve suelo: en el Paseo del
# Concejo el pretil del sur se quedaba los toques del metro de paseo que tapa (Kael iba hacia el pretil); si detrás no hay
# suelo, vale como antes (Kael va hacia él).
func _punto_suelo(pantalla: Vector2):
	var desde := cam.project_ray_origin(pantalla)
	var hasta := desde + cam.project_ray_normal(pantalla) * 500.0
	var excluir: Array[RID] = []
	var reserva = null
	for i in 8:
		var q := PhysicsRayQueryParameters3D.create(desde, hasta)
		q.exclude = excluir
		var r := get_world_3d().direct_space_state.intersect_ray(q)
		if r.is_empty():
			return reserva
		var p: Vector3 = r["position"]
		if p.y < P.altura(p.x, p.z) + 1.0:
			if P.andable(p.x, p.z) or not String((r["collider"] as Node).name).begins_with("Choque_"):
				return p
			if reserva == null:
				reserva = p
		excluir.append(r["rid"])
	return reserva


func suelo_de_pasos(p: Vector3) -> String:
	return "grava" if P.sector_de(p.x, p.z) in ["puerta_sur", "ribera"] else "piedra"


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


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


func _cambiar_perfil() -> void:
	guardar_posicion()
	super()


# ================================================================= API de región

func ocupado() -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	return dg != null and dg.current_timeline != null


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


func guardar_posicion() -> void:
	if kael == null:
		return
	Engine.set_meta("pos_3d", kael.global_position)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


func ancla(id: String) -> Vector3:
	return P.ancla(id)


# Cuánto sol y cuánto cielo llega a p: en la maqueta, la provisional (sin luz horneada).
func sonda(_p: Vector3) -> Vector2:
	return SONDA_PROVISIONAL


func iniciar_dialogo(ruta: String) -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	if dg == null or ruta == "" or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		return false
	_parar_kael()
	boton_accion.visible = false
	dialogo_actual = ruta
	dg.start(ruta)
	return true


func _al_terminar_dialogo() -> void:
	if dialogo_actual == "":
		return
	dialogo_actual = ""
	_bloqueo = 0.4
	guardar()


func volver_al_banco() -> void:
	if has_node("/root/Recursos") and not Recursos.cambiando:
		Recursos.cambiar_escena(load(BP_RUTA).ESCENA)


# «Guardar y recargar»: guarda, lee el archivo del banco, lo restaura y vuelve a ESTA escena.
func guardar_y_recargar() -> void:
	if ocupado() or not en_banco_pruebas() or not has_node("/root/Recursos") or Recursos.cambiando:
		return
	guardar()
	var d = Progreso.leer(Progreso.archivo())
	if d is Dictionary:
		Progreso.restaurar(d)
	Recursos.cambiar_escena(scene_file_path)


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
	super(delta)
	cargador.actualizar(kael.global_position)
	_comprobar_cerca()
	_t_titulo -= delta
	if _t_titulo <= 0.0:
		_t_titulo = 0.5
		_poner_titulo()


# [id, posición, radio, texto] de lo que se usa cerca: las puertas previstas y la Puerta del Sur.
func piezas_al_alcance() -> Array:
	if _puertas.is_empty():
		_puertas = P.puertas()
	var r: Array = [["puerta_sur", P.ancla("puerta_sur"), RADIO_PUERTA_SUR, "Salir por la Puerta del Sur"]]
	for pu in _puertas:
		var d: Dictionary = pu[2]
		r.append(["entrar_%s/%s" % [pu[0], pu[1]], d["fuera"], float(d["radio"]), d["texto"]])
	return r


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	var p := kael.global_position
	for pz in piezas_al_alcance():
		var q: Vector3 = pz[1]
		var d := Vector2(p.x - q.x, p.z - q.z).length()
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
	if cerca.begins_with("entrar_"):
		avisar(TEXTO_OBRAS, "", 2.4)               # (los interiores no existen ni se cargan: solo se prevén las puertas)
	elif cerca == "puerta_sur":
		avisar(TEXTO_SALIDA, "", 3.2)


# ================================================================= interfaz

func _poner_titulo() -> void:
	if titulo == null or cargador == null:
		return
	var s: String = cargador.actual
	titulo.text = "Ciudad de Oakhaven (maqueta, en pruebas) · %s · perfil %s · %d de 8 sectores montados" % [
		P.SECTORES[s]["nombre"] if P.SECTORES.has(s) else "—", nombre_perfil, cargador.montados.size()]


func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	titulo = Label.new()
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
	boton_recargar = Button.new()
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
	_poner_titulo()
