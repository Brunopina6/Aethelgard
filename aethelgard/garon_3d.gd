extends "res://maga_3d.gd"
# Garon «El Muro» Steel, el soldado (modelo «Crimson Helm Guardian» de Meshy, esqueleto Mixamo).
#
# Al cargar se RENOMBRAN las animaciones de Meshy dentro de Godot (AnimationLibrary):
#   Thoughtful_Walk            -> Reposo         de pie, cambiando el peso de pierna (sin avanzar)
#   Walking                    -> Andar
#   Running                    -> Correr
#   Sword_Judgment             -> Juicio         salta y cae con un tajo (golpe a 1,10 s)
#   Double_Blade_Spin          -> Giro           avanza girando, dos tajos (0,90 s y 1,50 s)
#   Shot_in_the_Back_and_Fall  -> Morir          cae de bruces
# No trae animación de golpe recibido: herida() usa el gesto de gestos_3d.gd.
# A todas se les quita el avance de la cadera: el combate es quien mueve a Garon.
#
# Armas y capa (todas opcionales, se cargan si existen):
#   RUTA_ESPADA  espada en la mano derecha. Si no hay, se dibuja una espada provisional.
#   RUTA_ESCUDO  escudo en el antebrazo izquierdo. Si no hay, va sin escudo.
#   RUTA_CAPA    capa enganchada a la espalda (Spine2) que ondea con el viento por shader.
# Convención de los modelos: espada con la empuñadura en el origen y la hoja hacia +Y, filo hacia +X;
# escudo mirando hacia +Z (su cara delantera); capa con la parte de los hombros arriba (+Y).
# Si alguno sale girado, corrígelo con GIRO_* (grados).

const RUTA_ESPADA := "res://hoja_infernal.obj"   # si el inventario no le da otra (inventario.gd, «arma» de Garon)
const RUTA_ESPADA_IZQ := ""             # segunda espada (si se deja vacío usa la misma que la derecha)
const DOS_ESPADAS := true               # Garon lucha con dos espadas (menú Esgrima)
const RUTA_ESCUDO := ""                 # p. ej. "res://garon_escudo.glb"
const RUTA_CAPA := "res://garon_capa.png"   # imagen de la capa (se hace una tela curva) o un modelo .glb/.obj
const LARGO_ESPADA := 1.1               # metros (Garon mide 1,7)
const AGARRE_ESPADA := 0.12             # dónde la agarra: 0 = pomo, 1 = punta
const TAM_ESCUDO := 0.65
const LARGO_CAPA := 1.05                # de los hombros al borde roto (medidas de un cuerpo de 1,7 m de proporciones
const ANCHO_CAPA := 0.74                # reales; Garon es chibi: _medidas_capa las ajusta a su esqueleto)
const CURVA_CAPA := 0.2                # cuánto se curva hacia atrás (envuelve la espalda)
# 13/11/2026 («la capa de Garon está mal puesta»): la capa se mide con SU esqueleto y sigue al pecho.
#   Antes medía 1,05 × 0,74 m pensados para un cuerpo de 1,7 m de proporciones reales, pero Garon es chibi (hombros a
#   1,05 m del suelo, cabeza de 0,55 m): la capa atravesaba el suelo 15-22 cm y sobresalía a los lados del cuerpo
#   (0,81 m de ancho para unos hombros de 0,21 m entre articulaciones). Ahora: largo = CAPA_LARGO_ALTO × la altura del
#   cuello sobre los pies (acaba a la altura de los tobillos) y ancho = CAPA_ANCHO_HOMBROS × la distancia entre hombros;
#   la curva y la caída hacia atrás, en la misma proporción que antes (el diseño no cambia, solo la talla).
#   Y se orientaba con el «adelante» del esqueleto en reposo, no con el del pecho: no seguía a los hombros (47° girada
#   en la guardia del original, hasta 87° en Juicio) y en el Giro y en el derribo de los v2 quedaba POR DELANTE del
#   cuerpo. Ahora toma el giro del pecho (Spine2 respecto a su reposo) y lo acerca a la línea de los hombros
#   (CAPA_HOMBROS), cuelga un poco hacia el suelo al inclinarse (solo hacia atrás, nunca hacia el cuerpo) y nunca baja
#   del plano de los pies (tumbado, en el derribo de los v2, se quedaba de pie en el aire o se metía 1 m en el suelo).
#   Medidas antes y después: D:\REBELUM_diagnosticonimaciones6-11-13\capa_garon\ (pruebas/fotos_capa_garon.gd).
const CAPA_LARGO_ALTO := 0.88          # largo / (altura del cuello sobre los dedos de los pies)
const CAPA_ANCHO_HOMBROS := 2.2        # ancho arriba / distancia entre las articulaciones de los hombros
const CAPA_GRAVEDAD := 0.55            # cuánto cuelga hacia el suelo al inclinarse (0 = rígida con el pecho)
const CAPA_GRAVEDAD_MAX := 60.0        # grados como mucho
const CAPA_HOMBROS := 0.6              # cuánto sigue a la línea de los hombros (el resto, al pecho): arriba va con los
                                       # hombros y abajo no sale de lado cuando Garon gira el tronco (su guardia)
const CAPA_SUELO := 0.03               # metros por encima del suelo que deja como poco el borde de abajo
const GIRO_ESPADA := Vector3.ZERO
const GIRO_ESCUDO := Vector3.ZERO
const GIRO_CAPA := Vector3.ZERO
const BAJAR_CAPA := 0.02                # cuánto baja la capa respecto al hueso Spine2 (metros)
const ATRAS_CAPA := 0.14                # cuánto se separa de la espalda
# 14/11/2026 (fase 6 del encargo del 13/11): la capa ARTICULADA (capa_garon.gd: la misma tela con huesos propios,
# sujeta a la espalda real de cada variante, movimiento progresivo y sin atravesar cuerpo, brazos ni espadas). Opción
# APAGADA por defecto (la de siempre, «rígida», queda igual y de respaldo). Se enciende con:
#   - Engine.set_meta("capa_garon", "articulada")   (antes de crear a Garon; "rigida" la apaga)
#   - el argumento de usuario «capa_articulada»     (godot ... -- capa_articulada)
#   - Ajustes: user://ajustes.cfg, [garon] capa = "articulada"
#   - CAPA_ARTICULADA_POR_DEFECTO = true            (cuando se apruebe tras verla en el Redmi)
const CAPA_ARTICULADA_POR_DEFECTO := false
const CapaArticulada := preload("res://capa_garon.gd")

const RENOMBRAR := {
	"thoughtful": "Paseo",          # parece que anda sin avanzar: no sirve de reposo en combate
	"walking": "Andar",
	"running": "Correr",
	"sword_judgment": "Juicio",
	"blade_spin": "Giro",
	"shot_in_the_back": "Morir",
}
# Guardia de combate (Meshy no trae una animación de estar quieto): se hace con dos instantes del
# principio de «Juicio», de pie con la espada baja. Va despacio de una pose a la otra y vuelve: cambia
# el peso y sube un poco la espada, sin mover los pies. Encima, la respiración de gestos_3d.gd.
const GUARDIA_A := 0.0          # segundos de «Juicio» de la primera pose
const GUARDIA_B := 0.25         # y de la segunda
const GUARDIA_MEZCLA := 0.7     # cuánto se acerca a la segunda pose (1 = del todo)
const GUARDIA_PERIODO := 3.2    # segundos de ida y vuelta
const RUTA_ESPADAS := "res://garon_espadas.res"   # GuardiaDoble, AvanzarDoble, RetrocederDoble
const GOLPES_JUICIO := [1.10]
const FIN_JUICIO := 2.3
const GOLPES_GIRO := [0.90, 1.50]
const FIN_GIRO := 1.9

const SHADER_CAPA := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform vec4 color : source_color = vec4(1.0);
uniform bool usar_textura = false;
uniform float alto = 1.0;        // alto de la capa en sus coordenadas
uniform float arriba = 0.0;      // y de los hombros
uniform float fuerza = 0.06;     // cuánto ondea (más al correr)
uniform bool recorte = false;    // la imagen trae transparencia (borde roto)
void vertex() {
	float bajo = clamp((arriba - VERTEX.y) / alto, 0.0, 1.0);   // 0 en los hombros, 1 en el borde
	float w = bajo * bajo;
	VERTEX.z -= w * fuerza * (1.0 + 0.6 * sin(TIME * 2.3 + VERTEX.x * 4.0));
	VERTEX.x += w * fuerza * 0.35 * sin(TIME * 3.1 + VERTEX.y * 5.0);
}
void fragment() {
	vec4 c = usar_textura ? texture(textura, UV) * color : color;
	ALBEDO = c.rgb;
	ROUGHNESS = 0.85;
	if (recorte) {
		ALPHA = c.a;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
	}
}
"""

var espada: Node3D          # mano derecha
var espada_izq: Node3D      # mano izquierda (Garon lucha con dos espadas)
var elemento := ""          # espadas imbuidas: "Fuego", "Hielo", "Rayo", "Agua" o "" (sin imbuir)
var _aura_mat: ShaderMaterial
var _chispas: Array = []
var escudo: Node3D
var capa: Node3D
var _mats_capa: Array = []
var _capa_largo := 0.0                 # medidas de la capa en unidades del esqueleto (_medidas_capa)
var _capa_ancho := 0.0
var _capa_fondo := 0.0                 # cuánto se va hacia atrás su borde de abajo (curva + caída), en su espacio
var _capa_curva := 0.0                 # curva del centro arriba (crece un 40 % hacia abajo)
var _i := {}


func _init() -> void:
	ruta_modelo = "res://garon.fbx"
	rutas_extra = ["res://Meshy_AI_Crimson_Helm_Guardian_20261103_animated_mixamo_All_animation.fbx", "res://garon.glb"]
	usa_vara = false        # lleva sus espadas, no el cetro de maga_3d.gd (si no, se queda colgando)
	clave_esperas = "Garon"     # sus esperas de exploración (esperas_3d.gd)
	vel_andar = 1.09        # sus clips sin patinar (marcha() de maga_3d.gd; prueba_anim_pies.gd)
	vel_correr = 3.64


func _ready() -> void:
	super._ready()
	if skel == null:
		return
	for nombre in ["RightHand", "RightHandIndex1", "RightHandPinky1", "RightHandMiddle1", "RightHandThumb1",
			"LeftHand", "LeftForeArm", "LeftHandIndex1", "LeftHandPinky1", "LeftHandMiddle1", "LeftHandThumb1", "Spine2", "Neck",
		"LeftArm", "RightArm", "LeftToeBase", "RightToeBase", "LeftFoot", "RightFoot"]:
		_i[nombre] = _hueso(nombre)
	_crear_espada()
	_crear_escudo()
	_crear_capa()
	gestos.al_terminar = _actualizar_equipo


# ---------------------------------------------------------------- animaciones

func _mapear_animaciones() -> void:
	var lib: AnimationLibrary = anim.get_animation_library("")
	if lib == null:
		return
	for n in lib.get_animation_list():
		var b := String(n).to_lower()
		for clave in RENOMBRAR:
			if clave in b and not lib.has_animation(RENOMBRAR[clave]):
				lib.rename_animation(n, RENOMBRAR[clave])
				break
	for n in ["Paseo", "Andar", "Correr", "Juicio", "Giro", "Morir"]:
		if lib.has_animation(n):
			nombres[n] = n
			_quitar_avance(n)
	# Movimientos de doble espada (pack «Dual-Blade Combat Essentials», pasados a los huesos de Garon
	# con el redireccionamiento de esqueleto de Godot): guardia de combate y pasos adelante/atrás.
	if ResourceLoader.exists(RUTA_ESPADAS):
		var extra: AnimationLibrary = load(RUTA_ESPADAS)
		for n in extra.get_animation_list():
			if not lib.has_animation(n):
				lib.add_animation(n, extra.get_animation(n))
	if lib.has_animation("GuardiaDoble"):
		lib.add_animation("Guardia", lib.get_animation("GuardiaDoble"))
	for n in ["AvanzarDoble", "RetrocederDoble"]:
		if lib.has_animation(n):
			nombres[n] = n
			lib.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	if lib.has_animation("Juicio") and not lib.has_animation("Guardia"):
		lib.add_animation("Guardia", _guardia_viva("Juicio"))     # sin el pack: la guardia hecha a mano
	var quieto := "Guardia" if lib.has_animation("Guardia") else "Paseo"
	nombres["Guardia"] = quieto
	nombres["Reposo"] = quieto
	nombres["Idle"] = quieto
	nombres["Walking"] = "Andar"
	nombres["Running"] = "Correr"
	for n in ["Guardia", "Paseo", "Andar", "Correr"]:
		if lib.has_animation(n):
			lib.get_animation(n).loop_mode = Animation.LOOP_LINEAR


# Guardia viva: bucle que va de la pose de «origen» en GUARDIA_A a casi la de GUARDIA_B y vuelve.
# Las caderas solo suben y bajan (los pies no se mueven).
func _guardia_viva(origen: String) -> Animation:
	var a := anim.get_animation(origen)
	var g := Animation.new()
	g.length = GUARDIA_PERIODO
	for i in a.get_track_count():
		var tipo := a.track_get_type(i)
		if tipo != Animation.TYPE_POSITION_3D and tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_SCALE_3D:
			continue
		var j := g.add_track(tipo)
		g.track_set_path(j, a.track_get_path(i))
		g.track_set_interpolation_type(j, Animation.INTERPOLATION_CUBIC)   # ida y vuelta suave
		var va
		var vb
		match tipo:
			Animation.TYPE_POSITION_3D:
				va = a.position_track_interpolate(i, GUARDIA_A)
				vb = a.position_track_interpolate(i, GUARDIA_B)
				vb = Vector3(va.x, lerpf(va.y, vb.y, GUARDIA_MEZCLA), va.z)
			Animation.TYPE_ROTATION_3D:
				va = a.rotation_track_interpolate(i, GUARDIA_A)
				vb = va.slerp(a.rotation_track_interpolate(i, GUARDIA_B), GUARDIA_MEZCLA)
			_:
				va = a.scale_track_interpolate(i, GUARDIA_A)
				vb = va
		g.track_insert_key(j, 0.0, va)
		g.track_insert_key(j, GUARDIA_PERIODO * 0.5, vb)
		g.track_insert_key(j, GUARDIA_PERIODO, va)
	return g


# Deja la animación en el sitio: la cadera no avanza (solo sube y baja).
func _quitar_avance(nombre_real: String) -> void:
	var a := anim.get_animation(nombre_real)
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(a.track_get_path(t)).ends_with("Hips"):
			continue
		var n := a.track_get_key_count(t)
		if n == 0:
			continue
		var p0: Vector3 = a.track_get_key_value(t, 0)
		for k in n:
			var p: Vector3 = a.track_get_key_value(t, k)
			a.track_set_key_value(t, k, Vector3(p0.x, p.y, p0.z))


func _hueso(fin: String) -> int:
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		if n.ends_with("_" + fin) or n.ends_with(":" + fin) or n == fin:
			return i
	return -1


# ---------------------------------------------------------------- equipo

func _crear_espada() -> void:
	espada = _nueva_espada("Right")
	if not DOS_ESPADAS:
		return
	espada_izq = _nueva_espada("Left")


func _nueva_espada(lado: String) -> Node3D:
	if _i[lado + "Hand"] < 0 or _i[lado + "HandMiddle1"] < 0:
		return null
	if (_i[lado + "HandIndex1"] < 0 or _i[lado + "HandPinky1"] < 0) and _i[lado + "HandThumb1"] < 0:
		return null
	var nodo := Node3D.new()
	nodo.name = "Espada" + ("Izq" if lado == "Left" else "")
	skel.add_child(nodo)
	var ruta: String = RUTA_ESPADA_IZQ if (lado == "Left" and RUTA_ESPADA_IZQ != "") else RUTA_ESPADA
	var largo_m := LARGO_ESPADA
	var arma: Dictionary = load("res://inventario.gd").arma_de("Garon") if ResourceLoader.exists("res://inventario.gd") else {}
	if not arma.is_empty() and ResourceLoader.exists(arma["modelo"]) and not (lado == "Left" and RUTA_ESPADA_IZQ != ""):
		ruta = arma["modelo"]                      # la que lleva equipada (inventario.gd)
		largo_m = arma.get("largo", LARGO_ESPADA)
	var largo: float = largo_m * gestos.escala
	var modelo := Node3D.new()
	modelo.rotation_degrees = GIRO_ESPADA
	modelo.position = Vector3(0, -AGARRE_ESPADA * largo, 0)
	nodo.add_child(modelo)
	if ruta != "" and ResourceLoader.exists(ruta):
		_cargar(modelo, ruta, largo, true)
	else:
		_espada_provisional(modelo, largo)
	return nodo


func _crear_escudo() -> void:
	if RUTA_ESCUDO == "" or not ResourceLoader.exists(RUTA_ESCUDO) or _i["LeftForeArm"] < 0 or _i["LeftHand"] < 0:
		return
	escudo = Node3D.new()
	escudo.name = "Escudo"
	skel.add_child(escudo)
	var modelo := Node3D.new()
	modelo.rotation_degrees = GIRO_ESCUDO
	escudo.add_child(modelo)
	_cargar(modelo, RUTA_ESCUDO, TAM_ESCUDO * gestos.escala, false)


static func capa_articulada() -> bool:
	if Engine.has_meta("capa_garon"):
		return str(Engine.get_meta("capa_garon")) == "articulada"
	var args := OS.get_cmdline_user_args()
	if "capa_articulada" in args:
		return true
	if "capa_rigida" in args:
		return false
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") == OK and c.has_section_key("garon", "capa"):
		return str(c.get_value("garon", "capa", "")) == "articulada"
	return CAPA_ARTICULADA_POR_DEFECTO


func _crear_capa() -> void:
	if RUTA_CAPA == "" or not ResourceLoader.exists(RUTA_CAPA) or _i["Spine2"] < 0:
		return
	_medidas_capa()
	var imagen := RUTA_CAPA.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]
	if imagen and capa_articulada() and _i["Neck"] >= 0 and gestos.idx.get("pecho", -1) >= 0:
		var e: float = gestos.escala                 # la misma talla que _capa_desde_imagen
		var k_largo := _capa_largo / (LARGO_CAPA * e)
		_capa_curva = CURVA_CAPA * e * _capa_ancho / (ANCHO_CAPA * e)
		_capa_fondo = _capa_curva * 1.4 + 0.16 * e * k_largo
		capa = CapaArticulada.new()
		capa.name = "Capa"
		skel.add_child(capa)
		capa.preparar(self, load(RUTA_CAPA), _capa_largo, _capa_ancho, _capa_curva, 0.16 * e * k_largo,
			BAJAR_CAPA * e)
		_mats_capa.append([capa.material, CapaArticulada.ONDA * _capa_largo])
		return
	capa = Node3D.new()
	capa.name = "Capa"
	skel.add_child(capa)
	var modelo := Node3D.new()
	modelo.rotation_degrees = GIRO_CAPA
	capa.add_child(modelo)
	var nodo: Node3D
	if RUTA_CAPA.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
		nodo = _capa_desde_imagen(load(RUTA_CAPA))
		modelo.add_child(nodo)
	else:
		nodo = _cargar(modelo, RUTA_CAPA, _capa_largo, false, true)
	if nodo != null:
		_ondear(nodo)


# Largo y ancho de la capa con las medidas del esqueleto en reposo (unidades del esqueleto). Sin los huesos, las de
# antes (LARGO_CAPA y ANCHO_CAPA por la escala).
func _medidas_capa() -> void:
	var e: float = gestos.escala
	_capa_largo = LARGO_CAPA * e
	_capa_ancho = ANCHO_CAPA * e
	var sk := skel
	var pie := -1
	for n in ["LeftToeBase", "RightToeBase", "LeftFoot", "RightFoot"]:
		if pie < 0 and _i.get(n, -1) >= 0:
			pie = _i[n]
	if _i.get("Neck", -1) >= 0 and pie >= 0:
		var alto: float = (sk.get_bone_global_rest(_i["Neck"]).origin - sk.get_bone_global_rest(pie).origin).dot(gestos.arriba)
		if alto > 0.1 * e:
			_capa_largo = minf(_capa_largo, CAPA_LARGO_ALTO * alto)
	if _i.get("LeftArm", -1) >= 0 and _i.get("RightArm", -1) >= 0:
		var hombros: float = sk.get_bone_global_rest(_i["LeftArm"]).origin.distance_to(sk.get_bone_global_rest(_i["RightArm"]).origin)
		if hombros > 0.05 * e:
			_capa_ancho = minf(_capa_ancho, CAPA_ANCHO_HOMBROS * hombros)


# Tela curva hecha con la imagen de la capa: arriba en los hombros (y = 0), cae hacia -Y,
# se abre hacia abajo y se curva hacia atrás (-Z). Malla de 14 × 18 cuadros para que ondee suave.
# Las proporciones (abrirse un 30 %, curva y caída hacia atrás) son las de siempre, a la talla de _medidas_capa.
func _capa_desde_imagen(tex: Texture2D) -> MeshInstance3D:
	var e: float = gestos.escala
	var largo := _capa_largo
	var k_ancho := _capa_ancho / (ANCHO_CAPA * e)      # cuánto más estrecha que la de antes (1 = igual)
	var k_largo := _capa_largo / (LARGO_CAPA * e)
	_capa_fondo = CURVA_CAPA * e * k_ancho * 1.4 + 0.16 * e * k_largo
	_capa_curva = CURVA_CAPA * e * k_ancho
	var columnas := 14
	var filas := 18
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var nor := PackedVector3Array()
	var idx := PackedInt32Array()
	for j in filas + 1:
		var fv := float(j) / filas
		var ancho := _capa_ancho * (1.0 + 0.3 * fv)
		var curva := CURVA_CAPA * e * k_ancho * (1.0 + 0.4 * fv)
		for i in columnas + 1:
			var fu := float(i) / columnas
			var x := (fu - 0.5) * ancho
			var c := 2.0 * fu - 1.0
			v.append(Vector3(x, -fv * largo, -curva * (1.0 - c * c) - 0.16 * e * k_largo * fv))
			uv.append(Vector2(1.0 - fu, fv))          # vista desde atrás: la imagen no sale al revés
			nor.append(Vector3(0, 0, -1))
	for j in filas:
		for i in columnas:
			var a := j * (columnas + 1) + i
			idx.append_array([a, a + 1, a + columnas + 1, a + 1, a + columnas + 2, a + columnas + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_INDEX] = idx
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	mi.set_meta("recorte", true)
	return mi


# Carga una malla (.obj/.mesh) o escena (.glb/.fbx/.tscn) y la escala para que su lado más largo
# mida "largo". anclar_abajo: el origen queda en su base (empuñadura); anclar_arriba: en su borde superior (capa).
func _cargar(modelo: Node3D, ruta: String, largo: float, anclar_abajo: bool, anclar_arriba := false) -> Node3D:
	var r = load(ruta)
	var nodo: Node3D
	if r is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = r
		var base := ruta.get_basename()
		if ResourceLoader.exists(base + "_color.jpg") or ResourceLoader.exists(base + "_color.png"):
			mi.material_override = load("res://material_arma.gd").de_base(base)   # con brillo (sin quedar blanco)
		nodo = mi
	elif r is PackedScene:
		nodo = r.instantiate()
	else:
		return null
	modelo.add_child(nodo)
	var caja := _caja(nodo)
	var lado := maxf(caja.size.x, maxf(caja.size.y, caja.size.z))
	if lado > 0.0001:
		var e := largo / lado
		nodo.scale = Vector3.ONE * e
		var y := caja.get_center().y
		if anclar_abajo:
			y = caja.position.y
		elif anclar_arriba:
			y = caja.end.y
		nodo.position = -Vector3(caja.get_center().x, y, caja.get_center().z) * e
	return nodo


func _caja(n: Node) -> AABB:
	var caja := AABB()
	var hay := false
	for m in [n] + n.find_children("*", "VisualInstance3D", true, false):
		if m is VisualInstance3D:
			var tr: Transform3D = Transform3D.IDENTITY if m == n else (n as Node3D).global_transform.affine_inverse() * m.global_transform
			var c: AABB = tr * m.get_aabb()
			caja = c if not hay else caja.merge(c)
			hay = true
	return caja


# Cambia el material de la capa por uno que ondea (conserva su textura de color).
func _ondear(nodo: Node3D) -> void:
	var mallas: Array = [nodo] if nodo is MeshInstance3D else []
	mallas += nodo.find_children("*", "MeshInstance3D", true, false)
	for mi in mallas:
		var mesh: Mesh = mi.mesh
		var aabb: AABB = mesh.get_aabb()
		for s in mesh.get_surface_count():
			var viejo = mi.material_override if mi.material_override != null else mi.get_active_material(s)
			var m := ShaderMaterial.new()
			m.shader = Shader.new()
			m.shader.code = SHADER_CAPA
			if viejo is StandardMaterial3D:
				m.set_shader_parameter("color", viejo.albedo_color)
				if viejo.albedo_texture != null:
					m.set_shader_parameter("textura", viejo.albedo_texture)
					m.set_shader_parameter("usar_textura", true)
			else:
				m.set_shader_parameter("color", Color(0.55, 0.1, 0.12))
			m.set_shader_parameter("alto", maxf(aabb.size.y, 0.001))
			m.set_shader_parameter("arriba", aabb.end.y)
			m.set_shader_parameter("fuerza", 0.06 * aabb.size.y)
			m.set_shader_parameter("recorte", mi.has_meta("recorte"))
			mi.material_override = null
			mi.set_surface_override_material(s, m)
			_mats_capa.append([m, 0.06 * aabb.size.y])


# Más viento al correr y al girar, poco en reposo.
func _viento(f: float) -> void:
	for par in _mats_capa:
		par[0].set_shader_parameter("fuerza", par[1] * f)


func _espada_provisional(modelo: Node3D, largo: float) -> void:
	var acero := StandardMaterial3D.new()
	acero.albedo_color = Color(0.78, 0.8, 0.85)
	acero.metallic = 0.9
	acero.roughness = 0.25
	var oro := StandardMaterial3D.new()
	oro.albedo_color = Color(0.85, 0.65, 0.3)
	oro.metallic = 0.8
	oro.roughness = 0.35
	var cuero := StandardMaterial3D.new()
	cuero.albedo_color = Color(0.3, 0.18, 0.1)
	var piezas := [
		[BoxMesh.new(), Vector3(0.07, 0.72, 0.016), Vector3(0, 0.6, 0), acero],     # hoja
		[BoxMesh.new(), Vector3(0.26, 0.04, 0.05), Vector3(0, 0.22, 0), oro],       # guarda
		[BoxMesh.new(), Vector3(0.035, 0.18, 0.035), Vector3(0, 0.11, 0), cuero],   # puño
		[SphereMesh.new(), Vector3(0.06, 0.06, 0.06), Vector3(0, 0.0, 0), oro],     # pomo
	]
	for p in piezas:
		var mi := MeshInstance3D.new()
		mi.mesh = p[0]
		mi.scale = p[1] * largo
		mi.position = p[2] * largo
		mi.material_override = p[3]
		modelo.add_child(mi)


func _colocar_espada(sk: Skeleton3D, nodo: Node3D, lado: String) -> void:
	if nodo == null:
		return
	var mano := sk.get_bone_global_pose(_i[lado + "Hand"]).origin
	var medio := sk.get_bone_global_pose(_i[lado + "HandMiddle1"]).origin
	var filo := medio - mano
	var hoja: Vector3
	if _i[lado + "HandIndex1"] >= 0 and _i[lado + "HandPinky1"] >= 0:   # línea de los nudillos
		hoja = sk.get_bone_global_pose(_i[lado + "HandIndex1"]).origin - sk.get_bone_global_pose(_i[lado + "HandPinky1"]).origin
	else:                                                                # sin índice ni meñique: hacia el pulgar
		var pulgar := sk.get_bone_global_pose(_i[lado + "HandThumb1"]).origin - mano
		hoja = pulgar - filo.normalized() * pulgar.dot(filo.normalized())
	hoja = hoja.normalized()                                             # la hoja sale por el lado del pulgar
	filo = (filo - hoja * filo.dot(hoja)).normalized()
	nodo.global_transform = sk.global_transform * Transform3D(Basis(filo, hoja, filo.cross(hoja)), mano.lerp(medio, 0.75))


# Coloca espada, escudo y capa cada fotograma (después de animaciones y gestos).
func _actualizar_equipo(sk: Skeleton3D) -> void:
	var g := sk.global_transform
	_colocar_espada(sk, espada, "Right")
	_colocar_espada(sk, espada_izq, "Left")
	if escudo != null:
		var codo := sk.get_bone_global_pose(_i["LeftForeArm"]).origin
		var muneca := sk.get_bone_global_pose(_i["LeftHand"]).origin
		var largo_brazo := (muneca - codo).normalized()
		var fuera: Vector3 = sk.get_bone_global_pose(_i["LeftHand"]).basis.orthonormalized().z
		fuera = (fuera - largo_brazo * fuera.dot(largo_brazo)).normalized()
		escudo.global_transform = g * Transform3D(Basis(largo_brazo.cross(fuera), largo_brazo, fuera), codo.lerp(muneca, 0.55))
	if capa is CapaArticulada:
		capa.colocar(sk)
	elif capa != null:
		_colocar_capa(sk)


# La capa va con el PECHO (el giro de Spine2 respecto a su reposo aplicado al arriba y al adelante del personaje) y la
# línea de los HOMBROS, no con el adelante del esqueleto en reposo; al inclinarse cuelga algo hacia el suelo, solo hacia
# atrás; y nunca por debajo del plano de los pies.
func _colocar_capa(sk: Skeleton3D) -> void:
	var g := sk.global_transform
	var pecho := sk.get_bone_global_pose(_i["Spine2"])
	var giro: Basis = pecho.basis.orthonormalized() * sk.get_bone_global_rest(_i["Spine2"]).basis.orthonormalized().inverse()
	var arriba: Vector3 = (giro * gestos.arriba).normalized()
	var atras: Vector3 = -(giro * gestos.adelante)
	atras = (atras - arriba * atras.dot(arriba)).normalized()
	if _i.get("LeftArm", -1) >= 0 and _i.get("RightArm", -1) >= 0:   # cuelga de los HOMBROS: su línea tira del giro
		var h: Vector3 = sk.get_bone_global_pose(_i["RightArm"]).origin - sk.get_bone_global_pose(_i["LeftArm"]).origin
		h -= arriba * h.dot(arriba)
		if h.length() > 0.02 * gestos.escala:
			var de_hombros: Vector3 = -arriba.cross(h.normalized())    # (el mismo sentido que gestos.adelante en reposo)
			atras = atras.slerp(de_hombros, CAPA_HOMBROS) if atras.dot(de_hombros) > -0.9 else de_hombros
	atras = (atras - arriba * atras.dot(arriba)).normalized()
	var cuello: Vector3 = sk.get_bone_global_pose(_i["Neck"]).origin if _i["Neck"] >= 0 else pecho.origin + arriba * 0.05 * gestos.escala
	var pos: Vector3 = cuello - arriba * BAJAR_CAPA * gestos.escala + atras * ATRAS_CAPA * gestos.escala
	var abajo: Vector3 = (g.basis.inverse() * Vector3.DOWN).normalized()     # el suelo, en el esqueleto
	var ang := atan2(abajo.dot(atras), abajo.dot(-arriba))                  # > 0: el suelo queda detrás de la caída
	var erguido := clampf((arriba.dot(-abajo) - 0.3) / 0.4, 0.0, 1.0)   # tumbado no cuelga (se metería en el suelo)
	if ang > 0.0 and erguido > 0.0:
		var t := minf(ang * CAPA_GRAVEDAD, deg_to_rad(CAPA_GRAVEDAD_MAX)) * erguido
		var arriba2 := arriba * cos(t) - atras * sin(t)
		atras = atras * cos(t) + arriba * sin(t)
		arriba = arriba2
	var lado: Vector3 = arriba.cross(atras)
	var tr := g * Transform3D(Basis(lado, arriba, -atras), pos)
	# Nunca por debajo del suelo (el plano de los pies de Garon, el de este nodo): si el borde de abajo lo cruzaría
	# (tumbado, rodilla en tierra), la capa gira sobre los hombros hasta quedar a ras.
	var arriba_suelo: Vector3 = global_transform.basis.y.normalized()
	var borde: Vector3 = tr.basis * Vector3(0.0, -_capa_largo, -_capa_fondo)
	var alto_arriba: float = (tr.origin - global_position).dot(arriba_suelo)
	var alto_borde: float = alto_arriba + borde.dot(arriba_suelo)
	if alto_borde < CAPA_SUELO and borde.length() > 0.001:
		var largo_m := borde.length()
		var vy := clampf(CAPA_SUELO - alto_arriba, -largo_m, 0.0)
		var plano: Vector3 = borde - arriba_suelo * borde.dot(arriba_suelo)
		if plano.length() < 0.001:
			plano = (g.basis * atras) - arriba_suelo * (g.basis * atras).dot(arriba_suelo)
		var nuevo: Vector3 = plano.normalized() * sqrt(maxf(0.0, largo_m * largo_m - vy * vy)) + arriba_suelo * vy
		tr.basis = Basis(Quaternion(borde.normalized(), nuevo.normalized())) * tr.basis
	var bajo := INF                                       # y si la curva de en medio aún lo cruza, sube a ras
	for f in [0.0, 0.5, 1.0]:
		var punto: Vector3 = tr * Vector3(0.0, -f * _capa_largo, -_capa_curva * (1.0 + 0.4 * f) - (_capa_fondo - 1.4 * _capa_curva) * f)
		bajo = minf(bajo, (punto - global_position).dot(arriba_suelo))
	for x in [-0.65, 0.65]:                               # (y las esquinas del borde roto, que es un 30 % más ancho)
		var esquina: Vector3 = tr * Vector3(x * _capa_ancho, -_capa_largo, -(_capa_fondo - 1.4 * _capa_curva))
		bajo = minf(bajo, (esquina - global_position).dot(arriba_suelo))
	if bajo < CAPA_SUELO:
		tr.origin += arriba_suelo * minf(CAPA_SUELO - bajo, 0.4)
	capa.global_transform = tr


# ---------------------------------------------------------------- Embuir: magia elemental en las espadas

const COLORES_ELEMENTO := {
	"Fuego": Color(1.0, 0.45, 0.1),
	"Hielo": Color(0.55, 0.88, 1.0),
	"Rayo": Color(1.0, 0.95, 0.35),
	"Agua": Color(0.2, 0.55, 1.0),
}
const SHADER_AURA := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float fuerza = 1.0;
void fragment() {
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	float latido = 0.7 + 0.3 * sin(TIME * 6.0 + UV.y * 10.0);
	ALBEDO = color.rgb * (0.35 + fres * 1.4) * latido * fuerza;
}
"""

# Envuelve las dos hojas con el elemento elegido (brillo + chispas). elemento "" lo quita.
func embuir(nuevo: String) -> void:
	elemento = nuevo if COLORES_ELEMENTO.has(nuevo) else ""
	for p in _chispas:
		if is_instance_valid(p):
			p.queue_free()
	_chispas.clear()
	if _aura_mat == null:
		_aura_mat = ShaderMaterial.new()
		_aura_mat.shader = Shader.new()
		_aura_mat.shader.code = SHADER_AURA
	var col: Color = COLORES_ELEMENTO.get(elemento, Color.BLACK)
	_aura_mat.set_shader_parameter("color", col)
	for nodo in [espada, espada_izq]:
		if nodo == null:
			continue
		for mi in nodo.find_children("*", "MeshInstance3D", true, false):
			mi.material_overlay = _aura_mat if elemento != "" else null
		if elemento != "":
			var p := _chispas_elemento(col)
			nodo.add_child(p)
			p.position = Vector3(0, LARGO_ESPADA * gestos.escala * 0.45, 0)
			_chispas.append(p)
	if elemento != "":
		var t := create_tween()
		t.tween_method(func(v): _aura_mat.set_shader_parameter("fuerza", v), 3.0, 1.0, 0.5)


func quitar_embuir() -> void:
	embuir("")


func _chispas_elemento(col: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 10
	p.lifetime = 0.6
	p.preprocess = 0.6          # en Compatibility evita la «bola» de partículas aún no nacidas
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.02, LARGO_ESPADA * gestos.escala * 0.35, 0.02)
	p.direction = Vector3.UP
	p.spread = 40.0
	p.gravity = Vector3(0, -0.6 if elemento == "Agua" else (0.2 if elemento == "Fuego" else 0.0), 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(col, 0.9), Color(col, 0.0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2.ONE * 0.05 * gestos.escala
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	var gt := GradientTexture2D.new()
	var gg := Gradient.new()
	gg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	gt.gradient = gg
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	m.albedo_texture = gt
	q.material = m
	p.mesh = q
	return p


# ---------------------------------------------------------------- movimientos para el combate

func reposo() -> void:
	play("Idle", 0.3)                 # la guardia viva
	gestos.respirar = 1.0             # y respira
	gestos.quitar_todos(0.3, ["cansada", "g_cubrir"] if cubriendo else ["cansada"])   # cubriendo, sigue en guardia
	anim.speed_scale = 1.0
	cansada(_cansada)
	_viento(0.5)


func andar() -> void:
	_base_movimiento()
	play("Andar")
	_viento(1.0)
	_porte("andar")


func correr() -> void:
	_base_movimiento()
	play("Correr")
	_viento(2.0)
	_porte("correr")


# En combate se acerca y se aleja en guardia, con los pasos de doble espada (si no están, corre).
func avanzar(velocidad := 1.6) -> void:
	if not nombres.has("AvanzarDoble"):
		correr()
		return
	_base_movimiento()
	play("AvanzarDoble", 0.15)
	anim.speed_scale = velocidad
	_viento(1.2)


func retroceder(velocidad := 1.6) -> void:
	if not nombres.has("RetrocederDoble"):
		correr()
		return
	_base_movimiento()
	play("RetrocederDoble", 0.15)
	anim.speed_scale = velocidad
	_viento(1.2)


# Ataque normal: salta y cae con un tajo. "impacto" se llama al tocar al enemigo.
func atacar_juicio(impacto: Callable) -> void:
	await _ataque("Juicio", GOLPES_JUICIO, FIN_JUICIO, impacto)


# Ataque giratorio con dos tajos (impacto se llama dos veces).
func atacar_giro(impacto: Callable) -> void:
	await _ataque("Giro", GOLPES_GIRO, FIN_GIRO, impacto)


func _ataque(nombre: String, golpes: Array, fin: float, impacto: Callable) -> void:
	if _muerta or not nombres.has(nombre):
		return
	gestos.respirar = 0.0
	gestos.quitar_todos(0.1)
	cubriendo = false                 # al atacar deja la Guardia (el gesto se va con los demás)
	anim.speed_scale = 1.0
	play(nombre, 0.12)
	_viento(2.5)
	var antes := 0.0
	for t in golpes:
		await get_tree().create_timer(t - antes).timeout
		antes = t
		if impacto.is_valid():
			impacto.call()
	await get_tree().create_timer(fin - antes).timeout
	if not _muerta:
		reposo()


func morir() -> void:
	if _muerta:
		return
	if not nombres.has("Morir"):
		super.morir()
		return
	_muerta = true
	cubriendo = false
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3)
	anim.speed_scale = 1.0
	play("Morir", 0.15)
	_viento(0.3)


func revivir() -> void:
	if not _muerta:
		return
	if not nombres.has("Morir"):
		super.revivir()
		return
	_muerta = false
	reposo()


# ---------------------------------------------------------------- la Guardia (T-100): cubrir a un aliado

# Gesto de la Guardia (combate.gd, _guardia): se vuelve hacia el aliado que cubre y se planta delante de él: las rodillas
# dobladas, el peso abajo y el cuerpo echado hacia el golpe, con las espadas en su guardia cruzada. Se queda así mientras
# cubre: su reposo no lo quita. Lo deja al atacar, al moverse, al caer o con fin_cubrir() (cuando se acaba la Guardia).
const GESTO_CUBRIR := {
	"_cadera": Vector3(0.03, -0.08, 0.0),
	"muslo_i": [Vector3(0.45, -0.9, -0.14), 55], "rodilla_i": [Vector3(-0.25, -1, 0), 55],
	"muslo_d": [Vector3(0.45, -0.9, 0.14), 55], "rodilla_d": [Vector3(-0.25, -1, 0), 55],
	"columna": [Vector3(0.35, 1, 0), 14], "cabeza": [Vector3(0.2, 1, 0), 10],
}
var cubriendo := false


func cubrir(hacia: Vector3) -> void:
	if _muerta:
		return
	cubriendo = true
	if not gestos.gestos_def.has("g_cubrir"):
		gestos.registrar("g_cubrir", GESTO_CUBRIR)
	if hacia.length() > 0.01:
		mirar(hacia, 0.2)
	gestos.poner("g_cubrir", 1.0, 0.25)
	_viento(1.2)


func fin_cubrir() -> void:
	if not cubriendo:
		return
	cubriendo = false
	gestos.quitar("g_cubrir", 0.3)
