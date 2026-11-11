extends Node3D
# Bramavidrio, VERSIÓN 3 (V12, noche del 11 al 12/11: «el Excavador», con boca articulada de verdad): el modelo 3D del
# jefe del Mar de Cristal, para el combate y para la exploración (zonas3d/mar_cristal/gusano.gd). Modelo, textura,
# esqueleto y clips hechos con Blender por fuente/crear_bramavidrio3.py (obra propia). Variantes, boca, rig y clips:
# docs/memory/agents/animaciones_v12_bramavidrio3.md.
#
# Es una copia de la v2 (enemigos/bramavidrio/v2/bramavidrio2_3d.gd, que no se toca) con la MISMA interfaz pública, los
# mismos clips, instantes y señales (placas_suelo, fin_succion). Cambian el modelo (enemigos/bramavidrio/v3/: cabeza de
# una sola piel con la boca cerrada en reposo, cejas, brazos con garras clavadas por IK), sus puntos y alcances, y se
# añaden: cierre_boca() y angulo_boca() (para las pruebas: la boca cerrada se mide), puntos_profundidad() (para el orden
# de dibujo frente a los héroes, ver el informe) y, solo para las fotos de las variantes, cargar un GLB de fuera del
# proyecto (Engine.set_meta("bramavidrio3_glb", ruta) y "bramavidrio3_textura").
# Cuál de las versiones se usa lo decide enemigos/bramavidrio/bramavidrio_version.gd (un solo interruptor).
#
# Interfaz (la de la v1):
#
# Misma interfaz que los enemigos 3D del combate (zarzalin_3d.gd, coloso_falla_3d.gd): combate.gd lo crea con .new() y
# ruta_modelo (MODELOS con "tipo": "3d"), y tiene reposo, andar/correr, cansada, herida/recibir_golpe, morir/derrota,
# victoria, revivir, entrada, mirar/mirar_frente, lanzar_magia/fin_magia/punto_magia, preparar_golpe/golpear/fin_golpe,
# play, duracion, tiempo_impacto y alcance. Además:
#   atacar(ataque, al_impactar)  «embestida», «sismico» o «aliento» (y alias: ataque, embestida_espinosa, golpe_fuerte,
#                                terremoto, chorro…); espera con await hasta volver al reposo. Si antes se llamó a
#                                avisar() con ese ataque, sigue desde el aviso sin repetirlo.
#   embestida(cb) / sismico(cb) / aliento(cb)   lo mismo, cada uno con su nombre
#   avisar(ataque)               el aviso del ataque (el combate lo usa un turno antes): la embestida se retrae y fija
#                                al objetivo; el sísmico se alza y ruge; el aliento abre la boca y aspira. Se queda ahí
#                                (en bucle) hasta atacar() o reposo(). cargar(ataque) es lo mismo.
#   emerger() / rugir() / subterraneo() / vibrar()   los clips de la exploración
# Señales:
#   aviso(ataque)       el aviso ya se ve (la embestida fijada, el sísmico erguido, el aliento aspirando)
#   impacto(ataque)     el instante del golpe, UNA vez por ataque: embestida 1,0 s, sísmico 2,533 s, aliento 1,85 s
#                       (el aliento golpea cuando sale el chorro)
#   succion / descarga / fin_descarga   el aliento: empieza a aspirar (0,45), sale el chorro (1,85), acaba (2,6)
#   rompe_arena         emerger: la cabeza rompe la arena (0,233 s)
#   rugido_pico         rugido, sísmico: el instante más fuerte del rugido (para el sonido y la sacudida)
#   caida               derrota: la cabeza da contra el suelo (1,6 s)
#   ataque_terminado(ataque), clip_terminado(clip)
#
# Coordenadas (en metros, con «escala» 1): el origen es el AGUJERO por donde sale; mira a +Z. En reposo la cabeza está
# a 9 m de altura y 9 m por delante del agujero; el cuerpo entero mide 26 m. Lo que queda por debajo de y = 0 está
# enterrado: en la exploración lo tapa el suelo y en el combate (recortar_suelo = true) no se dibuja.
# Luz: las aletas, los ocelos y las grietas brillan según la escala del hueso «brillo» de cada clip; la garganta según
# «garganta»; el chorro según «chorro» (0,01 escondido); el montículo de arena del agujero según «monticulo».

signal aviso(ataque: String)
signal impacto(ataque: String)
signal succion
signal descarga
signal fin_descarga
signal rompe_arena
signal rugido_pico
signal caida
signal ataque_terminado(ataque: String)
signal clip_terminado(clip: String)
signal placas_suelo                          # v2/v3: la Fractura levanta las placas del suelo (en su impacto)
signal fin_succion                           # v2: el Aliento deja de aspirar (1,7 s)

const VERSION := 3
const CARPETA := "res://enemigos/bramavidrio/v3/"
const RUTAS := {"alto": CARPETA + "bramavidrio3.glb", "medio": CARPETA + "bramavidrio3_medio.glb",
	"bajo": CARPETA + "bramavidrio3_bajo.glb"}
const TEXTURAS := {"alto": CARPETA + "bramavidrio3_piel.webp", "medio": CARPETA + "bramavidrio3_piel_medio.webp",
	"bajo": CARPETA + "bramavidrio3_piel_bajo.webp"}
const SH_PIEL := CARPETA + "bramavidrio3_piel.gdshader"
const SH_VIDRIO := CARPETA + "bramavidrio3_vidrio.gdshader"
const SH_CHORRO := CARPETA + "bramavidrio3_chorro.gdshader"
const SH_POLVO := CARPETA + "bramavidrio3_polvo.gdshader"
const RUTA_MODELO := CARPETA + "bramavidrio3.glb"
# combate.gd pasa en ruta_modelo la del alto de la v1 (MODELOS["bramavidrio"]["rutas"]): entonces manda el perfil
const RUTA_ALTO_V1 := "res://enemigos/bramavidrio/bramavidrio.glb"
const ALTURA := 9.0                          # del suelo a lo alto de la cabeza, en reposo (Érebo lo lee)
const CENTRO := Vector3(0.0, 6.0, 4.5)       # el cuello en reposo (efectos y números de daño si falta el esqueleto)
const FRENTE_ENEMIGO := Vector3(0.8, 0.0, 0.6)   # mira a los héroes, como los demás enemigos 3D
const CLIPS := ["reposo", "subterraneo", "aviso", "emerger", "rugido", "ataque", "ataque_sismico", "ataque_aliento",
	"herida", "derrota"]
const BUCLES := ["reposo", "subterraneo"]
# Instantes clave (segundos desde el principio del clip; los escribe crear_bramavidrio.py en bramavidrio_clips.json y
# prueba_bramavidrio_modelo.gd comprueba que coinciden)
const INSTANTES := {
	"aviso": {"vibracion": 0.1, "fin_vibracion": 1.2},
	"emerger": {"rompe_arena": 0.2333, "pico": 0.8667, "erguido": 2.45},
	"rugido": {"inicio_rugido": 0.55, "pico_rugido": 0.8, "fin_rugido": 1.9},
	"ataque": {"anticipacion": 0.2, "fijado": 0.55, "impacto": 1.0},
	"ataque_sismico": {"erguido": 1.0, "rugido": 1.15, "caida": 2.1, "impacto": 2.5333, "placas_suelo": 2.5333,
		"placas_asientan": 3.1, "placas_fin": 3.65},
	"ataque_aliento": {"apertura": 0.3, "inicio_succion": 0.45, "carga_max": 1.6, "fin_succion": 1.7, "descarga": 1.85,
		"fin_descarga": 2.6},
	"herida": {"golpe": 0.1},
	"derrota": {"dolor": 0.5, "caida": 1.6, "apagado": 3.0},
}
# Los tres ataques: su clip, el instante del golpe y el tramo que se repite mientras avisa (avisar()).
const ATAQUES := {
	"embestida": {"clip": "ataque", "impacto": 1.0, "aviso": 0.55, "espera": [0.6, 0.78]},
	"sismico": {"clip": "ataque_sismico", "impacto": 2.5333, "aviso": 1.0, "espera": [1.3, 2.0]},
	"aliento": {"clip": "ataque_aliento", "impacto": 1.85, "aviso": 0.45, "espera": [1.45, 1.58]},
}
# Cuánto llega por delante del agujero en el impacto (m; bramavidrio_clips.json: «alcance»). El aliento: hasta dónde
# llega el chorro.
const ALCANCES := {"embestida": 12.73, "sismico": 18.21, "aliento": 18.64}
const ALIAS := {"ataque": "embestida", "embestida_espinosa": "embestida", "colmillo_lateral": "embestida",
	"golpe": "embestida", "mordisco": "embestida", "golpe_fuerte": "sismico", "terremoto": "sismico",
	"sismo": "sismico", "ataque_sismico": "sismico", "chorro": "aliento", "ataque_aliento": "aliento",
	"soplo": "aliento"}
# Puntos de la cabeza en la pose de enlace (Godot: x, z de Blender, -y de Blender; crear_bramavidrio3.py, P_HOCICO…;
# bramavidrio3_clips.json, «puntos»)
const P_HOCICO := Vector3(0.0, -0.142, 5.041)
const P_BOCA := Vector3(0.0, -0.391, 3.692)   # el centro de la boca (de donde sale el chorro)
const P_GARGANTA := Vector3(0.0, -0.284, 0.284)  # el fondo de la boca, donde empieza la garganta
# Un punto de la línea de la boca, delante, que es del labio (cabeza) y del borde de la mandíbula a la vez: con la boca
# cerrada los dos coinciden (cierre_boca() = 0)
const P_CIERRE := Vector3(0.0, -0.383, 3.976)
# Mezclas entre clips (segundos)
const MEZCLA_REPOSO := 0.35
const MEZCLA_ATAQUE := 0.18
const MEZCLA_GOLPE := 0.08
const RITMO_CANSADO := 0.8

# Escala del combate: _crear_rig_3d (combate.gd) pone su cámara ortográfica a 6 m del origen, y a escala 1 la cabeza
# (9 m por delante en reposo, hasta 17 m en el sísmico) quedaría detrás de la cámara. A 0,32 todo cabe: reposo 2,9 m de
# alto y alcance máximo 5,4 m. La exploración (gusano.gd) lo usa a escala 1.
const ESCALA_COMBATE := 0.32

@export var ruta_modelo := ""                 # vacío o la del alto: la versión de la calidad en uso (alto, medio, bajo)
@export var calidad := ""                     # vacío: prototipos/calidad_proto.gd actual(); «alto»… la fuerza
@export var escala := -1.0                    # < 0: automática (1 en la exploración, ESCALA_COMBATE en el combate)
@export var recortar_suelo := true            # no dibujar lo enterrado (combate); la exploración lo apaga (lo tapa el suelo)
@export var ocultar_monticulo := false        # sin la arena revuelta del agujero
# El montículo en el combate: más pequeño y del tono del suelo (pasada 2: a tamaño entero y naranja parecía un plato,
# como la foto que se corrigió en la v581). < 0: automático (1 en la exploración, 0,55 en el combate).
@export var escala_monticulo := -1.0
const MONTICULO_COMBATE := 0.55
const TONO_ARENA_COMBATE := 0.62
@export var en_exploracion := false           # al empezar: bajo la arena (subterraneo) en vez del reposo
var rutas_extra: Array = []

var anim: AnimationPlayer
var skel: Skeleton3D
var caida_n: Node3D     # mismo esquema que coloso_falla_3d.gd: caida > pivote (mira) > ajuste (escala) > modelo
var pivote: Node3D
var ajuste: Node3D
var nombres := {}
var calidad_usada := ""
var _yaw0 := 0.0
var _tw_giro: Tween
var _muerta := false
var _cansada := false
var _atacando := false
var _entrando := false
var _clip := ""
var _eventos: Array = []
var _espera: Array = []                        # [desde, hasta] del tramo que se repite al avisar
var _avisado := ""                            # el ataque que está avisando
var _h := {}                                   # índices de huesos: brillo, garganta, chorro, monticulo, cabeza, mandibula
var _mats := {"piel": [], "vidrio": [], "garganta": [], "chorro": [], "polvo": []}
var _suelo := INF


func _ready() -> void:
	process_priority = 10                    # después del AnimationPlayer: lee la escala de los huesos de este fotograma
	caida_n = Node3D.new()
	caida_n.name = "Caida"
	pivote = Node3D.new()
	pivote.name = "Pivote"
	ajuste = Node3D.new()
	ajuste.name = "Ajuste"
	var previos := get_children()
	add_child(caida_n)
	caida_n.add_child(pivote)
	pivote.add_child(ajuste)
	if previos.is_empty():
		_cargar_modelo()
	else:
		for c in previos:
			c.reparent(ajuste, false)
	if escala < 0.0:
		escala = 1.0 if en_exploracion else ESCALA_COMBATE
	if escala_monticulo < 0.0:
		escala_monticulo = 1.0 if en_exploracion else MONTICULO_COMBATE
	ajuste.scale = Vector3.ONE * escala
	anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	skel = _buscar_esqueleto(self)
	if anim == null or skel == null:
		push_warning("bramavidrio3_3d: no encuentro el modelo, el AnimationPlayer o el esqueleto")
		return
	for n in BUCLES:
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in CLIPS:
		nombres[n] = n
	nombres["Idle"] = "reposo"
	for h in ["brillo", "garganta", "chorro", "monticulo", "succion", "cabeza", "mandibula", "col_05"]:
		_h[h] = skel.find_bone(h)
	_preparar_materiales()
	mirar(Vector3.BACK if en_exploracion else FRENTE_ENEMIGO, 0.0)   # en la exploración lo orienta quien lo coloca
	if en_exploracion:
		subterraneo()
	else:
		reposo()


func calidad_en_uso() -> String:
	if calidad != "":
		return calidad
	if ResourceLoader.exists("res://prototipos/calidad_proto.gd"):
		return str(load("res://prototipos/calidad_proto.gd").actual())
	return "alto"


func _cargar_modelo() -> void:
	calidad_usada = calidad_en_uso()
	if not RUTAS.has(calidad_usada):
		calidad_usada = "alto"
	var lista: Array = []
	if ruta_modelo != "" and ruta_modelo != RUTAS["alto"] and ruta_modelo != RUTA_ALTO_V1:   # la del alto: manda el perfil
		lista.append(ruta_modelo)
		for c in RUTAS:                                  # la textura que va con el modelo pedido
			if RUTAS[c] == ruta_modelo:
				calidad_usada = c
	lista.append(RUTAS[calidad_usada])
	lista.append_array(rutas_extra)
	if Engine.has_meta("bramavidrio3_glb"):              # solo las fotos de las variantes (un GLB de fuera del proyecto)
		var ext := _cargar_glb_externo(str(Engine.get_meta("bramavidrio3_glb")))
		if ext != null:
			ajuste.add_child(ext)
			calidad_usada = "alto"
			return
	for r in lista:
		if ResourceLoader.exists(r):
			var escena = load(r)
			if escena is PackedScene:
				ajuste.add_child(escena.instantiate())
				return
	push_warning("bramavidrio3_3d: no encuentro el modelo en %s" % str(lista))


# Un GLB de fuera de res:// (las variantes que se comparan en las fotos; nunca en el juego).
static func _cargar_glb_externo(ruta: String) -> Node:
	var doc := GLTFDocument.new()
	var estado := GLTFState.new()
	if doc.append_from_file(ruta, estado) != OK:
		push_warning("bramavidrio3_3d: no puedo leer " + ruta)
		return null
	return doc.generate_scene(estado, 30.0)


func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _buscar_esqueleto(c)
		if s != null:
			return s
	return null


static func _shader(ruta: String, defines: Array) -> Shader:
	var s: Shader = load(ruta)
	if defines.is_empty():
		return s
	var codigo := s.code
	var pre := ""
	for d in defines:
		pre += "#define %s\n" % d
	var i := codigo.find("\n", codigo.find("shader_type"))
	var nuevo := Shader.new()
	nuevo.code = codigo.substr(0, i + 1) + pre + codigo.substr(i + 1)
	return nuevo


# Los materiales de cada superficie, por su nombre (los del GLB solo las separan), propios de este gusano: cada uno
# brilla por su cuenta.
func _preparar_materiales() -> void:
	var rec: Array = ["RECORTE"] if recortar_suelo else []
	var tex: Texture2D = load(TEXTURAS.get(calidad_usada, TEXTURAS["alto"])) if ResourceLoader.exists(TEXTURAS.get(calidad_usada, "")) else null
	if Engine.has_meta("bramavidrio3_textura"):          # la textura de la variante de las fotos
		var img := Image.load_from_file(str(Engine.get_meta("bramavidrio3_textura")))
		if img != null:
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	var sh_piel := _shader(SH_PIEL, rec)
	var sh_vidrio := _shader(SH_VIDRIO, rec)
	var sh_garganta := _shader(SH_VIDRIO, ["GARGANTA"])
	var sh_chorro: Shader = load(SH_CHORRO)
	var sh_polvo: Shader = load(SH_POLVO)
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(i)
			var nombre := orig.resource_name if orig != null else "piel"
			var mat := ShaderMaterial.new()
			match nombre:
				"vidrio":
					mat.shader = sh_vidrio
					_mats["vidrio"].append(mat)
				"garganta":
					mat.shader = sh_garganta
					_mats["garganta"].append(mat)
				"chorro":
					mat.shader = sh_chorro
					_mats["chorro"].append(mat)
				"polvo":                                 # v2/v3: la arena que aspira
					mat.shader = sh_polvo                # transparente: no entra en la pasada de sombras
					_mats["polvo"].append(mat)
				_:                                       # piel y arena (el montículo: la arena del mismo atlas)
					mat.shader = sh_piel
					mat.set_shader_parameter("textura", tex)
					if nombre == "arena" and not en_exploracion:
						mat.set_shader_parameter("tono", TONO_ARENA_COMBATE)
					_mats["piel"].append(mat)
			m.set_surface_override_material(i, mat)


# ---------------------------------------------------------------- cada fotograma

func _process(delta: float) -> void:
	if anim == null or skel == null:
		return
	var actual := String(anim.current_animation)
	if not _espera.is_empty() and actual == _clip and anim.current_animation_position > _espera[1]:
		anim.seek(_espera[0], true)                       # avisando: repite el tramo hasta atacar()
	if _h["monticulo"] >= 0:
		if ocultar_monticulo:
			skel.set_bone_pose_scale(_h["monticulo"], Vector3.ONE * 0.01)
		elif escala_monticulo != 1.0:
			skel.set_bone_pose_scale(_h["monticulo"], skel.get_bone_pose_scale(_h["monticulo"]) * escala_monticulo)
	_actualizar_luz()
	if _eventos.is_empty() or actual != _clip:
		return
	var pos := anim.current_animation_position + delta * anim.speed_scale * 0.5
	while not _eventos.is_empty() and pos >= _eventos[0][0]:
		var e: Array = _eventos.pop_front()
		(e[1] as Callable).call()


func _escala_hueso(nombre: String) -> float:
	var i: int = _h.get(nombre, -1)
	return skel.get_bone_pose_scale(i).x if i >= 0 else 1.0


# La luz sigue a la escala de sus huesos en cada clip (más tenue con poca vida).
func _actualizar_luz() -> void:
	var b := _escala_hueso("brillo") * (0.75 if _cansada else 1.0)
	var g := _escala_hueso("garganta")
	var c := _escala_hueso("chorro")
	var suelo := global_position.y if recortar_suelo else -INF
	for m in _mats["piel"]:
		m.set_shader_parameter("energia", b)
		if recortar_suelo and suelo != _suelo:
			m.set_shader_parameter("suelo", suelo)
	for m in _mats["vidrio"]:
		m.set_shader_parameter("energia", b)
		if recortar_suelo and suelo != _suelo:
			m.set_shader_parameter("suelo", suelo)
	for m in _mats["garganta"]:
		m.set_shader_parameter("energia", g)
	# En el combate, el chorro 3D del modelo salía hacia abajo, hacia la cámara (no hacia los héroes): allí lo dibuja
	# combate_bramavidrio.gd (2D, hacia el grupo) y este se esconde (coordinador, 11/11). En la exploración, sí se ve.
	for m in _mats["chorro"]:
		m.set_shader_parameter("fuerza", c if c > 0.03 and en_exploracion else 0.0)
	var a := _escala_hueso("succion")                    # v2: la arena que sube a la boca (también en el combate)
	for m in _mats["polvo"]:
		m.set_shader_parameter("fuerza", a if a > 0.03 else 0.0)
		if recortar_suelo and suelo != _suelo:
			m.set_shader_parameter("suelo", suelo)
	_suelo = suelo


func energia() -> Dictionary:
	return {"brillo": _escala_hueso("brillo"), "garganta": _escala_hueso("garganta"), "chorro": _escala_hueso("chorro"),
		"monticulo": _escala_hueso("monticulo"), "succion": _escala_hueso("succion")}


# ---------------------------------------------------------------- clips y anclas

func _reproducir(clip: String, mezcla: float, desde := 0.0, eventos: Array = []) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	_eventos = eventos.duplicate()
	_eventos.sort_custom(func(a, b): return a[0] < b[0])
	_eventos = _eventos.filter(func(e): return e[0] >= desde)
	_clip = clip
	_espera = []
	anim.speed_scale = RITMO_CANSADO if (_cansada and clip == "reposo") else 1.0
	if String(anim.current_animation) == clip:
		if not (clip in BUCLES and desde == 0.0):
			anim.seek(desde, true)
	else:
		anim.play(clip, mezcla)
		if desde > 0.0:
			anim.seek(desde, true)


func _esperar_clip(clip: String) -> void:
	while is_inside_tree() and anim != null and _clip == clip and String(anim.current_animation) == clip:
		await get_tree().process_frame


func play(nombre: String, transicion := 0.2) -> void:
	_reproducir(nombres.get(nombre, nombre), transicion)


func duracion(clip: String) -> float:
	return anim.get_animation(clip).length if anim != null and anim.has_animation(clip) else 0.0


func nombre_ataque(ataque: String) -> String:
	return ataque if ATAQUES.has(ataque) else str(ALIAS.get(ataque, ataque))


# Segundos desde que se llama a atacar() (sin aviso previo) hasta su impacto.
func tiempo_impacto(ataque: String) -> float:
	var a := nombre_ataque(ataque)
	return ATAQUES[a]["impacto"] if ATAQUES.has(a) else 0.0


# Cuánto llega por delante del agujero en el impacto, en metros de este nodo (con «escala»).
func alcance(ataque: String) -> float:
	var a := nombre_ataque(ataque)
	return ALCANCES.get(a, 0.0) * escala


# ---------------------------------------------------------------- lo que pide el combate

func reposo() -> void:
	if _muerta or anim == null:
		return
	_avisado = ""
	_reproducir("reposo", MEZCLA_REPOSO)


# El gusano no se desplaza en el combate: se queda en su agujero y ataca desde ahí (su cuello llega lejos).
func andar() -> void:
	reposo()


func correr() -> void:
	reposo()


func cansada(si: bool) -> void:
	_cansada = si
	if not _muerta and anim != null and _clip == "reposo":
		anim.speed_scale = RITMO_CANSADO if si else 1.0


func herida() -> void:
	recibir_golpe()


func morir() -> void:
	derrota()


func victoria() -> void:
	rugir()


func revivir() -> void:
	if not _muerta:
		return
	_muerta = false
	reposo()


# El aviso del ataque: lo prepara y se queda repitiendo ese tramo hasta atacar() o reposo(). «aviso» sale una vez,
# cuando la pose ya se lee.
func avisar(ataque := "embestida") -> void:
	if _muerta or anim == null or _atacando:
		return
	var a := nombre_ataque(ataque)
	if a in ["subterraneo", "temblor", "vibrar"]:
		await vibrar()
		return
	if not ATAQUES.has(a):
		a = "embestida"
	var d: Dictionary = ATAQUES[a]
	_avisado = a
	var hecho := [false]
	var dar := func():
		if not hecho[0]:
			hecho[0] = true
			aviso.emit(a)
	var ev: Array = [[d["aviso"], dar]]
	if a == "aliento":
		ev.append([INSTANTES["ataque_aliento"]["inicio_succion"], func(): succion.emit()])
	if a == "sismico":
		ev.append([INSTANTES["ataque_sismico"]["rugido"] + 0.1, func(): rugido_pico.emit()])
	_reproducir(d["clip"], MEZCLA_ATAQUE, 0.0, ev)
	_espera = d["espera"]
	await _esperar_hasta(d["aviso"] + 0.05)
	dar.call()


func cargar(ataque := "embestida") -> void:
	await avisar(ataque)


func _esperar_hasta(segundos: float) -> void:
	while is_inside_tree() and anim != null and String(anim.current_animation) == _clip \
			and anim.current_animation_position < segundos:
		await get_tree().process_frame


# Ataque: emite impacto(ataque) y llama a al_impactar una sola vez, en el ancla del clip; vuelve al reposo y emite
# ataque_terminado. Si cae derrotado a medias, no golpea; si otro clip lo corta antes del golpe, el daño se resuelve
# igualmente, una vez.
func atacar(ataque := "embestida", al_impactar := Callable()) -> void:
	var a := nombre_ataque(ataque)
	if _muerta or anim == null or not ATAQUES.has(a):
		return
	var d: Dictionary = ATAQUES[a]
	var clip: String = d["clip"]
	if not anim.has_animation(clip):
		return
	_atacando = true
	var hecho := [false]
	var golpe := func():
		if hecho[0] or _muerta:
			return
		hecho[0] = true
		impacto.emit(a)
		if al_impactar.is_valid():
			al_impactar.call()
	var ev: Array = [[d["impacto"], golpe]]
	if a == "aliento":
		var i: Dictionary = INSTANTES["ataque_aliento"]
		ev.append([i["fin_succion"], func(): fin_succion.emit()])
		ev.append([i["descarga"], func(): descarga.emit()])
		ev.append([i["fin_descarga"], func(): fin_descarga.emit()])
	if a == "sismico":
		ev.append([INSTANTES["ataque_sismico"]["rugido"] + 0.1, func(): rugido_pico.emit()])
		ev.append([INSTANTES["ataque_sismico"]["placas_suelo"], func(): if not _muerta: placas_suelo.emit()])
	if _avisado == a and _clip == clip and String(anim.current_animation) == clip:
		_espera = []                                         # sigue desde el aviso, sin repetirlo
		_eventos = ev.filter(func(e): return e[0] >= anim.current_animation_position)
		_eventos.sort_custom(func(x, y): return x[0] < y[0])
	else:
		if a == "aliento":
			ev.append([INSTANTES["ataque_aliento"]["inicio_succion"], func(): succion.emit()])
		_reproducir(clip, MEZCLA_ATAQUE, 0.0, ev)
	_avisado = ""
	await _esperar_clip(clip)
	if not hecho[0] and not _muerta:
		golpe.call()
	_atacando = false
	if _muerta:
		return
	if _clip == clip:
		reposo()
	ataque_terminado.emit(a)


func embestida(al_impactar := Callable()) -> void:
	await atacar("embestida", al_impactar)


func sismico(al_impactar := Callable()) -> void:
	await atacar("sismico", al_impactar)


func aliento(al_impactar := Callable()) -> void:
	await atacar("aliento", al_impactar)


# Alias del Coloso (golpe_fuerte = el sísmico) y del combate genérico.
func golpe_fuerte(al_impactar := Callable()) -> void:
	await atacar("sismico", al_impactar)


func ataque(al_impactar := Callable()) -> void:
	await atacar("embestida", al_impactar)


func recibir_golpe() -> void:
	if _muerta or anim == null or _atacando or _entrando or _avisado != "":
		return
	_reproducir("herida", MEZCLA_GOLPE)
	await _esperar_clip("herida")
	if _muerta or _clip != "herida":
		return
	reposo()


# Se retuerce, se desploma de lado (caida) y se hunde a medias con la luz apagándose; se queda así.
func derrota() -> void:
	if _muerta:
		return
	_muerta = true
	_avisado = ""
	if anim == null:
		return
	_reproducir("derrota", 0.15, 0.0, [[INSTANTES["derrota"]["caida"], func(): caida.emit()]])
	await _esperar_clip("derrota")
	clip_terminado.emit("derrota")


# ---------------------------------------------------------------- la exploración (y la entrada del combate)

# Bajo la arena, avanzando (en el sitio: quien lo mueve es gusano.gd). Solo asoman las aletas del lomo.
func subterraneo() -> void:
	if anim == null:
		return
	_muerta = false
	_reproducir("subterraneo", 0.3)


# La vibración del aviso, bajo la arena; vuelve a subterraneo. Emite clip_terminado("aviso").
func vibrar() -> void:
	if anim == null:
		return
	_reproducir("aviso", 0.2)
	await _esperar_clip("aviso")
	if _clip == "aviso":
		_reproducir("subterraneo", 0.2)
	clip_terminado.emit("aviso")


# Revienta la arena y se alza (rompe_arena), se cuelga en lo alto y baja la cabeza al reposo.
func emerger() -> void:
	if anim == null:
		return
	_muerta = false
	_entrando = true
	_reproducir("emerger", 0.1, 0.0, [[INSTANTES["emerger"]["rompe_arena"], func(): rompe_arena.emit()]])
	await _esperar_clip("emerger")
	_entrando = false
	if _clip == "emerger":
		_reproducir("reposo", 0.2)
	clip_terminado.emit("emerger")


func rugir() -> void:
	if _muerta or anim == null:
		return
	_reproducir("rugido", 0.2, 0.0, [[INSTANTES["rugido"]["pico_rugido"], func(): rugido_pico.emit()]])
	await _esperar_clip("rugido")
	if _clip == "rugido" and not _muerta:
		reposo()
	clip_terminado.emit("rugido")


# Al empezar el combate: emerge de la arena y queda en reposo. Emite clip_terminado("entrada").
func entrada() -> void:
	if _muerta or anim == null:
		return
	await emerger()
	clip_terminado.emit("entrada")


func mirar(dir: Vector3, dur := 0.2) -> void:
	if pivote == null:
		return
	var meta := atan2(dir.x, dir.z) - _yaw0
	var actual := pivote.rotation.y
	meta = actual + wrapf(meta - actual, -PI, PI)
	if _tw_giro != null and _tw_giro.is_valid():
		_tw_giro.kill()
	if dur <= 0.0:
		pivote.rotation.y = meta
		return
	_tw_giro = create_tween()
	_tw_giro.tween_property(pivote, "rotation:y", meta, dur)


func mirar_frente(dur := 0.25) -> void:
	mirar(FRENTE_ENEMIGO, dur)


# Magia: abre la boca y aspira un momento (el principio del aliento); la luz nace en la garganta.
func lanzar_magia() -> void:
	if _muerta or anim == null:
		return
	_reproducir("ataque_aliento", 0.2)
	_espera = ATAQUES["aliento"]["espera"]
	await get_tree().create_timer(0.6).timeout


func fin_magia() -> void:
	reposo()


func preparar_golpe() -> void:
	atacar("embestida")


func golpear() -> void:
	pass


func fin_golpe() -> void:
	pass


func punto_magia() -> Vector3:
	return boca()


# ---------------------------------------------------------------- puntos en el mundo

func _punto(hueso: String, p_reposo: Vector3, si_no: Vector3) -> Vector3:
	if skel == null:
		return si_no
	var i := skel.find_bone(hueso)
	if i < 0:
		return si_no
	var local := skel.get_bone_global_rest(i).affine_inverse() * p_reposo
	return skel.global_transform * (skel.get_bone_global_pose(i) * local)


# La punta del hocico (donde golpea la embestida).
func cabeza() -> Vector3:
	return _punto("cabeza", P_HOCICO, global_position + Vector3(0, ALTURA, ALCANCES["embestida"] * 0.8) * escala)


# El centro de la boca (de donde sale el chorro y nace la magia).
func boca() -> Vector3:
	return _punto("cabeza", P_BOCA, global_position + Vector3(0, ALTURA - 1.0, 8.0) * escala)


# El fondo de la garganta (la luz mineral): el «corazón» para Érebo y los efectos.
func nucleo() -> Vector3:
	return _punto("cabeza", P_GARGANTA, global_position + CENTRO * escala)


func corazon() -> Vector3:
	return nucleo()


# v3: cuánto está abierta la boca (en metros, a escala 1): la distancia entre el labio y el borde de la mandíbula en
# P_CIERRE. 0 con la boca cerrada.
func cierre_boca() -> float:
	if skel == null:
		return 0.0
	return _punto("cabeza", P_CIERRE, Vector3.ZERO).distance_to(_punto("mandibula", P_CIERRE, Vector3.ZERO)) / maxf(0.001, escala)


# v3: cuántos grados está girada la mandíbula respecto de su reposo (0 cerrada). Que nunca cierre «de más» (hacia
# dentro del cráneo) lo dice borde_sobre_labio().
func angulo_boca() -> float:
	if skel == null:
		return 0.0
	var i := skel.find_bone("mandibula")
	var q: Quaternion = skel.get_bone_pose_rotation(i)
	var r: Quaternion = skel.get_bone_rest(i).basis.get_rotation_quaternion()
	return rad_to_deg((r.inverse() * q).get_angle())


# v3: cuánto sube el borde de la mandíbula por encima del labio en P_CIERRE, en el marco de la cabeza (m, escala 1):
# 0 con la boca cerrada, negativo al abrir; positivo querría decir que la mandíbula se mete en el cráneo.
func borde_sobre_labio() -> float:
	if skel == null:
		return 0.0
	var ic := skel.find_bone("cabeza")
	var cab := skel.global_transform * skel.get_bone_global_pose(ic)
	var lab := cab.affine_inverse() * _punto("cabeza", P_CIERRE, Vector3.ZERO)
	var bor := cab.affine_inverse() * _punto("mandibula", P_CIERRE, Vector3.ZERO)
	var arriba := (skel.get_bone_global_rest(ic).basis.inverse() * Vector3.UP).normalized()
	return (bor - lab).dot(arriba)                      # (el marco del hueso ya quita la escala)


# v3: puntos del cuerpo en el mundo para decidir el orden de dibujo frente a los héroes (cada uno con su punto sobre la
# arena): el hocico, la barbilla, el cuello en varios tramos y las garras. combate_bramavidrio.gd puede ordenarse con el
# más cercano a la cámara que caiga sobre cada héroe (ver docs/memory/agents/animaciones_v12_bramavidrio3.md).
func puntos_profundidad() -> PackedVector3Array:
	var pts := PackedVector3Array()
	if skel == null:
		return pts
	pts.append(cabeza())
	pts.append(_punto("mandibula", P_CIERRE, cabeza()))
	for h in ["col_01", "col_03", "col_05", "col_07", "col_09", "mano_izq", "mano_der"]:
		var i := skel.find_bone(h)
		if i >= 0:
			pts.append(skel.global_transform * skel.get_bone_global_pose(i).origin)
	return pts


# v3: el ORDEN DE DIBUJO frente a los héroes, en el combate. Causa del fallo (combate.gd, _crear_rig_3d y
# _crear_interfaz): cada luchador 3D se dibuja en su propia ventana 3D (own_world_3d, fondo transparente) y esa imagen
# va a la escena 2D como un Sprite2D; no hay profundidad compartida, así que manda el orden del árbol y el z_index. El
# gusano se crea ANTES que los héroes (for f in enemigos + heroes) y queda siempre detrás, aunque su cabeza o su cuello
# pasen por delante de ellos; además, el héroe que actúa sube a z_index 5 (_anim_fisico_3d, _anim_salto_3d…) y se pinta
# encima de todo. combate_bramavidrio.gd solo lo adelanta (_al_frente) en la embestida y la caída de la Fractura, y solo
# mirando el hocico. Esto mira varios tramos del cuerpo: lo pone delante de cada héroe al que tapa un tramo más cercano
# a la cámara (su sombra en la arena más abajo en pantalla que los pies del héroe) que cae encima de él, y le da el
# z_index más alto de esos héroes (el 5 del que actúa). Sin héroes tapados, vuelve a su sitio y a z_index 0.
# Lo llama combate_bramavidrio.gd en cada fotograma (cambio propuesto en el informe); aquí no se toca el combate.
const RADIO_HEROE := 85.0                     # medio ancho de un héroe en la escena del combate (px)
var _indice_combate := -1


func ordenar_en_combate(c: Node, f: Dictionary) -> void:
	var rig = f.get("rig")
	if rig == null or not is_instance_valid(rig) or rig.get_parent() != c.escena or not f.has("cam3d"):
		return
	var spr: Sprite2D = f["partes"]["sprite"]
	var cam: Camera3D = f["cam3d"]
	var suelo := global_position.y
	var pts := puntos_profundidad()
	var marcas: Array = []
	for w in pts:
		marcas.append([c.escena.to_local(spr.to_global(cam.unproject_position(w))),
			c.escena.to_local(spr.to_global(cam.unproject_position(Vector3(w.x, suelo, w.z))))])
	var tras := -1
	var z := 0
	for h in c.heroes:
		if not h.has("rig") or not is_instance_valid(h["rig"]) or h["rig"].get_parent() != c.escena:
			continue
		var pie: Vector2 = c._suelo_de(h)
		for m in marcas:
			if absf((m[0] as Vector2).x - pie.x) < RADIO_HEROE and (m[1] as Vector2).y > pie.y + 4.0:
				tras = maxi(tras, h["rig"].get_index())
				z = maxi(z, h["rig"].z_index)
				break
	if _indice_combate < 0:
		_indice_combate = rig.get_index()
	var actual: int = rig.get_index()
	var meta := _indice_combate
	if tras >= 0:
		meta = tras if actual < tras else tras + 1
	if meta != actual:
		c.escena.move_child(rig, meta)
	rig.z_index = z


# El centro del cuello (números de daño, efectos sobre el cuerpo).
func centro() -> Vector3:
	if skel == null or _h.get("col_05", -1) < 0:
		return global_position + CENTRO * escala
	return skel.global_transform * skel.get_bone_global_pose(_h["col_05"]).origin
