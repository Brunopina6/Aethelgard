extends "res://maga_3d.gd"
# Naira 3D (V12, 12/11): MODELO PROVISIONAL (concepto A, «La Viajera del Eclipse»; personajes/naira/naira_provisional.glb,
# hecho en Blender por guion: docs/memory/agents/animaciones_v12_naira.md). Naira es una PROPUESTA, NO CANON
# (docs/v12/NAIRA.md): solo sale con su hito o con el interruptor «naira_v12» (grupo.gd), APAGADO.
#
# Sigue el patrón de los héroes: hereda de maga_3d.gd, así que el combate (combate.gd, MODELOS «naira3d») y la
# exploración (zonas3d/grupo_3d.gd) la llaman igual que a Lya. Lo que cambia:
#   - su esqueleto no es Mixamo (23 huesos con nombres propios: «cadera», «brazo.L»…): los gestos por código
#     (gestos_3d.gd) se enganchan a mano con HUESOS_NAIRA, sin el aviso de «no encuentro los huesos»;
#   - sus movimientos son sus clips (naira_provisional_clips.json): reposo, caminar, correr, ataque, recibir_golpe,
#     victoria, derrota, lanzar_hechizo, concentracion y magia_poderosa. Los gestos solo ponen el cansancio;
#   - lleva el astrolabio en el modelo (hueso «astrolabio»): no se le crea la vara del inventario.
# Medidas: la malla mide 1,523 m; se normaliza a ALTURA (1,7 m) como los demás y cada escena la escala (combate.gd y
# grupo_3d.gd, a 1,55 m: entre Lya y Kael).

const RUTA_NAIRA := "res://personajes/naira/naira_provisional.glb"
const ALTO_MALLA := 1.523                 # altura de la malla en reposo (pruebas/fotos_naira.gd, 12/11)
const HUESOS_NAIRA := {"cadera": "cadera", "columna": "columna", "pecho": "pecho", "cuello": "cuello",
	"cabeza": "cabeza", "brazo_i": "brazo.L", "antebrazo_i": "antebrazo.L", "mano_i": "mano.L",
	"brazo_d": "brazo.R", "antebrazo_d": "antebrazo.R", "mano_d": "mano.R",
	"muslo_i": "muslo.L", "rodilla_i": "pierna.L", "pie_i": "pie.L",
	"muslo_d": "muslo.R", "rodilla_d": "pierna.R", "pie_d": "pie.R"}
const CLIPS := {"Idle": "reposo", "Walking": "caminar", "Running": "correr", "Casting": "lanzar_hechizo"}
const BUCLES := ["reposo", "caminar", "correr", "concentracion"]
# Instantes de sus clips (naira_provisional_clips.json)
const LANZA := 0.867                      # lanzar_hechizo: el hechizo sale
const LANZA_PODEROSA := 1.7               # magia_poderosa: descarga
const PREPARA_GOLPE := 0.25               # ataque: el astrolabio ya está en la mano (se espera ahí a que el combate diga)
const IMPACTO_GOLPE := 0.4                # ataque: el golpe de palma

var _i_clip := {}                         # nombre lógico → nombre real en el AnimationPlayer


func _init() -> void:
	ruta_modelo = RUTA_NAIRA
	rutas_extra = []
	heroe = "Naira"
	clave_esperas = "Naira"               # sin esperas propias todavía (esperas_3d.gd no la tiene): no hace ninguna
	usa_vara = false
	vel_andar = 1.3                        # sin medir (prueba_anim_pies.gd no la tiene): provisional
	vel_correr = 4.4


func _ready() -> void:
	caida = Node3D.new()
	pivote = Node3D.new()
	ajuste = Node3D.new()
	add_child(caida)
	caida.add_child(pivote)
	pivote.add_child(ajuste)
	_cargar_modelo()
	anim = find_child("AnimationPlayer", true, false)
	skel = _buscar_esqueleto(self)
	if anim == null or skel == null:
		push_warning("naira_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
		return
	_mapear_animaciones()
	gestos = load("res://gestos_3d.gd").new()
	_preparar_gestos()
	skel.add_child(gestos)
	_normalizar()
	_yaw0 = _angulo(_adelante_mundo())
	mirar(FRENTE, 0.0)
	reposo()


# Los huesos de su esqueleto para los gestos por código (los que no tiene, como los dedos, quedan en -1: no se tocan).
func _preparar_gestos() -> void:
	var G3 = load("res://gestos_3d.gd")
	for k in G3.HUESOS:
		gestos.idx[k] = skel.find_bone(HUESOS_NAIRA.get(k, ""))
	var cad := skel.get_bone_global_rest(gestos.idx["cadera"]).origin
	var cab := skel.get_bone_global_rest(gestos.idx["cabeza"]).origin
	var bi := skel.get_bone_global_rest(gestos.idx["brazo_i"]).origin
	var bd := skel.get_bone_global_rest(gestos.idx["brazo_d"]).origin
	gestos.arriba = (cab - cad).normalized()
	if gestos.arriba.dot(Vector3.UP) > 0.8:
		gestos.arriba = Vector3.UP
	gestos.adelante = gestos.arriba.cross((bd - bi).normalized()).normalized()
	gestos.derecha = gestos.adelante.cross(gestos.arriba).normalized()
	gestos.escala = ALTO_MALLA / 1.65
	gestos.gestos_def = G3.GESTOS.duplicate(true)
	for g in gestos.gestos_def:
		gestos.peso[g] = 0.0
		gestos.objetivo[g] = 0.0
		gestos.rapidez[g] = 4.0
	gestos.respirar = 0.0                 # sus clips ya respiran
	gestos.listo = true


func _mapear_animaciones() -> void:
	for n in anim.get_animation_list():
		var s := String(n)
		var corto := s.get_slice("|", s.get_slice_count("|") - 1)   # por si el GLB les pone delante el esqueleto
		_i_clip[corto] = s
	for k in CLIPS:
		if _i_clip.has(CLIPS[k]):
			nombres[k] = _i_clip[CLIPS[k]]
	for b in BUCLES:
		if _i_clip.has(b):
			anim.get_animation(_i_clip[b]).loop_mode = Animation.LOOP_LINEAR


func _normalizar() -> void:
	ajuste.scale *= ALTURA / ALTO_MALLA      # los pies ya están en el suelo (y = 0) y centrada en el origen


# Un clip suyo desde el principio. Devuelve lo que dura (0 si no lo tiene).
func reproducir(clip: String, fundido := 0.15) -> float:
	if anim == null or not _i_clip.has(clip):
		return 0.0
	if esperas != null:
		esperas.cortar()
	var real: String = _i_clip[clip]
	anim.speed_scale = 1.0
	if anim.current_animation == real:
		anim.seek(0.0, true)
	else:
		anim.play(real, fundido)
	return anim.get_animation(real).length


# ---------------------------------------------------------------- combate (los mismos nombres que maga_3d.gd)

func reposo() -> void:
	play("Idle", 0.25)
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3, ["cansada"])
	cansada(_cansada)


func lanzar_magia() -> void:
	gestos.quitar_todos(0.15, ["cansada"])
	reproducir("lanzar_hechizo", 0.15)
	await get_tree().create_timer(LANZA).timeout


func fin_magia() -> void:
	if not _muerta:
		reposo()


# Mientras prepara un hechizo (estado «conjuro» de combate.gd): manos juntas y el astrolabio girando (bucle).
func concentrar() -> void:
	if not _muerta:
		reproducir("concentracion", 0.25)


# Los hechizos largos (el Eclipse): espera con «await» a que se descargue.
func magia_poderosa() -> void:
	gestos.quitar_todos(0.15, ["cansada"])
	reproducir("magia_poderosa", 0.2)
	await get_tree().create_timer(LANZA_PODEROSA).timeout


func preparar_golpe() -> void:
	reproducir("ataque", 0.15)
	get_tree().create_timer(PREPARA_GOLPE).timeout.connect(func():
		if is_instance_valid(self) and anim.current_animation == _i_clip.get("ataque", "") \
				and anim.current_animation_position < IMPACTO_GOLPE:
			anim.speed_scale = 0.0, CONNECT_ONE_SHOT)


func golpear() -> void:
	anim.speed_scale = 1.0
	if anim.current_animation == _i_clip.get("ataque", ""):
		anim.seek(IMPACTO_GOLPE - 0.08, true)


func fin_golpe() -> void:
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(self) and not _muerta and anim.current_animation == _i_clip.get("ataque", ""):
			reposo(), CONNECT_ONE_SHOT)


func herida() -> void:
	if _muerta:
		return
	var d := reproducir("recibir_golpe", 0.06)
	await get_tree().create_timer(maxf(d, 0.3)).timeout
	if not _muerta and anim.current_animation == _i_clip.get("recibir_golpe", ""):
		reposo()


func victoria() -> void:
	if _muerta:
		return
	cansada(false)
	gestos.quitar_todos(0.2)
	mirar(Vector3(-0.2, 0.0, 1.0), 0.4)
	reproducir("victoria", 0.2)


func morir() -> void:
	if _muerta:
		return
	_muerta = true
	gestos.quitar_todos(0.3)
	anim.speed_scale = 1.0
	reproducir("derrota", 0.12)            # acaba de rodillas, en su última pose (no es bucle)


func revivir() -> void:
	if not _muerta:
		return
	_muerta = false
	anim.speed_scale = 1.0
	reposo()
