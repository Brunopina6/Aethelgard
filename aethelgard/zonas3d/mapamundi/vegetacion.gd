extends RefCounted
# V12, mapamundi 3D (15/11/2026): los bosques agrupados de la maqueta.
#
# Dónde: en la zona «bosque» de la máscara del mapa 2D (los bosques que pinta el mapa), en sotos de pradera (manchas de
# ruido: bosques agrupados, no árboles sueltos por todas partes) y pinos en las faldas de la sierra. Nunca en el camino,
# la playa, los sitios ni la roca alta. El Corro de los Mirlos (el secreto) queda dentro de un soto cerrado: solo se ve
# entrando por su senda casi borrada.
# Cómo: MultiMesh por trozos de la rejilla (4 × 4) y dos tipos (copa redonda y pino). Cada trozo tiene además una
# versión LEJANA muy simple (un cono o una bola de pocas caras) que sustituye a la de cerca a partir de LEJOS metros de la
# cámara (visibility_range de Godot): el detalle lejano se simplifica sin que se note desde la cámara elevada.
# Densidad según el perfil (bajo 0,6 · medio 0,8 · alto 1). Los troncos son obstáculos (troncos(): celdas de 1 m).

const D := preload("res://zonas3d/mapamundi/datos.gd")
const T := preload("res://zonas3d/mapamundi/terreno.gd")
const Kit := preload("res://zonas3d/mapamundi/kit.gd")
const PASO := 1.7                        # rejilla de candidatos (m)
const LEJOS := 48.0                      # a partir de aquí, la versión lejana
const DENSIDAD := {"bajo": 0.6, "medio": 0.8, "alto": 1.0}
const LIBRE := {"oakhaven": 9.2, "pastos": 7.0, "campamento": 5.0, "portal": 3.2, "secreto": 3.0, "gran_bosque": 3.2}
const SOTO_SECRETO := 8.5                # radio del soto que esconde el corro

var troncos := {}                        # Vector2i (celda de 1 m) → true
var cuantos := 0
var nodos: Array = []


static func _malla_copa(lejos: bool) -> ArrayMesh:
	var k := Kit.new()
	var verde := Color(0.36, 0.60, 0.25)
	if lejos:
		k.bola(Vector3(0, 1.35, 0), 0.85, verde, 0.95, 2, 5)
		return k.malla()
	k.cilindro(Vector3.ZERO, 0.13, 0.09, 0.8, 5, Color(0.42, 0.29, 0.18), false)
	k.bola(Vector3(0, 1.25, 0), 0.78, verde, 0.85, 3, 7)
	k.bola(Vector3(0.12, 1.78, -0.05), 0.52, verde.lightened(0.08), 0.85, 3, 6, 0.4)
	return k.malla()


static func _malla_pino(lejos: bool) -> ArrayMesh:
	var k := Kit.new()
	var verde := Color(0.20, 0.42, 0.26)
	if lejos:
		k.cono(Vector3(0, 0.25, 0), 0.7, 1.9, 5, verde)
		return k.malla()
	k.cilindro(Vector3.ZERO, 0.1, 0.08, 0.45, 5, Color(0.40, 0.27, 0.17), false)
	k.cono(Vector3(0, 0.35, 0), 0.72, 0.95, 7, verde)
	k.cono(Vector3(0, 0.85, 0), 0.56, 0.85, 7, verde.lightened(0.05))
	k.cono(Vector3(0, 1.3, 0), 0.38, 0.8, 7, verde.lightened(0.1))
	return k.malla()


func crear(padre: Node3D, mat: Material, perfil: String) -> void:
	var dd := T.datos()
	var dens: float = DENSIDAD.get(perfil, 0.8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 15112026
	var mancha := FastNoiseLite.new()
	mancha.seed = 1521
	mancha.frequency = 0.07
	var tipo := FastNoiseLite.new()
	tipo.seed = 1522
	tipo.frequency = 0.11
	var secreto: Vector2 = D.SITIOS["secreto"]["centro"]
	var nx := int((T.ANCHO - 1) / PASO)
	var nz := int((T.FONDO - 1) / PASO)
	var por_trozo := {}                   # Vector3i(trozo x, trozo z, tipo) → [Transform3D, Color]
	for jz in nz:
		for jx in nx:
			var p := Vector2(T.X0 + 1.0 + jx * PASO + rng.randf_range(-0.6, 0.6), T.Z0 + 1.0 + jz * PASO + rng.randf_range(-0.6, 0.6))
			var sorteo := rng.randf()
			var escala := rng.randf_range(0.8, 1.35)
			var giro := rng.randf() * TAU
			var tinte := rng.randf_range(-0.08, 0.08)
			if sorteo > dens:
				continue
			var costa := T.campo("costa", p.x, p.y)
			if costa < 1.8:
				continue
			if T.campo("camino", p.x, p.y) < 2.5 or T.campo("senda", p.x, p.y) < 1.1:
				continue
			var lejos_de_todo := true
			for id in LIBRE:
				if p.distance_to(D.SITIOS[id]["centro"]) < LIBRE[id]:
					lejos_de_todo = false
			if p.distance_to(D.SITIOS["cueva"]["centro"]) < 4.2 or p.distance_to(D.SITIOS["cueva"]["entrada"]) < 3.0:
				lejos_de_todo = false
			if not lejos_de_todo:
				continue
			var m := T.campo("monte", p.x, p.y)
			if m > 4.5:
				continue
			var prob := 0.0
			var n := mancha.get_noise_2dv(p)
			if T.es_bosque(p.x, p.y):
				prob = 0.62 + 0.3 * smoothstep(-0.3, 0.4, n)
			else:
				prob = smoothstep(0.22, 0.5, n) * 0.85 + 0.015
			if m > 0.8:
				prob = maxf(prob, 0.4)
			var ds := p.distance_to(secreto)
			if ds > 2.9 and ds < SOTO_SECRETO:
				prob = 0.97                         # el soto cerrado alrededor del corro
			if sorteo / dens > prob:
				continue
			var es_pino := m > 0.8 or (T.es_bosque(p.x, p.y) and tipo.get_noise_2dv(p) > 0.15)
			var h := T.altura(p.x, p.y)
			var tr := Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * escala), Vector3(p.x, h - 0.05, p.y))
			var col := Color(1.0 + tinte, 1.0 + tinte * 0.5, 1.0 - tinte * 0.6)
			var clave := Vector3i(clampi(int((p.x - T.X0) / ((T.ANCHO - 1) / 4.0)), 0, 3),
				clampi(int((p.y - T.Z0) / ((T.FONDO - 1) / 4.0)), 0, 3), 1 if es_pino else 0)
			if not por_trozo.has(clave):
				por_trozo[clave] = []
			por_trozo[clave].append([tr, col])
			troncos[Vector2i(int(floor(p.x)), int(floor(p.y)))] = true
			cuantos += 1
	var mallas := [[_malla_copa(false), _malla_copa(true)], [_malla_pino(false), _malla_pino(true)]]
	var sombra := perfil == "alto"
	for clave in por_trozo:
		var lista: Array = por_trozo[clave]
		for lejos in [false, true]:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = mallas[clave.z][1 if lejos else 0]
			mm.instance_count = lista.size()
			for k in lista.size():
				mm.set_instance_transform(k, lista[k][0])
				mm.set_instance_color(k, lista[k][1])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Arboles_%d_%d_%s%s" % [clave.x, clave.y, "pino" if clave.z == 1 else "copa", "_lejos" if lejos else ""]
			mmi.multimesh = mm
			mmi.material_override = mat
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (sombra and not lejos) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if lejos:
				mmi.visibility_range_begin = LEJOS
			else:
				mmi.visibility_range_end = LEJOS
			padre.add_child(mmi)
			nodos.append(mmi)


func hay_tronco(x: float, z: float) -> bool:
	return troncos.has(Vector2i(int(floor(x)), int(floor(z))))
