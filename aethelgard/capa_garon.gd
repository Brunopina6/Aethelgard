extends Node3D
# La capa ARTICULADA de Garon (V12, fase 6 del encargo del 13/11; 14/11/2026). Opción APAGADA por defecto: se
# enciende con garon_3d.gd → capa_articulada() (meta «capa_garon», argumento «capa_articulada» o Ajustes [garon] capa).
#
# Por qué: la capa de siempre (garon_3d.gd, _colocar_capa, la «rígida», que queda de respaldo) es UNA malla sin huesos
# que se coloca entera cada fotograma con el giro del pecho. Por eso es un bloque: al inclinarse (Juicio, Giro) sale
# por detrás como una tabla, el borde no reacciona al andar, correr, girar ni pararse (solo la onda del shader), su
# arriba queda separada de la espalda (el centro de la curva, a 0,31 m detrás del cuello) y tumbado se gira entera
# atravesando el cuerpo. Medidas en docs/v12/CAPA_GARON_V12.md.
#
# Qué es: la MISMA tela (garon_capa.png, la misma silueta, largo, ancho, curva y caída de _capa_desde_imagen) con un
# esqueleto PROPIO (Skeleton3D hijo de la capa: una raíz y 5 cadenas de 4 huesos) y su piel (Skin, 4 pesos por
# vértice). Es una pieza independiente del cuerpo: no toca el esqueleto de Garon, solo lo lee.
#   - Sujeción: la fila de arriba va pegada al pecho (Spine2) y sus esquinas siguen a medias a las clavículas
#     (LeftShoulder/RightShoulder). Su forma de reposo se ajusta a la espalda REAL de cada variante: se mide la malla
#     del cuerpo en reposo (original, v2 y v3 tienen cuerpos distintos) y la tela queda HOLGURA por detrás.
#   - Movimiento progresivo: cada junta tira hacia su sitio de reposo con menos fuerza cuanto más abajo (RIGIDEZ) y
#     el resto lo hacen la inercia (al andar, correr, girar y pararse) y la gravedad relativa al pecho (al inclinarse
#     cuelga hacia el suelo en vez de salir como una tabla).
#   - Sin atravesar: las juntas y los tramos chocan con cápsulas del cuerpo (tronco, cabeza, piernas y brazos, con el
#     radio medido en la malla) y de las DOS espadas, y nunca bajan del plano de los pies.
#   - Barato: 21 huesos, 285 vértices con piel en la GPU y unas 20 partículas con 13 cápsulas en GDScript; sin física
#     del motor ni SpringBoneSimulator3D (existe en 4.7.2, pero no deja ajustar la sujeción ni la gravedad relativa).

const CADENAS := 5                                  # columnas de huesos (izquierda … derecha)
const JUNTAS := [0.0, 0.3, 0.53, 0.76, 1.0]         # alto de cada junta (0 = hombros, 1 = borde roto)
const RIGIDEZ := [1.0, 0.6, 0.22, 0.1, 0.06]        # cuánto vuelve a su sitio cada junta por fotograma (a 30 fps)
const AMORTIGUAR := 0.1                             # pérdida de velocidad por fotograma (a 30 fps)
const GRAVEDAD := 9.8
const HOLGURA := 0.02                               # metros entre la tela y el cuerpo (en reposo)
const HOLGURA_CHOQUE := 0.035                       # y al chocar en movimiento (la armadura no es una cápsula)
const HOMBROS := 0.6                                # cuánto se gira la sujeción hacia la línea de los hombros (el
                                                    # resto, con el pecho; como la rígida: en la guardia del original
                                                    # el pecho va 47° girado respecto a los hombros y la espalda
                                                    # visible sigue a los hombros)
const CLAVICULA := [0.5, 0.25]                      # cuánto siguen a las clavículas las esquinas (fila 0 y fila 1)
const VEL_MAX := 9.0                                # m/s como mucho (nada sale disparado)
const ITERACIONES := 2                              # pasadas de restricciones y choques por fotograma (1 = más barato)
const SALTO := 0.6                                  # si el pecho salta más que esto (m) en un fotograma, se recoloca
const COLUMNAS := 14
const FILAS := 18
const ONDA := 0.03                                  # la onda del shader (antes 0,06: ahora la mueven los huesos)
const COLISORES := [
	["cadera", "pecho"], ["pecho", "cuello"], ["cabeza", "cabeza_fin"],
	["muslo_i", "rodilla_i"], ["rodilla_i", "pie_i"], ["muslo_d", "rodilla_d"], ["rodilla_d", "pie_d"],
	["brazo_i", "antebrazo_i"], ["antebrazo_i", "mano_i"], ["brazo_d", "antebrazo_d"], ["antebrazo_d", "mano_d"],
]

const SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform float fuerza = 0.03;     // cuánto ondea (más al correr)
void vertex() {
	float w = UV.y * UV.y;           // 0 en los hombros, 1 en el borde
	VERTEX.z -= w * fuerza * (1.0 + 0.6 * sin(TIME * 2.3 + VERTEX.x * 4.0));
	VERTEX.x += w * fuerza * 0.35 * sin(TIME * 3.1 + VERTEX.y * 5.0);
}
void fragment() {
	vec4 c = texture(textura, UV);
	ALBEDO = c.rgb;
	ROUGHNESS = 0.85;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""

static var _cache_muestras := {}                    # malla del cuerpo → muestras en reposo (se miden una vez)

var heroe: Node3D
var sk: Skeleton3D
var esq: Skeleton3D                                 # el esqueleto de la capa
var malla: MeshInstance3D
var material: ShaderMaterial
var largo := 1.0                                    # medidas en unidades del esqueleto de Garon
var ancho := 0.6
var curva := 0.15
var caida := 0.1
var desfase := 0.0                                  # cuánto se mete la tela hacia el cuerpo para tocar la espalda
var _ancla0 := Transform3D()                        # el sitio de la capa con Garon en reposo (espacio del esqueleto)
var _perfil: Array = []                             # [i][j] la espalda más atrás en cada casilla de la tela
var _reposo: Array = []                             # [c][k] juntas en reposo (espacio de la capa)
var _largo_tramo: Array = []                        # [c][k] largo de cada tramo (k → k+1)
var _lado_reposo: Array = []                        # [k] distancia entre cadenas vecinas en reposo
var _clav := [-1, -1]                               # clavícula de la esquina izquierda (c = 0) y derecha
var _i_pecho := -1
var _i_cuello := -1
var _i_brazos := [-1, -1]                           # LeftArm y RightArm (la línea de los hombros)
var _signo_hombros := 1.0
var _colisores: Array = []                          # [hueso_a, hueso_b, radio] o [nodo_espada, a, b, radio]
var _p: Array = []                                  # posición de cada junta (mundo)
var _v: Array = []                                  # velocidad
var _ancla_antes := Vector3.INF
var _bind: Array = []                               # Transform3D de reposo de cada hueso (para la CPU)
var _V := PackedVector3Array()
var _B := PackedInt32Array()
var _W := PackedFloat32Array()
var _suelo_extra := 0.0                            # cuánto se aparta la tela de la línea de sus huesos (unidades)
var reinicios := 0                                  # veces que se ha recolocado (las pruebas lo miran)
var tiempo_ultimo_us := 0                           # lo que tardó el último colocar() (microsegundos, PC)


# ---------------------------------------------------------------- preparación
func preparar(h: Node3D, tex: Texture2D, largo_su: float, ancho_su: float, curva_su: float, caida_su: float,
		bajar_su: float) -> void:
	heroe = h
	sk = h.get("skel")
	largo = largo_su
	ancho = ancho_su
	curva = curva_su
	caida = caida_su
	var gs = h.get("gestos")
	var arriba: Vector3 = gs.arriba
	var atras: Vector3 = -gs.adelante
	var lado := arriba.cross(atras)
	_i_pecho = gs.idx["pecho"]
	_i_cuello = gs.idx["cuello"]
	_i_brazos = [gs.idx.get("brazo_i", -1), gs.idx.get("brazo_d", -1)]
	var cuello: Vector3 = sk.get_bone_global_rest(gs.idx["cuello"]).origin
	_ancla0 = Transform3D(Basis(lado, arriba, -atras), cuello - arriba * bajar_su)
	if _i_brazos[0] >= 0 and _i_brazos[1] >= 0:
		var h0 := sk.get_bone_global_rest(_i_brazos[1]).origin - sk.get_bone_global_rest(_i_brazos[0]).origin
		_signo_hombros = 1.0 if h0.dot(lado) >= 0.0 else -1.0
	var muestras := _muestras_cuerpo()
	_medir_perfil(muestras)
	_preparar_juntas()
	_preparar_claviculas(gs)
	_preparar_colisores(gs, muestras)
	_crear_esqueleto_y_malla(tex)


# Muestras de la malla del cuerpo en REPOSO (espacio del esqueleto), con el hueso que más pesa en cada una. Se toma
# como mucho 1 de cada n vértices (unas 4000) y se guardan por malla: el siguiente Garon no las vuelve a medir.
func _muestras_cuerpo() -> Array:
	var res: Array = []
	for mi in heroe.find_children("*", "MeshInstance3D", true, false):
		if mi.get_parent() != sk or mi.skin == null or mi.mesh == null:
			continue
		var clave: String = mi.mesh.resource_path if mi.mesh.resource_path != "" else str(mi.mesh.get_instance_id())
		if not _cache_muestras.has(clave):
			_cache_muestras[clave] = _muestrear(mi)
		res.append_array(_cache_muestras[clave])
	return res


func _muestrear(mi: MeshInstance3D) -> Array:
	var skin: Skin = mi.skin
	var mats: Array = []
	var nombres: Array = []
	for k in skin.get_bind_count():
		var bn := String(skin.get_bind_name(k))
		var b := sk.find_bone(bn) if bn != "" else skin.get_bind_bone(k)
		mats.append(sk.get_bone_global_rest(b) * skin.get_bind_pose(k) if b >= 0 else Transform3D())
		nombres.append(sk.get_bone_name(b) if b >= 0 else "")
	var out: Array = []
	for s in mi.mesh.get_surface_count():
		var arr: Array = mi.mesh.surface_get_arrays(s)
		var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var B = arr[Mesh.ARRAY_BONES]
		var W = arr[Mesh.ARRAY_WEIGHTS]
		if B == null or W == null or V.size() == 0:
			continue
		var por: int = B.size() / V.size()
		var paso := maxi(1, V.size() / 4000)
		for v in range(0, V.size(), paso):
			var p := Vector3.ZERO
			var mejor := -1.0
			var dom := ""
			for j in por:
				var w: float = W[v * por + j]
				if w <= 0.0:
					continue
				var b := int(B[v * por + j])
				p += w * (mats[b] * V[v])
				if w > mejor:
					mejor = w
					dom = nombres[b]
			out.append([p, dom])
	return out


static func _tipo(hueso: String) -> String:
	if "Head" in hueso or "head" in hueso:
		return "cabeza"
	if "Arm" in hueso or "Hand" in hueso:
		return "brazo"
	return "cuerpo"


# Dónde está la espalda detrás de cada casilla de la tela (en el espacio de la capa en reposo: +Z hacia el cuerpo).
# La cabeza no cuenta (la tela va por debajo del yelmo) y los brazos solo arriba (hombreras): en reposo están abiertos.
func _medir_perfil(muestras: Array) -> void:
	_perfil = []
	for i in COLUMNAS + 1:
		var col: Array = []
		col.resize(FILAS + 1)
		col.fill(INF)
		_perfil.append(col)
	var inv := _ancla0.affine_inverse()
	for m in muestras:
		var t := _tipo(m[1])
		if t == "cabeza":
			continue
		var q: Vector3 = inv * m[0]
		var fv := -q.y / largo
		if fv < -0.06 or fv > 1.06 or (t == "brazo" and fv > 0.15):
			continue
		var fu := q.x / (ancho * (1.0 + 0.3 * clampf(fv, 0.0, 1.0))) + 0.5
		if fu < -0.04 or fu > 1.04:
			continue
		var i := clampi(roundi(fu * COLUMNAS), 0, COLUMNAS)
		var j := clampi(roundi(fv * FILAS), 0, FILAS)
		_perfil[i][j] = minf(_perfil[i][j], q.z)
	var liso: Array = []                       # cada casilla toma lo más atrás de sus vecinas (sin escalones)
	for i in COLUMNAS + 1:
		var col: Array = []
		for j in FILAS + 1:
			var z := INF
			for di in [-1, 0, 1]:
				for dj in [-1, 0, 1]:
					var a: int = i + di
					var b: int = j + dj
					if a >= 0 and a <= COLUMNAS and b >= 0 and b <= FILAS:
						z = minf(z, _perfil[a][b])
			col.append(z)
		liso.append(col)
	_perfil = liso
	# La tela se mete hacia el cuerpo hasta que el centro de arriba queda HOLGURA detrás de la espalda (antes
	# quedaba a ATRAS_CAPA del cuello y el centro de la curva, mucho más atrás: separada de la espalda).
	var holgura := HOLGURA / _escala_mundo()
	var zc := INF
	for i in range(COLUMNAS / 2 - 1, COLUMNAS / 2 + 2):
		for j in 3:
			zc = minf(zc, _perfil[i][j])
	desfase = (zc - holgura) if zc < INF else -0.14 * largo
	desfase = minf(desfase, 0.0)


func _escala_mundo() -> float:
	return maxf(sk.global_transform.basis.get_scale().x, 0.0001) if sk != null and sk.is_inside_tree() else 1.0


# La forma de la tela en reposo (espacio de la capa): la de siempre (se abre un 30 %, curva que envuelve y caída
# hacia atrás), pegada a la espalda arriba y nunca por delante del perfil del cuerpo.
func forma(fu: float, fv: float) -> Vector3:
	var x := (fu - 0.5) * ancho * (1.0 + 0.3 * fv)
	var c := 2.0 * fu - 1.0
	var cf := curva * (1.0 + 0.4 * fv)
	var z := -cf * (1.0 - c * c) + curva - caida * fv + desfase
	var zb := _perfil_en(fu, fv)
	if zb < INF:
		z = minf(z, zb - HOLGURA / _escala_mundo())
	return Vector3(x, -fv * largo, z)


func _perfil_en(fu: float, fv: float) -> float:
	var x := clampf(fu, 0.0, 1.0) * COLUMNAS
	var y := clampf(fv, 0.0, 1.0) * FILAS
	var i0 := clampi(floori(x), 0, COLUMNAS)
	var j0 := clampi(floori(y), 0, FILAS)
	var i1 := mini(i0 + 1, COLUMNAS)
	var j1 := mini(j0 + 1, FILAS)
	var z := INF
	for v in [_perfil[i0][j0], _perfil[i1][j0], _perfil[i0][j1], _perfil[i1][j1]]:   # lo más atrás de las 4
		z = minf(z, v)
	return z


func _preparar_juntas() -> void:
	_reposo = []
	_largo_tramo = []
	for c in CADENAS:
		var col: Array = []
		var tramos: Array = []
		for k in JUNTAS.size():
			col.append(forma(float(c) / (CADENAS - 1), JUNTAS[k]))
		for k in JUNTAS.size() - 1:
			tramos.append(col[k].distance_to(col[k + 1]))
		_reposo.append(col)
		_largo_tramo.append(tramos)
	_lado_reposo = []
	for k in JUNTAS.size():
		_lado_reposo.append(_reposo[0][k].distance_to(_reposo[1][k]))


func _preparar_claviculas(gs) -> void:
	var izq: int = gs._buscar(sk, ["LeftShoulder"])
	var der: int = gs._buscar(sk, ["RightShoulder"])
	var e0: Vector3 = _ancla0 * _reposo[0][0]
	if izq >= 0 and der >= 0:
		var cerca_izq := e0.distance_to(sk.get_bone_global_rest(izq).origin) < e0.distance_to(sk.get_bone_global_rest(der).origin)
		_clav = [izq, der] if cerca_izq else [der, izq]


# Cápsulas del cuerpo entre huesos: el radio, el de la malla (85 % de las muestras más cercanas a ese tramo están
# dentro) sin pasar del hueco que tiene la tela en reposo (así en reposo no se empuja: queda con su forma).
func _preparar_colisores(gs, muestras: Array) -> void:
	_colisores = []
	var tramos: Array = []
	for par in COLISORES:
		var a: int = gs.idx.get(par[0], -1)
		var b: int = gs.idx.get(par[1], -1)
		if a >= 0 and b >= 0:
			tramos.append([a, b, sk.get_bone_global_rest(a).origin, sk.get_bone_global_rest(b).origin, []])
	for m in muestras:
		var mejor := INF
		var t_mejor = null
		for t in tramos:
			var d := _dist_tramo(m[0], t[2], t[3])
			if d < mejor:
				mejor = d
				t_mejor = t
		if t_mejor != null:
			t_mejor[4].append(mejor)
	var holgura := HOLGURA / _escala_mundo()
	for t in tramos:
		var ds: Array = t[4]
		if ds.is_empty():
			continue
		ds.sort()
		var r: float = ds[int(ds.size() * 0.85)]
		for c in CADENAS:                      # (también la sujeción y el medio de cada tramo: el yelmo enorme de
			for k in JUNTAS.size():            # Garon llega hasta la nuca, y la tela cuelga de ahí)
				r = minf(r, _dist_tramo(_ancla0 * _reposo[c][k], t[2], t[3]) - holgura)
				if k > 0:
					r = minf(r, _dist_tramo(_ancla0 * _reposo[c][k].lerp(_reposo[c][k - 1], 0.5), t[2], t[3]) - holgura)
		if r > 0.01 * largo:
			_colisores.append([t[0], t[1], r])
	for lado in ["espada", "espada_izq"]:
		var n = heroe.get(lado)
		if n is Node3D and is_instance_valid(n):
			var caja: AABB = heroe._caja(n)
			if caja.size.y > 0.001:
				var cx := caja.get_center()
				var r := clampf(0.5 * minf(caja.size.x, caja.size.z), 0.02 * largo, 0.08 * largo)
				_colisores.append([n, Vector3(cx.x, caja.position.y, cx.z), Vector3(cx.x, caja.end.y, cx.z), r])


static func _dist_tramo(p: Vector3, a: Vector3, b: Vector3) -> float:
	return p.distance_to(Geometry3D.get_closest_point_to_segment(p, a, b))


# Hueso del tramo k de la cadena c a partir de sus juntas: baja de k a k+1 (eje -Y, como la tela) y su X va de la
# cadena de la izquierda a la de la derecha.
func _hueso_de(j: Array, c: int, k: int) -> Transform3D:
	var p: Vector3 = j[c][k]
	var abajo: Vector3 = (j[c][k + 1] - p).normalized()
	var ci := maxi(c - 1, 0)
	var cd := mini(c + 1, CADENAS - 1)
	var lado: Vector3 = (j[cd][k] - j[ci][k]) + (j[cd][k + 1] - j[ci][k + 1])
	var y := -abajo
	var x := (lado - y * lado.dot(y)).normalized()
	if x.length() < 0.5:
		x = Vector3.RIGHT
	return Transform3D(Basis(x, y, x.cross(y)), p)


static func _indice(c: int, k: int) -> int:
	return 1 + c * (JUNTAS.size() - 1) + k


func _crear_esqueleto_y_malla(tex: Texture2D) -> void:
	esq = Skeleton3D.new()
	esq.name = "EsqueletoCapa"
	add_child(esq)
	esq.add_bone("capa_raiz")
	var skin := Skin.new()
	skin.add_bind(0, Transform3D())
	_bind = [Transform3D()]
	for c in CADENAS:
		for k in JUNTAS.size() - 1:
			var b := esq.add_bone("capa_%d_%d" % [c, k])
			esq.set_bone_parent(b, 0)
			var t := _hueso_de(_reposo, c, k)
			esq.set_bone_rest(b, t)
			esq.set_bone_pose(b, t)
			skin.add_bind(b, t.affine_inverse())
			_bind.append(t)
	# La tela: la malla de 14 × 18 cuadros de siempre, cada vértice con las dos cadenas y los dos tramos que lo rodean.
	_V = PackedVector3Array()
	_B = PackedInt32Array()
	_W = PackedFloat32Array()
	var uv := PackedVector2Array()
	var nor := PackedVector3Array()
	var idx := PackedInt32Array()
	var centros: Array = []                          # alto del centro de cada tramo
	for k in JUNTAS.size() - 1:
		centros.append(0.5 * (JUNTAS[k] + JUNTAS[k + 1]))
	for j in FILAS + 1:
		var fv := float(j) / FILAS
		var k0 := 0
		var tk := 0.0
		if fv <= centros[0]:
			k0 = 0
		elif fv >= centros[-1]:
			k0 = centros.size() - 2
			tk = 1.0
		else:
			for k in centros.size() - 1:
				if fv >= centros[k] and fv <= centros[k + 1]:
					k0 = k
					tk = (fv - centros[k]) / (centros[k + 1] - centros[k])
		for i in COLUMNAS + 1:
			var fu := float(i) / COLUMNAS
			_V.append(forma(fu, fv))
			uv.append(Vector2(1.0 - fu, fv))         # vista desde atrás: la imagen no sale al revés
			nor.append(Vector3(0, 0, -1))
			var x := fu * (CADENAS - 1)
			var c0 := mini(floori(x), CADENAS - 2)
			var tc := x - c0
			_B.append_array([_indice(c0, k0), _indice(c0, k0 + 1), _indice(c0 + 1, k0), _indice(c0 + 1, k0 + 1)])
			_W.append_array([(1.0 - tc) * (1.0 - tk), (1.0 - tc) * tk, tc * (1.0 - tk), tc * tk])
			# Lo que este vértice se aparta de la superficie de las cadenas (la curva entre cadena y cadena): las juntas
			# guardan esa distancia de más con el suelo, para que tumbado no se meta ningún vértice.
			var kk := 0
			while kk < JUNTAS.size() - 2 and fv > JUNTAS[kk + 1]:
				kk += 1
			var tj: float = clampf((fv - JUNTAS[kk]) / (JUNTAS[kk + 1] - JUNTAS[kk]), 0.0, 1.0)
			var a0: Vector3 = _reposo[c0][kk].lerp(_reposo[c0][kk + 1], tj)
			var a1: Vector3 = _reposo[c0 + 1][kk].lerp(_reposo[c0 + 1][kk + 1], tj)
			_suelo_extra = maxf(_suelo_extra, _V[_V.size() - 1].distance_to(a0.lerp(a1, tc)))
	for j in FILAS:
		for i in COLUMNAS:
			var a := j * (COLUMNAS + 1) + i
			idx.append_array([a, a + 1, a + COLUMNAS + 1, a + 1, a + COLUMNAS + 2, a + COLUMNAS + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _V
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_BONES] = _B
	arr[Mesh.ARRAY_WEIGHTS] = _W
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = SHADER
	material.set_shader_parameter("textura", tex)
	material.set_shader_parameter("fuerza", ONDA * largo)
	malla = MeshInstance3D.new()
	malla.name = "Tela"
	malla.mesh = m
	malla.set_surface_override_material(0, material)
	malla.custom_aabb = AABB(Vector3(-1.5, -1.8, -1.5) * largo, Vector3(3.0, 2.6, 3.0) * largo)  # nunca se recorta
	# Hermana del esqueleto (no hija): los ayudantes de los héroes v2/v3 cambian el material de toda malla hija de un
	# Skeleton3D (heroe_v3_ayudante.gd, _materiales) y la capa perdería su imagen. Los dos en el origen de la capa.
	add_child(malla)
	malla.skin = skin
	malla.skeleton = malla.get_path_to(esq)


# ---------------------------------------------------------------- cada fotograma
# Lo llama garon_3d.gd (_actualizar_equipo) después de las animaciones, los gestos y las espadas.
func colocar(_sk: Skeleton3D) -> void:
	if not is_visible_in_tree():                     # Garon oculto (en la reserva, fuera de la escena): nada que mover
		return
	var t0 := Time.get_ticks_usec()
	var dt := clampf(heroe.get_process_delta_time(), 1.0 / 240.0, 0.1)
	var g := sk.global_transform
	var pecho := sk.get_bone_global_pose(_i_pecho)
	var giro := Transform3D(pecho.basis.orthonormalized(), pecho.origin) * \
		Transform3D(sk.get_bone_global_rest(_i_pecho).basis.orthonormalized(), sk.get_bone_global_rest(_i_pecho).origin).affine_inverse()
	var ancla := giro * _ancla0
	ancla.basis = ancla.basis.orthonormalized()
	if _i_brazos[0] >= 0 and _i_brazos[1] >= 0 and HOMBROS > 0.0:
		# Se gira (sobre el eje de la columna, por el cuello) hacia la línea de los hombros de ahora
		var arriba_a: Vector3 = ancla.basis.y
		var h: Vector3 = sk.get_bone_global_pose(_i_brazos[1]).origin - sk.get_bone_global_pose(_i_brazos[0]).origin
		h = (h - arriba_a * h.dot(arriba_a)) * _signo_hombros
		var lado_a: Vector3 = ancla.basis.x
		if h.length() > 0.001:
			var ang := lado_a.signed_angle_to(h.normalized(), arriba_a)
			if absf(ang) < deg_to_rad(120.0):
				var pivote: Vector3 = sk.get_bone_global_pose(_i_cuello).origin
				var rot := Basis(arriba_a, ang * HOMBROS)
				ancla = Transform3D(rot * ancla.basis, pivote + rot * (ancla.origin - pivote))
				ancla.basis = ancla.basis.orthonormalized()
	global_transform = g * ancla
	var a_mundo := global_transform
	var s := _escala_mundo()
	# Adónde iría cada junta pegada al pecho (y las esquinas de arriba, a medias con su clavícula)
	var obj: Array = []
	var deltas_clav: Array = []
	for b in _clav:
		if b >= 0:
			var pose := sk.get_bone_global_pose(b)
			var rest := sk.get_bone_global_rest(b)
			deltas_clav.append(Transform3D(pose.basis.orthonormalized(), pose.origin) * Transform3D(rest.basis.orthonormalized(), rest.origin).affine_inverse())
	for c in CADENAS:
		var col: Array = []
		for k in JUNTAS.size():
			var w: Vector3 = a_mundo * _reposo[c][k]
			if deltas_clav.size() == 2 and (c == 0 or c == CADENAS - 1) and k < CLAVICULA.size():
				var dc: Transform3D = deltas_clav[0 if c == 0 else 1]
				w = w.lerp(g * (dc * (_ancla0 * _reposo[c][k])), CLAVICULA[k])
			col.append(w)
		obj.append(col)
	var reiniciar := _p.is_empty() or _ancla_antes == Vector3.INF or _ancla_antes.distance_to(a_mundo.origin) > SALTO
	_ancla_antes = a_mundo.origin
	if reiniciar:
		reinicios += 1
		_p = []
		_v = []
		for c in CADENAS:
			_p.append(obj[c].duplicate())
			var vs: Array = []
			vs.resize(JUNTAS.size())
			vs.fill(Vector3.ZERO)
			_v.append(vs)
	# Gravedad relativa al pecho: erguido no tira (la forma de reposo ya cuelga); inclinado o tumbado, hacia el suelo.
	var abajo_pecho := -(a_mundo.basis.y.normalized())
	var grav := (Vector3.DOWN - abajo_pecho) * GRAVEDAD
	var amort := pow(1.0 - AMORTIGUAR, dt * 30.0)
	var antes: Array = []
	for c in CADENAS:
		antes.append(_p[c].duplicate())
		_p[c][0] = obj[c][0]
		_v[c][0] = Vector3.ZERO
		for k in range(1, JUNTAS.size()):
			_v[c][k] = (_v[c][k] + grav * dt) * amort
			_p[c][k] += _v[c][k] * dt
			_p[c][k] = _p[c][k].lerp(obj[c][k], 1.0 - pow(1.0 - RIGIDEZ[k], dt * 30.0))
	var cols := _colisores_mundo(g)
	var suelo_o := heroe.global_position
	var suelo_n := heroe.global_transform.basis.y.normalized()
	for _it in ITERACIONES:
		_restricciones(s)
		_chocar(cols, s)
		var alto_min := HOLGURA + _suelo_extra * s
		for c in CADENAS:                                # nunca por debajo de los pies
			for k in range(1, JUNTAS.size()):
				var h: float = (_p[c][k] - suelo_o).dot(suelo_n)
				if h < alto_min:
					_p[c][k] += suelo_n * (alto_min - h)
	for c in CADENAS:
		for k in range(1, JUNTAS.size()):
			var v: Vector3 = (_p[c][k] - antes[c][k]) / dt
			_v[c][k] = v.limit_length(VEL_MAX) if not reiniciar else Vector3.ZERO
	# Los huesos, en el espacio de la capa
	var inv := a_mundo.affine_inverse()
	var loc: Array = []
	for c in CADENAS:
		var col: Array = []
		for k in JUNTAS.size():
			col.append(inv * _p[c][k])
		loc.append(col)
	for c in CADENAS:
		for k in JUNTAS.size() - 1:
			esq.set_bone_pose(_indice(c, k), _hueso_de(loc, c, k))
	tiempo_ultimo_us = Time.get_ticks_usec() - t0


# Las cadenas no se separan ni se juntan de más (la tela no se rompe ni se arruga en un punto) y cada tramo mide lo
# suyo (de arriba abajo: la sujeción manda).
func _restricciones(s: float) -> void:
	for k in range(1, JUNTAS.size()):
		var d0: float = _lado_reposo[k] * s
		for c in CADENAS - 1:
			var d: Vector3 = _p[c + 1][k] - _p[c][k]
			var l := d.length()
			if l < 0.0001:
				continue
			var l2 := clampf(l, 0.8 * d0, 1.12 * d0)
			if not is_equal_approx(l, l2):
				var corr: Vector3 = d * ((l - l2) / l) * 0.5
				_p[c][k] += corr
				_p[c + 1][k] -= corr
	for c in CADENAS:
		for k in range(1, JUNTAS.size()):
			var d: Vector3 = _p[c][k] - _p[c][k - 1]
			var l := d.length()
			var l0: float = _largo_tramo[c][k - 1] * s
			if l > 0.0001:
				_p[c][k] = _p[c][k - 1] + d * (l0 / l)


func _colisores_mundo(g: Transform3D) -> Array:
	var res: Array = []
	var s := _escala_mundo()
	for col in _colisores:
		if col[0] is int:
			res.append([g * sk.get_bone_global_pose(col[0]).origin, g * sk.get_bone_global_pose(col[1]).origin, col[2] * s, false])
		elif is_instance_valid(col[0]) and col[0].is_inside_tree() and col[0].visible:
			var t: Transform3D = col[0].global_transform
			res.append([t * col[1], t * col[2], col[3] * s, true])
	return res


# Empuja fuera de cada cápsula las juntas y los tramos (el punto del tramo más cercano a la cápsula), sin tocar la
# fila de arriba (la sujeción).
func _chocar(cols: Array, _s: float) -> void:
	for col in cols:
		var a: Vector3 = col[0]
		var b: Vector3 = col[1]
		var r: float = col[2] + HOLGURA_CHOQUE
		for c in CADENAS:
			for k in range(1, JUNTAS.size()):
				var p0: Vector3 = _p[c][k - 1]
				var p1: Vector3 = _p[c][k]
				var par := Geometry3D.get_closest_points_between_segments(p0, p1, a, b)
				var d: Vector3 = par[0] - par[1]
				var l := d.length()
				if l >= r:
					continue
				var fuera: Vector3 = d / l if l > 0.0001 else -global_transform.basis.z.normalized()
				var empuje: Vector3 = fuera * (r - l)
				var seg := p1 - p0
				var t := 1.0
				if seg.length_squared() > 0.000001:
					t = clampf((par[0] - p0).dot(seg) / seg.length_squared(), 0.0, 1.0)
				if k - 1 == 0:                               # la junta de arriba no se mueve: empuja la de abajo
					_p[c][k] += (empuje / maxf(t, 0.35)).limit_length(0.15)
				else:
					_p[c][k - 1] += empuje * (1.0 - t)
					_p[c][k] += empuje * t
		# Una hoja (o una pierna al girar) puede pasar ENTRE dos cadenas: también los tramos de lado a lado (con el cuerpo,
		# solo en la tela libre, por debajo de la sujeción).
		for k in range(1 if col[3] else 2, JUNTAS.size()):
			for c in CADENAS - 1:
				var par := Geometry3D.get_closest_points_between_segments(_p[c][k], _p[c + 1][k], a, b)
				var d: Vector3 = par[0] - par[1]
				var l := d.length()
				if l >= r:
					continue
				var fuera: Vector3 = d / l if l > 0.0001 else -global_transform.basis.z.normalized()
				var seg: Vector3 = _p[c + 1][k] - _p[c][k]
				var t := 0.5
				if seg.length_squared() > 0.000001:
					t = clampf((par[0] - _p[c][k]).dot(seg) / seg.length_squared(), 0.0, 1.0)
				_p[c][k] += fuera * (r - l) * (1.0 - t)
				_p[c + 1][k] += fuera * (r - l) * t


# ---------------------------------------------------------------- para las pruebas
# Los vértices de la tela como se ven ahora (la piel calculada en la CPU, sin la onda del shader).
func puntos_mundo() -> PackedVector3Array:
	var mats: Array = []
	var ge := esq.global_transform
	for b in esq.get_bone_count():
		mats.append(ge * esq.get_bone_global_pose(b) * _bind[b].affine_inverse())
	var out := PackedVector3Array()
	out.resize(_V.size())
	for v in _V.size():
		var p := Vector3.ZERO
		for j in 4:
			var w: float = _W[v * 4 + j]
			if w > 0.0:
				p += w * (mats[_B[v * 4 + j]] * _V[v])
		out[v] = p
	return out


# Las juntas (mundo): fila 0 la sujeción … fila 4 el borde.
func juntas() -> Array:
	return _p


func colisores() -> Array:
	return _colisores_mundo(sk.global_transform)
