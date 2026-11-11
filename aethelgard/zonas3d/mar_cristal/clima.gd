extends RefCounted
# El viento y las tormentas de arena del Mar de Cristal (V12; DISENO_V12.md §4).
#
# Siempre hay brisa: arena arrastrada a ras de suelo alrededor de Kael (partículas en CPU, pocas y por perfil), telas y
# palmeras que se mecen (terreno.animar) y el viento de fondo. La TORMENTA es controlada, nunca molesta sin más:
# - narrativa: la pide la misión (paso 4, «La caravana perdida»), dura hasta que Kael llega al cobijo y espera allí
#   ESPERA_COBIJO segundos; si no lo encuentra, amaina sola a los MAX_NARRATIVA segundos (nunca deja a nadie atrapado);
# - sistémica: después de la misión, como mucho una cada ENFRIAR segundos, de DURACION segundos; nunca durante un
#   diálogo ni en el campamento.
# Con tormenta fuerte: niebla espesa y color de polvo, menos sol, viento fuerte, más arena, el buscador no oye
# (buscador_estorbado) y no se puede excavar; más emboscadas (la región). No se guarda: al volver a entrar, la de la
# misión vuelve a empezar si aún toca, y la sistémica no (un respiro).

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const SUBIR := 4.0                     # segundos en llegar a fuerte
const BAJAR := 5.0
const ESPERA_COBIJO := 6.0
const MAX_NARRATIVA := 120.0
const ENFRIAR := 420.0
const DURACION := 50.0
const NIEBLA_CALMA := 0.006
const NIEBLA_TORMENTA := 0.075
const COLOR_CALMA := Color(0.96, 0.84, 0.66)
const COLOR_TORMENTA := Color(0.78, 0.55, 0.34)

var region: Node3D
var perfil: Dictionary
var fuerza := 0.0                      # 0 calma, 1 tormenta fuerte
var objetivo := 0.0
var narrativa := false
var t_tormenta := 0.0
var t_cobijo := 0.0
var t_enfriar := ENFRIAR
var sistemicas := true                 # se apagan en las pruebas que no las quieren
var arena: CPUParticles3D
var _env: Environment
var _sol: DirectionalLight3D
var _sol_base := 1.0
var _ambiente_base := Color(0.72, 0.76, 0.86)   # los colores de calma: los de la escena (se leen al construir)
var _fondo_base := Color(0.66, 0.77, 0.90)
var _niebla_base := COLOR_CALMA
var _densidad_base := NIEBLA_CALMA
var _viento: Node
var _sonido_tormenta := false
signal amaino(era_narrativa: bool)


func _init(r: Node3D, p: Dictionary) -> void:
	region = r
	perfil = p


func construir() -> void:
	var we: WorldEnvironment = region.get_node_or_null("Ambiente")
	_env = we.environment if we != null else null
	_sol = region.get_node_or_null("Sol")
	_sol_base = _sol.light_energy if _sol != null else 1.0
	if _env != null:
		_ambiente_base = _env.ambient_light_color
		_fondo_base = _env.background_color
		_niebla_base = _env.fog_light_color
		_densidad_base = _env.fog_density             # 12/11: la del perfil (el bajo de esta región lleva la suya)
	arena = CPUParticles3D.new()
	arena.name = "ArenaViento"
	var cuantas := {"bajo": 60, "medio": 110, "alto": 180}
	arena.amount = int(cuantas.get(str(region.get("nombre_perfil")), 110))
	arena.lifetime = 2.4
	arena.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	arena.emission_box_extents = Vector3(14.0, 0.4, 10.0)
	arena.direction = Vector3(1.0, 0.08, 0.15)
	arena.spread = 12.0
	arena.gravity = Vector3(0, -0.15, 0)
	arena.initial_velocity_min = 2.0
	arena.initial_velocity_max = 4.0
	arena.scale_amount_min = 0.5
	arena.scale_amount_max = 1.4
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 0.05)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.96, 0.84, 0.62, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = m
	arena.mesh = q
	region.add_child(arena)


# Los dos vientos son la capa «ambiente» de musica.gd (contextos «mar_cristal» y «tormenta_arena», que se funden entre
# sí; docs/memory/agents/sonido_v12_desierto.md §2). Al salir de la escena, musica.gd pone el contexto de la siguiente.
func empezar_sonido() -> void:
	_pedir_ambiente("tormenta_arena" if objetivo > 0.0 else "mar_cristal")


func parar_sonido() -> void:
	_sonido_tormenta = false


func _pedir_ambiente(contexto: String) -> void:
	var m = region.get_node_or_null("/root/Musica")
	if m != null and m.has_method("pedir"):
		m.pedir(contexto)


func viento() -> float:
	return 0.25 + 0.75 * fuerza


func tormenta_fuerte() -> bool:
	return fuerza > 0.6


func en_tormenta() -> bool:
	return objetivo > 0.0 or fuerza > 0.05


# El buscador no oye nada con la tormenta fuerte (y con la media, poco: lo decide buscador_hud).
func buscador_estorbado() -> float:
	return clampf((fuerza - 0.25) / 0.5, 0.0, 1.0)


# La misión la pide (narrativa = true) o la pide el clima (sistémica).
func empezar_tormenta(es_narrativa: bool) -> void:
	if objetivo > 0.0:
		return
	narrativa = es_narrativa
	objetivo = 1.0
	t_tormenta = 0.0
	t_cobijo = 0.0
	_pedir_ambiente("tormenta_arena")
	_sonido_tormenta = true


func _amainar() -> void:
	objetivo = 0.0
	t_enfriar = ENFRIAR
	if _sonido_tormenta:
		_pedir_ambiente("mar_cristal")
		_sonido_tormenta = false
	amaino.emit(narrativa)
	narrativa = false


func actualizar(delta: float, pos_kael: Vector3, ocupado: bool) -> void:
	# la de la misión: amaina tras esperar en el cobijo, o sola a los MAX_NARRATIVA segundos
	# con un diálogo abierto (ocupado) la tormenta sigue, pero sus relojes se paran y no amaina: si no, la de la misión
	# podía acabar con su propio diálogo a medias y dejar la misión en un estado raro (Redmi, v581)
	if objetivo > 0.0 and ocupado:
		pass
	elif objetivo > 0.0:
		t_tormenta += delta
		if T.en_cobijo(pos_kael.x, pos_kael.z):
			t_cobijo += delta
		else:
			t_cobijo = 0.0
		if narrativa and (t_cobijo >= ESPERA_COBIJO or t_tormenta >= MAX_NARRATIVA):
			_amainar()
		elif not narrativa and t_tormenta >= DURACION:
			_amainar()
	elif sistemicas and not ocupado:
		t_enfriar -= delta
		var en_campamento: bool = Vector2(pos_kael.x, pos_kael.z).distance_to(T.CAMPAMENTO) < 14.0
		if t_enfriar <= 0.0 and not en_campamento and _puede_sistemica():
			empezar_tormenta(false)
	fuerza = move_toward(fuerza, objetivo, delta / (SUBIR if objetivo > fuerza else BAJAR))
	_aplicar(pos_kael)


# Las sistémicas solo después de la misión (antes, la de la misión es la primera que se ve).
func _puede_sistemica() -> bool:
	return load("res://progreso.gd").hito("mc_fin")


func _aplicar(pos_kael: Vector3) -> void:
	if _env != null:
		_env.fog_density = lerpf(_densidad_base, NIEBLA_TORMENTA, fuerza)
		_env.fog_light_color = _niebla_base.lerp(COLOR_TORMENTA, fuerza)
		_env.ambient_light_color = _ambiente_base.lerp(Color(0.80, 0.62, 0.46), fuerza)
		_env.background_color = _fondo_base.lerp(Color(0.80, 0.58, 0.38), fuerza)
	if _sol != null:
		_sol.light_energy = _sol_base * lerpf(1.0, 0.45, fuerza)
	if arena != null:
		arena.position = pos_kael + Vector3(-6.0, 0.6, 0.0)
		arena.initial_velocity_min = lerpf(2.0, 7.0, fuerza)
		arena.initial_velocity_max = lerpf(4.0, 11.0, fuerza)
		arena.emission_box_extents = Vector3(14.0, lerpf(0.4, 3.0, fuerza), 10.0)
		arena.speed_scale = lerpf(1.0, 1.8, fuerza)
		# con la arena arrastrada de gráficos (terreno.gd, efectos_arte), estas partículas solo hacen falta con tormenta
		var arte: bool = region.terreno != null and region.terreno.arrastre_raiz != null
		arena.emitting = fuerza > 0.15 or not arte
