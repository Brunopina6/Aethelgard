extends Node
# La ventisca de las Cumbres de Ciclópea 3D (V12, especialista de mundo, 13/11): va y viene. Calma (70-110 s) → sube
# (7 s) → ventisca (24-36 s) → amaina (8 s) → calma… Con ella: la bruma se cierra y blanquea, el sol se apaga, la nevada
# se vuelve horizontal y pasan ráfagas de nieve junto a Kael. Junto a un refugio encendido (refugios.gd) se está al
# abrigo: la ventisca se nota mucho menos.
# Ligera (lo que aprendió rendimiento): nada transparente a pantalla completa; la bruma es la del entorno (sin coste
# extra), y las ráfagas, partículas opacas pequeñas y pocas (alrededor de Kael, según el perfil).

const DURACION := {"calma": [70.0, 110.0], "sube": [7.0, 7.0], "ventisca": [24.0, 36.0], "baja": [8.0, 8.0]}
const SIGUIENTE := {"calma": "sube", "sube": "ventisca", "ventisca": "baja", "baja": "calma"}
const NIEBLA_MAX := 0.034
const RAFAGAS := {"bajo": 40, "medio": 70, "alto": 110}

var env: Environment
var sol: DirectionalLight3D
var copos: CPUParticles3D
var rafagas: CPUParticles3D
var estado := "calma"
var t := 0.0
var dura := 80.0
var intensidad := 0.0                 # 0 calma … 1 ventisca plena (lo que se ve, ya con el abrigo)
var abrigo := 0.0                     # 0 a la intemperie … 1 junto a un refugio encendido (lo pone la región)
var _base := {}
var _rng := RandomNumberGenerator.new()


static func crear(region: Node3D, env_: Environment, sol_: DirectionalLight3D, copos_: CPUParticles3D, perfil: String) -> Node:
	var v: Node = load("res://zonas3d/ciclopea/ventisca.gd").new()
	v.name = "Ventisca"
	v.env = env_
	v.sol = sol_
	v.copos = copos_
	region.add_child(v)
	v._montar(region, perfil)
	return v


func _montar(region: Node3D, perfil: String) -> void:
	_rng.randomize()
	_base = {"niebla": env.fog_density, "niebla_color": env.fog_light_color, "sol": sol.light_energy,
		"ambiente": env.ambient_light_energy, "fondo": env.background_color}
	dura = _rng.randf_range(35.0, 60.0)          # la primera llega antes (que se vea en una visita corta)
	rafagas = CPUParticles3D.new()
	rafagas.name = "Rafagas"
	rafagas.amount = int(RAFAGAS.get(perfil, 70))
	rafagas.lifetime = 1.6
	rafagas.local_coords = false
	rafagas.emitting = false
	rafagas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rafagas.emission_box_extents = Vector3(3.0, 2.2, 9.0)
	rafagas.direction = Vector3(1, -0.08, 0.2)
	rafagas.spread = 6.0
	rafagas.initial_velocity_min = 11.0
	rafagas.initial_velocity_max = 15.0
	rafagas.gravity = Vector3(0, -0.6, 0)
	rafagas.particle_flag_align_y = true               # alargadas en la dirección del viento
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.42)
	var m := StandardMaterial3D.new()                  # opaca: sin mezcla
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(0.94, 0.97, 1.0)
	q.material = m
	rafagas.mesh = q
	rafagas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	region.add_child(rafagas)


# Para las pruebas y las capturas: salta a un estado (y se queda en él «segundos»).
func forzar(nuevo: String, segundos := 9999.0) -> void:
	estado = nuevo
	t = 0.0
	dura = segundos
	if nuevo == "ventisca":
		_objetivo = 1.0
		_crudo = 1.0
	elif nuevo == "calma":
		_objetivo = 0.0
		_crudo = 0.0


var _objetivo := 0.0
var _crudo := 0.0                    # la intensidad del tiempo, sin el abrigo


func _process(delta: float) -> void:
	t += delta
	if t >= dura:
		estado = SIGUIENTE[estado]
		t = 0.0
		var r: Array = DURACION[estado]
		dura = _rng.randf_range(r[0], r[1])
	match estado:
		"calma":
			_crudo = 0.0
		"sube":
			_crudo = smoothstep(0.0, dura, t)
		"ventisca":
			_crudo = 0.85 + 0.15 * sin(t * 0.9) * sin(t * 2.3)     # rachas
		"baja":
			_crudo = 1.0 - smoothstep(0.0, dura, t)
	var k := 1.0 - exp(-3.0 * delta)
	intensidad = lerpf(intensidad, _crudo * (1.0 - 0.8 * abrigo), k)
	aplicar()


func aplicar() -> void:
	var i := intensidad
	env.fog_density = lerpf(_base["niebla"], NIEBLA_MAX, i)
	env.fog_light_color = (_base["niebla_color"] as Color).lerp(Color(0.90, 0.93, 0.98), i)
	env.background_color = (_base["fondo"] as Color).lerp(Color(0.86, 0.89, 0.94), i)
	env.ambient_light_energy = lerpf(_base["ambiente"], _base["ambiente"] * 1.15, i)
	sol.light_energy = lerpf(_base["sol"], _base["sol"] * 0.38, i)      # sombras más flojas: el sol, tapado
	if copos != null:
		copos.gravity = Vector3(0.25 + 4.5 * i, -0.35 - 0.6 * i, 0.4 * i)
		copos.speed_scale = 1.0 + 1.4 * i
	if rafagas != null:
		rafagas.emitting = i > 0.25


# Las ráfagas pasan junto a Kael (las sigue la región, como la nevada).
func seguir(kael: Vector3) -> void:
	if rafagas != null:
		rafagas.global_position = kael + Vector3(-7.0, 1.4, 0.0)
